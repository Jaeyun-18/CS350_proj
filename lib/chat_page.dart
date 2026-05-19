import 'package:flutter/material.dart';

import 'chat_service.dart';

const Color _chatBackground = Color(0xFFF8FAFC);
const Color _chatSurface = Colors.white;
const Color _chatText = Color(0xFF0F172A);
const Color _chatSubtle = Color(0xFF64748B);
const Color _chatBorder = Color(0xFFE2E8F0);
const Color _chatDivider = Color(0xFFF1F5F9);
const Color _chatPlaceholder = Color(0xFFCBD5E1);
const Color _chatSenderName = Color(0xFF94A3B8);
const Color _chatGreen = Color(0xFF22C55E);

const LinearGradient _chatGreenGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF34D399), Color(0xFF16A34A)],
);

/// Realtime chat room for a single group.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.currentUserId,
    this.service,
  });

  final String groupId;
  final String groupName;
  final int memberCount;
  final String currentUserId;

  /// Injectable for testing; defaults to the Firestore implementation.
  final ChatService? service;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatService _service =
      widget.service ?? FirestoreChatService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        groupId: widget.groupId,
        text: text,
        senderId: widget.currentUserId,
      );
      _controller.clear();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 실패: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chatBackground,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              groupName: widget.groupName,
              memberCount: widget.memberCount,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _service.watchMessages(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _ChatNotice(text: '메시지를 불러오지 못했어요.');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return const _ChatNotice(
                      text: '아직 메시지가 없어요.\n첫 메시지를 보내보세요.',
                    );
                  }

                  _scrollToBottom();
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message,
                        isMine: message.senderId == widget.currentUserId,
                      );
                    },
                  );
                },
              ),
            ),
            _ChatComposer(
              controller: _controller,
              isSending: _isSending,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.groupName,
    required this.memberCount,
    required this.onBack,
  });

  final String groupName;
  final int memberCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: _chatSurface,
        border: Border(bottom: BorderSide(color: _chatDivider)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _chatBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _chatBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _chatText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _chatGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$memberCount members',
                      style: const TextStyle(color: _chatSubtle, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatNotice extends StatelessWidget {
  const _ChatNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _chatSubtle, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (isMine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              gradient: _chatGreenGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2, top: 4),
            child: Text(
              _formatTime(message.createdAt),
              style: const TextStyle(color: _chatPlaceholder, fontSize: 10),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChatAvatar(name: message.senderName),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    color: _chatSenderName,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _chatSurface,
                  border: Border.all(color: _chatBorder, width: 1.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: _chatText,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 4),
                child: Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(color: _chatPlaceholder, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF86EFAC), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _chatSurface,
        border: Border(top: BorderSide(color: _chatDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _chatBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _chatBorder, width: 1.5),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: _chatText, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: _chatPlaceholder, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            key: const ValueKey('chat-send-button'),
            onTap: isSending ? null : onSend,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _chatGreenGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
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

String _formatTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
