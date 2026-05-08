// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Cambiar el nombre a Pedido (o cualquier otro nombre que prefieras)
class Sesiones {
  final String id;
  final String numero;
  final String nuevoEstado;
  final Map<String, dynamic> datosEnvio;
  final List<Map<String, dynamic>> productos;
  final Timestamp timestamp;
  final String? userId;
  final String? sessionId;

  Sesiones({
    required this.id,
    required this.numero,
    required this.nuevoEstado,
    required this.datosEnvio,
    required this.productos,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  factory Sesiones.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir número a String de forma segura
    final numero = data['numero']?.toString() ?? '';

    // Convertir datos_envio de forma segura
    final datosEnvioRaw = data['datos_envio'] ?? {};
    final Map<String, dynamic> datosEnvio = {};

    if (datosEnvioRaw is Map) {
      datosEnvioRaw.forEach((key, value) {
        datosEnvio[key.toString()] = value;
      });
    }

    // Convertir productos de forma segura
    final sesionesRaw = data['productos'] ?? [];
    final List<Map<String, dynamic>> productos = [];

    if (sesionesRaw is List) {
      for (final item in sesionesRaw) {
        if (item is Map) {
          final Map<String, dynamic> productMap = {};
          item.forEach((key, value) {
            productMap[key.toString()] = value;
          });
          productos.add(productMap);
        }
      }
    }

    return Sesiones(
      id: doc.id,
      numero: numero,
      nuevoEstado: data['nuevoEstado']?.toString() ?? 'pendiente',
      datosEnvio: datosEnvio,
      productos: productos,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      userId: data['userId']?.toString(),
      sessionId: data['sessionId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numero': numero,
      'nuevoEstado': nuevoEstado,
      'datos_envio': datosEnvio,
      'productos': productos,
      'timestamp': timestamp,
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  // Verificar si el pedido es urgente (más de 1 semana)
  bool get isUrgente {
    final now = DateTime.now();
    final orderDate = timestamp.toDate();
    final difference = now.difference(orderDate);
    return difference.inDays >= 7;
  }

  // Verificar si el pedido está terminado
  bool get isTerminado {
    return nuevoEstado == 'entregado' || nuevoEstado == 'completado';
  }

  // Obtener el total del pedido de forma segura
  double get total {
    double total = 0;
    for (final producto in productos) {
      final precio = _safeToDouble(producto['precio']);
      final cantidad = _safeToInt(producto['cantidad']);
      total += precio * cantidad;
    }
    return total;
  }

  // Obtener cantidad total de productos de forma segura
  int get cantidadTotal {
    int total = 0;
    for (final producto in productos) {
      total += _safeToInt(producto['cantidad']);
    }
    return total;
  }

  // Métodos auxiliares para conversión segura
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Método para obtener datos de envío de forma segura
  String get clienteNombre => datosEnvio['nombre']?.toString() ?? 'Cliente';
  String get clienteDepartamento => datosEnvio['departamento']?.toString() ?? '';
  String get clienteProvincia => datosEnvio['provincia']?.toString() ?? '';
  String get clienteTelefono => datosEnvio['telefono']?.toString() ?? '';
}