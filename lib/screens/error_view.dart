import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICONO
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            // TITULO
            const Text(
              "Ups... algo salió mal",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // MENSAJE
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            // BOTON
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}