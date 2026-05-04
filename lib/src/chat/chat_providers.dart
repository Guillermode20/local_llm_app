import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inference/chat_template.dart';
import '../inference/inference_service.dart';
import '../inference/sampling_params.dart';
import '../models/model_repository.dart';
import 'chat_repository.dart';

// ---------------------------------------------------------------------------
// Chat repository provider
// ---------------------------------------------------------------------------

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ChatRepository(db: db);
});

// ---------------------------------------------------------------------------
// Conversation list provider
// ---------------------------------------------------------------------------

final conversationListProvider =
    StreamProvider<List<ConversationSummary>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchConversations();
});

// ---------------------------------------------------------------------------
// Active conversation provider
// ---------------------------------------------------------------------------

final activeConversationIdProvider = StateProvider<int?>((ref) => null);

// ---------------------------------------------------------------------------
// Messages provider for a specific conversation
// ---------------------------------------------------------------------------

final conversationMessagesProvider =
    StreamProvider.family<List<ChatMessage>, int>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(conversationId);
});

// ---------------------------------------------------------------------------
// Inference service provider
// ---------------------------------------------------------------------------

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  return InferenceService();
});

// ---------------------------------------------------------------------------
// Chat controller provider — orchestrates a single conversation's lifecycle
// ---------------------------------------------------------------------------

/// State of the chat controller.
sealed class ChatControllerState {
  const ChatControllerState();
}

class ChatIdle extends ChatControllerState {
  const ChatIdle();
}

class ChatGenerating extends ChatControllerState {
  const ChatGenerating({required this.assistantMessageId});
  final int assistantMessageId;
}

class ChatError extends ChatControllerState {
  const ChatError(this.message);
  final String message;
}

final chatControllerProvider =
    NotifierProvider.family<ChatControllerNotifier, ChatControllerState, int>(
  ChatControllerNotifier.new,
);

class ChatControllerNotifier extends FamilyNotifier<ChatControllerState, int> {
  StreamSubscription<dynamic>? _genSub;

  @override
  ChatControllerState build(int arg) {
    return const ChatIdle();
  }

  /// Send a user message and start generation.
  Future<void> sendMessage(String content, {int? parentMessageId}) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversationId = arg;

    // Add user message — returns the new user message's ID.
    final userMsgId = await repo.addUserMessage(
      conversationId: conversationId,
      content: content,
      parentMessageId: parentMessageId,
    );

    // Create assistant message placeholder, linked to the NEW user message.
    final assistantId = await repo.createAssistantMessage(
      conversationId: conversationId,
      parentMessageId: userMsgId, // was incorrectly using parentMessageId
    );

    state = ChatGenerating(assistantMessageId: assistantId);

    // Wire InferenceService generation pipeline.
    try {
      final inferenceService = ref.read(inferenceServiceProvider);
      final modelRepo = ref.read(modelRepositoryProvider);
      final activeModel = modelRepo.activeModel;

      if (activeModel == null) {
        state = const ChatError('No active model');
        return;
      }

      // Get message history for chat template.
      final history = await repo.getMessageHistory(conversationId);
      final systemPrompt = await repo.getSystemPrompt(conversationId);

      // Build messages list with optional system prompt.
      final messages = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.addAll(history);

      // Build prompt via chat template (using Dart-side fallback for now).
      final prompt = formatGemma3nChat(messages: messages);

      // Start generation and wire tokens.
      final stream = inferenceService.generate(
        prompt,
        sampling: activeModel.profile?.effectiveSamplingParams ??
            const SamplingParams(),
      );

      _genSub = stream.listen(
        (event) {
          repo.appendToMessage(assistantId, event.token);
        },
        onDone: () async {
          // Generation completed or cancelled.
          if (state is ChatGenerating) {
            final genState = state as ChatGenerating;
            await repo.finaliseAssistantMessage(genState.assistantMessageId);
            state = const ChatIdle();
          }
        },
        onError: (err) {
          state = ChatError(err.toString());
        },
      );
    } catch (e) {
      state = ChatError('Generation failed: $e');
    }
  }

  /// Append tokens during generation.
  Future<void> appendToken(int messageId, String token) async {
    final repo = ref.read(chatRepositoryProvider);
    final messages = await repo.watchMessages(arg).first;
    final msg = messages.where((m) => m.id == messageId).firstOrNull;
    if (msg == null) return;

    final newContent = msg.content + token;
    await repo.appendToMessage(messageId, newContent);
  }

  /// Finalise generation with metrics.
  Future<void> finaliseGeneration(int messageId,
      {Map<String, dynamic>? metrics}) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.finaliseAssistantMessage(messageId);
    state = const ChatIdle();
  }

  /// Cancel current generation.
  Future<void> cancelGeneration() async {
    final inferenceService = ref.read(inferenceServiceProvider);
    await inferenceService.cancel();
    await _genSub?.cancel();
    state = const ChatIdle();
  }

  /// Regenerate the last assistant message.
  Future<void> regenerate(int messageId) async {
    final repo = ref.read(chatRepositoryProvider);

    // Archive the current assistant message and its descendants.
    await repo.archiveBranchFrom(messageId);

    // Find the parent user message — do NOT duplicate it.
    final messages = await repo.watchMessages(arg).first;
    final msg = messages.where((m) => m.id == messageId).firstOrNull;
    if (msg == null || msg.parentMessageId == null) return;

    // Create a new assistant message linked to the EXISTING user message.
    final assistantId = await repo.createAssistantMessage(
      conversationId: arg,
      parentMessageId: msg.parentMessageId,
    );

    state = ChatGenerating(assistantMessageId: assistantId);

    // Get the parent user message content for the prompt.
    final parentMsg =
        messages.where((m) => m.id == msg.parentMessageId).firstOrNull;
    if (parentMsg == null) return;

    // Trigger inference for the new assistant message.
    try {
      final inferenceService = ref.read(inferenceServiceProvider);
      final history = await repo.getMessageHistory(arg);
      final prompt = formatGemma3nChat(messages: history);

      final stream = inferenceService.generate(prompt);

      _genSub = stream.listen(
        (event) {
          repo.appendToMessage(assistantId, event.token);
        },
        onDone: () async {
          await repo.finaliseAssistantMessage(assistantId);
          state = const ChatIdle();
        },
        onError: (err) {
          state = ChatError(err.toString());
        },
      );
    } catch (e) {
      state = ChatError('Regeneration failed: $e');
    }
  }

  /// Edit a user message and resend.
  Future<void> editAndResend(int messageId, String newContent) async {
    final repo = ref.read(chatRepositoryProvider);

    // Archive from this message onward.
    await repo.archiveBranchFrom(messageId);

    // Send the edited message — sendMessage now correctly links the
    // new assistant to the new user message.
    await sendMessage(newContent, parentMessageId: messageId);
  }

  /// Cancel the current generation subscription (not a widget lifecycle override).
  void cancelSub() {
    _genSub?.cancel();
  }
}
