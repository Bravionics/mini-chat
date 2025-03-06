import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/room.dart';
import 'chat_page.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Forum'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return IconButton(
                icon:
                    chatProvider.isRefreshing
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                onPressed:
                    chatProvider.isRefreshing
                        ? null
                        : () => chatProvider.refreshRooms(),
              );
            },
          ),
        ],
      ),
      // Use Consumer to rebuild only when rooms list changes
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (!chatProvider.isConnected) {
            return const Center(child: Text('Connecting...'));
          }

          return ListView.builder(
            itemCount: chatProvider.rooms.length,
            itemBuilder: (context, index) {
              final room = chatProvider.rooms[index];
              return RoomListTile(room: room);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoomDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Room'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Room Name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    context.read<ChatProvider>().createRoom(name);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }
}

class RoomListTile extends StatelessWidget {
  final Room room;

  const RoomListTile({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<ChatProvider>().joinRoom(room.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(roomId: room.id)),
        );
      },
      child: Container(
        height: 100, // Fixed height for the tile
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Square left section with icon
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.deepPurple,
                child: const Center(
                  child: Icon(Icons.forum, color: Colors.white, size: 32),
                ),
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and subtitle at the top
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(room.name),
                          const SizedBox(height: 4),
                          const Text('Created by: Admin'),
                        ],
                      ),
                    ),
                    // Tertiary info at the bottom
                    Text('${room.numClients} users active'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
