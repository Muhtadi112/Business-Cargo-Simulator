import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _input = TextEditingController();
  List<LocalChatMessage> _messages = <LocalChatMessage>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _input.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    await _service.initialize();
    final messages = await _service.fetchChatMessages();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final message = _input.text.trim();
    if (message.isEmpty) return;
    try {
      await _service.sendChatMessage(
        sender: 'ADIEXPRESS',
        message: message,
        level: 1,
      );
      _input.clear();
      await _loadMessages();
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: const Row(
            children: [
              Icon(Icons.public, color: AppColors.emerald),
              SizedBox(width: 8),
              Text(
                'GLOBAL CHAT • MODE SIMULASI',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _messages.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.sender,
                                  style: const TextStyle(
                                    color: AppColors.emerald,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                item.isSystem ? 'SYSTEM' : 'LV ${item.level}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(item.message),
                          const SizedBox(height: 4),
                          Text(
                            item.sentAtUtc.toLocal().toString().substring(0, 16),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Tulis pesan...',
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
