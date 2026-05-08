import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:calzados_luciana/services/firestore_service.dart';
import 'package:calzados_luciana/services/whatsapp_service.dart';
import 'package:calzados_luciana/models/order_model.dart';
import 'package:path_provider/path_provider.dart';

class ComprobanteDialog extends StatefulWidget {
  final Pedido pedido;

  const ComprobanteDialog({super.key, required this.pedido});

  @override
  State<ComprobanteDialog> createState() => _ComprobanteDialogState();
}

class _ComprobanteDialogState extends State<ComprobanteDialog> {
  final ImagePicker _picker = ImagePicker();
  final WhatsAppService _whatsAppService = WhatsAppService();

  bool _isLoading = false;
  Uint8List? _comprobanteImage;
  String? _imagePath; // Nueva variable para guardar la ruta del archivo

  @override
  void initState() {
    super.initState();
    _verificarYMostrarComprobante();
  }

  Future<void> _subirComprobante() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final file = File(image.path);
        final bytes = await file.readAsBytes();

        // Guardar en Firestore
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.uploadComprobante(widget.pedido.codigo, file);

        // Guardar localmente para mostrar y enviar
        setState(() {
          _comprobanteImage = bytes;
          _imagePath = image.path; // Guardar la ruta original
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comprobante subido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error subiendo comprobante: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarComprobante() async {
    try {
      setState(() => _isLoading = true);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      await firestoreService.deleteComprobante(widget.pedido.codigo);

      setState(() {
        _comprobanteImage = null;
        _imagePath = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Comprobante eliminado'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ Error eliminando comprobante: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enviarMensajeAgencia() async {
    if (_imagePath == null || _comprobanteImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Primero sube un comprobante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear archivo temporal si no tenemos ruta
      String imagePathToSend = _imagePath!;

      if (!await File(imagePathToSend).exists()) {
        // Crear archivo temporal desde los bytes
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/comprobante_${widget.pedido.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(_comprobanteImage!);
        imagePathToSend = tempFile.path;
      }

      // Enviar por WhatsApp usando el nuevo método
      await _whatsAppService.sendDirectToWhatsAppChat(
        widget.pedido,
        imagePath: imagePathToSend,
        context: context,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Enviando a ${widget.pedido.clienteNombre}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verificarYMostrarComprobante() async {
    try {
      setState(() => _isLoading = true);

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final comprobanteData = await firestoreService.getComprobante(widget.pedido.codigo);

      if (comprobanteData != null && comprobanteData['imageData'] != null) {
        try {
          final imageBytes = base64Decode(comprobanteData['imageData']);

          // Guardar como archivo temporal para poder enviarlo
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/comprobante_${widget.pedido.id}.jpg');
          await tempFile.writeAsBytes(imageBytes);

          setState(() {
            _comprobanteImage = imageBytes;
            _imagePath = tempFile.path;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Comprobante cargado desde la nube'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('❌ Error decodificando imagen: $e');
        }
      }
    } catch (e) {
      print('❌ Error verificando comprobante: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📦 Comprobante de Envío',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),

              const Divider(height: 20),

              // INFORMACIÓN DEL PEDIDO
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 ${widget.pedido.clienteNombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${widget.pedido.numero}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🆔 Pedido: ${widget.pedido.codigo}',
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // INDICADOR DE ESTADO
              _buildEstadoComprobante(),

              const SizedBox(height: 20),

              // LOADING
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Procesando...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              // COMPROBANTE
              if (!_isLoading && _comprobanteImage != null)
                _buildComprobanteSubido()
              else if (!_isLoading)
                _buildSubirComprobante(),

              const SizedBox(height: 20),

              // BOTÓN ENVIAR WHATSAPP
              if (_comprobanteImage != null && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviarMensajeAgencia,
                    icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                    label: const Text(
                      'ENVIAR POR WHATSAPP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // INFORMACIÓN ADICIONAL
              if (_comprobanteImage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se abrirá WhatsApp. Busca el contacto del cliente y envía.',
                          style: TextStyle(fontSize: 12, color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoComprobante() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _comprobanteImage != null ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _comprobanteImage != null ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _comprobanteImage != null ? Icons.check_circle : Icons.warning_amber,
            color: _comprobanteImage != null ? Colors.green : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _comprobanteImage != null
                  ? '✅ Comprobante listo para enviar'
                  : '📤 Sube el comprobante de la agencia',
              style: TextStyle(
                color: _comprobanteImage != null ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSubido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📄 Comprobante subido:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // IMAGEN
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _comprobanteImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 15),

        // BOTONES DE ACCIÓN
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _eliminarComprobante,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _subirComprobante,
                icon: const Icon(Icons.edit, color: Colors.blue),
                label: const Text(
                  'Cambiar',
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 5),

        // MENSAJE A ENVIAR
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 Mensaje que se enviará:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                '¡Hola [Cliente]! Tu pedido está en camino. Presenta tu DNI y este comprobante.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubirComprobante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📤 Subir comprobante:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue,
              width: 2,
            ), // Eliminado BorderStyle.dashed
            borderRadius: BorderRadius.circular(10),
            color: Colors.blue[50],
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload, size: 50, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Toma una foto del comprobante\nde la agencia de envíos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Formatos: JPG, PNG\nTamaño máximo: 5MB',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _subirComprobante,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Seleccionar imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}