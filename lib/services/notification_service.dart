import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

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

  // Public method to be called after login/signup
  static Future<void> saveTokenToCurrentUser() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
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
        print('FCM token saved to Firestore for user: $userId');
      } else {
        print('Skipping FCM save: No logged in user');
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
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
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
    // Get sender info from data payload
    final String senderName = message.data['senderName'] ??
        message.notification?.title ??
        'New Message';
    final String? senderImage = message.data['senderImage'];
    final String content = message.notification?.body ??
        message.data['body'] ??
        'You have a new message';

    // Download image if available for WhatsApp style
    String? largeIconPath;
    Person? sender;

    if (senderImage != null && senderImage.isNotEmpty) {
      largeIconPath = await _downloadFile(
          senderImage, 'sender_profile_${message.hashCode}.jpg');
    }

    if (largeIconPath != null) {
      sender = Person(
        name: senderName,
        key: message.data['senderId'] ?? 'sender',
        icon: BitmapFilePathAndroidIcon(largeIconPath),
      );
    } else {
      sender = Person(
        name: senderName,
        key: message.data['senderId'] ?? 'sender',
      );
    }

    // Prepare MessagingStyle for WhatsApp-like grouping and appearance
    final messagingStyle = MessagingStyleInformation(
      sender,
      groupConversation: false,
      messages: [
        Message(
          content,
          DateTime.now(),
          sender,
        ),
      ],
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      styleInformation: messagingStyle,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      senderName,
      content,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _onNotificationResponse(NotificationResponse details) {
    print('Notification tapped payload: ${details.payload}');
  }

  // Helper to download image for notifications

  // Helper to download image for notifications
  static Future<String?> _downloadFile(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = p.join(directory.path, fileName);
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('Error downloading notification icon: $e');
      return null;
    }
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
    String? senderName,
    String? senderImage,
    String? senderId,
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
          'senderName': senderName ?? '',
          'senderImage': senderImage ?? '',
          'senderId': senderId ?? '',
          'type': 'chat',
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
