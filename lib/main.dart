import 'package:calzados_luciana/services/session_timeout_service.dart';
import 'core/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'screens/splash_screen.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ Inicializamos el servicio aquí
    final sessionService = SessionTimeoutService();
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sessionService.initialize(context);
    });

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()), // <-- Agregar este provider
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // 🔹 Detecta cualquier toque o movimiento para reiniciar el timer
        onTap: () => SessionTimeoutService().onUserInteraction(context),
        onPanDown: (_) => SessionTimeoutService().onUserInteraction(context),
        onScaleStart: (_) => SessionTimeoutService().onUserInteraction(context),
        child: MaterialApp(
          navigatorKey: navigatorKey, // 🔥 aquí
          title: 'Calzados Luciana',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _minSplashTimeElapsed = false;
  firebase_auth.User? _user;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
    _checkAuthState();
  }

  void _startSplashTimer() {
    // Timer mínimo de 5 segundos para el SplashScreen
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _minSplashTimeElapsed = true;
        });
      }
    });
  }

  void _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Escuchar el stream de autenticación
    authService.userStream.listen((user) async {
      //final sessionService = SessionTimeoutService();
      //final expired = await sessionService.hasSessionExpired();
      if (mounted) {
        setState(() {
          _user =user;
          _authChecked = true;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _authChecked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar SplashScreen hasta que pasen 5 segundos Y se verifique la autenticación
    if (!_minSplashTimeElapsed || !_authChecked) {
      return SplashScreen();
    }

    // Si hay usuario autenticado, ir al Dashboard
    if (_user != null) {
      return DashboardPage();
    }

    // Si no hay usuario, ir al Login
    return LoginPage();
  }
}