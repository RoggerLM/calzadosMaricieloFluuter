import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';

Uint8List convertirBase64(String base64String) {
  return base64Decode(base64String);
}

class VistaImagen extends StatelessWidget {
  final String imagenId;

  const VistaImagen({super.key, required this.imagenId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vista del Producto")),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(
            convertirBase64(imagenId),
            errorBuilder: (_, __, ___) =>
            const Text("Imagen inválida o corrupta"),
          ),
        ),
      ),
    );
  }
}
