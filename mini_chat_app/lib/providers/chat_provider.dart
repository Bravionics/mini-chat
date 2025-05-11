import '../models/message.dart';
import '../models/room.dart';
import '../services/chat_service.dart';
import '../services/openai_service.dart';
import 'package:flutter/foundation.dart';

/// Manages chat state and communication with the backend server.
/// Uses [ChatService] for WebSocket and HTTP operations.
class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  final OpenAIService? _openAIService;

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

  /// Error message when server connection fails
  String? connectionError;

  /// Constants for the OpenAI chat room
  static const String openAiRoomId = 'openai_assistant';
  static const String openAiRoomName = 'AI Assistant';

  /// Whether an OpenAI API request is in progress
  bool isOpenAiProcessing = false;

  ChatProvider(this._chatService, {OpenAIService? openAIService})
    : _openAIService = openAIService {
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
      connectionError = 'Could not connect to server';
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
      connectionError = null;
      notifyListeners();

      // Create a future that delays for 1000ms
      final minLoadingFuture = Future.delayed(
        const Duration(milliseconds: 1000),
      );

      // Get rooms and wait for minimum loading time
      final roomsFuture = _chatService.getRooms();
      final results = await Future.wait([minLoadingFuture, roomsFuture]);
      rooms = results[1]; // roomsFuture result

      // Always add the OpenAI room to the list if it's not already there
      _ensureOpenAiRoomExists();
    } catch (e) {
      print('Failed to refresh rooms: $e');
      connectionError = 'Could not connect to server';

      // Even if server connection fails, ensure the OpenAI room exists
      _ensureOpenAiRoomExists();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// Ensures that the OpenAI chat room always exists in the rooms list
  void _ensureOpenAiRoomExists() {
    bool openAiRoomExists = rooms.any((room) => room.id == openAiRoomId);

    if (!openAiRoomExists) {
      rooms.add(
        Room(
          id: openAiRoomId,
          name: openAiRoomName,
          numClients: 1, // Just the user and the AI
          messages: [],
        ),
      );
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
      connectionError = 'Could not connect to server';
      notifyListeners();
      rethrow;
    }
  }

  /// Joins a chat room and clears previous messages.
  /// [roomId] - ID of room to join
  void joinRoom(String roomId) {
    currentRoom = roomId;
    messages.clear();

    // Only call the chat service's joinRoom for non-OpenAI rooms
    if (roomId != openAiRoomId) {
      _chatService.joinRoom(roomId);
    }

    notifyListeners();
  }

  /// Sends a text message to the current room.
  /// Does nothing if no room is selected
  void sendMessage(String content, {List<String>? imagePaths}) async {
    if (currentRoom == null) return;

    // Create message (text or image type)
    final message = Message(
      type:
          imagePaths != null && imagePaths.isNotEmpty
              ? MessageType.image
              : MessageType.text,
      content: content,
      sender: 'user', // TODO: Replace with actual user ID when auth is added
      room: currentRoom!,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      imagePaths: imagePaths,
    );

    // If it's the OpenAI room, use the OpenAI service to get a response
    if (currentRoom == openAiRoomId) {
      // Add the user's message to the local messages list for OpenAI chat
      // This is needed because OpenAI responses aren't echoed by the main chat WebSocket
      messages.add(message);
      notifyListeners();
      await _handleOpenAiMessage(content, imagePaths: imagePaths);
    } else {
      // For regular rooms, send through the chat service
      // The message will be added to the list when it's received back from the WebSocket
      _chatService.sendMessage(message);
    }
  }

  /// Handles sending a message to the OpenAI API and processing the response
  Future<void> _handleOpenAiMessage(
    String content, {
    List<String>? imagePaths,
  }) async {
    // Check if OpenAI service is available
    if (_openAIService == null) {
      _addAiMessage(
        'OpenAI service is not configured. Please check your API key.',
      );
      return;
    }

    try {
      // Set processing flag to true to show a loading indicator if needed
      isOpenAiProcessing = true;
      notifyListeners();

      // Call the OpenAI service to get a response
      final response = await _openAIService!.sendMessage(
        content,
        messages,
        imagePaths: imagePaths,
      );

      // Add the AI's response to the messages list
      _addAiMessage(response);
    } catch (e) {
      print('Error with OpenAI: $e');
      _addAiMessage('Sorry, I encountered an error processing your request.');
    } finally {
      isOpenAiProcessing = false;
      notifyListeners();
    }
  }

  /// Helper method to add an AI message to the current conversation
  void _addAiMessage(String content) {
    if (currentRoom == null) return;

    final aiMessage = Message(
      type: MessageType.text,
      content: content,
      sender: 'Assistant', // Use 'assistant' as the sender ID for AI messages
      room: currentRoom!,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    messages.add(aiMessage);
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
