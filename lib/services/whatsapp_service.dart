import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/order_model.dart';

class WhatsAppService {

  /// ENVÍA DIRECTO AL CHAT DE WHATSAPP - MÉTODO PRINCIPAL
  Future<void> sendDirectToWhatsAppChat(
      Pedido pedido, {
        required String imagePath,
        required BuildContext context,
      }) async {
    final message = '''
¡Hola ${pedido.clienteNombre}! 

🚚 *TU PEDIDO ESTÁ EN CAMINO*

📦 *Para recoger tu pedido:*
Presenta tu DNI y esta imagen de comprobante.

⏰ *Tiempo de entrega:*
3-5 días hábiles.

¡Gracias por tu compra! 🛍️
''';

    // Verificar imagen
    if (!await File(imagePath).exists()) {
      throw Exception("La imagen no existe: $imagePath");
    }

    // MOSTRAR OPCIONES al usuario
    await _showOptionsDialog(
      context: context,
      pedido: pedido,
      imagePath: imagePath,
      message: message,
    );
  }

  /// Muestra diálogo con opciones
  Future<void> _showOptionsDialog({
    required BuildContext context,
    required Pedido pedido,
    required String imagePath,
    required String message,
  }) async {
    final formattedPhone = _formatPhoneForDisplay(pedido.numero);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                SizedBox(width: 10),
                Text('Enviar a WhatsApp'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elige cómo quieres enviar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // OPCIÓN 1: Chat directo (solo mensaje)
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.chat, color: Colors.green),
                      title: const Text('Abrir chat directo'),
                      subtitle: const Text('Envía el mensaje primero, luego la imagen'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        Navigator.pop(context);
                        await _option1_OpenChatThenShare(
                            pedido.numero,
                            imagePath,
                            message,
                            context
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // OPCIÓN 2: Compartir normal
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.share, color: Colors.blue),
                      title: const Text('Compartir normalmente'),
                      subtitle: const Text('Selecciona WhatsApp manualmente'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () async {
                        Navigator.pop(context);
                        await _option2_NormalShare(imagePath, message);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // OPCIÓN 3: Copiar número
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.content_copy, color: Colors.orange),
                      title: const Text('Copiar número'),
                      subtitle: Text('Copiar: $formattedPhone'),
                      trailing: const Icon(Icons.copy),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: pedido.numero));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Número copiado al portapapeles'),
                          ),
                        );
                        Navigator.pop(context);
                        _option2_NormalShare(imagePath, message);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Información del cliente
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 Información del envío:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('👤 Cliente: ${pedido.clienteNombre}'),
                        Text('📞 Teléfono: $formattedPhone'),
                        Text('🆔 Pedido: ${pedido.id}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// OPCIÓN 1: Abrir chat y luego compartir imagen
  Future<void> _option1_OpenChatThenShare(
      String phone,
      String imagePath,
      String message,
      BuildContext context,
      ) async {
    try {
      // PASO 1: Abrir WhatsApp con el número
      await _openWhatsAppWithNumber(phone, message);

      // PASO 2: Esperar y mostrar instrucciones para la imagen
      await Future.delayed(const Duration(milliseconds: 1000));

      await _showImageInstructions(context, imagePath);

    } catch (e) {
      print('❌ Error opción 1: $e');
      // Fallback a opción 2
      await _option2_NormalShare(imagePath, message);
    }
  }

  /// Abre WhatsApp con un número específico
  Future<void> _openWhatsAppWithNumber(String phone, String message) async {
    final formattedNumber = _formatPhoneForUrl(phone);
    final encodedMessage = Uri.encodeComponent('$message\n\n(Imagen a continuación →)');
    final url = 'https://wa.me/$formattedNumber?text=$encodedMessage';

    print('🔗 Abriendo WhatsApp: $url');

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'No se pudo abrir WhatsApp';
    }
  }

  /// Muestra instrucciones para la imagen
  Future<void> _showImageInstructions(
      BuildContext context,
      String imagePath,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📤 Ahora envía la imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sigue estos pasos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildStep(1, 'WhatsApp ya está abierto'),
            _buildStep(2, 'Toca el botón "Adjuntar" (clip)'),
            _buildStep(3, 'Selecciona "Galería" o "Documentos"'),
            _buildStep(4, 'Busca y selecciona esta imagen'),
            _buildStep(5, 'Presiona "Enviar"'),

            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow),
              ),
              child: const Text(
                '💡 Consejo: Si ya tienes el chat abierto, solo adjunta la imagen',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Compartir la imagen (el usuario seleccionará WhatsApp)
              await Share.shareXFiles(
                [XFile(imagePath)],
                text: 'Comprobante del pedido',
                sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
              );
            },
            child: const Text('Compartir imagen ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  /// OPCIÓN 2: Compartir normalmente
  Future<void> _option2_NormalShare(String imagePath, String message) async {
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: message,
      sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  /// Formatear número para URL (sin +, solo números)
  String _formatPhoneForUrl(String phone) {
    // Solo números
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Quitar 0 inicial
    if (clean.startsWith('0')) clean = clean.substring(1);

    // Agregar código de país si es necesario
    // Ajusta según tu país:
    if (clean.length == 10 && !clean.startsWith('52')) {
      clean = '52$clean'; // México
    } else if (clean.length == 9 && !clean.startsWith('51')) {
      clean = '51$clean'; // Perú
    } else if (clean.length == 10 && !clean.startsWith('57')) {
      clean = '57$clean'; // Colombia
    }

    return clean;
  }

  /// Formatear número para mostrar
  String _formatPhoneForDisplay(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.length == 10) {
      return '(${clean.substring(0, 3)}) ${clean.substring(3, 6)}-${clean.substring(6)}';
    } else if (clean.length == 9) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }

    return phone;
  }

  /// MÉTODO DIRECTO: Intenta todo automáticamente
  Future<void> sendAutoToWhatsApp(
      Pedido pedido,
      String imagePath,
      BuildContext context,
      ) async {
    // Intentar abrir WhatsApp directo
    try {
      await _openWhatsAppWithNumber(pedido.numero, 'Te envío el comprobante...');
      await Future.delayed(const Duration(seconds: 2));
      await _option2_NormalShare(imagePath, 'Comprobante adjunto');
    } catch (e) {
      // Si falla, mostrar opciones
      await sendDirectToWhatsAppChat(
        pedido,
        imagePath: imagePath,
        context: context,
      );
    }
  }
}