import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart' as app_message;

/// Service for OpenAI API interactions
class OpenAIService {
  final OpenAIClient _client;

  static const String defaultSystemPrompt =
      'You are a helpful assistant that can analyze images and provide accurate responses.';

  OpenAIService({required String apiKey, String? organization})
    : _client = OpenAIClient(apiKey: apiKey, organization: organization);

  /// Send a message to the OpenAI API and get a response
  ///
  /// [message] is the user's message to send to the API
  /// [previousMessages] is the list of previous messages in the conversation
  /// [imagePaths] is an optional list of local image file paths to include with the message
  /// Returns the assistant's response as a String
  Future<String> sendMessage(
    String message,
    List<app_message.Message> previousMessages, {
    List<String>? imagePaths,
  }) async {
    try {
      // Convert the app's message model to OpenAI's message format
      final messages = await _convertToOpenAIMessages(
        message,
        previousMessages,
        imagePaths: imagePaths,
      );

      // Create a chat completion request
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.gpt4o),
          messages: messages,
          temperature: 0.7,
        ),
      );

      // Extract and return the assistant's response
      return response.choices.first.message.content ?? '';
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return 'Sorry, I encountered an error while processing your request.';
    }
  }

  /// Convert the app's message models to OpenAI's message format
  ///
  /// [currentMessage] is the new message being sent
  /// [previousMessages] is the list of previous messages in the conversation
  /// [imagePaths] is an optional list of local image file paths to include with the message
  /// Returns a list of ChatCompletionMessage objects
  Future<List<ChatCompletionMessage>> _convertToOpenAIMessages(
    String currentMessage,
    List<app_message.Message> previousMessages, {
    List<String>? imagePaths,
  }) async {
    // Start with a system message
    final messages = <ChatCompletionMessage>[
      ChatCompletionMessage.system(content: defaultSystemPrompt),
    ];

    // Add previous messages to maintain conversation context
    // Limiting to the last 10 messages to avoid token limits
    final recentMessages =
        previousMessages
            .where(
              (msg) =>
                  msg.type == app_message.MessageType.text ||
                  msg.type == app_message.MessageType.image,
            )
            .toList()
            .reversed
            .take(10)
            .toList()
            .reversed
            .toList();

    // Add previous messages
    for (final msg in recentMessages) {
      if (msg.sender == 'user') {
        // For text-only messages
        if (msg.type == app_message.MessageType.text ||
            msg.imagePaths == null) {
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(msg.content),
            ),
          );
        }
        // For messages with images
        else if (msg.type == app_message.MessageType.image &&
            msg.imagePaths != null) {
          // We don't process old image messages because we'd need to reread all files
          // Just add a placeholder indicating there were images
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                "${msg.content} [Previous message contained ${msg.imagePaths!.length} image(s)]",
              ),
            ),
          );
        }
      } else {
        messages.add(ChatCompletionMessage.assistant(content: msg.content));
      }
    }

    // Add the current message content
    if (imagePaths == null || imagePaths.isEmpty) {
      // Simple text message with no images
      messages.add(
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(currentMessage),
        ),
      );
    } else {
      // Message with images - use the parts format
      final List<ChatCompletionMessageContentPart> parts = [];

      // Add text content if not empty
      if (currentMessage.trim().isNotEmpty) {
        parts.add(ChatCompletionMessageContentPart.text(text: currentMessage));
      }

      // Add image parts
      try {
        for (final imagePath in imagePaths) {
          Uint8List imageBytes;

          if (kIsWeb) {
            // For web, fetch the image using HTTP
            try {
              final response = await http.get(Uri.parse(imagePath));
              if (response.statusCode == 200) {
                imageBytes = response.bodyBytes;
              } else {
                throw Exception('Failed to load image from URL: $imagePath');
              }
            } catch (e) {
              debugPrint('Error fetching image from web: $e');
              continue; // Skip this image if it fails
            }
          } else {
            // For mobile, read from the file system
            final file = File(imagePath);
            if (file.existsSync()) {
              imageBytes = file.readAsBytesSync();
            } else {
              debugPrint('Image file not found: $imagePath');
              continue; // Skip this image if the file doesn't exist
            }
          }

          // Convert to base64 and add to parts
          final base64Image = base64Encode(imageBytes);
          parts.add(
            ChatCompletionMessageContentPart.image(
              imageUrl: ChatCompletionMessageImageUrl(
                url: "data:image/jpeg;base64,$base64Image",
              ),
            ),
          );
        }

        // Add the message with parts (if we have any parts)
        if (parts.isNotEmpty) {
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts(parts),
            ),
          );
        } else {
          // If all images failed, fall back to just the text
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$currentMessage [No images could be processed]',
              ),
            ),
          );
        }
      } catch (e) {
        // If there's an error processing images, fall back to just the text
        debugPrint('Error processing image files: $e');
        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(
              '$currentMessage [Error processing images: $e]',
            ),
          ),
        );
      }
    }

    return messages;
  }

  /// Get available OpenAI models
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _client.listModels();
      return response.data.map((model) => model.id).toList();
    } catch (e) {
      debugPrint('Error fetching models: $e');
      return [];
    }
  }
}
