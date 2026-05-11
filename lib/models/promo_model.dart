// models/promo_model.dart
import 'item_pedido.dart';

class PromoRule {
  final String id;
  final String nombre;
  final String tipo; // '3x120', '2x80', 'descuento_porcentaje'
  final int cantidadRequerida;
  final int precioPromocional;
  final int? porcentajeDescuento;
  final List<String> productosAplicables; // vacío = todos los productos
  final bool activo;

  PromoRule({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.cantidadRequerida,
    required this.precioPromocional,
    this.porcentajeDescuento,
    this.productosAplicables = const [],
    this.activo = true,
  });

  factory PromoRule.fromJson(Map<String, dynamic> json) {
    return PromoRule(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      cantidadRequerida: json['cantidad_requerida'] ?? 0,
      precioPromocional: json['precio_promocional'] ?? 0,
      porcentajeDescuento: json['porcentaje_descuento'],
      productosAplicables: List<String>.from(json['productos_aplicables'] ?? []),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'cantidad_requerida': cantidadRequerida,
      'precio_promocional': precioPromocional,
      'porcentaje_descuento': porcentajeDescuento,
      'productos_aplicables': productosAplicables,
      'activo': activo,
    };
  }
}

class PromoAplicada {
  final PromoRule regla;
  final List<ItemPedido> items;
  final int ahorro;
  final int precioFinal;

  PromoAplicada({
    required this.regla,
    required this.items,
    required this.ahorro,
    required this.precioFinal,
  });
}