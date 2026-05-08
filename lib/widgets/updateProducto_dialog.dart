
import 'dart:convert';

import 'package:calzados_luciana/models/product_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';

class UpdateProductoDialog extends StatefulWidget{
  final Product product;

  const UpdateProductoDialog({super.key, required this.product});

  @override
  State<UpdateProductoDialog> createState() => _UpdateProductoDialog();
}

class _UpdateProductoDialog extends State<UpdateProductoDialog> {
  late Map<String, int> _tallas;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tallas = Map.from(widget.product.sizes);
  }

  void _updateTalla(String talla, int newStock) {
    setState(() {
      if (newStock > 0) {
        _tallas[talla] = newStock;
      } else {
        _tallas.remove(talla);
      }
    });
  }

  void _addNewSize() {
    final tallaController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nueva Talla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tallaController,
              decoration: const InputDecoration(
                labelText: 'Talla',
                hintText: 'Ej: 38, 39, 40',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'Stock',
                hintText: 'Cantidad disponible',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final talla = tallaController.text.trim();
              final stock = int.tryParse(stockController.text.trim()) ?? 0;

              if (talla.isNotEmpty && stock > 0) {
                _updateTalla(talla, stock);
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // Calcular stock total
      int totalStock = _tallas.values.fold(0, (sum, stock) => sum + stock);

      // Crear producto actualizado SOLO con las tallas y stock total
      final updatedProduct = Product(
        id: widget.product.id,
        codigo: widget.product.codigo,
        categoria: widget.product.categoria,
        color: widget.product.color,
        precio: widget.product.precio,
        sizes: _tallas,
        imagen: widget.product.imagen,
        stockMinimo: widget.product.stockMinimo,
        createdAt: widget.product.createdAt,
      );

      await firestoreService.updateProductSizes(updatedProduct);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tallas actualizadas correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editar Tallas: ${widget.product.codigo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del producto (solo visual)
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.product.imagen.isNotEmpty
                              ? Image.memory(
                            base64Decode(widget.product.imagen),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultIcon();
                            },
                          )
                              : _buildDefaultIcon(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Información del producto (solo lectura)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Código', widget.product.codigo),
                          const Divider(),
                          _buildInfoRow('Categoría', widget.product.categoria),
                          const Divider(),
                          _buildInfoRow('Color', widget.product.color),
                          const Divider(),
                          _buildInfoRow('Precio', '\$${widget.product.precio.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tallas disponibles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tallas y Stock',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addNewSize,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Agregar Talla'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid de tallas
                    _tallas.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No hay tallas registradas',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tallas.keys.length,
                      itemBuilder: (context, index) {
                        final talla = _tallas.keys.elementAt(index);
                        final stock = _tallas[talla]!;
                        return _buildSizeCard(talla, stock);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Resumen de stock total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stock Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_tallas.values.fold(0, (sum, stock) => sum + stock)} unidades',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveChanges,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeCard(String talla, int stock) {
    final stockController = TextEditingController(text: stock.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Talla $talla',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final newStock = int.tryParse(value) ?? 0;
                  _updateTalla(talla, newStock);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _updateTalla(talla, 0);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.shopping_bag, size: 60, color: Colors.grey),
    );
  }
}