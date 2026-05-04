#include "inference.h"

#include <llama.h>
#include <ggml-backend.h>

#include <atomic>
#include <cstring>
#include <cstdio>
#include <new>
#include <string>
#include <thread>
#include <vector>

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

// Opaque type for the abort callback user data.
struct llm_abort_data {
    std::atomic<int> * flag;
};

// Generation status enum (mirrors the C ABI return of llm_get_generation_status).
enum class GenStatus : int32_t {
    IDLE      = 0,
    RUNNING   = 1,
    DONE      = 2,
    CANCELLED = 3,
    ERROR     = 4,
};

struct llm_ctx {
    struct llama_model   * model   = nullptr;
    struct llama_context * ctx     = nullptr;
    struct llama_sampler * sampler = nullptr;

    const struct llama_vocab * vocab = nullptr;

    // Cancellation flag (set from any thread, read from gen thread).
    std::atomic<int> cancel_flag{0};

    // Async generation thread.
    std::thread * gen_thread = nullptr;

    // Protected by gen_mutex when read/written across threads.
    GenStatus                gen_status   = GenStatus::IDLE;
    std::mutex               gen_mutex;
    int64_t                  t_start_us       = 0;
    int64_t                  t_prompt_end_us  = 0;
    int32_t                  n_prompt_tokens  = 0;
    int32_t                  n_decoded        = 0;
    double                   time_to_first_token_ms = 0.0;
    double                   tokens_per_sec         = 0.0;

    // Abort callback user-data; freed in llm_free_model.
    llm_abort_data * abort_data = nullptr;
};

// Ensure llama_backend_init is called exactly once.
static std::atomic<bool> g_backend_initialized{false};

static bool ensure_backend_init() {
    bool expected = false;
    if (g_backend_initialized.compare_exchange_strong(expected, true)) {
        llama_backend_init();
    }
    return true;
}

// ---------------------------------------------------------------------------
// Helper: write a message into a fixed-size error buffer
// ---------------------------------------------------------------------------

static void set_error(char * buf, int32_t buf_len, const char * msg) {
    if (buf && buf_len > 0) {
        int32_t len = static_cast<int32_t>(std::strlen(msg));
        if (len >= buf_len) len = buf_len - 1;
        std::memcpy(buf, msg, static_cast<size_t>(len));
        buf[len] = '\0';
    }
}

// ---------------------------------------------------------------------------
// Helper: shared decode loop used by both sync and async paths
// ---------------------------------------------------------------------------

// The generation loop body.  Returns GenStatus::DONE, GenStatus::CANCELLED,
// or GenStatus::ERROR.  On success, populates state->metrics fields.
static GenStatus run_generation_loop(llm_ctx * state,
                                      int32_t   max_tokens,
                                      llm_token_cb cb,
                                      void *     user) {
    max_tokens = (max_tokens <= 0) ? 512 : max_tokens;

    std::vector<char> piece_buffer(256);
    auto * batch = new (std::nothrow) llama_token[1];
    if (!batch) return GenStatus::ERROR;

    int32_t generated = 0;
    bool    first_token = true;

    while (generated < max_tokens) {
        // Check cancellation
        if (state->cancel_flag.load() != 0) {
            delete[] batch;
            return GenStatus::CANCELLED;
        }

        // Sample the next token
        llama_token token_id = llama_sampler_sample(
            state->sampler, state->ctx, -1);

        if (token_id == LLAMA_TOKEN_NULL ||
            llama_vocab_is_eog(state->vocab, token_id)) {
            break;
        }

        // Detokenize
        int32_t piece_len = llama_token_to_piece(
            state->vocab, token_id,
            piece_buffer.data(), static_cast<int32_t>(piece_buffer.size()),
            0, false);

        if (piece_len < 0) {
            piece_buffer.resize(static_cast<size_t>(-piece_len));
            piece_len = llama_token_to_piece(
                state->vocab, token_id,
                piece_buffer.data(), static_cast<int32_t>(piece_buffer.size()),
                0, false);
        }

        if (piece_len > 0) {
            cb(piece_buffer.data(), piece_len,
               (generated + 1 >= max_tokens) ? 1 : 0, user);

            llama_sampler_accept(state->sampler, token_id);
        }

        if (first_token) {
            first_token = false;
            int64_t now = llama_time_us();
            state->time_to_first_token_ms =
                static_cast<double>(now - state->t_prompt_end_us) / 1000.0;
        }

        generated++;
        state->n_decoded = generated;

        // Prepare next input
        batch[0] = token_id;
        llama_batch next_batch = llama_batch_get_one(batch, 1);
        next_batch.logits[0] = 1;

        int32_t ret = llama_decode(state->ctx, next_batch);
        if (ret != 0) {
            delete[] batch;
            return GenStatus::ERROR;
        }
    }

    // Final metrics
    if (generated > 0) {
        int64_t t_end_us = llama_time_us();
        double total_ms = static_cast<double>(t_end_us - state->t_start_us) / 1000.0;
        state->tokens_per_sec =
            static_cast<double>(generated) / (total_ms / 1000.0);
    }

    delete[] batch;

    if (state->cancel_flag.load() != 0) {
        return GenStatus::CANCELLED;
    }
    return GenStatus::DONE;
}

