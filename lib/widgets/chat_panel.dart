import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chatbot_service.dart';
import '../theme/app_theme.dart';

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
  final int? memberId;
  const ChatPanel({super.key, required this.onClose, this.memberId});

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

  // -- Colors --------------------------------------------------------
  // Restyled to match the PrimeFit Support widget on the landing page: a
  // near-black panel with gold + cyan accents, in both light and dark mode.
  static const Color _cyan = Color(0xFF18B7D9);
  static const Color _onGold = Color(0xFF0A0A0A);

  Color get _accent => AppColors.gold;
  Color get _panelBg => const Color(0xFF0A0A0A);
  Color get _panelBorder => const Color(0xFF26262B);
  Color get _dividerColor => const Color(0xFF1F1F23);
  Color get _titleColor => Colors.white;
  Color get _iconMuted => const Color(0xFFB4B4BC);
  Color get _bubbleOther => const Color(0xFF1A1A1D);
  Color get _bubbleOtherBorder => const Color(0xFF26262B);
  Color get _bubbleOtherText => const Color(0xFFF4F4F5);
  Color get _inputFill => const Color(0xFF0A0A0A);
  Color get _hintColor => const Color(0xFFA1A1AA);
  Color get _inputText => Colors.white;
  Color get _subtitleColor => const Color(0xFFA1A1AA);

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
          ? await ChatbotService.sendTextMessage(text, memberId: widget.memberId)
          : await ChatbotService.sendImagesMessage(
              images.map((e) => e.bytes).toList(),
              images.map((e) => e.name).toList(),
              caption: text,
              memberId: widget.memberId,
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
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showHistory)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 20, color: _titleColor),
                onPressed: () => setState(() => _showHistory = false),
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: _showHistory ? 10 : 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showHistory)
                    Text(
                      'Chat History',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _titleColor),
                    )
                  else ...[
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20),
                        children: [
                          const TextSpan(
                              text: 'Prime', style: TextStyle(color: _cyan)),
                          TextSpan(
                              text: 'Fit', style: TextStyle(color: _accent)),
                          TextSpan(
                              text: ' Support',
                              style: TextStyle(color: _titleColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask about your membership, workouts and more.',
                      style: TextStyle(fontSize: 13, color: _subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_showHistory)
            IconButton(
              tooltip: 'History',
              icon: Icon(Icons.history, size: 20, color: _iconMuted),
              onPressed: () => setState(() => _showHistory = true),
            ),
          IconButton(
            tooltip: 'New chat',
            icon: Icon(Icons.add_comment_outlined, size: 20, color: _iconMuted),
            onPressed: _newChat,
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: _iconMuted),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_sessions.isEmpty) {
      return Center(child: Text('No conversations yet.', style: TextStyle(color: _subtitleColor)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: _dividerColor),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isCurrent = session.id == _currentSessionId;
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          selectedTileColor: const Color(0x14FFFFFF),
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isCurrent ? _accent : _iconMuted,
          ),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: _titleColor,
            ),
          ),
          subtitle: Text(
            '${session.messages.length} messages · ${_formatTime(session.createdAt)}',
            style: TextStyle(color: _subtitleColor),
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
      padding: const EdgeInsets.all(20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            decoration: BoxDecoration(
              color: msg.isMe ? _accent : _bubbleOther,
              borderRadius: BorderRadius.circular(18),
              border: msg.isMe ? null : Border.all(color: _bubbleOtherBorder),
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
                      ? Text(
                          msg.text,
                          style: const TextStyle(
                            color: _onGold,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : MarkdownBody(
                          data: msg.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: _bubbleOtherText, fontSize: 14.5, height: 1.45),
                            strong: TextStyle(
                              color: _bubbleOtherText,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: TextStyle(color: _bubbleOtherText),
                            h1: TextStyle(
                                color: _bubbleOtherText, fontWeight: FontWeight.bold, fontSize: 18),
                            h2: TextStyle(
                                color: _bubbleOtherText, fontWeight: FontWeight.bold, fontSize: 16),
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _dividerColor)),
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

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  Widget _buildInputBar() {
    final atLimit = _pendingImages.length >= kMaxChatImages;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: atLimit ? 'Photo limit reached ($kMaxChatImages)' : 'Attach photos',
            icon: Icon(Icons.image_outlined, color: _accent),
            onPressed: _sending ? null : _pickImages,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              style: TextStyle(color: _inputText),
              cursorColor: _accent,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: _hintColor),
                filled: true,
                fillColor: _inputFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: _inputBorder(_accent),
                enabledBorder: _inputBorder(_accent),
                focusedBorder: _inputBorder(_accent),
                disabledBorder: _inputBorder(_accent.withValues(alpha: 0.4)),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _onGold,
              disabledBackgroundColor: _accent.withValues(alpha: 0.4),
              disabledForegroundColor: _onGold,
              fixedSize: const Size(48, 48),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.send_rounded, size: 22),
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _panelBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _panelBorder),
      ),
      child: LayoutBuilder(
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accent,
                      ),
                    ),
                  ),
                _buildPendingImageStrip(),
                _buildInputBar(),
              ],
            ],
          );
        },
      ),
    );
  }
}
