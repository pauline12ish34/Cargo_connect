import 'package:cargo_app/core/repositories/chat_repository.dart';
import 'package:cargo_app/features/chat/chat_provider.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    // Initialize global services once
    _initServices();
  }

  void _initServices() {
    // These services usually run in the background and don't need UI context
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
      initialRoute: '/splash',
      // We use the builder to initialize PushNotificationService with a context
      // that is a child of MaterialApp (so it can find ScaffoldMessenger)
      builder: (context, child) {
        return _NotificationWrapper(child: child!);
      },
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/forgot-password': (context) => const ForgetPasswordScreen(),
        '/password-reset-confirmation': (context) =>
            const PasswordResetConfirmation(),
        '/email-verification': (context) =>
            const EmailVerificationScreen(),
        '/home': (context) => const Home(),
        '/personal-data': (context) => const PersonalDataScreen(),
      },
    );
  }
}

/// A wrapper widget to handle PushNotificationService initialization
/// with access to the MaterialApp's context.
class _NotificationWrapper extends StatefulWidget {
  final Widget child;
  const _NotificationWrapper({required this.child});

  @override
  State<_NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<_NotificationWrapper> {
  bool _pushInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize push notifications only once when the context is ready
    if (!_pushInitialized) {
      PushNotificationService.initialize(context);
      _pushInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