// ---------------------------------------------------------------------------
// Helper: tokenize prompt (shared between sync/async)
// ---------------------------------------------------------------------------

// Returns the number of prompt tokens on success, or -1 on error.
// Caller must delete[] *out_tokens.
static int32_t tokenize_prompt(llm_ctx * state,
                                const char * prompt,
                                llama_token ** out_tokens) {
    int32_t n_prompt = static_cast<int32_t>(std::strlen(prompt)) + 8;
    auto * prompt_tokens = new (std::nothrow) llama_token[n_prompt];
    if (!prompt_tokens) return -1;

    n_prompt = llama_tokenize(state->vocab, prompt, -1,
                               prompt_tokens, n_prompt, true, false);
    if (n_prompt < 0) {
        if (n_prompt == (-2147483647 - 1)) {
            delete[] prompt_tokens;
            return -1;
        }
        delete[] prompt_tokens;
        n_prompt = -n_prompt;
        prompt_tokens = new (std::nothrow) llama_token[n_prompt];
        if (!prompt_tokens) return -1;
        n_prompt = llama_tokenize(state->vocab, prompt, -1,
                                   prompt_tokens, n_prompt, true, false);
        if (n_prompt <= 0) {
            delete[] prompt_tokens;
            return -1;
        }
    }

    *out_tokens = prompt_tokens;
    return n_prompt;
}

// ---------------------------------------------------------------------------
// Helper: run prompt processing
// ---------------------------------------------------------------------------

static int32_t process_prompt(llm_ctx * state,
                               llama_token * prompt_tokens,
                               int32_t n_prompt) {
    int32_t batch_size = static_cast<int32_t>(llama_n_batch(state->ctx));
    int32_t processed  = 0;

    while (processed < n_prompt) {
        int32_t chunk = n_prompt - processed;
        if (chunk > batch_size) chunk = batch_size;

        llama_batch batch = llama_batch_get_one(
            prompt_tokens + processed, chunk);

        if (processed + chunk >= n_prompt) {
            batch.logits[chunk - 1] = 1;
        }

        int32_t ret = llama_decode(state->ctx, batch);
        if (ret != 0) return (ret == 1) ? -2 : -3;

        processed += chunk;
    }
    return 0;
}

// ---------------------------------------------------------------------------
// llm_load_model
// ---------------------------------------------------------------------------

