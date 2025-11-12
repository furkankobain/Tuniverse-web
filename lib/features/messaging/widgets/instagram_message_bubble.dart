import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../shared/models/message.dart';
import '../../../shared/services/messaging_service.dart';

class InstagramMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onDoubleTap;

  const InstagramMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onDoubleTap,
  });

  @override
  State<InstagramMessageBubble> createState() => _InstagramMessageBubbleState();
}

class _InstagramMessageBubbleState extends State<InstagramMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.isMe ? -0.15 : 0.15, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.isMe && details.delta.dx < 0) {
      setState(() => _showActions = true);
      _controller.forward();
    } else if (!widget.isMe && details.delta.dx > 0) {
      setState(() => _showActions = true);
      _controller.forward();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_controller.value > 0.5) {
      widget.onReply();
    }
    _controller.reverse();
    setState(() => _showActions = false);
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Dün ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd.MM HH:mm').format(timestamp);
    }
  }

  Widget _buildReactions() {
    if (widget.message.reactions == null || widget.message.reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    final reactions = widget.message.reactions!;
    
    return Positioned(
      bottom: -8,
      right: widget.isMe ? 8 : null,
      left: widget.isMe ? null : 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactions.entries.map((entry) {
            final emoji = entry.key;
            final users = entry.value;
            final hasReacted = users.contains(widget.currentUserId);
            
            return GestureDetector(
              onTap: () {
                MessagingService.toggleReaction(
                  messageId: widget.message.id,
                  emoji: emoji,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: hasReacted ? Colors.blue.shade50 : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (users.length > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${users.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasReacted ? Colors.blue : Colors.grey.shade600,
                          fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe && _showActions) ...[
              IconButton(
                icon: const Icon(Icons.reply, size: 20),
                onPressed: widget.onReply,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
            ],
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.blue
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.content,
                            style: TextStyle(
                              color: widget.isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMessageTime(widget.message.timestamp),
                                style: TextStyle(
                                  color: widget.isMe
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                              if (widget.isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  widget.message.isRead
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 12,
                                  color: widget.message.isRead
                                      ? Colors.blue.shade200
                                      : Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildReactions(),
                  ],
                ),
              ),
            ),
            if (widget.isMe && _showActions) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.reply, size: 20),
                onPressed: widget.onReply,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
