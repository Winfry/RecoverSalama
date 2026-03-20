import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single chat message
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Chat state notifier — manages conversation with AI
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
      : super([
          ChatMessage(
            text:
                'Hi! I\'m your recovery assistant. Ask me anything about your '
                'recovery in English or Kiswahili.',
            isUser: false,
          ),
        ]);

  Future<void> sendMessage(String text) async {
    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true)];

    // TODO: Call FastAPI backend → Gemini AI with RAG
    // POST /api/chat { message: text, language: 'en' }
    // The backend retrieves relevant Kenya MOH nutrition/clinical chunks
    // from pgvector, injects them into the Gemini prompt, and returns
    // a clinically grounded response.

    // Placeholder AI response
    await Future.delayed(const Duration(seconds: 1));
    state = [
      ...state,
      ChatMessage(
        text: 'I\'m connecting to the AI... This will use Gemini API '
            'with Kenya MOH clinical guidelines once the backend is live.',
        isUser: false,
      ),
    ];
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});