llm_ctx * llm_load_model(const char * gguf_path,
                         int32_t       n_gpu_layers,
                         int32_t       n_ctx,
                         int32_t       n_threads,
                         int32_t       backend_hint,
                         char *        err_buf,
                         int32_t       err_buf_len) {
    if (!gguf_path || !gguf_path[0]) {
        set_error(err_buf, err_buf_len, "model path is null or empty");
        return nullptr;
    }

    if (!ensure_backend_init()) {
        set_error(err_buf, err_buf_len, "backend init failed");
        return nullptr;
    }

    auto * state = new (std::nothrow) llm_ctx();
    if (!state) {
        set_error(err_buf, err_buf_len, "out of memory for llm_ctx");
        return nullptr;
    }

    // ---- Model params ----------------------------------------------------
    auto mparams = llama_model_default_params();
    std::vector<ggml_backend_dev_t> dev_list;

    if (n_gpu_layers > 0 && backend_hint != 1) {
        if (backend_hint == 0) {
            size_t nd = ggml_backend_dev_count();
            for (size_t i = 0; i < nd; ++i) {
                auto dev = ggml_backend_dev_get(i);
                auto type = ggml_backend_dev_type(dev);
                if (type == GGML_BACKEND_DEVICE_TYPE_GPU ||
                    type == GGML_BACKEND_DEVICE_TYPE_IGPU) {
                    dev_list.push_back(dev);
                }
            }
        } else {
            const char * target = (backend_hint == 2) ? "Vulkan" : "OpenCL";
            size_t nd = ggml_backend_dev_count();
            for (size_t i = 0; i < nd; ++i) {
                auto dev = ggml_backend_dev_get(i);
                const char * name = ggml_backend_dev_name(dev);
                if (name && std::strstr(name, target) != nullptr) {
                    dev_list.push_back(dev);
                }
            }
        }

        if (!dev_list.empty()) {
            dev_list.push_back(nullptr);
            mparams.devices      = dev_list.data();
            mparams.n_gpu_layers = n_gpu_layers;
        }
    }

    mparams.use_mmap    = true;
    mparams.use_mlock   = false;

    state->model = llama_model_load_from_file(gguf_path, mparams);
    if (!state->model) {
        set_error(err_buf, err_buf_len, "failed to load model from file");
        delete state;
        return nullptr;
    }

    // ---- Context params --------------------------------------------------
    auto cparams = llama_context_default_params();
    cparams.n_ctx        = static_cast<uint32_t>(n_ctx > 0 ? n_ctx : 4096);
    cparams.n_batch      = cparams.n_ctx;
    cparams.n_ubatch     = 512;
    cparams.n_threads    = n_threads > 0 ? n_threads : 4;
    cparams.n_threads_batch = cparams.n_threads;
    cparams.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_AUTO;

    state->ctx = llama_init_from_model(state->model, cparams);
    if (!state->ctx) {
        set_error(err_buf, err_buf_len, "failed to create context from model");
        llama_model_free(state->model);
        state->model = nullptr;
        delete state;
        return nullptr;
    }

    // ---- Set abort callback ----------------------------------------------
    state->abort_data = new (std::nothrow) llm_abort_data{&state->cancel_flag};
    if (!state->abort_data) {
        set_error(err_buf, err_buf_len, "out of memory for abort data");
        llama_free(state->ctx);
        llama_model_free(state->model);
        delete state;
        return nullptr;
    }

    llama_set_abort_callback(
        state->ctx,
        [](void * data) -> bool {
            auto * ad = static_cast<llm_abort_data *>(data);
            return ad->flag->load() != 0;
        },
        state->abort_data);

    state->vocab = llama_model_get_vocab(state->model);

    // ---- Build default sampler chain -------------------------------------
    {
        auto sparams = llama_sampler_chain_default_params();
        state->sampler = llama_sampler_chain_init(sparams);
        if (!state->sampler) {
            set_error(err_buf, err_buf_len, "failed to create sampler chain");
            llama_free(state->ctx);
            llama_model_free(state->model);
            delete state;
            return nullptr;
        }

        llama_sampler_chain_add(state->sampler, llama_sampler_init_top_k(40));
        llama_sampler_chain_add(state->sampler, llama_sampler_init_top_p(0.95f, 1));
        llama_sampler_chain_add(state->sampler, llama_sampler_init_temp(1.0f));
        llama_sampler_chain_add(state->sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    }

    return state;
}

// ---------------------------------------------------------------------------
// llm_free_model
// ---------------------------------------------------------------------------

void llm_free_model(llm_ctx * state) {
    if (!state) return;

    // If an async generation is running, cancel it and join the thread.
    if (state->gen_thread && state->gen_thread->joinable()) {
        state->cancel_flag.store(1);
        state->gen_thread->join();
    }
    delete state->gen_thread;
    state->gen_thread = nullptr;

    delete state->abort_data;
    state->abort_data = nullptr;

    if (state->sampler) {
        llama_sampler_free(state->sampler);
        state->sampler = nullptr;
    }
    if (state->ctx) {
        llama_free(state->ctx);
        state->ctx = nullptr;
    }
    if (state->model) {
        llama_model_free(state->model);
        state->model = nullptr;
    }
    delete state;
}

// ---------------------------------------------------------------------------
// Simple JSON array parser (unchanged)
// ---------------------------------------------------------------------------

static int parse_chat_messages(const char * json,
                                struct llama_chat_message * out,
                                int max_msgs) {
    if (!json || !out || max_msgs <= 0) return -1;

    int n = 0;
    const char * p = json;
    while (*p && *p != '[') ++p;
    if (!*p) return -1;
    ++p;

    while (*p && n < max_msgs) {
        while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) ++p;
        if (*p == ']') break;
        if (*p != '{') return -1;
        ++p;

        const char * role    = nullptr;
        const char * content = nullptr;

        while (*p && *p != '}') {
            while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) ++p;
            if (*p == '}') break;
            if (*p != '"') return -1;
            ++p;
            const char * key_start = p;
            while (*p && *p != '"') ++p;
            if (!*p) return -1;
            size_t key_len = static_cast<size_t>(p - key_start);
            ++p;
            while (*p && (*p == ' ' || *p == ':')) ++p;
            if (!*p) return -1;

            if (*p == '"') {
                ++p;
                const char * val_start = p;
                while (*p && *p != '"') {
                    if (*p == '\\') { if (*(p + 1)) p += 2; else break; }
                    else { ++p; }
                }
                if (!*p) return -1;
                if (key_len == 4 && std::strncmp(key_start, "role", 4) == 0) role = val_start;
                else if (key_len == 7 && std::strncmp(key_start, "content", 7) == 0) content = val_start;
                ++p;
            }
            while (*p && (*p == ' ' || *p == ',')) ++p;
        }
        if (*p == '}') ++p;
        if (role && content) {
            out[n].role    = role;
            out[n].content = content;
            ++n;
        }
        while (*p && (*p == ' ' || *p == ',')) ++p;
    }
    return n;
}

