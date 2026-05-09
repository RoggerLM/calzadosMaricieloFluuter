import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:calzados_luciana/services/api_service.dart';
import 'package:calzados_luciana/models/product_model.dart';
import 'package:calzados_luciana/screens/error_view.dart';
import 'package:calzados_luciana/widgets/skeletons.dart';
import '../widgets/updateProducto_dialog.dart';
import 'add_product_page.dart';

// ─────────────────────────────────────────────────────────
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {

  List<Product> _products = [];
  String _searchQuery      = '';
  String _selectedCategory = 'Todos';
  bool   _loading          = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  // ── Carga ────────────────────────────────────────────────
  Future<void> _loadProductos() async {
    setState(() { _loading = true; _error = null; });

    try {
      final data = await ApiService.getProductos();

      if (!mounted) return;
      setState(() {
        _products = data.map((j) => Product.fromJson(j)).toList();
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    if (_loading) return Skeletons.pedidosList(); // reutiliza tu skeleton

    if (_error != null) {
      return ErrorView(mensaje: _error!, onRetry: _loadProductos);
    }

    // Categorías únicas extraídas de los productos
    final categories = _products
        .map((p) => p.categoria)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProductos,
        child: Column(
          children: [
            _buildSearchAndFilters(categories),
            _buildStockSummary(),
            Expanded(child: _buildProductsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(
                onProductAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Producto agregado correctamente")),
                  );
                  _loadProductos(); // refresca después de agregar
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Barra búsqueda + filtros ──────────────────────────────
  Widget _buildSearchAndFilters(List<String> categories) {
    final available = ['Todos', ...categories];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: available.length,
              itemBuilder: (context, index) {
                final cat = available[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Resumen stock ─────────────────────────────────────────
  Widget _buildStockSummary() {
    final total     = _products.length;
    final lowStock  = _products.where((p) => p.hasLowStock).length;
    final outStock  = _products.where((p) => p.isOutOfStock).length;
    final goodStock = _products.where((p) => !p.isOutOfStock && !p.hasLowStock).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStockStat('Total',      total.toString(),     Colors.blue),
          _buildStockStat('Bajo Stock', lowStock.toString(),  Colors.orange),
          _buildStockStat('Sin Stock',  outStock.toString(),  Colors.red),
          _buildStockStat('OK',         goodStock.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStockStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Lista filtrada ────────────────────────────────────────
  List<Product> get _filtered {
    var list = _products;
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
      p.codigo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.color.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    if (_selectedCategory != 'Todos') {
      list = list.where((p) => p.categoria == _selectedCategory).toList();
    }
    return list;
  }

  Widget _buildProductsList() {
    final filteredProducts = _filtered;

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron productos',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) => _buildProductItem(filteredProducts[index]),
    );
  }

  // ── Item ──────────────────────────────────────────────────
  Widget _buildProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showProductDetails(product),
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          child: Row(
            children: [
              _buildProductImage(product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.codigo.isNotEmpty ? product.codigo : 'Sin código',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(product.color,
                        style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    Row(
                      children: [
                        Text(
                          'Stock: ${product.stockTotal}',
                          style: TextStyle(
                            color: product.isOutOfStock ? Colors.red
                                : product.hasLowStock   ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(product.categoria,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStockStatus(product),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockStatus(Product product) {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text('SIN STOCK',
            style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
      );
    } else if (product.hasLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text('STOCK BAJO',
            style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox();
  }

  // ── Imagen ────────────────────────────────────────────────
  Widget _buildProductImage(Product product) {
    if (product.imagen != null && product.imagen!.isNotEmpty) {
      try {
        // Soporta tanto base64 puro como URL http
        if (product.imagen!.startsWith('http')) {
          return _imageContainer(
            child: Image.network(product.imagen!, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _defaultIcon()),
          );
        } else {
          return _imageContainer(
            child: Image.memory(base64Decode(product.imagen!), fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _defaultIcon()),
          );
        }
      } catch (_) {}
    }
    return _defaultIcon();
  }

  Widget _imageContainer({required Widget child}) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  Widget _defaultIcon({double size = 100}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
    );
  }

  // ── Detalle ───────────────────────────────────────────────
  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 👈 agrega esto
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header imagen + título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildDialogImage(product),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.codigo.isNotEmpty ? product.codigo : 'Sin código',
                            style: const TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _stockColor(product).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _stockColor(product)),
                            ),
                            child: Text(
                              _stockText(product),
                              style: TextStyle(
                                  color: _stockColor(product),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                _buildInfoCard(title: 'Información General', children: [
                  _buildInfoRow('Color', product.color),
                  if (product.categoria.isNotEmpty)
                    _buildInfoRow('Categoría', product.categoria),
                ]),

                const SizedBox(height: 16),

                _buildInfoCard(title: 'Inventario', children: [
                  _buildInfoRow('Stock Total', '${product.stockTotal} unidades',
                      valueColor: _stockColor(product)),
                ]),

                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Tallas Disponibles',
                  children: [
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: product.tallas.entries.map((entry) {
                        final stock = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: stock > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: stock > 0 ? Colors.blue.shade200 : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text('Talla ${entry.key}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: stock > 0 ? Colors.blue.shade800 : Colors.grey)),
                              Text('$stock',
                                  style: TextStyle(
                                      color: stock > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUpdateProduct(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Editar Producto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogImage(Product product) {
    if (product.imagen != null && product.imagen!.isNotEmpty) {
      try {
        if (product.imagen!.startsWith('http')) {
          return Image.network(product.imagen!, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _dialogDefaultIcon());
        } else {
          return Image.memory(base64Decode(product.imagen!), fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _dialogDefaultIcon());
        }
      } catch (_) {}
    }
    return _dialogDefaultIcon();
  }

  Widget _dialogDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  Color _stockColor(Product p) {
    if (p.isOutOfStock) return Colors.red;
    if (p.hasLowStock)  return Colors.orange;
    return Colors.green;
  }

  String _stockText(Product p) {
    if (p.isOutOfStock) return 'SIN STOCK';
    if (p.hasLowStock)  return 'STOCK BAJO';
    return 'STOCK OK';
  }

  void _showUpdateProduct(Product product) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => UpdateProductoDialog(
        product: product,
        onProductUpdated: (Product p1) {},
      ),
    ).then((result) {
      if (result == true) _loadProductos();
    });
  }
}