import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A widget that provides a text input field, image attachment and send button for chat messages.
class MessageInput extends StatefulWidget {
  /// Callback function when a message is sent with optional image paths
  final Function(String, {List<String>? imagePaths}) onSendMessage;

  const MessageInput({super.key, required this.onSendMessage});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  static const int _maxImages = 4;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          // Limit to max 4 images
          final int remainingSlots = _maxImages - _selectedImages.length;
          if (remainingSlots > 0) {
            _selectedImages.addAll(images.take(remainingSlots));
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _handleSubmit() {
    final message = _textController.text.trim();
    
    // Allow sending if there's text or images
    if (message.isNotEmpty || _selectedImages.isNotEmpty) {
      // Convert XFile to paths for the callback
      final List<String>? imagePaths =
          _selectedImages.isNotEmpty
              ? _selectedImages.map((image) => image.path).toList()
              : null;

      widget.onSendMessage(message, imagePaths: imagePaths);

      // Clear the fields after sending
      _textController.clear();
      setState(() {
        _selectedImages.clear();
      });
      
      _focusNode.requestFocus(); // Keep focus on the input field
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Image preview area - only show if there are selected images
        if (_selectedImages.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: _buildImagePreview(_selectedImages[index]),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Input controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                      0.3,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),

              // Attach image button
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                child: IconButton(
                  onPressed:
                      _selectedImages.length < _maxImages ? _pickImages : null,
                  icon: Icon(
                    Icons.attach_file,
                    color: theme.colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withOpacity(0.4),
                    shape: const CircleBorder(),
                  ),
                ),
              ),

              // Send button
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: IconButton(
                  onPressed: _handleSubmit,
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withOpacity(0.4),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds an image preview that works on both web and mobile platforms
  Widget _buildImagePreview(XFile image) {
    return Image.network(
      image.path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
