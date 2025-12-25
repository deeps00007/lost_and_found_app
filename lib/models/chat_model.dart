import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String itemId;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.itemId,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'itemId': itemId,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemId: map['itemId'] ?? '',
      unreadCounts: (map['unreadCounts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          {},
    );
  }
}
