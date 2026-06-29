import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/services/notification_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerChatScreen extends StatefulWidget {
  const OfficerChatScreen({super.key});

  @override
  State<OfficerChatScreen> createState() => _OfficerChatScreenState();
}

class _OfficerChatScreenState extends State<OfficerChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Suppress notifications while on chat screen
    NotificationService().enterChatScreen();
    // Mark chat as read when officer opens the chat
    if (_uid.isNotEmpty) {
      _firestoreService.markChatAsReadForOfficer(_uid);
    }
  }
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _firestoreService.sendMessage(_uid, text);
      _messageController.clear();
      
      // Scroll to bottom after message is sent
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.error(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    // Re-enable notifications when leaving chat screen
    NotificationService().leaveChatScreen();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMain(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent, color: AppTheme.primary(context), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.isIndo ? 'Dukungan Admin' : 'Admin Support',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain(context),
                  ),
                ),
                Text(
                  AppLocalizations.isIndo ? 'Online' : 'Online',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: const Color(0xFF10B981), // Emerald green
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.outline(context), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.bg(context),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getChatMessagesStream(_uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppTheme.textMuted(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.isIndo
                                  ? 'Belum ada pesan. Mulai percakapan\ndengan Admin.'
                                  : 'No messages yet. Start a conversation\nwith Admin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isOfficer = msg['senderRole'] == 'officer';
                        final text = msg['message'] ?? '';
                        final timestamp = msg['timestamp'] as Timestamp?;
                        
                        // Formatting time
                        String timeText = '';
                        if (timestamp != null) {
                          timeText = DateFormat('HH:mm').format(timestamp.toDate());
                        }

                        // Determine if we need to show date header
                        bool showDateHeader = false;
                        String dateHeader = '';
                        if (index == messages.length - 1) {
                          showDateHeader = true; // First message ever
                        } else {
                          final prevMsg = messages[index + 1]; // Because it's reversed
                          final prevTimestamp = prevMsg['timestamp'] as Timestamp?;
                          if (timestamp != null && prevTimestamp != null) {
                            final date = timestamp.toDate();
                            final prevDate = prevTimestamp.toDate();
                            if (date.day != prevDate.day || date.month != prevDate.month || date.year != prevDate.year) {
                              showDateHeader = true;
                            }
                          }
                        }

                        if (showDateHeader && timestamp != null) {
                          dateHeader = DateFormat('dd MMM yyyy').format(timestamp.toDate());
                          // Check if today
                          final today = DateTime.now();
                          final date = timestamp.toDate();
                          if (date.day == today.day && date.month == today.month && date.year == today.year) {
                            dateHeader = AppLocalizations.isIndo ? 'Hari Ini' : 'Today';
                          }
                        }

                        return Column(
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.outline(context).withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    dateHeader,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted(context),
                                    ),
                                  ),
                                ),
                              ),
                            _ChatBubble(
                              text: text,
                              timeText: timeText,
                              isMe: isOfficer,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        boxShadow: [
          if (!AppTheme.isDark(context))
            const BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outline(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.textMain(context),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: AppLocalizations.isIndo ? 'Ketik pesan...' : 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary(context),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.timeText,
    required this.isMe,
  });

  final String text;
  final String timeText;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? AppTheme.primary(context) : AppTheme.surface(context);
    final textColor = isMe ? Colors.white : AppTheme.textMain(context);
    final timeColor = isMe ? Colors.white70 : AppTheme.textMuted(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent, size: 14, color: AppTheme.primary(context)),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppTheme.outline(context)),
                boxShadow: [
                  if (!AppTheme.isDark(context) && isMe)
                    BoxShadow(
                      color: AppTheme.primary(context).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24), // Keep space equivalent to avatar on the other side
        ],
      ),
    );
  }
}
