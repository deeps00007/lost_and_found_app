import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? status; // 'sending', 'sent', 'delivered', 'read'
  final String type; // 'text', 'image', 'inquiry'
  final Map<String, dynamic>? metadata; // For storing item details, etc.

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.status,
    this.type = 'text',
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'status': status ?? 'sent',
      'type': type,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      status: map['status'],
      type: map['type'] ?? 'text',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
