#ifndef LOCAL_LLM_APP_INFERENCE_H_
#define LOCAL_LLM_APP_INFERENCE_H_

#include "llm_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct llm_ctx llm_ctx;
typedef void (*llm_token_cb)(const char* token, int32_t len, int32_t is_final, void* user);

llm_ctx* llm_load_model(const char* gguf_path,
                        int32_t n_gpu_layers,
                        int32_t n_ctx,
                        int32_t n_threads,
                        int32_t backend_hint,
                        char* err_buf,
                        int32_t err_buf_len);

void llm_free_model(llm_ctx* ctx);

int32_t llm_apply_chat_template(llm_ctx* ctx,
                                const char* messages_json,
                                char* out,
                                int32_t out_len);

// Synchronous (blocking) generation — kept for backward compat.
int32_t llm_start_generation(llm_ctx* ctx,
                             const char* prompt,
                             int32_t max_tokens,
                             float temperature,
                             float top_p,
                             int32_t top_k,
                             float repeat_penalty,
                             uint32_t seed,
                             llm_token_cb cb,
                             void* user);

// Async generation — returns immediately; spawns a std::thread.
// Returns 0 on successful launch, -1 on error.
// After calling this, poll with llm_get_generation_status().
int32_t llm_start_generation_async(llm_ctx* ctx,
                                   const char* prompt,
                                   int32_t max_tokens,
                                   float temperature,
                                   float top_p,
                                   int32_t top_k,
                                   float repeat_penalty,
                                   uint32_t seed,
                                   llm_token_cb cb,
                                   void* user);

// Returns generation status:
//   0 = idle (no generation running)
//   1 = running
//   2 = completed (success)
//   3 = cancelled
//   4 = completed (error)
int32_t llm_get_generation_status(llm_ctx* ctx);

void llm_cancel_generation(llm_ctx* ctx);

int32_t llm_get_kv_cache_used(llm_ctx* ctx);

void llm_get_metrics(llm_ctx* ctx,
                     double* time_to_first_token_ms,
                     double* tokens_per_sec,
                     int32_t* n_prompt_tokens,
                     int32_t* n_decoded);

int32_t llm_probe_backends(int32_t* out_vulkan_ok, int32_t* out_opencl_ok);

const char* llm_version(void);

#ifdef __cplusplus
}
#endif

#endif  // LOCAL_LLM_APP_INFERENCE_H_
