import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:calzados_luciana/models/product_model.dart';
import 'package:calzados_luciana/services/api_service.dart';

class UpdateProductoDialog extends StatefulWidget {
  final Product product;
  final Function(Product) onProductUpdated;

  const UpdateProductoDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<UpdateProductoDialog> createState() => _UpdateProductoDialogState();
}

class _UpdateProductoDialogState extends State<UpdateProductoDialog> {
  // Modo: 'estandar', 'personalizado', 'manual'
  String _modo = 'estandar';

  // Talla repetida en modo personalizado (por defecto 37)
  String _tallaRepetida = '37';

  // Stock a SUMAR por talla en modo manual
  late Map<String, int> _sumar;

  bool _isLoading = false;

  // Media docena estándar: 35×1 36×1 37×2 38×1 39×1
  static const Map<String, int> _estandar = {
    '35': 1, '36': 1, '37': 2, '38': 1, '39': 1,
  };

  final List<String> _tallasDisponibles = ['35','36','37','38','39','40'];

  @override
  void initState() {
    super.initState();
    // Iniciar sumar en 0 para todas las tallas del producto
    _sumar = { for (var t in _tallasDisponibles) t: 0 };
  }

  // Calcula la distribución según el modo activo
  Map<String, int> get _distribucion {
    switch (_modo) {
      case 'estandar':
        return Map.from(_estandar);
      case 'personalizado':
      // Igual al estándar pero la talla seleccionada lleva 2
        final dist = { for (var t in _tallasDisponibles.take(5).toList()) t: 1 };
        dist[_tallaRepetida] = 2;
        // Asegurarse que suma 6
        return dist;
      case 'manual':
        return Map.from(_sumar);
      default:
        return {};
    }
  }

  int get _totalSumar =>
      _distribucion.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 👈
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 600,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductoInfo(),
                    const SizedBox(height: 20),
                    _buildModoSelector(),
                    const SizedBox(height: 20),
                    _buildContenidoModo(),
                    const SizedBox(height: 16),
                    _buildResumen(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.codigo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.product.color,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Info del producto ─────────────────────────────────────
  Widget _buildProductoInfo() {
    return Row(
      children: [
        // Imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 70, height: 70,
            color: Colors.grey.shade200,
            child: widget.product.imagen != null &&
                widget.product.imagen!.isNotEmpty
                ? (widget.product.imagen!.startsWith('http')
                ? Image.network(widget.product.imagen!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.shopping_bag, color: Colors.grey))
                : Image.memory(base64Decode(widget.product.imagen!),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.shopping_bag, color: Colors.grey)))
                : const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 14),
        // Stock actual por talla
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock actual',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: widget.product.tallas.entries.map((e) {
                  final sinStock = e.value == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sinStock
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sinStock
                            ? Colors.red.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sinStock
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Selector de modo ──────────────────────────────────────
  Widget _buildModoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de reposición',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            _modoChip('estandar',   '📦 Estándar'),
            const SizedBox(width: 6),
            _modoChip('personalizado', '✏️ Personalizado'),
            const SizedBox(width: 6),
            _modoChip('manual',     '🔢 Manual'),
          ],
        ),
      ],
    );
  }

  Widget _modoChip(String modo, String label) {
    final selected = _modo == modo;
    return GestureDetector(
      onTap: () => setState(() => _modo = modo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── Contenido según modo ──────────────────────────────────
  Widget _buildContenidoModo() {
    switch (_modo) {
      case 'estandar':
        return _buildModoEstandar();
      case 'personalizado':
        return _buildModoPersonalizado();
      case 'manual':
        return _buildModoManual();
      default:
        return const SizedBox();
    }
  }

  // Modo estándar: solo muestra la distribución fija
  Widget _buildModoEstandar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Media docena estándar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _estandar.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'T${e.key}  ',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      TextSpan(
                        text: '+${e.value}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Modo personalizado: elige qué talla se repite (lleva ×2)
  Widget _buildModoPersonalizado() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text('¿Qué talla se repite?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Las demás llevan ×1',
              style:
              TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _tallasDisponibles.take(5).map((talla) {
              final selected = _tallaRepetida == talla;
              return GestureDetector(
                onTap: () => setState(() => _tallaRepetida = talla),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.orange.shade600
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.orange.shade600
                          : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(talla,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                          )),
                      Text(selected ? '×2' : '×1',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white.withOpacity(0.9)
                                : Colors.grey.shade500,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Preview de la distribución resultante
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _distribucion.entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: e.key == _tallaRepetida
                    ? Colors.orange.shade100
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: e.key == _tallaRepetida
                      ? Colors.orange.shade400
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                'T${e.key} +${e.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: e.key == _tallaRepetida
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: e.key == _tallaRepetida
                      ? Colors.orange.shade800
                      : Colors.grey.shade700,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Modo manual: controles +/- por talla
  Widget _buildModoManual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingresa cuánto sumar por talla',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        ..._tallasDisponibles.map((talla) {
          final sumar = _sumar[talla] ?? 0;
          final actual = widget.product.tallas[talla] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              children: [
                // Talla + stock actual
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Talla $talla',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('Actual: $actual',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // Controles +/-
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.grey.shade600,
                  onPressed: sumar > 0
                      ? () => setState(() => _sumar[talla] = sumar - 1)
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '+$sumar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: sumar > 0
                          ? Colors.blue.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.blue.shade600,
                  onPressed: () =>
                      setState(() => _sumar[talla] = sumar + 1),
                ),
                // Nuevo total
                SizedBox(
                  width: 40,
                  child: Text(
                    '= ${actual + sumar}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ── Resumen ───────────────────────────────────────────────
  Widget _buildResumen() {
    if (_totalSumar == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle, color: Colors.green.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Se agregarán $_totalSumar pares al stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: (_isLoading || _totalSumar == 0) ? null : _guardar,
            icon: _isLoading
                ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.save),
            label: Text(_isLoading
                ? 'Guardando...'
                : 'Agregar $_totalSumar pares'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Guardar ───────────────────────────────────────────────
  Future<void> _guardar() async {
    setState(() => _isLoading = true);

    try {
      final dist = _distribucion;

      // Filtrar solo tallas con cantidad > 0
      final tallasASumar = Map<String, int>.fromEntries(
        dist.entries.where((e) => e.value > 0),
      );

      await ApiService.reponerStock(
        productoId: widget.product.id!,
        tallas: tallasASumar,
      );

      if (!mounted) return;

      // Construir producto actualizado localmente
      final nuevasTallas = Map<String, int>.from(widget.product.tallas);
      tallasASumar.forEach((talla, cantidad) {
        nuevasTallas[talla] = (nuevasTallas[talla] ?? 0) + cantidad;
      });

      final updatedProduct = Product(
        id:          widget.product.id,
        codigo:      widget.product.codigo,
        color:       widget.product.color,
        precio:      widget.product.precio,
        categoria:   widget.product.categoria,
        tallas:       nuevasTallas,
        imagen:      widget.product.imagen,
        stockMinimo: widget.product.stockMinimo,
        createdAt:   widget.product.createdAt,
      );

      widget.onProductUpdated(updatedProduct);

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $_totalSumar pares agregados al stock'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}