// ---------------------------------------------------------------------------
// llm_apply_chat_template
// ---------------------------------------------------------------------------

int32_t llm_apply_chat_template(llm_ctx *          state,
                                const char *       messages_json,
                                char *             out,
                                int32_t            out_len) {
    if (!state || !state->model || !messages_json || !out || out_len <= 0) {
        return -1;
    }

    const char * tmpl = llama_model_chat_template(state->model, nullptr);
    if (!tmpl) {
        struct llama_chat_message msgs[1];
        int n = parse_chat_messages(messages_json, msgs, 1);
        if (n > 0 && msgs[0].content) {
            const char * content = msgs[0].content;
            size_t content_len = std::strlen(content);
            size_t needed = 64 + content_len;
            if (static_cast<int32_t>(needed) > out_len) {
                return static_cast<int32_t>(needed);
            }
            return std::snprintf(out, static_cast<size_t>(out_len),
                "<bos><start_of_turn>user\n%.*s<end_of_turn>\n<start_of_turn>model\n",
                static_cast<int>(content_len), content);
        }
        return std::snprintf(out, static_cast<size_t>(out_len),
            "<bos><start_of_turn>user\n%s<end_of_turn>\n<start_of_turn>model\n",
            messages_json);
    }

    struct llama_chat_message msgs[8];
    int n_msgs = parse_chat_messages(messages_json, msgs, 8);
    if (n_msgs <= 0) {
        return std::snprintf(out, static_cast<size_t>(out_len),
            "<bos><start_of_turn>user\n%s<end_of_turn>\n<start_of_turn>model\n",
            messages_json);
    }
    return llama_chat_apply_template(
        tmpl, msgs, static_cast<size_t>(n_msgs), true, out, out_len);
}

// ---------------------------------------------------------------------------
// llm_start_generation (sync, blocking — kept for backward compat)
// ---------------------------------------------------------------------------

