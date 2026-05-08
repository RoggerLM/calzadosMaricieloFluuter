import 'dart:ffi';

class Pedido {
  final String id;

  final Map<String, dynamic> cliente;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> promos;
  final double totalPedido;
  final int totalProductos;
  final String nuevoEstado;
  final DateTime  fecha;
  final String telefonoWhatsapp;
  final bool tieneComprobante;
  final String comprobanteImagen;

  Pedido({
    required this.id,
    required this.cliente,
    required this.productos,
    required this.promos,
    required this.totalPedido,
    required this.totalProductos,
    required this.nuevoEstado,
    required this.fecha,
    required this.telefonoWhatsapp,

    this.tieneComprobante = false,
    this.comprobanteImagen = "",
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] ?? '',
      cliente: json['cliente'] ?? {},

      productos: List<Map<String, dynamic>>.from(json['productos'] ?? []),
      promos: List<Map<String, dynamic>>.from(json['promos'] ?? []),
      totalPedido: (json['total'] ?? 0).toDouble(),
      totalProductos: (json['totalProductos'] ?? 0).toInt(),
      nuevoEstado: json['estado'] ?? 'pendiente',
      fecha:   DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      telefonoWhatsapp: json['telefonoWhatsapp'],

      tieneComprobante: json["tieneComprobante"] ?? false,
      comprobanteImagen: json["comprobanteImagen"] ?? "",
    );
  }
  // 🔥 COPY WITH (CLAVE PARA TU ERROR)
  Pedido copyWith({
    String? nuevoEstado,
    String? comprobanteImagen,
    bool? tieneComprobante,
    bool? comprobanteSubido,
  }) {
    return Pedido(
      id: id,
      nuevoEstado: nuevoEstado ?? this.nuevoEstado,
      productos: productos,
      cliente: cliente,
      promos: promos,
      totalPedido: totalPedido,
      totalProductos: totalProductos,
      telefonoWhatsapp: telefonoWhatsapp,
      tieneComprobante: tieneComprobante ?? this.tieneComprobante,
      comprobanteImagen: comprobanteImagen ?? this.comprobanteImagen,
      fecha: fecha,
    );
  }

  // 🔥 ESTA ES LA CLAVE (fusiona todo)
  List<Map<String, dynamic>> get productosFinales {
    List<Map<String, dynamic>> lista = [];

    // productos normales
    lista.addAll(productos);

    // productos dentro de promos
    for (final promo in promos) {
      final items = promo['items'] ?? [];

      for (final item in items) {
        lista.add({
          ...item,
          "promo": promo['tipo'],
        });
      }
    }

    return lista;
  }

  // helpers para UI
  String get clienteNombre => cliente['nombre'] ?? 'Cliente';
  String get clienteProvincia => cliente['provincia'] ?? '';

  // 🔹 TOTAL (usa backend, no recalcula)
  double get total => totalPedido;

  // 🔹 CANTIDAD TOTAL
  int get cantidadTotal {
    int total = 0;
    for (final producto in productos) {
      total += _safeToInt(producto['cantidad']);
    }
    return total;
  }

  // 🔹 ESTADO
  /*bool get isUrgente {
    final now = DateTime.now();
    final orderDate = DateTime.timestamp().day";
    final difference = now.difference(orderDate);
    return difference.inDays >= 7;
  }
*/
  bool get isTerminado {
    return nuevoEstado == 'entregado' || nuevoEstado == 'completado';
  }

  // 🔹 CLIENTE
  String get Nombre => cliente['nombre'] ?? 'Cliente';
  String get Dni => cliente['dni'] ?? "Dni";
  String get Departamento => cliente['departamento'] ?? '';
  String get Provincia => cliente['provincia'] ?? '';
  String get Telefono => cliente['celular'] ?? '';
  String get Oficina => cliente['oficina'] ?? '';

  set comprobanteSubido(bool comprobanteSubido) {}
  // 🔹 HELPERS
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

}