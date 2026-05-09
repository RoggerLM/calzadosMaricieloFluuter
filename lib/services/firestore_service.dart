// services/firestore_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === COLECCIONES ===
  CollectionReference get _productsRef => _firestore.collection('productos');
  CollectionReference get _categoriasRef => _firestore.collection('categorias');
  // === CATEGORÍAS ===

  // Obtener todas las categorías
  Stream<List<String>> getCategories() {
    return _categoriasRef
        .orderBy('codigo')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['descripcion'] as String;
      }).toList();
    });
  }
// Cargar categorías por defecto (ejecutar una sola vez)
  Future<void> loadDefaultCategories() async {
    final defaultCategories = [
      {
        'codigo': 'CAT-001',
        'descripcion': 'Mocasines',
      },
      {
        'codigo': 'CAT-002',
        'descripcion': 'Botines',
      },
    ];

    try {
      // Verificar si ya existen categorías
      final snapshot = await _categoriasRef.get();
      if (snapshot.docs.isEmpty) {
        for (final category in defaultCategories) {
          await _categoriasRef.add({
            'codigo': category['codigo'],
            'descripcion': category['descripcion'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Error al cargar categorías por defecto: $e');
    }
  }
  // Agregar nueva categoría
  Future<void> addCategory(String categoryName,String categoryDescription) async {
    try {
      await _categoriasRef.add({
        'codigo': categoryName,
        'descripcion': categoryDescription,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar categoría: $e');
    }
  }
  // === PRODUCTOS ===

  // Agregar producto
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _productsRef.add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar producto: $e');
    }
  }

  // Obtener todos los productos
  Stream<List<Product>> getProducts() {
    return _productsRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Obtener productos por categoría
  Stream<List<Map<String, dynamic>>> getProductsByCategory(String category) {
    return _productsRef
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }
  // Obtener todos los productos sin stock o menos
  Stream<List<Product>> getProductsSinStock() {
    return _productsRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .where((product) => product.tallas.values.any((stock) => stock < 3))
          .toList();
    });
  }

  // En firestore_service.dart
  Future<void> updateProductSizes(Product product) async {
    try {
      await _firestore.collection('productos').doc(product.id).update({
        'tallas': product.tallas,
      });
    } catch (e) {
      print('Error actualizando tallas: $e');
      throw e;
    }
  }

  // Eliminar producto
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // Obtener productos con stock bajo
  Stream<List<Map<String, dynamic>>> getLowStockProducts() {
    return _productsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList()
          .where((product) {
        // Calcular stock total
        final sizes = product['sizes'] as Map<String, dynamic>? ?? {};
        final totalStock = sizes.values.fold(0, (sum, stock) => sum + (stock as int));
        final minStock = product['minStock'] as int? ?? 5;
        return totalStock > 0 && totalStock <= minStock;
      }).toList();
    });
  }

  // Obtener productos sin stock
  Stream<List<Map<String, dynamic>>> getOutOfStockProducts() {
    return _productsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList()
          .where((product) {
        final sizes = product['sizes'] as Map<String, dynamic>? ?? {};
        final totalStock = sizes.values.fold(0, (sum, stock) => sum + (stock as int));
        return totalStock == 0;
      }).toList();
    });
  }
/*
  // Pedidos
  Stream<List<Pedido>> getOrders() {
    return FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Pedido.fromFirestore(doc))
        .toList());
  }

  Stream<List<Pedido>> getOrdersByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('sesiones')
        .where('nuevoEstado', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Pedido.fromFirestore(doc))
        .toList());
  }

  Stream<List<Pedido>> getUrgentOrders() {
    final oneWeekAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7))
    );

    return FirebaseFirestore.instance
        .collection('sesiones')
        .where('timestamp', isLessThan: oneWeekAgo)
        .where('nuevoEstado', whereIn: ['confirmando_datos_envio', 'procesando', 'pendiente'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Pedido.fromFirestore(doc))
        .toList());
  }
  // En tu aplicación, usa un solo estado para sesiones

  Stream<List<Pedido>> getSessions() {
  return FirebaseFirestore.instance
      .collection('sesiones')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => Pedido.fromFirestore(doc))
      .toList());
  }
*/
  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return FirebaseFirestore.instance
        .collection('pedidos')
        .doc(orderId)
        .update({'nuevoEstado': newStatus});
  }

  Future<void> deleteOrder(String orderId) {
    return FirebaseFirestore.instance
        .collection('sesiones')
        .doc(orderId)
        .delete();
  }

// Subir comprobante de la agencia de envíos (guardar como base64 en Firestore)
  Future<void> uploadComprobante(String orderId, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      await _firestore
          .collection('comprobantes')
          .doc(orderId)
          .set({
        'imageData': base64Image,
        'fileName': 'comprobante_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'orderId': orderId,
        'uploadedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al subir comprobante: $e');
    }
  }

  // Obtener comprobante desde Firestore
  Future<Map<String, dynamic>?> getComprobante(String orderId) async {
    try {
      final doc = await _firestore
          .collection('comprobantes')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener comprobante: $e');
    }
  }

  // Eliminar comprobante
  Future<void> deleteComprobante(String orderId) async {
    try {
      await _firestore
          .collection('comprobantes')
          .doc(orderId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar comprobante: $e');
    }
  }

  // Verificar si existe comprobante
  Future<bool> comprobanteExists(String orderId) async {
    try {
      final doc = await _firestore
          .collection('comprobantes')
          .doc(orderId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}