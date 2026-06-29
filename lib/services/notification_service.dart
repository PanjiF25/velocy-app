import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A singleton service that listens to Firestore and shows local notifications
/// when a new admin message arrives and the user is NOT on the chat screen.
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription? _chatSub;
  StreamSubscription? _taskSub;
  bool _isOnChatScreen = false;
  bool _initialized = false;
  int _lastKnownCount = -1; // -1 = not yet loaded
  int _lastTaskCount = -1; // -1 = not yet loaded

  /// Initialize the notification plugin. Call once from main().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped the notification — we could navigate to chat here
        // but for now we just let the app handle it naturally
      },
    );

    // Create notification channel for Android 8+
    const androidChannel = AndroidNotificationChannel(
      'velocy_chat',
      'Chat Messages',
      description: 'Notifikasi pesan chat dari Admin',
      importance: Importance.high,
      playSound: true,
    );
    
    const taskChannel = AndroidNotificationChannel(
      'velocy_tasks',
      'Task Notifications',
      description: 'Notifikasi tugas baru',
      importance: Importance.high,
      playSound: true,
    );

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // Request permission for Android 13+
    await androidImplementation?.requestNotificationsPermission();
    
    await androidImplementation?.createNotificationChannel(androidChannel);
    await androidImplementation?.createNotificationChannel(taskChannel);
  }

  /// Start listening for new chat messages for the current user
  void startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // Cancel any existing subscription
    _chatSub?.cancel();
    _taskSub?.cancel();

    _chatSub = FirebaseFirestore.instance
        .collection('support_chats')
        .where('officerId', isEqualTo: uid)
        .where('senderRole', isEqualTo: 'admin')
        .snapshots()
        .listen((snapshot) {
      final currentCount = snapshot.docs.length;

      // Skip the initial load — only notify on NEW messages
      if (_lastKnownCount == -1) {
        _lastKnownCount = currentCount;
        return;
      }

      // If there are more messages than before, we got a new one
      if (currentCount > _lastKnownCount && !_isOnChatScreen) {
        // Find the newest message
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isNotEmpty) {
          final newest = docs.first.data();
          final message = newest['message'] ?? 'Pesan baru';
          _showNotification('Admin Support', message);
        }
      }

      _lastKnownCount = currentCount;
    });

    // Listen to new tasks
    _taskSub = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      final currentCount = snapshot.docs.length;

      if (_lastTaskCount == -1) {
        _lastTaskCount = currentCount;
        return;
      }

      if (currentCount > _lastTaskCount) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isNotEmpty) {
          final newest = docs.first.data();
          final title = newest['title'] ?? 'Tugas Baru';
          _showNotification('Tugas Baru', title, channelId: 'velocy_tasks');
        }
      }

      _lastTaskCount = currentCount;
    });
  }

  /// Stop listening (call on logout)
  void stopListening() {
    _chatSub?.cancel();
    _chatSub = null;
    _taskSub?.cancel();
    _taskSub = null;
    _lastKnownCount = -1;
    _lastTaskCount = -1;
  }

  /// Call this when user enters the chat screen
  void enterChatScreen() {
    _isOnChatScreen = true;
  }

  /// Call this when user leaves the chat screen
  void leaveChatScreen() {
    _isOnChatScreen = false;
  }

  /// Show a local notification
  Future<void> _showNotification(String title, String body, {String channelId = 'velocy_chat'}) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'velocy_chat' ? 'Chat Messages' : 'Task Notifications',
      channelDescription: channelId == 'velocy_chat' ? 'Notifikasi pesan chat dari Admin' : 'Notifikasi tugas baru',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      details,
    );
  }
}
