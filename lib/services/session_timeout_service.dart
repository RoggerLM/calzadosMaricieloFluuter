import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_navigator.dart';

class SessionTimeoutService with WidgetsBindingObserver {
  static final SessionTimeoutService _instance = SessionTimeoutService._internal();
  factory SessionTimeoutService() => _instance;

  SessionTimeoutService._internal();

  Timer? _inactivityTimer;
  DateTime? _backgroundTime;
  static const Duration sessionTimeout = Duration(minutes: 5); // 🔹 Cambia a Duration(minutes: 5) luego


  void initialize(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _startTimer(context);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
  }
  // 🔹 Detecta cuando la app pasa a segundo plano o vuelve
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App minimizada o cerrada → iniciar temporizador de cierre
      //_inactivityTimer?.cancel();
      //_inactivityTimer = Timer(sessionTimeout, () async {await FirebaseAuth.instance.signOut();});
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // App volvió al primer plano → reinicia el temporizador
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        if (diff > sessionTimeout) {
          _forceLogout(_lastContext);
        }
      }
    }
  }

  BuildContext? _lastContext;

  void onUserInteraction(BuildContext context) {
    _lastContext = context;
    _inactivityTimer?.cancel();
    _startTimer(context);
  }
  void _startTimer(BuildContext context) {
    _lastContext = context;
    _inactivityTimer = Timer(sessionTimeout, () {
      _forceLogout(context);
    });
  }

  Future<void> _forceLogout(BuildContext? context) async {
    /*if (context == null) return;
    _inactivityTimer?.cancel();

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
          context,
          '/splash',
              (route) => false
      );
    }*/
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/splash',
        (route) => false
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    _inactivityTimer?.cancel();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    }
  }
}
