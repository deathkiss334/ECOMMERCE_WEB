import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderChatDialog extends StatefulWidget {
  final String orderNumber;
  final String currentRole; // 'customer' or 'admin'
  final String currentUserName;
  final String? customerName;

  const OrderChatDialog({
    super.key,
    required this.orderNumber,
    required this.currentRole,
    required this.currentUserName,
    this.customerName,
  });

  @override
  State<OrderChatDialog> createState() => _OrderChatDialogState();
}

class _OrderChatDialogState extends State<OrderChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;

  static const Color brandOrange = Color(0xFFF36F21);

  @override
  void initState() {
    super.initState();
    _fetchMessages(initial: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool initial = false}) async {
    try {
      final msgs = await ApiService.getOrderChats(widget.orderNumber);
      if (mounted) {
        setState(() {
          _messages = msgs;
          if (initial) _isLoading = false;
        });
        if (initial && msgs.isNotEmpty) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted && initial) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final success = await ApiService.sendOrderChat(
      orderId: widget.orderNumber,
      senderRole: widget.currentRole,
      senderName: widget.currentUserName.isNotEmpty ? widget.currentUserName : (widget.currentRole == 'admin' ? 'Store Support' : 'Customer'),
      message: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        await _fetchMessages();
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please retry.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentRole.toLowerCase() == 'admin';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isAdmin ? const Color(0xFF1E293B) : brandOrange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    radius: 18,
                    child: Icon(
                      isAdmin ? Icons.support_agent : Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Customer Support Chat' : 'Chat with Store Staff',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.customerName != null && widget.customerName!.trim().isNotEmpty
                              ? 'Order #${widget.orderNumber} • ${widget.customerName}'
                              : 'Order #${widget.orderNumber}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Chat Messages Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mark_chat_unread_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              Text(
                                'No messages yet for this order.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin
                                    ? 'Send a message to update the customer on their order.'
                                    : 'Ask a question or provide delivery notes to the store staff.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, index) {
                            final msg = _messages[index];
                            final senderRole = (msg['sender_role'] ?? 'customer').toString().toLowerCase();
                            final isMe = senderRole == widget.currentRole.toLowerCase();
                            final senderName = msg['sender_name'] ?? (senderRole == 'admin' ? 'Store Admin' : 'Customer');
                            final text = msg['message'] ?? '';
                            final createdAt = msg['created_at']?.toString() ?? '';

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: const BoxConstraints(maxWidth: 340),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? (isAdmin ? const Color(0xFF1E293B) : brandOrange)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(14),
                                    topRight: const Radius.circular(14),
                                    bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          senderName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isMe
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : (senderRole == 'admin' ? brandOrange : const Color(0xFF334155)),
                                          ),
                                        ),
                                        if (senderRole == 'admin') ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isMe ? Colors.white.withValues(alpha: 0.25) : brandOrange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'STAFF',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? Colors.white : brandOrange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isMe ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (createdAt.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt.length >= 16 ? createdAt.substring(11, 16) : createdAt,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Message Composer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: brandOrange),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: brandOrange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
