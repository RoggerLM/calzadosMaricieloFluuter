import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFF5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Calzados Luciana",
                style: TextStyle(
                  fontFamily: 'Elegant',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent.shade200,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 180,
                child: Lottie.asset(
                  'assets/animations/shoe.json',
                  repeat: false,
                  animate: true,
                ),
              ),

              const SizedBox(height: 30),

              CircularProgressIndicator(
                color: Colors.pinkAccent.shade100,
                strokeWidth: 3,
              ),

              const SizedBox(height: 30),

              Text(
                "Elegancia en cada paso",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}