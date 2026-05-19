import 'package:cargo_app/core/repositories/chat_repository.dart';
import 'package:cargo_app/features/chat/chat_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/firebase_auth_helper.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/password_reset_confirmation.dart';
import 'screens/email_verification_screen.dart';
import 'screens/home.dart';
import 'screens/personal_data_screen.dart';
import 'providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/booking/providers/booking_provider.dart';
import 'core/repositories/user_repository.dart';
import 'core/repositories/booking_repository.dart';

import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';

import 'services/push_notification_service.dart';
import 'services/device_token_service.dart';

/// Must be a top-level function for FCM to call it in the background isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the FCM plugin before this is called.
  debugPrint('FCM background message received: ${message.messageId}');
}

/// Global keys so PushNotificationService can show UI without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the background handler BEFORE Firebase.initializeApp so the
  // FCM plugin sees it during cold-start background processing.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase before the app starts to prevent runtime errors
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Configure Firebase Auth settings (language, etc.)
    await FirebaseAuthHelper.configureFirebaseAuth();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize push notifications (channel setup, permission request, listeners)
  await PushNotificationService.initialize(
    navigatorKey: navigatorKey,
    scaffoldMessengerKey: scaffoldMessengerKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider should be initialized once here
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuth()),
        
        // Repositories
        ProxyProvider0<UserRepository>(
          update: (_, _) => FirebaseUserRepository(),
        ),
        ProxyProvider0<BookingRepository>(
          update: (_, _) => FirebaseBookingRepository(),
        ),
        ProxyProvider0<ChatRepository>(
          update: (_, _) => FirebaseChatRepository(),
        ),
        
        // Feature Providers
        ChangeNotifierProxyProvider<UserRepository, ProfileProvider>(
          create: (context) => ProfileProvider(
            Provider.of<UserRepository>(context, listen: false),
          ),
          update: (context, userRepo, previous) =>
              previous ?? ProfileProvider(userRepo),
        ),
        ChangeNotifierProxyProvider<BookingRepository, BookingProvider>(
          create: (context) => BookingProvider(
            Provider.of<BookingRepository>(context, listen: false),
          ),
          update: (context, bookingRepo, previous) =>
              previous ?? BookingProvider(bookingRepo),
        ),
        ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<ChatRepository>(context, listen: false),
          ),
          update: (context, chatRepo, previous) =>
              previous ?? ChatProvider(chatRepo),
        ),
        
        // UI Providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const CargoLinkApp(),
    );
  }
}

class CargoLinkApp extends StatefulWidget {
  const CargoLinkApp({super.key});

  @override
  State<CargoLinkApp> createState() => _CargoLinkAppState();
}

class _CargoLinkAppState extends State<CargoLinkApp> {
  @override
  void initState() {
    super.initState();
    DeviceTokenService.saveDeviceToken();
    DeviceTokenService.listenForTokenRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CargoLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/forgot-password': (context) => const ForgetPasswordScreen(),
        '/password-reset-confirmation': (context) =>
            const PasswordResetConfirmation(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/home': (context) => const Home(),
        '/personal-data': (context) => const PersonalDataScreen(),
      },
    );
  }
}
