import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chatbot_service.dart';

const int kMaxChatImages = 10;
const String _kGreeting = "Hi! How can we help you today?";

class ChatMessage {
  final String text;
  final bool isMe;
  final List<Uint8List> images;
  ChatMessage({required this.text, required this.isMe, this.images = const []});
}

class _PendingImage {
  final Uint8List bytes;
  final String name;
  _PendingImage(this.bytes, this.name);
}

class _ChatSession {
  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  _ChatSession({required this.id, required this.createdAt, required this.messages});

  bool get hasUserContent => messages.any((m) => m.isMe);

  String get title {
    final firstUserMsg = messages.firstWhere(
      (m) => m.isMe,
      orElse: () => ChatMessage(text: '', isMe: true),
    );
    if (firstUserMsg.text.trim().isNotEmpty) {
      final t = firstUserMsg.text.trim();
      return t.length > 40 ? '${t.substring(0, 40)}...' : t;
    }
    if (firstUserMsg.images.isNotEmpty) {
      return 'Photos (${firstUserMsg.images.length})';
    }
    return 'New conversation';
  }
}

class ChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const ChatPanel({super.key, required this.onClose});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  bool _showHistory = false;

  final List<_ChatSession> _sessions = [];
  late String _currentSessionId;
  final List<_PendingImage> _pendingImages = [];

  @override
  void initState() {
    super.initState();
    final session = _ChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      messages: [ChatMessage(text: _kGreeting, isMe: false)],
    );
    _sessions.insert(0, session);
    _currentSessionId = session.id;
  }

  _ChatSession get _currentSession =>
      _sessions.firstWhere((s) => s.id == _currentSessionId);

  void _newChat() {
    if (_sending) return;
    setState(() {
      if (_currentSession.hasUserContent) {
        final session = _ChatSession(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          messages: [ChatMessage(text: _kGreeting, isMe: false)],
        );
        _sessions.insert(0, session);
        _currentSessionId = session.id;
      }
      _pendingImages.clear();
      _controller.clear();
      _showHistory = false;
    });
  }

  void _selectSession(String id) {
    setState(() {
      _currentSessionId = id;
      _showHistory = false;
    });
  }

  Future<void> _pickImages() async {
    if (_sending) return;
    final remaining = kMaxChatImages - _pendingImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to $kMaxChatImages photos.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;

    final toAdd = picked.take(remaining);
    final truncated = picked.length > remaining;

    for (final file in toAdd) {
      final bytes = await file.readAsBytes();
      _pendingImages.add(_PendingImage(bytes, file.name));
    }

    if (mounted) {
      setState(() {});
      if (truncated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only added up to $kMaxChatImages photos per message.')),
        );
      }
    }
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final images = List<_PendingImage>.from(_pendingImages);
    if (text.isEmpty && images.isEmpty) return;
    if (_sending) return;

    setState(() {
      _currentSession.messages.add(ChatMessage(
        text: text,
        isMe: true,
        images: images.map((e) => e.bytes).toList(),
      ));
      _controller.clear();
      _pendingImages.clear();
      _sending = true;
    });

    try {
      final reply = images.isEmpty
          ? await ChatbotService.sendTextMessage(text)
          : await ChatbotService.sendImagesMessage(
              images.map((e) => e.bytes).toList(),
              images.map((e) => e.name).toList(),
              caption: text,
            );
      setState(() {
        _currentSession.messages.add(ChatMessage(text: reply, isMe: false));
      });
    } catch (e) {
      setState(() {
        _currentSession.messages
            .add(ChatMessage(text: "Sorry, something went wrong: $e", isMe: false));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (_showHistory)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => setState(() => _showHistory = false),
            )
          else
            const Icon(Icons.support_agent, color: Color(0xFF00B4D8)),
          const SizedBox(width: 8),
          Text(
            _showHistory ? 'Chat History' : 'PrimeFit Support',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const Spacer(),
          if (!_showHistory)
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history, size: 20),
              onPressed: () => setState(() => _showHistory = true),
            ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            onPressed: _newChat,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_sessions.isEmpty) {
      return const Center(child: Text('No conversations yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isCurrent = session.id == _currentSessionId;
        return ListTile(
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isCurrent ? const Color(0xFF00B4D8) : Colors.black45,
          ),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${session.messages.length} messages · ${_formatTime(session.createdAt)}',
          ),
          selected: isCurrent,
          onTap: () => _selectSession(session.id),
        );
      },
    );
  }

  Widget _buildMessages(double maxBubbleWidth) {
    final messages = _currentSession.messages;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            decoration: BoxDecoration(
              color: msg.isMe ? const Color(0xFF00B4D8) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.images.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: msg.images
                        .map((bytes) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover),
                            ))
                        .toList(),
                  ),
                if (msg.images.isNotEmpty && msg.text.isNotEmpty)
                  const SizedBox(height: 6),
                if (msg.text.isNotEmpty)
                  msg.isMe
                      // User's own messages are plain text (not markdown).
                      ? Text(
                          msg.text,
                          style: const TextStyle(color: Colors.white),
                        )
                      // AI replies are rendered as markdown (bold, lists, etc.).
                      : MarkdownBody(
                          data: msg.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.black87, fontSize: 14),
                            strong: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(color: Colors.black87),
                            h1: const TextStyle(
                                color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                            h2: const TextStyle(
                                color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingImageStrip() {
    if (_pendingImages.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final img = _pendingImages[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(img.bytes, width: 56, height: 56, fit: BoxFit.cover),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => _removePendingImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final atLimit = _pendingImages.length >= kMaxChatImages;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: atLimit ? 'Photo limit reached ($kMaxChatImages)' : 'Attach photos',
            icon: const Icon(Icons.image_outlined, color: Color(0xFF00B4D8)),
            onPressed: _sending ? null : _pickImages,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF00B4D8)),
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * 0.72;
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _showHistory
                  ? _buildHistoryList()
                  : _buildMessages(maxBubbleWidth),
            ),
            if (!_showHistory) ...[
              if (_sending)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              _buildPendingImageStrip(),
              _buildInputBar(),
            ],
          ],
        );
      },
    );
  }
}
