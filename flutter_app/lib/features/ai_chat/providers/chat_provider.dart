import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';
import '../../recovery/providers/recovery_provider.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final List<String> sources;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.sources = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;

  /// True while waiting for Gemini response — shows typing indicator
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  ChatState copyWith({List<ChatMessage>? messages, bool? isTyping}) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
      );
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api;

  ChatNotifier(this._api)
      : super(ChatState(messages: [
          ChatMessage(
            text: 'Habari! I\'m your recovery assistant. Ask me anything '
                'about your recovery in English or Kiswahili. 🩺',
            isUser: false,
          ),
        ]));

  /// Send a message to Gemini via FastAPI.
  ///
  /// Flow:
  ///   1. Add user message to chat + show typing indicator
  ///   2. POST /api/chat/ → backend does RAG retrieval + Gemini call
  ///   3. Backend saves both messages to chat_messages table in Supabase
  ///   4. Add AI reply to chat, hide typing indicator
  ///   5. On failure → show error bubble, hide typing indicator
  Future<void> sendMessage(
    String text, {
    String surgeryType = '',
    int daysSinceSurgery = 0,
  }) async {
    if (text.trim().isEmpty) return;

    // Add user message and show typing indicator immediately
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: text.trim(), isUser: true),
      ],
      isTyping: true,
    );

    try {
      final response = await _api.sendChatMessage(
        message: text.trim(),
        surgeryType: surgeryType,
        daysSinceSurgery: daysSinceSurgery,
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? '';
      final sourcesRaw = data['sources'] as List<dynamic>? ?? [];
      final sources = sourcesRaw.map((s) => s.toString()).toList();

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: reply, isUser: false, sources: sources),
        ],
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: _friendlyError(e),
            isUser: false,
            isError: true,
          ),
        ],
        isTyping: false,
      );
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    return 'I\'m having trouble connecting right now. Please try again in a moment.';
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(apiServiceProvider));
});
