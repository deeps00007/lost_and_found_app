import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track the current active chat room to suppress notifications
  static String? activeChatId;

  // Initialize notifications
  static Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      if (token != null) {
        await _saveFCMToken(token);
        print('💾 Token saved to Firestore');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();
      print('📲 Local notifications initialized');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        print('📬 Foreground message received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('🖱️ Notification tapped: ${message.data}');
        _handleNotificationTap(message);
      });

      print('✅ Notification service fully initialized');
    } else {
      print('❌ User declined notification permission');
    }
  }

  // Save FCM token to user document
  static Future<void> _saveFCMToken(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token saved to Firestore');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Initialize local notifications for Android
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }

    // Suppress notification if user is already in this chat room
    final incomingChatId = message.data['chatId'];
    if (activeChatId != null && activeChatId == incomingChatId) {
      print('🔇 Suppressing notification for active chat: $incomingChatId');
      return;
    }

    // Always show local notification if we have content, either from notification object or data
    await _showLocalNotification(message);
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Extract title and body from notification payload OR data payload
    String title =
        message.notification?.title ?? message.data['title'] ?? 'New Message';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    // If body is empty, it might be a specific type of data message, e.g., chat
    if (body.isEmpty && message.data['type'] == 'chat') {
      // We could customize this based on message.data['senderName'] etc.
      body = 'You have a new message';
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate to specific screen based on message data
  }

  // Send push notification using custom PHP API
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String chatId,
  }) async {
    const String apiUrl =
        'https://fcm-php-api.onrender.com/send_notification.php';

    try {
      print('📤 Sending notification to token: $fcmToken');

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'fcm_token': fcmToken,
          'title': title,
          'body': body,
          'chat_id': chatId,
        },
      );

      if (response.statusCode == 200) {
        print('✅ PHP API Response Received (200)');
        print('Body: ${response.body}');

        if (response.body.contains('"error"') || response.body.contains('❌')) {
          print(
              '⚠️ Notification might have failed at FCM level. Check response above.');
        } else {
          print('🚀 Notification successfully passed through PHP to FCM.');
        }
      } else {
        print('❌ PHP API Error. Status: ${response.statusCode}');
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Network Error sending notification: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
