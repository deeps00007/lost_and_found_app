import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart'; // Added
import 'widgets/main_navigation.dart'; // Changed import
import 'services/auth_service.dart';
import 'utils/permissions.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request permissions on startup (optional)
  await PermissionHelper.requestAllPermissions();

  // Initialize notifications
  await NotificationService.initialize();

  // Check if onboarding is seen
  bool showOnboarding = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    showOnboarding = !(prefs.getBool('seenOnboarding') ?? false);
  } catch (e) {
    print(
        "⚠️ Error initializing SharedPreferences (likely missing native plugin): $e");
    // Fallback to skipping onboarding to ensure app starts
    showOnboarding = false;
  }

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({Key? key, required this.showOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Lost & Found',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: showOnboarding ? OnboardingScreen() : AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return MainNavigation(); // Updated to MainNavigation
        }

        return LoginScreen();
      },
    );
  }
}
