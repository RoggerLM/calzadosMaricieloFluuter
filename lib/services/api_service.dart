import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:calzados_luciana/models/categori_model.dart';
import 'package:calzados_luciana/models/product_model.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class ApiService {
  static const String baseUrl =
      "https://abrasive-paper-vanish.ngrok-free.dev/api";


  /// Crea un nuevo pedido en el backend
  static Future<Map<String, dynamic>> crearPedido(
      Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
        Uri.parse("$baseUrl/pedidos/crearpedido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? "Error HTTP ${response.statusCode}");
      }
      if (data['success'] != true) {
        if (data['productos_sin_stock'] != null) {
          final lista = (data['productos_sin_stock'] as List)
              .map((p) =>
          '${p['codigo']} T${p['talla']}: disponible ${p['disponible']}')
              .join('\n');
          throw Exception('Stock insuficiente:\n$lista');
        }
        throw Exception(data['error'] ?? "Error al crear pedido");
      }

      return data;
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("El servidor no responde (timeout)");
    }
  }

  static Future<List<Pedido>> getPedidos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/showpedidos"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return List<Pedido>.from(
          data.map((x) => Pedido.fromJson(x)),
        );
      }
      // 🔴 Error del servidor
      else if (response.statusCode >= 500) {
        throw Exception("🚫 Servicio no disponible (servidor caído)");
      }
      // 🟠 Error del cliente (400, 404, etc)
      else {
        throw Exception("⚠️ Error al cargar pedidos (${response.statusCode})");
      }
    } on SocketException {
      // ❌ Sin internet
      throw Exception("📡 Sin conexión a internet");
    } on TimeoutException {
      // ⏱ Timeout
      throw Exception("⏳ El servidor no responde (timeout)");
    } catch (e) {
      // ⚠️ Error general
      throw Exception("❌ Error inesperado: $e");
    }
  }

  static Future<void> updateEstado(String id, String estado) async {
    await http.put(
      Uri.parse("$baseUrl/pedidos/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"estado": estado}),
    );
  }

  static Future<Map<String, dynamic>> subirComprobante( String pedidoId,String base64Img,) async {
    final url = Uri.parse("$baseUrl/pedidos/addcomprobante");

    try {
      final body = {
        "pedido_id": pedidoId,
        "image": base64Img,
      };



      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );



      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw Exception("Respuesta inválida del servidor");
      }

      // 🔴 ERROR HTTP
      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? "Error HTTP ${response.statusCode}",
        );
      }

      // 🔴 ERROR LÓGICO DEL BACKEND
      if (data['success'] != true) {
        throw Exception(
          data['message'] ?? "Error desconocido del backend",
        );
      }

      // ✅ TODO OK
      return data;

    } catch (e) {
      // 🔥 DEBUG FINAL
      print("❌ ERROR subirComprobante: $e");

      rethrow; // importante → lo manejas en el UI
    }
  }

  static Future<Map<String, dynamic>> marcarEnviado(String pedidoId) async {
    final url = Uri.parse("$baseUrl/pedidos/enviado");

    try {
      final body = {
        "pedido_id": pedidoId
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw Exception("Respuesta inválida del servidor");
      }

      // 🔴 ERROR HTTP
      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? "Error HTTP ${response.statusCode}",
        );
      }

      // 🔴 ERROR LÓGICO DEL BACKEND
      if (data['success'] != true) {
        throw Exception(
          data['message'] ?? "Error desconocido del backend",
        );
      }

      // ✅ TODO OK
      return data;

    } catch (e) {
      // 🔥 DEBUG FINAL
      print("❌ ERROR subirComprobante: $e");

      rethrow; // importante → lo manejas en el UI
    }
  }

  static Future<List<String>>  getCategories() async {
    final url = await Uri.parse("$baseUrl/categorias/showcategorias");
    try {
      final response = await http.get(
          url
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(
            data['data'].map((x) => x['descripcion'].toString()),
          );
        } else {
          throw Exception('Respuesta inválida del servidor');
        }
      } else {
        print(response.statusCode);
        throw Exception('Error al cargar categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  // ─────────────────────────────────────────────
  // PRODUCTOS
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final url = Uri.parse("$baseUrl/productos/addproductos");
    try {

      // 🔥 DEBUG (ver qué envías)
      print("📤 BODY: ${jsonEncode(productData)}");

      final response = await http.post(
          url,
        body: jsonEncode(productData),
      ).timeout(const Duration(seconds: 30));

      // 🔥 DEBUG (ver respuesta cruda)
      print("📥 STATUS: ${response.statusCode}");
      print("📥 BODY: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al crear producto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> reponerStock({
    required String productoId,
    required Map<String, int> tallas,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse("$baseUrl/productos/reposicion"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "producto_id": productoId,
          "tallas": tallas,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? "Error HTTP ${response.statusCode}");
      }
      if (data['success'] != true) {
        throw Exception(data['message'] ?? "Error al reponer stock");
      }
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("El servidor no responde");
    }
  }
  /// Lista completa de productos ordenada por código
  static Future<List<Map<String, dynamic>>> getProductos() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/productos/showproductos"))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        return List<Map<String, dynamic>>.from(data);

      } else if (response.statusCode >= 500) {
        throw Exception("🚫 Servicio no disponible (servidor caído)");
      } else {
        throw Exception("⚠️ Error al cargar productos (${response.statusCode})");
      }
    } on SocketException {
      throw Exception("📡 Sin conexión a internet");
    } on TimeoutException {
      throw Exception("⏳ El servidor no responde (timeout)");
    } catch (e) {
      throw Exception("❌ Error inesperado: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> buscarProductos(String query) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/productos/buscar?q=${Uri.encodeComponent(query)}"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getImagenes(List<Map<String, String>> productos) async {

    final response = await http.post(
      Uri.parse("$baseUrl/productos/imagenes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(productos),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return List<Map<String, dynamic>>.from(jsonData['data']);
    }
    else {
      throw Exception("Error servidor");
    }
  }
  // ─────────────────────────────────────────────
  // DASHBOARD
  // ─────────────────────────────────────────────

  /// Estadísticas rápidas: total_productos, sin_stock, stock_bajo
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response =
      await http.get(Uri.parse("$baseUrl/dashboard/stats")).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return body['data'];
        throw Exception(body['message'] ?? 'Error en stats');
      }
      throw Exception("Error HTTP ${response.statusCode}");
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("El servidor no responde");
    }
  }

  /// Alertas de stock agrupadas por producto
  /// Retorna lista de: { codigo, color, imagen, alertas: [{talla, stock, tipo}] }
  static Future<List<Map<String, dynamic>>> getDashboardAlertas() async {
    try {
      final response =
      await http.get(Uri.parse("$baseUrl/dashboard/alertas")).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
        throw Exception(body['message'] ?? 'Error en alertas');
      }
      throw Exception("Error HTTP ${response.statusCode}");
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("El servidor no responde");
    }
  }

  /// Top más vendidos
  /// Retorna lista de: { codigo, color, imagen, ventas }
  static Future<List<Map<String, dynamic>>> getMasVendidos({int limit = 5}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/dashboard/mas-vendidos?limit=$limit"))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
        throw Exception(body['message'] ?? 'Error en más vendidos');
      }
      throw Exception("Error HTTP ${response.statusCode}");
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("El servidor no responde");
    }
  }



}