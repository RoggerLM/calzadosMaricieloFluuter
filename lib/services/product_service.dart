// services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la colección de productos
  CollectionReference get _productsRef => _firestore.collection('products');

  // Agregar producto a Firebase
  Future<void> addProduct(Product product) async {
    try {
      await _productsRef.add(product.toMap());
    } catch (e) {
      throw Exception('Error al agregar producto: $e');
    }
  }

  // Obtener todos los productos
  Stream<List<Product>> getProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Actualizar producto
  Future<void> updateProduct(Product product) async {
    try {
      await _productsRef.doc(product.id).update(product.toMap());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
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
}