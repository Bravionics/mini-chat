import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/message_bubble.dart';
import '../components/message_input.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

/// A page that displays a chat room with messages and allows sending new messages.
class ChatPage extends StatefulWidget {
  /// The ID of the room to display
  final String roomId;

  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            // Find the current room
            final currentRoom = chatProvider.rooms.firstWhere(
              (room) => room.id == widget.roomId,
              orElse: () => throw Exception('Room not found'),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(currentRoom.name),
              ],
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (chatProvider.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });

                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isCurrentUser =
                        message.sender ==
                        'user'; // TODO: Replace with actual user check

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          MessageInput(
            onSendMessage: (content, {List<String>? imagePaths}) {
              context.read<ChatProvider>().sendMessage(
                content,
                imagePaths: imagePaths,
              );
            },
          ),
        ],
      ),
    );
  }
}