int32_t llm_start_generation(llm_ctx *   state,
                             const char * prompt,
                             int32_t      max_tokens,
                             float        temperature,
                             float        top_p,
                             int32_t      top_k,
                             float        repeat_penalty,
                             uint32_t     seed,
                             llm_token_cb cb,
                             void *       user) {
    if (!state || !state->ctx || !state->model || !state->vocab) return -1;
    if (!prompt || !cb) return -1;

    state->cancel_flag.store(0);
    state->n_prompt_tokens  = 0;
    state->n_decoded        = 0;
    state->time_to_first_token_ms = 0.0;
    state->tokens_per_sec         = 0.0;

    // Tokenize
    llama_token * prompt_tokens = nullptr;
    int32_t n_prompt = tokenize_prompt(state, prompt, &prompt_tokens);
    if (n_prompt <= 0) return -1;
    state->n_prompt_tokens = n_prompt;

    // Process prompt
    state->t_start_us = llama_time_us();
    int32_t ret = process_prompt(state, prompt_tokens, n_prompt);
    delete[] prompt_tokens;
    if (ret != 0) return ret;
    state->t_prompt_end_us = llama_time_us();

    // Setup sampler
    llama_sampler_reset(state->sampler);
    {
        const int n_samplers = llama_sampler_chain_n(state->sampler);
        if (n_samplers > 0) {
            struct llama_sampler * old_dist =
                llama_sampler_chain_remove(state->sampler, n_samplers - 1);
            if (old_dist) llama_sampler_free(old_dist);
        }
        llama_sampler_chain_add(
            state->sampler,
            llama_sampler_init_dist(
                seed == LLAMA_DEFAULT_SEED ? LLAMA_DEFAULT_SEED : seed));
    }

    // Run generation loop
    GenStatus status = run_generation_loop(state, max_tokens, cb, user);

    switch (status) {
        case GenStatus::CANCELLED: return 1;
        case GenStatus::ERROR:     return -3;
        default:                   return 0;
    }
}

// ---------------------------------------------------------------------------
// Async generation thread entry point
// ---------------------------------------------------------------------------

struct llm_async_args {
    llm_ctx *    state;
    std::string  prompt;
    int32_t      max_tokens;
    float        temperature;
    float        top_p;
    int32_t      top_k;
    float        repeat_penalty;
    uint32_t     seed;
    llm_token_cb cb;
    void *       user;
};

static void async_gen_thread_proc(llm_async_args args) {
    llm_ctx * state = args.state;

    // Reset state for this generation
    state->cancel_flag.store(0);
    state->n_prompt_tokens  = 0;
    state->n_decoded        = 0;
    state->time_to_first_token_ms = 0.0;
    state->tokens_per_sec         = 0.0;

    // Tokenize
    llama_token * prompt_tokens = nullptr;
    int32_t n_prompt = tokenize_prompt(state, args.prompt.c_str(), &prompt_tokens);
    if (n_prompt <= 0) {
        state->gen_status = GenStatus::ERROR;
        return;
    }
    state->n_prompt_tokens = n_prompt;

    // Process prompt
    state->t_start_us = llama_time_us();
    int32_t ret = process_prompt(state, prompt_tokens, n_prompt);
    delete[] prompt_tokens;
    if (ret != 0) {
        state->gen_status = GenStatus::ERROR;
        return;
    }
    state->t_prompt_end_us = llama_time_us();

    // Setup sampler with per-generation seed
    llama_sampler_reset(state->sampler);
    {
        const int n_samplers = llama_sampler_chain_n(state->sampler);
        if (n_samplers > 0) {
            struct llama_sampler * old_dist =
                llama_sampler_chain_remove(state->sampler, n_samplers - 1);
            if (old_dist) llama_sampler_free(old_dist);
        }
        llama_sampler_chain_add(
            state->sampler,
            llama_sampler_init_dist(
                args.seed == LLAMA_DEFAULT_SEED ? LLAMA_DEFAULT_SEED : args.seed));
    }

    // Run generation loop
    GenStatus status = run_generation_loop(
        state, args.max_tokens, args.cb, args.user);

    state->gen_status = status;
}

// ---------------------------------------------------------------------------
// llm_start_generation_async
// ---------------------------------------------------------------------------

