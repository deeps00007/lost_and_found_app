import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/profile_header_action.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import 'chat_room_screen.dart';

import '../../widgets/screen_header.dart';

class ChatListScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ChatModel>> _getChatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<Map<String, dynamic>> _getOtherUserData(
      List<String> participants) async {
    final otherUserId = participants.firstWhere((id) => id != currentUserId);
    final userDoc = await _firestore.collection('users').doc(otherUserId).get();

    return {
      'id': otherUserId,
      'name': userDoc.data()?['name'] ?? 'Unknown User',
      'profilePicUrl': userDoc.data()?['profilePicUrl'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Messages',
            subtitle: 'Recent conversations',
            action: ProfileHeaderAction(),
          ),
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _getChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              size: 60, color: Colors.grey[400]),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start chatting about lost items',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getOtherUserData(chat.participants),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Loading...'),
                          );
                        }

                        final otherUser = userSnapshot.data!;

                        final unreadCount =
                            chat.unreadCounts[currentUserId] ?? 0;

                        return ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          // ... (leading)
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              backgroundImage:
                                  otherUser['profilePicUrl'] != null
                                      ? CachedNetworkImageProvider(
                                          otherUser['profilePicUrl'])
                                      : null,
                              child: otherUser['profilePicUrl'] == null
                                  ? Text(
                                      otherUser['name'][0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            otherUser['name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              // Bold if unread
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeago.format(chat.lastMessageTime,
                                    locale: 'en_short'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: unreadCount > 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[500],
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal),
                              ),
                              if (unreadCount > 0) ...[
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomScreen(
                                  otherUserId: otherUser['id'],
                                  otherUserName: otherUser['name'],
                                  itemId: chat.itemId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
