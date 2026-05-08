// models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String codigo;
  final double precio;
  final String color;
  final String categoria;
  final Map<String, int> sizes;
  final String imagen;
  final int stockMinimo;
  final Timestamp  createdAt;

  Product({
    this.id,
    required this.codigo,
    required this.precio,
    required this.color,
    required this.categoria,
    required this.sizes,
    required this.imagen,
    this.stockMinimo = 2,
    required this.createdAt,
  });

  // Getter para calcular el stock total
  int get stockTotal {
    return sizes.values.fold(0, (sum, stock) => sum + stock);
  }

  // Getter para verificar si tiene stock bajo
  bool get hasLowStock {
    return stockTotal > 0 && stockTotal <= stockMinimo;
  }

  // Getter para verificar si está sin stock
  bool get isOutOfStock {
    return stockTotal == 0;
  }

  // Método para convertir desde Firebase
  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      codigo: data['codigo'],
      precio: (data['precio'] ?? 0).toDouble(),
      color: data['color'] ?? '',
      categoria: data['categoria'] ?? '',
      sizes: Map<String, int>.from(data['tallas'] ?? {}),
      imagen: data['imagen'],
      stockMinimo: data['stockMinimo'] ?? 2,
      createdAt: data['createdAt'] ?? Timestamp.now(), // Mantener como Timestamp
    );
  }

  // Método para convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'precio': precio,
      'color': color,
      'categoria': categoria,
      'tallas': sizes,
      'imagen': imagen,
      'stockMinimo': stockMinimo,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }


}