int32_t llm_start_generation_async(llm_ctx *   state,
                                    const char * prompt,
                                    int32_t      max_tokens,
                                    float        temperature,
                                    float        top_p,
                                    int32_t      top_k,
                                    float        repeat_penalty,
                                    uint32_t     seed,
                                    llm_token_cb cb,
                                    void *       user) {
    if (!state || !state->ctx || !state->model || !state->vocab) return -1;
    if (!prompt || !cb) return -1;

    // If a generation is already running, refuse.
    if (state->gen_status == GenStatus::RUNNING) return -1;

    // If there's a previous thread that somehow didn't finish, join it.
    if (state->gen_thread && state->gen_thread->joinable()) {
        state->gen_thread->join();
    }
    delete state->gen_thread;
    state->gen_thread = nullptr;

    // Build args and spawn thread.
    llm_async_args args;
    args.state         = state;
    args.prompt        = prompt;
    args.max_tokens    = max_tokens;
    args.temperature   = temperature;
    args.top_p         = top_p;
    args.top_k         = top_k;
    args.repeat_penalty = repeat_penalty;
    args.seed          = seed;
    args.cb            = cb;
    args.user          = user;

    state->gen_status = GenStatus::RUNNING;

    state->gen_thread = new (std::nothrow) std::thread(async_gen_thread_proc, std::move(args));
    if (!state->gen_thread || !state->gen_thread->joinable()) {
        state->gen_status = GenStatus::ERROR;
        delete state->gen_thread;
        state->gen_thread = nullptr;
        return -1;
    }

    return 0;
}

// ---------------------------------------------------------------------------
// llm_get_generation_status
// ---------------------------------------------------------------------------

int32_t llm_get_generation_status(llm_ctx * state) {
    if (!state) return 0;
    return static_cast<int32_t>(state->gen_status);
}

// ---------------------------------------------------------------------------
// llm_cancel_generation
// ---------------------------------------------------------------------------

void llm_cancel_generation(llm_ctx * state) {
    if (!state) return;
    state->cancel_flag.store(1);
}

// ---------------------------------------------------------------------------
// llm_get_kv_cache_used
// ---------------------------------------------------------------------------

int32_t llm_get_kv_cache_used(llm_ctx * state) {
    if (!state || !state->ctx) return 0;
    return state->n_prompt_tokens + state->n_decoded;
}

// ---------------------------------------------------------------------------
// llm_get_metrics
// ---------------------------------------------------------------------------

void llm_get_metrics(llm_ctx * state,
                     double *  time_to_first_token_ms,
                     double *  tokens_per_sec,
                     int32_t * n_prompt_tokens,
                     int32_t * n_decoded) {
    if (!state) {
        if (time_to_first_token_ms) *time_to_first_token_ms = 0.0;
        if (tokens_per_sec)         *tokens_per_sec         = 0.0;
        if (n_prompt_tokens)        *n_prompt_tokens        = 0;
        if (n_decoded)              *n_decoded              = 0;
        return;
    }
    if (time_to_first_token_ms) *time_to_first_token_ms = state->time_to_first_token_ms;
    if (tokens_per_sec)         *tokens_per_sec         = state->tokens_per_sec;
    if (n_prompt_tokens)        *n_prompt_tokens        = state->n_prompt_tokens;
    if (n_decoded)              *n_decoded              = state->n_decoded;
}

// ---------------------------------------------------------------------------
// llm_probe_backends
// ---------------------------------------------------------------------------

int32_t llm_probe_backends(int32_t * out_vulkan_ok, int32_t * out_opencl_ok) {
    ensure_backend_init();

    int vulkan_found = 0;
    int opencl_found = 0;

    size_t nd = ggml_backend_dev_count();
    for (size_t i = 0; i < nd; ++i) {
        auto dev  = ggml_backend_dev_get(i);
        auto type = ggml_backend_dev_type(dev);
        if (type != GGML_BACKEND_DEVICE_TYPE_GPU &&
            type != GGML_BACKEND_DEVICE_TYPE_IGPU) {
            continue;
        }
        const char * name = ggml_backend_dev_name(dev);
        if (!name) continue;
        if (std::strstr(name, "Vulkan"))  vulkan_found = 1;
        if (std::strstr(name, "OpenCL"))  opencl_found = 1;
    }

    if (out_vulkan_ok) *out_vulkan_ok = vulkan_found;
    if (out_opencl_ok) *out_opencl_ok = opencl_found;
    return 0;
}

// ---------------------------------------------------------------------------
// llm_version
// ---------------------------------------------------------------------------

const char * llm_version(void) {
    return "llama.cpp (wrapped)";
}
