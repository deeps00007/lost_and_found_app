import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        home: AuthWrapper(),
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
