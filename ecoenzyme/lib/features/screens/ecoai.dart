import 'dart:typed_data';

import 'package:ecoenzyme/features/ecoai/data/eco_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Ecoai extends StatefulWidget {
  const Ecoai({super.key, required this.pendingCrop});

  final ValueNotifier<XFile?> pendingCrop;

  @override
  State<Ecoai> createState() => _EcoaiState();
}

class _EcoaiState extends State<Ecoai> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _service = EcoAiService();
  final List<_ChatMessage> _messages = [];

  XFile? _pendingImage;
  Future<Uint8List>? _pendingImageBytes;
  Uint8List? _contextImageBytes;
  String? _contextImageMimeType;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    widget.pendingCrop.addListener(_consumePendingCrop);
    _consumePendingCrop();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _service.getChatHistory();
      if (!mounted || _messages.isNotEmpty) return;
      setState(() {
        for (final exchange in history) {
          _messages
            ..add(_ChatMessage(exchange.prompt, isUser: true))
            ..add(_ChatMessage(exchange.reply, isUser: false));
        }
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_readableError(error))));
      });
    }
  }

  @override
  void didUpdateWidget(covariant Ecoai oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pendingCrop != widget.pendingCrop) {
      oldWidget.pendingCrop.removeListener(_consumePendingCrop);
      widget.pendingCrop.addListener(_consumePendingCrop);
      _consumePendingCrop();
    }
  }

  @override
  void dispose() {
    widget.pendingCrop.removeListener(_consumePendingCrop);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _consumePendingCrop() {
    final image = widget.pendingCrop.value;
    if (image == null) return;

    widget.pendingCrop.value = null;
    setState(() {
      _setPendingImage(image);
      if (_messageController.text.trim().isEmpty) {
        _messageController.text = 'What can you tell me about this crop?';
      }
    });
  }

  void _setPendingImage(XFile image) {
    _pendingImage = image;
    _pendingImageBytes = image.readAsBytes();
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image != null && mounted) {
        setState(() => _setPendingImage(image));
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the photo: $error')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final selectedImage = _pendingImage;
    final question = _messageController.text.trim();
    if (selectedImage == null &&
        _contextImageBytes == null &&
        question.isEmpty) {
      return;
    }
    if (selectedImage == null && _contextImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach a crop photo to ask EcoAI.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final selectedBytes = selectedImage == null
          ? null
          : await _pendingImageBytes!;
      final imageBytes = selectedBytes ?? _contextImageBytes;
      if (imageBytes == null) {
        throw StateError('Attach a crop photo before asking EcoAI.');
      }

      final prompt = question.isEmpty
          ? 'Please describe this crop and share any visible signs of stress or disease.'
          : question;
      final mimeType = selectedImage == null
          ? _contextImageMimeType!
          : _resolveMimeType(selectedImage);

      setState(() {
        _contextImageBytes = imageBytes;
        _contextImageMimeType = mimeType;
        _messages.add(
          _ChatMessage(prompt, imageBytes: selectedBytes, isUser: true),
        );
        _messageController.clear();
        _pendingImage = null;
        _pendingImageBytes = null;
      });

      final reply = await _service.analyzeCrop(
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      if (mounted) {
        setState(() => _messages.add(_ChatMessage(reply, isUser: false)));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _messages.add(
            _ChatMessage(
              'I could not analyze that photo. ${_readableError(error)}',
              isUser: false,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _resolveMimeType(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null &&
        const {
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/heic',
          'image/heif',
        }.contains(mimeType)) {
      return mimeType;
    }

    final extension = image.name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => throw StateError('Use a JPEG, PNG, WebP, or HEIC crop photo.'),
    };
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst(
      RegExp(r'^(Exception|StateError):\s*'),
      '',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _pendingImage == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B4332), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFA5D66A),
                              size: 30,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'A little greener,\none question at a time.',
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Share a crop photo and ask EcoAI for practical growing advice.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('TRY ASKING', style: textTheme.labelMedium),
                      const SizedBox(height: 12),
                      _SuggestionCard(
                        icon: Icons.eco_outlined,
                        title: 'What can you tell me about my crop?',
                        onTap: () => _messageController.text =
                            'What can you tell me about my crop?',
                      ),
                      _SuggestionCard(
                        icon: Icons.search,
                        title: 'Do you see any signs of stress?',
                        onTap: () => _messageController.text =
                            'Do you see any signs of stress?',
                      ),
                      _SuggestionCard(
                        icon: Icons.spa_outlined,
                        title: 'How can I care for this plant?',
                        onTap: () => _messageController.text =
                            'How can I care for this plant?',
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Looking at your crop…'),
                              ],
                            ),
                          ),
                        );
                      }

                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.imageBytes != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    message.imageBytes!,
                                    width: 220,
                                    height: 170,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Text(
                                message.text,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: message.isUser
                                      ? Colors.white
                                      : const Color(0xFF1B4332),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  if (_pendingImage != null) _buildPendingImagePreview(),
                  if (_pendingImage == null && _contextImageBytes != null)
                    _buildContextImagePreview(),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Choose a crop photo',
                        onPressed: _isSending ? null : _pickFromGallery,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: _contextImageBytes == null
                                ? 'Add a crop photo to get started'
                                : 'Ask a follow-up about this crop…',
                            prefixIcon: const Icon(Icons.chat_bubble_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: 'Send to EcoAI',
                        onPressed: _isSending ? null : _sendMessage,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(52, 52),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingImagePreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 64,
              width: 64,
              child: FutureBuilder<Uint8List>(
                future: _pendingImageBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Icon(Icons.broken_image_outlined);
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Crop photo ready for EcoAI')),
          IconButton(
            tooltip: 'Remove photo',
            onPressed: () {
              setState(() {
                _pendingImage = null;
                _pendingImageBytes = null;
              });
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContextImagePreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _contextImageBytes!,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Using this crop photo for follow-ups')),
          IconButton(
            tooltip: 'Clear crop photo',
            onPressed: () {
              setState(() {
                _contextImageBytes = null;
                _contextImageMimeType = null;
              });
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage(this.text, {required this.isUser, this.imageBytes});

  final String text;
  final Uint8List? imageBytes;
  final bool isUser;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
