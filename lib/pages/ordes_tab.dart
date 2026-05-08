// orders_tab.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import '../screens/error_view.dart';
import '../services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

import '../widgets/skeletons.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with WidgetsBindingObserver{

  List<Pedido> _orders = [];
  String? _pedidoPendienteEnvio;
  bool _subiendo = false;
  bool _loading = true;
  String? _error;


  late String nuevoEstado;
  final Map<String, String> _imagenesCache = {};



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPedidos();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return Skeletons.pedidosList();
    }

    // 🔴 ERROR UI PRO
    if (_error != null) {
      return ErrorView(
        mensaje: _error!,
        onRetry: _loadPedidos,
      );
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index){
            final order = _orders[index];
            return _buildOrderItem(order);
          },
        ),
        if(_subiendo)
          Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        "Subiendo comprobante...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ),
      ],
    );

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pedidoPendienteEnvio != null) {
      _mostrarConfirmacionEnvio(_pedidoPendienteEnvio! as Pedido);
      _pedidoPendienteEnvio = null;
    }
  }

  Future<void> _loadPedidos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getPedidos();

      // 🔥
      await _precargarImagenes(data);

      if (!mounted) return;

      setState(() {
        _orders = data;
        _loading = false;
      });


    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

//
  Widget _buildOrderItem(Pedido order) {
    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 HEADER (cliente + estado)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.Nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                _buildEstadoChip(order.nuevoEstado),
              ],
            ),

            const SizedBox(height: 6),

            // 🔹 UBICACIÓN
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${order.Provincia}-${order.Departamento}",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 PRODUCTOS RESUMEN
            Text(
              "${order.totalProductos} producto(s)",
              style: TextStyle(color: Colors.black),
            ),

            const SizedBox(height: 10),

            // 🔹 FOOTER (total + flecha)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "S/ ${order.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
  //
  Widget _buildEstadoChip(String estado) {
    Color color;
    String text;

    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        text = "Pendiente";
        break;
      case 'confirmando_datos_envio':
        color = Colors.blue;
        text = "Confirmando";
        break;
      case 'procesando':
        color = Colors.purple;
        text = "Procesando";
        break;
      case 'entregado':
        color = Colors.green;
        text = "Entregado";
        break;
      default:
        color = Colors.grey;
        text = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  // 🔥 DETALLE BONITO
  void _showOrderDetails(Pedido order) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // 🔹 CONTENIDO COMPLETO
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔹 HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pedido",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(order.telefonoWhatsapp),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text("Datos de Envio", style: TextStyle(fontWeight: FontWeight.bold)),
                      // 🔹 CLIENTE
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 28),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.Nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(order.Dni),
                                Text(order.Telefono),
                                Text(order.Provincia),
                                Text(order.Oficina),
                                Text(order.Departamento),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 PRODUCTOS
                      const Text("🛒 Productos", style: TextStyle(fontWeight: FontWeight.bold)),

                      const SizedBox(height: 8),

                      ...order.productosFinales.map((item) {
                        final key = "${item['codigo']}_${item['color']}";
                        final url = _imagenesCache[key];

                        return InkWell(
                          onTap: () {
                            if (url == null || url.isEmpty) return;

                            showDialog(
                              context: context,
                              barrierColor: Colors.black87,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Hero(
                                    tag: key,
                                    child: _buildImagenGrande(url),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade200,
                                ),
                                child: url != null && url.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImagenMini(url),
                                )
                                    : const Icon(Icons.image_not_supported),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Código: ${item['codigo']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Color: ${item['color']}"),
                                    Text("Talla: ${item['talla']}"),
                                    Text("Cantidad: ${item['cantidad']}"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // 🔹 TOTAL
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total", style: TextStyle(color: Colors.white)),
                            Text(
                              "S/ ${order.total.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /*
                      // 🔥 BOTÓN SUBIR COMPROBANTE
                      ElevatedButton.icon(
                        icon: _subiendo
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.upload),
                        label: Text(_subiendo ? "Subiendo..." : "Subir comprobante"),
                        onPressed: () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 60,
                          );

                          if (image == null) return;

                          final bytes = await image.readAsBytes();
                          final base64Img = base64Encode(bytes);

                          // 🔥 CIERRA EL DIALOG
                          Navigator.pop(context);

                          // 🔥 LLAMA AL PADRE (pantalla principal)
                          _subirComprobanteDesdeLista(order.id, base64Img);
                        },
                      ),

                       */

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton.icon(
                                icon: _subiendo
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.upload),
                                label: Text(_subiendo ? "Subiendo..." : "Subir comprobante"),
                                onPressed: () async {
                                  final image = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 60,
                                  );

                                  if (image == null) return;

                                  final bytes = await image.readAsBytes();
                                  final base64Img = base64Encode(bytes);

                                  // 🔥 CIERRA EL DIALOG
                                  Navigator.pop(context);

                                  // 🔥 LLAMA AL PADRE (pantalla principal)
                                  _subirComprobanteDesdeLista(order.id, base64Img);
                                },
                              ),
                          ),
                          const SizedBox(height: 10),

                          if (order.tieneComprobante)
                            Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text("Ver comprobante"),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.black,
                                      builder: (_) => GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          color: Colors.black,
                                          child: Center(
                                            child: InteractiveViewer(
                                              child: _buildImagenGrande(order.comprobanteImagen),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ),
                        ],
                      ),
                      /*
                      // 🔥 COMPROBANTE
                      if (order.tieneComprobante)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Ver comprobante"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black,
                              builder: (_) => GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: InteractiveViewer(
                                      child: _buildImagenGrande(order.comprobanteImagen),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

 */
                      const SizedBox(height: 20),

                      // 🔥 WHATSAPP
                      if (order.tieneComprobante)
                        ElevatedButton.icon(
                          icon: const Icon(FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                            size: 30,
                          ),
                          label: const Text("Enviar comprobante"),
                          onPressed: () async {
                            try {
                              String celular = order.cliente['celular'] ?? "";

                              // 🔥 limpiar número
                              celular = celular.replaceAll(RegExp(r'\D'), '');

                              if (!celular.startsWith("51")) {
                                celular = "51$celular";
                              }

                              // 🔥 copiar número
                              await Clipboard.setData(ClipboardData(text: celular));

                              // 🔥 convertir base64 → archivo
                              final bytes = base64Decode(order.comprobanteImagen);
                              final tempDir = await getTemporaryDirectory();
                              final file = File('${tempDir.path}/comprobante.jpg');
                              await file.writeAsBytes(bytes);

                              // 🔥 mensaje al usuario
                              if (!mounted) return;

                              showTopMessage(context, "Número copiado 📋 Ahora selecciona WhatsApp y pega el número");
                             //_pedidoPendienteEnvio = order.id; // 🔥 guardas el pedido
                              // 🔥 compartir imagen
                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: "Tu pedido ha sido enviado",
                              );
                              // 🔥 cuando regrese el usuario
                              Future.delayed(const Duration(seconds: 2), () {
                                _mostrarConfirmacionEnvio(order);
                              });
                            } catch (e) {
                              debugPrint("Error compartir: $e");

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Error al compartir comprobante"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }

                          },
                        ),
                      const SizedBox(height: 16),

                      // 🔹 CERRAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("Cerrar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 OVERLAY GLOBAL
              if (_subiendo)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            "Subiendo comprobante...",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  //
  Widget _buildImagenMini(String base64Img) {
    try {
      final bytes = base64Decode(
        base64Img.replaceAll(RegExp(r'\s+'), ''),
      );

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
      );
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }

  Widget _buildImagenGrande(String base64Img) {
    final bytes = base64Decode(base64Img.replaceAll(RegExp(r'\s+'), ''));

    return Image.memory(
      bytes,
      fit: BoxFit.contain, // 👈 clave para que NO recorte
    );
  }

  //Imagenes cache
  Future<void> _precargarImagenes(List<Pedido> pedidos) async {
    try {
      final productosUnicos = <Map<String, String>>[];

      for (var p in pedidos) {
        for (var item in p.productosFinales) {

          final key = "${item['codigo']}_${item['color']}";

          // evitar repetir
          if (!_imagenesCache.containsKey(key)) {
            productosUnicos.add({
              "codigo": item['codigo'],
              "color": item['color'],
            });
          }
        }
      }

      if (productosUnicos.isEmpty) return;

      final data = await ApiService.getImagenes(productosUnicos);

      for (var item in data) {
        final key = "${item['codigo']}_${item['color']}";
        _imagenesCache[key] = item['imagen'] ?? '';
      }

    } catch (e) {
      debugPrint("Error precargando imágenes: $e");
    }
  }

  Future<void> _subirComprobanteDesdeLista(String pedidoId,String base64Img,) async {
        try {
          setState(() => _subiendo = true);

          final response = await ApiService.subirComprobante(
            pedidoId,
            base64Img,
          );

          final success = response['success'] == true;
          final message =
              response['message'] ?? response['estado'] ?? "Sin mensaje";

          if (!success) {
            throw Exception(message);
          }

          // 🔥 REFRESCA DESDE BACKEND (CLAVE)
          await _loadPedidos();

          if (!mounted) return;

          setState(() => _subiendo = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

        } catch (e) {
          if (!mounted) return;

          setState(() => _subiendo = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll("Exception: ", ""),
              ),
              backgroundColor: Colors.red,
            ),
          );

          debugPrint("Error subida: $e");
        }
      }

  void showTopMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // 🔥 se elimina solo
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  void _mostrarConfirmacionEnvio(Pedido order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 50.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 🔹 HANDLE (estilo Uber)
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Icon(Icons.check_circle, color: Colors.green, size: 50),

                const SizedBox(height: 10),

                const Text(
                  "¿Enviaste el comprobante?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Confirma para finalizar el pedido",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // 🔥 BOTONES
                Row(
                  children: [

                    // ❌ NO
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Aún no"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ✅ SI
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(bottomContext);

                          Navigator.pop(context);

                          // ⏳ opcional: deja que cierre suave
                          await Future.delayed(const Duration(milliseconds: 200));
                          // 🔥 ACTUALIZA BACKEND
                          await ApiService.marcarEnviado(order.id);

                          setState(() {
                            final index = _orders.indexWhere((p) => p.id == order.id);

                            if (index != -1) {
                              _orders[index] = _orders[index].copyWith(
                                nuevoEstado: "finalizado",
                              );
                            }
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Pedido finalizado"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },

                        child: const Text("Sí, ya envié"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}