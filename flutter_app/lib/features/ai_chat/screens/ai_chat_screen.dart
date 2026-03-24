// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 06: AI Chat Assistant
// Free-text Q&A powered by Gemini API + RAG over Kenya
// clinical guidelines. Supports English + Kiswahili.
// Quick chips for common questions. Red "Connect to Doctor"
// bar appears when critical keywords are detected.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../providers/chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showDoctorCta = false;

  // Pre-written quick questions — tapping auto-sends
  final _quickQuestions = [
    'Is swelling normal?',
    'Can I shower?',
    'What should I eat?',
    'When can I walk?',
  ];

  // Keywords that trigger the "Connect to Doctor" CTA
  static const _criticalKeywords = [
    'bleeding', 'blood', 'fever', 'chest pain', 'breathing',
    'emergency', 'hospital', 'worse', 'severe', 'faint',
    'damu', 'homa', 'hospitali', 'dharura', 'hatari',
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Check if a message contains critical keywords
  bool _isCritical(String text) {
    final lower = text.toLowerCase();
    return _criticalKeywords.any((k) => lower.contains(k));
  }

  /// Send a message and scroll to bottom
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Check for critical keywords — show doctor CTA if found
    if (_isCritical(text)) {
      setState(() => _showDoctorCta = true);
    }

    // Send via Riverpod provider → will call backend API in Phase 1
    ref.read(chatProvider.notifier).sendMessage(text.trim());
    _messageCtrl.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Blue header with online status ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                child: Row(
                  children: [
                    // Green avatar circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                          child: Text('🤖',
                              style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Recovery Assistant',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            Icon(Icons.circle,
                                size: 8, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Online · Day 5 · EN/SW',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick question chips ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick questions',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickQuestions.map((q) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => _sendMessage(q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF85B7EB)),
                            ),
                            child: Text(q,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // ── Connect to Doctor CTA — appears on critical keywords ──
          if (_showDoctorCta)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                border: Border(
                    top: BorderSide(
                        color: AppColors.emergency.withOpacity(0.3))),
              ),
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.hospital),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.emergency.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('🚨', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text('Symptoms worsening? Connect to a Doctor',
                          style: TextStyle(
                              color: AppColors.emergency,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Input bar — pill shape + amber send button ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Text input — rounded pill
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ask about recovery…',
                        hintStyle: const TextStyle(
                            color: AppColors.textHint, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary),
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button — amber circle
                  GestureDetector(
                    onTap: () => _sendMessage(_messageCtrl.text),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom nav — active on AI (index 2) ──
          SalamaBottomNav(
            currentIndex: 2,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard,
                AppRoutes.checkIn,
                AppRoutes.aiChat,
                AppRoutes.diet,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }
}

/// Chat bubble widget — user bubbles right/blue, AI bubbles left/green.
/// Asymmetric border radius creates the chat tail effect.
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.successLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  // Tail effect — asymmetric corners
                  bottomLeft: Radius.circular(isUser ? 16 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.success.withOpacity(0.15)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                  child: Text('🧑', style: TextStyle(fontSize: 14))),
            ),
          ],
        ],
      ),
    );
  }
}
