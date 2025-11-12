import 'package:flutter/material.dart';
import '../../../shared/services/messaging_service.dart';

class EmojiReactionPicker extends StatelessWidget {
  final String messageId;
  
  const EmojiReactionPicker({
    super.key,
    required this.messageId,
  });

  static const List<String> _quickEmojis = [
    '❤️', '👍', '😂', '😮', '😢', '🔥', '🎵', '🎶'
  ];

  void _addReaction(BuildContext context, String emoji) {
    MessagingService.toggleReaction(
      messageId: messageId,
      emoji: emoji,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Tepki Ver',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Quick emoji reactions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _quickEmojis.map((emoji) {
              return GestureDetector(
                onTap: () => _addReaction(context, emoji),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

void showEmojiReactionPicker(BuildContext context, String messageId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => EmojiReactionPicker(messageId: messageId),
  );
}
