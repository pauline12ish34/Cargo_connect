import 'package:cargo_app/core/repositories/chat_repository.dart';
import 'package:cargo_app/features/chat/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/firebase_initializer.dart';
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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';
import 'services/device_token_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Must be a top-level function. Called by FCM when the app is terminated/background.
/// The [notification] field in the payload means FCM auto-shows the system notification,
/// so no manual display is needed here.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background display is handled automatically by FCM because our payload
  // includes the 'notification' key. Nothing extra needed.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return FirebaseInitializer(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ProxyProvider0<UserRepository>(
            update: (_, _) => FirebaseUserRepository(),
          ),
          ProxyProvider0<BookingRepository>(
            update: (_, _) => FirebaseBookingRepository(),
          ),
          ProxyProvider0<ChatRepository>(
            update: (_, _) => FirebaseChatRepository(),
          ),
          ChangeNotifierProxyProvider<UserRepository, ProfileProvider>(
            create: (context) =>
                ProfileProvider(Provider.of<UserRepository>(context, listen: false)),
            update: (context, userRepo, previous) =>
                previous ?? ProfileProvider(userRepo),
          ),
          ChangeNotifierProxyProvider<BookingRepository, BookingProvider>(
            create: (context) =>
                BookingProvider(Provider.of<BookingRepository>(context, listen: false)),
            update: (context, bookingRepo, previous) =>
                previous ?? BookingProvider(bookingRepo),
          ),
          ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
            create: (context) =>
                ChatProvider(Provider.of<ChatRepository>(context, listen: false)),
            update: (context, chatRepo, previous) =>
                previous ?? ChatProvider(chatRepo),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        // _AppBootstrap runs initialization exactly once after Firebase is ready.
        child: const _AppBootstrap(),
      ),
    );
  }
}

/// Sits inside MultiProvider so it can access all providers.
/// Runs one-time initialization in [initState] — never repeats on rebuild.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeAuth();
      DeviceTokenService.saveDeviceToken();
      DeviceTokenService.listenForTokenRefresh();
      // Notification listeners registered once here — uses the global key.
      PushNotificationService.initialize(scaffoldMessengerKey, navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'CargoLink',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/splash',
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
      },
    );
  }
}
