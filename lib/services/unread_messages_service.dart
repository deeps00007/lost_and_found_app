import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UnreadMessagesService {
  static final UnreadMessagesService _instance =
      UnreadMessagesService._internal();
  factory UnreadMessagesService() => _instance;
  UnreadMessagesService._internal();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keep track of the subscription
  StreamSubscription<QuerySnapshot>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  void init() {
    print('UnreadMessagesService: init called');
    _authSubscription?.cancel();

    final user = _auth.currentUser;
    if (user != null) {
      print('UnreadMessagesService: Initial user found: ${user.uid}');
      _startListening(user.uid);
    }

    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        print(
            'UnreadMessagesService: Auth state changed. User user: ${user.uid}');
        _startListening(user.uid);
      } else {
        print('UnreadMessagesService: User logged out');
        unreadCountNotifier.value = 0;
        _subscription?.cancel();
        _subscription = null;
      }
    });
  }

  void _startListening(String userId) {
    print('UnreadMessagesService: Starting to listen for user $userId');
    _subscription?.cancel();
    _subscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      print(
          'UnreadMessagesService: Received snapshot with ${snapshot.docs.length} docs');
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('UnreadMessagesService: Doc ${doc.id} data: $data');
        if (data.containsKey('unreadCounts')) {
          final unreadCounts = (data['unreadCounts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              {};
          final count = unreadCounts[userId] ?? 0;
          print('UnreadMessagesService: Count for this chat: $count');
          totalUnread += count;
        } else {
          print('UnreadMessagesService: No unreadCounts field');
        }
      }
      print('UnreadMessagesService: Total unread count: $totalUnread');
      unreadCountNotifier.value = totalUnread;
    });
  }
}
