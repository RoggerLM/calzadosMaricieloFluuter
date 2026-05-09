// models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String codigo;
  final double precio;
  final String color;
  final String categoria;
  final Map<String, int> tallas;
  final String imagen;
  final int stockMinimo;
  final Timestamp createdAt;

  Product({
    this.id,
    required this.codigo,
    required this.precio,
    required this.color,
    required this.categoria,
    required this.tallas,
    required this.imagen,
    this.stockMinimo = 2,
    required this.createdAt,
  });

  // Getter para calcular el stock total
  int get stockTotal => tallas.values.fold(0, (sum, stock) => sum + stock);

  // Getter para verificar si tiene stock bajo
  bool get hasLowStock => stockTotal > 0 && stockTotal <= stockMinimo;

  // Getter para verificar si está sin stock
  bool get isOutOfStock => stockTotal == 0;

  // ── Desde Firestore (original) ──────────────────────────
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: data['id'],
      codigo: data['codigo'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      color: data['color'] ?? '',
      categoria: data['categoria'] ?? '',
      tallas: Map<String, int>.from(data['tallas'] ?? {}),
      imagen: data['imagen'],
      stockMinimo: data['stockMinimo'] ?? 2,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // ── Desde el backend REST (nuevo) ───────────────────────
  // El backend devuelve: { codigo, color, tallas, imagen, precio?, categoria? }
  factory Product.fromJson(Map<String, dynamic> json) {
    final tallasRaw = Map<String, dynamic>.from(json['tallas'] ?? {});
    final tallas    = tallasRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    return Product(
      id:          json['id'], // el backend no devuelve el doc id de Firestore
      codigo:      json['codigo']    ?? '',
      precio:      (json['precio']   ?? 0).toDouble(),
      color:       json['color']     ?? '',
      categoria:   json['categoria'] ?? '',
      tallas:       tallas,
      imagen:      json['imagen'],
      stockMinimo: json['stockMinimo'] ?? 2,
      createdAt:   Timestamp.now(), // el backend no lo manda, valor por defecto
    );
  }

  // ── Para guardar en Firestore ───────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'codigo':     codigo,
      'precio':     precio,
      'color':      color,
      'categoria':  categoria,
      'tallas':     tallas,
      'imagen':     imagen,
      'stockMinimo': stockMinimo,
      'createdAt':  createdAt.millisecondsSinceEpoch,
    };
  }
}