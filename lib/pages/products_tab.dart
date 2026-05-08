import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calzados_luciana/services/firestore_service.dart';
import 'package:calzados_luciana/models/product_model.dart';
import '../widgets/updateProducto_dialog.dart';
import 'add_product_page.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: firestoreService.getProducts(),
        builder: (context, productsSnapshot) {
          if (productsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productsSnapshot.hasError) {
            return Center(child: Text('Error: ${productsSnapshot.error}'));
          }

          final products = productsSnapshot.data ?? [];

          return StreamBuilder<List<String>>(
            stream: firestoreService.getCategories(),
            builder: (context, categoriesSnapshot) {
              final categories = categoriesSnapshot.data ?? [];

              return Column(
                children: [
                  // Barra de búsqueda y filtros
                  _buildSearchAndFilters(categories),

                  // Resumen de stock
                  _buildStockSummary(products),

                  // Lista de productos
                  Expanded(
                    child: _buildProductsList(products),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(
                onProductAdded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Producto agregado correctamente"),
                    ),
                  );
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

  Widget _buildSearchAndFilters(List<String> categories) {
    final availableCategories = ['Todos', ...categories];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary(List<Product> products) {
    final totalProducts = products.length;
    final lowStock = products.where((p) => p.hasLowStock).length;
    final outOfStock = products.where((p) => p.isOutOfStock).length;
    final goodStock = products.where((p) => !p.isOutOfStock && !p.hasLowStock).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStockStat('Total', totalProducts.toString(), Colors.blue),
          _buildStockStat('Bajo Stock', lowStock.toString(), Colors.orange),
          _buildStockStat('Sin Stock', outOfStock.toString(), Colors.red),
          _buildStockStat('OK', goodStock.toString(), Colors.green),
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.codigo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (product.codigo ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((product) => product.categoria == _selectedCategory).toList();
    }

    return filtered;
  }

  Widget _buildProductsList(List<Product> products) {
    final filteredProducts = _getFilteredProducts(products);

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showProductDetails(product);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          child: Row(
            children: [
              // Imagen del producto
              _buildProductImage(product),

              const SizedBox(width: 12),

              // Contenido del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fila superior: Código
                    Text(
                      product.codigo ?? 'Sin código',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.color,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),

                    ),
                    // Fila media: Stock y precio
                    Row(
                      children: [
                        Text(
                          'Stock: ${product.stockTotal}',
                          style: TextStyle(
                            color: product.isOutOfStock
                                ? Colors.red
                                : product.hasLowStock
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${product.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Fila inferior: Categoría
                    Text(
                      product.categoria,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Estado de stock (trailing)
              _buildStockStatus(product),
            ],
          ),
        ),
      ),
    );
  }
// Método auxiliar para el estado de stock
  Widget _buildStockStatus(Product product) {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text(
          'SIN STOCK',
          style: TextStyle(
            fontSize: 10,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (product.hasLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          'STOCK BAJO',
          style: TextStyle(
            fontSize: 10,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox(); // Vacío si no hay alerta
  }

  Widget _buildProductImage(Product product) {
    if (product.imagen != null) {
      try {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(product.imagen!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultIcon();
              },
            ),
          ),
        );
      } catch (e) {
        return _buildDefaultIcon();
      }
    } else {
      print('✅ Imagen no encontrada)');
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag, color: Colors.grey),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                // Header con imagen y título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del producto
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product.imagen != null
                            ? Image.memory(
                          base64Decode(product.imagen!),
                          fit: BoxFit.contain, // Cambiado de cover a contain
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDialogDefaultIcon();
                          },
                        )
                            : _buildDialogDefaultIcon(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Título y código
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.codigo ?? 'Sin código',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStockColor(product).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStockColor(product)),
                            ),
                            child: Text(
                              _getStockText(product),
                              style: TextStyle(
                                color: _getStockColor(product),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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

                // Información del producto en tarjetas
                _buildInfoCard(
                  title: 'Información General',
                  children: [
                    _buildInfoRow('Categoría', product.categoria),
                    _buildInfoRow('Color', product.color),
                    _buildInfoRow('Precio', '\$${product.precio.toStringAsFixed(2)}'),
                  ],
                ),

                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Inventario',
                  children: [
                    _buildInfoRow(
                      'Stock Total',
                      '${product.stockTotal} unidades',
                      valueColor: _getStockColor(product),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Tallas Disponibles',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.sizes.entries.map((entry) {
                        final size = entry.key;
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
                              Text(
                                'Talla $size',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: stock > 0 ? Colors.blue.shade800 : Colors.grey,
                                ),
                              ),
                              Text(
                                '$stock',
                                style: TextStyle(
                                  color: stock > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),

                    ElevatedButton(
                      onPressed: () {
                        // Aquí podrías implementar la edición del producto
                        Navigator.pop(context);
                        _showUdpdateProduct(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
  // Widget auxiliar para tarjetas de información
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

// Widget auxiliar para filas de información
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Widget para el icono por defecto en el diálogo
  Widget _buildDialogDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
    );
  }

// Métodos auxiliares para el stock
  Color _getStockColor(Product product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.hasLowStock) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(Product product) {
    if (product.isOutOfStock) return 'SIN STOCK';
    if (product.hasLowStock) return 'STOCK BAJO';
    return 'STOCK OK';
  }

  //METODO PARA EDITAR TALLAS DEL PRODUCTO
  void _showUdpdateProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => UpdateProductoDialog(product: product),
    ).then((result) {
      if (result == true) {
        // Opcional: refrescar la lista
        setState(() {});
      }
    });
  }
}