import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message_model.dart';
import '../../models/item_model.dart';
import '../../services/notification_service.dart';

import '../../widgets/screen_header.dart';

class ChatRoomScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String itemId;
  final ItemModel? contextItem; // The item triggering this chat

  ChatRoomScreen({
    required this.otherUserId,
    required this.otherUserName,
    required this.itemId,
    this.contextItem,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isLoading = true;
  String? _error;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String? _otherUserImage;
  String? _otherUserFcmToken;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserProfile();
    _fetchCurrentUserProfile();
    _initializeChat();
  }

  Future<void> _fetchCurrentUserProfile() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc.data()?['name'] ?? 'Someone';
        });
      }
    } catch (e) {
      print('Error fetching current user profile: $e');
    }
  }

  Future<void> _fetchOtherUserProfile() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.otherUserId).get();
      if (userDoc.exists) {
        setState(() {
          _otherUserImage = userDoc.data()?['profilePicUrl'];
          _otherUserFcmToken = userDoc.data()?['fcmToken'];
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? foundChatId;
      for (var doc in chatQuery.docs) {
        final participants =
            List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(widget.otherUserId)) {
          foundChatId = doc.id;
          break;
        }
      }

      if (foundChatId != null) {
        setState(() {
          _chatId = foundChatId;
          _isLoading = false;
        });

        // Set active chat ID for notification suppression
        NotificationService.activeChatId = foundChatId;

        _markMessagesAsRead();
        _resetUnreadCount();
        _checkAndSendInquiry();
      } else {
        final chatData = {
          'participants': [currentUserId, widget.otherUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'itemId': widget.itemId,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final newChat = await _firestore.collection('chats').add(chatData);

        setState(() {
          _chatId = newChat.id;
          _isLoading = false;
        });

        // Set active chat ID for notification suppression
        NotificationService.activeChatId = newChat.id;

        _checkAndSendInquiry();
      }
    } catch (e, stackTrace) {
      print('Error initializing chat: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndSendInquiry() async {
    if (widget.contextItem == null || _chatId == null) return;

    try {
      final recentMessages = await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      bool alreadySent = false;
      for (var doc in recentMessages.docs) {
        final data = doc.data();
        if (data['type'] == 'inquiry' &&
            data['metadata']?['itemId'] == widget.contextItem!.id) {
          alreadySent = true;
          break;
        }
      }

      if (!alreadySent) {
        final text =
            "Hi, I'm interested in your post: ${widget.contextItem!.title}";
        await _firestore
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .add({
          'senderId': currentUserId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'status': 'sent',
          'type': 'inquiry',
          'metadata': {
            'itemId': widget.contextItem!.id,
            'title': widget.contextItem!.title,
            'imageUrl': widget.contextItem!.images.isNotEmpty
                ? widget.contextItem!.images.first
                : null,
            'itemType': widget.contextItem!.type,
          }
        });

        await _firestore.collection('chats').doc(_chatId).update({
          'lastMessage': 'Sent an inquiry about ${widget.contextItem!.title}',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCounts.${widget.otherUserId}': FieldValue.increment(1),
        });

        // Send Push Notification for Inquiry
        if (_otherUserFcmToken != null) {
          await NotificationService.sendPushNotification(
            fcmToken: _otherUserFcmToken!,
            title: 'New interest in your post!',
            body:
                '${_currentUserName ?? "Someone"} is interested in "${widget.contextItem!.title}"',
            chatId: _chatId!,
          );
        }
      }
    } catch (e) {
      print('Error sending inquiry: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_chatId == null) return;

    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _resetUnreadCount() async {
    if (_chatId == null) return;
    try {
      await _firestore.collection('chats').doc(_chatId).update({
        'unreadCounts.$currentUserId': 0,
      });
    } catch (e) {
      print('Error resetting unread count: $e');
    }
  }

  Stream<List<MessageModel>> _getMessagesStream() {
    if (_chatId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'status': 'sent',
        'type': 'text',
      });

      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.${widget.otherUserId}': FieldValue.increment(1),
      });

      // Send Push Notification
      if (_otherUserFcmToken != null) {
        await NotificationService.sendPushNotification(
          fcmToken: _otherUserFcmToken!,
          title: _currentUserName ?? 'New Message',
          body: messageText,
          chatId: _chatId!,
        );
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F8),
      body: Column(
        children: [
          ScreenHeader(
            showBackButton: true,
            titleWidget: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF2C5F6F).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF2C5F6F),
                    backgroundImage: _otherUserImage != null
                        ? CachedNetworkImageProvider(_otherUserImage!)
                        : null,
                    child: _otherUserImage == null
                        ? Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: TextStyle(
                        color: Color(0xFF2C5F6F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Active now',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Setting up chat...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Failed to load chat'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeChat,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : StreamBuilder<List<MessageModel>>(
                        stream: _getMessagesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final messages = snapshot.data ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Start the conversation',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUserId;

                              return ChatBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF2C5F6F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Clear active chat ID when leaving the screen
    if (_chatId != null && NotificationService.activeChatId == _chatId) {
      NotificationService.activeChatId = null;
    }
    super.dispose();
  }
}

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.type == 'inquiry') {
      return _buildInquiryCard(context);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64.0 : 8.0,
        right: isMe ? 8.0 : 64.0,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [Color(0xFF6DB3C8), Color(0xFF4A9BAE)],
                  )
                : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 16,
                      color: message.isRead ? Colors.blue[200] : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryCard(BuildContext context) {
    final metadata = message.metadata ?? {};
    final imageUrl = metadata['imageUrl'] as String?;
    final title = metadata['title'] as String? ?? 'Item';
    final isInquiry = message.type == 'inquiry';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Color(0xFF2C5F6F), // Deep Teal
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded,
                          size: 16, color: Colors.white.withOpacity(0.9)),
                      SizedBox(width: 8),
                      Text(
                        'Item Inquiry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Item Content
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Image
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                          color: Colors.grey.shade50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Center(
                                      child: Icon(Icons.image,
                                          color: Colors.grey[300])),
                                  errorWidget: (c, u, e) => Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[300])),
                                )
                              : Center(
                                  child: Icon(Icons.image_not_supported_rounded,
                                      color: Colors.grey[300])),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF8C7A)
                                    .withOpacity(0.1), // Soft Coral tint
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                metadata['itemType'] == 'lost'
                                    ? 'Lost Item'
                                    : 'Found Item',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF8C7A), // Soft Coral
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action hint (optional)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Center(
                    child: Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
