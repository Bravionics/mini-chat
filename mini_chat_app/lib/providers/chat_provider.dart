import '../models/message.dart';
import '../models/room.dart';
import '../services/chat_service.dart';
import 'package:flutter/foundation.dart';

/// Manages chat state and communication with the backend server.
/// Uses [ChatService] for WebSocket and HTTP operations.
class ChatProvider with ChangeNotifier {
  final ChatService _chatService;

  /// List of available chat rooms
  List<Room> rooms = [];

  /// Messages in the current room
  List<Message> messages = [];

  /// ID of the currently active room, null if no room selected
  String? currentRoom;

  /// Whether WebSocket connection is established
  bool isConnected = false;

  /// Whether rooms are currently being refreshed
  bool isRefreshing = false;

  ChatProvider(this._chatService) {
    _initialize();
  }

  /// Initializes WebSocket connection and sets up message listener
  Future<void> _initialize() async {
    try {
      await _chatService.connect();
      isConnected = true;
      _chatService.messages.listen(_handleMessage);
      await refreshRooms();
      notifyListeners();
    } catch (e) {
      print('Failed to initialize chat: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  /// Handles incoming messages from WebSocket.
  /// Updates rooms list on room updates and adds messages
  /// to current room's message list
  void _handleMessage(Message message) {
    if (message.type == MessageType.roomUpdate) {
      refreshRooms();
    } else if (message.room == currentRoom) {
      messages.add(message);
      notifyListeners();
    }
  }

  /// Fetches updated list of rooms from server
  Future<void> refreshRooms() async {
    try {
      isRefreshing = true;
      notifyListeners();

      // Create a future that delays for 1000ms
      final minLoadingFuture = Future.delayed(
        const Duration(milliseconds: 1000),
      );

      // Get rooms and wait for minimum loading time
      final roomsFuture = _chatService.getRooms();
      final results = await Future.wait([minLoadingFuture, roomsFuture]);
      rooms = results[1]; // roomsFuture result
    } catch (e) {
      print('Failed to refresh rooms: $e');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// Creates a new chat room with given name.
  /// Throws an exception if creation fails
  Future<void> createRoom(String name) async {
    try {
      await _chatService.createRoom(name);
      await refreshRooms();
    } catch (e) {
      print('Failed to create room: $e');
      rethrow;
    }
  }

  /// Joins a chat room and clears previous messages.
  /// [roomId] - ID of room to join
  void joinRoom(String roomId) {
    currentRoom = roomId;
    messages.clear();
    _chatService.joinRoom(roomId);
    notifyListeners();
  }

  /// Sends a text message to the current room.
  /// Does nothing if no room is selected
  void sendMessage(String content) {
    if (currentRoom == null) return;

    final message = Message(
      type: MessageType.text,
      content: content,
      sender: 'user', // TODO: Replace with actual user ID when auth is added
      room: currentRoom!,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    _chatService.sendMessage(message);
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
