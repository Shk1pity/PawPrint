import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'views/login_screen.dart';
import 'views/onboarding_screen.dart';
import 'views/signup_screen.dart';
import 'views/auth_page.dart';
import 'views/home_screen.dart';
import 'models/adoptionpost_model.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await checkForNearbyReports();
      return Future.value(true);
    } catch (e) {
      print("Error: $e");
      return Future.value(false);
    }
  });
}

Future<void> checkForNearbyReports() async {
  print("Checking for nearby reports...");
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final querySnapshot = await FirebaseFirestore.instance.collection('adoptions').get();
  final allReports = querySnapshot.docs.map((doc) => AdoptionPost.fromMap(doc.data() as Map<String, dynamic>)).toList();

  final nearbyReports = allReports.where((report) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      report.latitude,
      report.longitude,
    );
    return distance <= 1000; 
  }).toList();

  String notificationText = nearbyReports.isEmpty
      ? "No reports were found nearby"
      : "${nearbyReports.length} number of reports in the nearby area detected";

  print(notificationText); 

  
  final ByteData bytes = await rootBundle.load('assets/pet-border-launcher-removebg-preview.png');
  final Uint8List byteList = bytes.buffer.asUint8List();
  final ByteArrayAndroidBitmap largeIcon = ByteArrayAndroidBitmap(byteList);

  var androidDetails = AndroidNotificationDetails(
    'channelId',
    'channelName',
    channelDescription: 'channelDescription',
    importance: Importance.max,
    priority: Priority.high,
    largeIcon: largeIcon, 
    icon: '@mipmap/ic_launcher', 
  );
  var generalNotificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'StrayRescue',
    notificationText,
    generalNotificationDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher', 
          ),
        ),
      );
    }
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  if (isFirstTime) {
    await prefs.setBool('isFirstTime', false);
  }

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "1",
    "checkForNearbyReports",
    frequency: Duration(hours: 1),
  );

  runApp(
    MaterialApp(
      title: 'Animal Adoption and Rescue Service',
      theme: ThemeData(
        primaryColor: const Color(0xFF6C63FF), 
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF6C63FF), 
          secondary: const Color(0xFFB3B3B3), 
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF6C63FF), 
          textTheme: ButtonTextTheme.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF), 
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF), 
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/onboarding',
      routes: {
        '/': (context) => const AuthPage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/onboarding': (context) => OnboardingScreen(),
      },
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
