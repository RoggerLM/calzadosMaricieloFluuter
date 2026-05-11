import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/departamento_dropdown.dart';
import '../widgets/provincia_dropdown.dart';
import 'package:flutter/services.dart';
// ══════════════════════════════════════════════════════════════════
// MODELO LOCAL — solo para esta pantalla
// ══════════════════════════════════════════════════════════════════
class _ItemPedido {
  final String codigo;
  final String color;
  final String talla;
  int cantidad;

  _ItemPedido({
    required this.codigo,
    required this.color,
    required this.talla,
    this.cantidad = 1,
  });

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'color': color,
    'talla': talla,
    'cantidad': cantidad,
  };
}

class _Promo {
  String tipo; // "Promo 3x120"
  List<_ItemPedido> items;

  _Promo({required this.tipo, List<_ItemPedido>? items})
      : items = items ?? [];

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

// ══════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════════════════
class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // ── Datos cliente ─────────────────────────────────────────
  final _nombreCtrl      = TextEditingController();
  final _dniCtrl         = TextEditingController();
  final _celularCtrl     = TextEditingController();
  // Cambiar de TextEditingController a variables String
  String? _selectedDepartamento;
  String? _selectedProvincia;
  // Opcional: controlador para provincia si quieres mantener TextEditingController
  final _provinciaCtrl = TextEditingController();
  final _oficinaCtrl     = TextEditingController();
  final _clienteFormKey  = GlobalKey<FormState>();
  final _whastAppCtrl   = TextEditingController();
  // ── Productos y promos ────────────────────────────────────
  final List<_ItemPedido> _productos = [];
  final List<_Promo>      _promos    = [];

  // ── Búsqueda de producto ──────────────────────────────────
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  bool   _buscando        = false;
  String _queryBusqueda   = '';
  final  _busquedaCtrl    = TextEditingController();

  bool _guardando = false;

  // ── Totales ───────────────────────────────────────────────
  int get _totalProductos {
    final p = _productos.fold(0, (s, i) => s + i.cantidad);
    final pr = _promos.fold(0, (s, promo) =>
    s + promo.items.fold(0, (s2, i) => s2 + i.cantidad));
    return p + pr;
  }

  // El precio de productos normales viene del backend al crear
  // Aquí solo calculamos el total de promos para el resumen
  int get _totalPromos {
    int total = 0;
    for (final p in _promos) {
      final match = RegExp(r'\d+x(\d+)').firstMatch(p.tipo);
      if (match != null) total += int.tryParse(match.group(1)!) ?? 0;
    }
    return total;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _celularCtrl.dispose();
    //_departamentoCtrl.dispose();
    _provinciaCtrl.dispose();
    _oficinaCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.blue.shade400,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Indicador de pasos ──────────────────────────
          _buildStepIndicator(),

          // ── Contenido ───────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPaso1Cliente(),
                _buildPaso2Productos(),
                _buildPaso3Promos(),
                _buildPaso4Resumen(),
              ],
            ),
          ),

          // ── Botones navegación ──────────────────────────
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // INDICADOR DE PASOS
  // ══════════════════════════════════════════════════════════
  Widget _buildStepIndicator() {
    final pasos = ['Cliente', 'Productos', 'Promos', 'Resumen'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: pasos.asMap().entries.map((e) {
          final i       = e.key;
          final label   = e.value;
          final activo  = i == _currentStep;
          final listo   = i < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: listo
                              ? Colors.green
                              : activo
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: listo
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text('${i + 1}',
                              style: TextStyle(
                                color: activo ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              )),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10,
                            color: activo
                                ? Colors.blue.shade700
                                : Colors.grey.shade500,
                            fontWeight: activo
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
                if (i < pasos.length - 1)
                  Container(
                    width: 20, height: 1,
                    color: listo ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PASO 1 — DATOS DEL CLIENTE
  // ══════════════════════════════════════════════════════════
  Widget _buildPaso1Cliente() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _clienteFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('👤 Datos del Cliente'),
            const SizedBox(height: 16),
            _campo(_nombreCtrl,      'Nombre completo',  Icons.person,       requerido: true,formatters: [LengthLimitingTextInputFormatter(100),],),
            _campo(_dniCtrl,         'DNI',              Icons.badge,         requerido: true, tipo: TextInputType.number ,formatters: [LengthLimitingTextInputFormatter(8),],),
            _campo(_celularCtrl,     'Celular',          Icons.phone,         requerido: true, tipo: TextInputType.phone,formatters: [LengthLimitingTextInputFormatter(9),],),
            _campo(_whastAppCtrl,    'WhastApp',         Icons.phone_android,requerido:true, tipo: TextInputType.phone,formatters: [LengthLimitingTextInputFormatter(9),],),
            //_campo(_departamentoCtrl,'Departamento',     Icons.map,           requerido: true),
            // Dropdown de Departamento
            DepartamentoDropdown(
              value: _selectedDepartamento,
              onChanged: (value) {
                setState(() {
                  _selectedDepartamento = value;
                  _selectedProvincia = null; // Resetear provincia cuando cambia departamento
                  _provinciaCtrl.clear();
                });
              },
              requerido: true,
            ),
            const SizedBox(height: 14),

            // Dropdown de Provincia (opcional, basado en departamento)
            if (_selectedDepartamento != null) ...[
              ProvinciaDropdown(
                departamento: _selectedDepartamento,
                value: _selectedProvincia,
                onChanged: (value) {
                  setState(() {
                    _selectedProvincia = value;
                    _provinciaCtrl.text = value ?? '';
                  });
                },
                requerido: true,
              ),
              const SizedBox(height: 14),
            ],
            //_campo(_provinciaCtrl,   'Provincia',        Icons.location_city, requerido: true),
            _campo(_oficinaCtrl,     'Oficina de envío', Icons.business,      requerido: true,formatters: [LengthLimitingTextInputFormatter(50),],),
          ],
        ),
      ),
    );
  }

  Widget _campo(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool requerido = false,
        TextInputType tipo = TextInputType.text, required List<LengthLimitingTextInputFormatter> formatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: requerido
            ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
            : null,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PASO 2 — PRODUCTOS
  // ══════════════════════════════════════════════════════════
  Widget _buildPaso2Productos() {
    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('📦 Productos'),
              const SizedBox(height: 12),
              TextField(
                controller: _busquedaCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por código...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscando
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _buscarProducto,
              ),

              // Resultados de búsqueda
              if (_resultadosBusqueda.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    children: _resultadosBusqueda.map((p) {
                      final tallas = Map<String, int>.from(p['tallas'] ?? {});
                      return ListTile(
                        leading: const Icon(Icons.inventory_2,
                            color: Colors.blue),
                        title: Text('${p['codigo']} — ${p['color']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          tallas.entries
                              .where((e) => e.value > 0)
                              .map((e) => 'T${e.key}:${e.value}')
                              .join('  '),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _mostrarSelectorTalla(p),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),

        // Lista de productos agregados
        Expanded(
          child: _productos.isEmpty
              ? _emptyState('Agrega productos buscando\npor código arriba',
              Icons.search)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _productos.length,
            itemBuilder: (_, i) => _buildItemProducto(_productos[i], i),
          ),
        ),
      ],
    );
  }

  void _buscarProducto(String query) async {
    _queryBusqueda = query;

    if (query.trim().isEmpty || query.length < 2) {
      setState(() { _resultadosBusqueda = []; _buscando = false; });
      return;
    }

    setState(() => _buscando = true);

    try {
      final filtrados = await ApiService.buscarProductos(query.trim());
      if (!mounted || _queryBusqueda != query) return;
      setState(() { _resultadosBusqueda = filtrados; _buscando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscando = false);
    }
  }
  void _mostrarSelectorTalla(Map<String, dynamic> producto) {
    final tallas = Map<String, int>.from(producto['tallas'] ?? {});
    final tallasConStock =
    tallas.entries.where((e) => e.value > 0).toList();

    if (tallasConStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto no tiene stock disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? tallaSeleccionada;
    int cantidad = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${producto['codigo']} — ${producto['color']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Selector de talla
              const Text('Selecciona talla:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: tallasConStock.map((e) {
                  final sel = tallaSeleccionada == e.key;
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => tallaSeleccionada = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.blue.shade700
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('T${e.key}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : Colors.black87,
                              )),
                          Text('Stock: ${e.value}',
                              style: TextStyle(
                                fontSize: 10,
                                color: sel
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Cantidad
              const Text('Cantidad:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: cantidad > 1
                        ? () => setModalState(() => cantidad--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.blue.shade700,
                  ),
                  Text('$cantidad',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      final maxStock = tallaSeleccionada != null
                          ? (tallas[tallaSeleccionada] ?? 1)
                          : 99;
                      if (cantidad < maxStock) {
                        setModalState(() => cantidad++);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.blue.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: tallaSeleccionada == null
                      ? null
                      : () {
                    setState(() {
                      _productos.add(_ItemPedido(
                        codigo:   producto['codigo'] ?? '',
                        color:    producto['color']  ?? '',
                        talla:    tallaSeleccionada!,
                        cantidad: cantidad,
                      ));
                      _resultadosBusqueda = [];
                      _busquedaCtrl.clear();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Agregar al pedido',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemProducto(_ItemPedido item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(item.talla,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.codigo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(item.color,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            // Cantidad
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: item.cantidad > 1
                      ? () => setState(() => item.cantidad--)
                      : null,
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('×${item.cantidad}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => setState(() => item.cantidad++),
                  color: Colors.blue.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => setState(() => _productos.removeAt(index)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PASO 3 — PROMOS
  // ══════════════════════════════════════════════════════════
  Widget _buildPaso3Promos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('🎯 Promociones'),
              ElevatedButton.icon(
                onPressed: _agregarPromo,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar promo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _promos.isEmpty
              ? _emptyState(
              'Sin promociones.\nPuedes continuar sin ellas.',
              Icons.local_offer_outlined)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promos.length,
            itemBuilder: (_, i) =>
                _buildPromoCard(_promos[i], i),
          ),
        ),
      ],
    );
  }

  void _agregarPromo() {
    final tipoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nueva Promoción',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Ej: Promo 3x120, Promo 6x200',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: tipoCtrl,
              decoration: InputDecoration(
                labelText: 'Tipo de promo',
                hintText: 'Promo 3x120',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.local_offer),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (tipoCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _promos.add(_Promo(tipo: tipoCtrl.text.trim()));
                  });
                  Navigator.pop(ctx);
                  // Abrir editor de items de la promo recién creada
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _editarItemsPromo(_promos.last, _promos.length - 1);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Crear y agregar productos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(_Promo promo, int promoIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header promo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(promo.tipo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      )),
                ),
                Text('${promo.items.length} producto(s)',
                    style: TextStyle(
                        color: Colors.purple.shade400, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editarItemsPromo(promo, promoIndex),
                  color: Colors.purple.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () =>
                      setState(() => _promos.removeAt(promoIndex)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Items de la promo
          if (promo.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: promo.items
                    .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right,
                          size: 16, color: Colors.grey),
                      Text(
                        '${item.codigo} · ${item.color} · T${item.talla} · ×${item.cantidad}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _editarItemsPromo(_Promo promo, int promoIndex) {
    final busquedaPromoCtrl = TextEditingController();
    List<Map<String, dynamic>> resultados = [];
    bool buscandoPromo = false;
    String _queryPromo = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(promo.tipo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // ── Buscador ────────────────────────────────
                TextField(
                  controller: busquedaPromoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto por código...',
                    prefixIcon: const Icon(Icons.search),
                    // 👇 loading visible en el sufijo
                    suffixIcon: buscandoPromo
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (q) async {
                    _queryPromo = q;

                    // Vacío o muy corto → limpia resultados
                    if (q.trim().isEmpty || q.length < 2) {
                      setModal(() {
                        resultados    = [];
                        buscandoPromo = false;
                      });
                      return;
                    }

                    setModal(() => buscandoPromo = true);

                    try {
                      final f = await ApiService.buscarProductos(q.trim());
                      if (_queryPromo != q) return;
                      setModal(() { resultados = f; buscandoPromo = false; });
                    } catch (_) {
                      setModal(() => buscandoPromo = false);
                    }
                  },
                ),

                // ── Resultados ──────────────────────────────
                if (resultados.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: resultados.map((p) {
                        final tallas = Map<String, int>.from(p['tallas'] ?? {});
                        return ListTile(
                          dense: true,
                          title: Text('${p['codigo']} — ${p['color']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            tallas.entries
                                .where((e) => e.value > 0)
                                .map((e) => 'T${e.key}:${e.value}')
                                .join('  '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            setModal(() => resultados = []);
                            busquedaPromoCtrl.clear();
                            _queryPromo = '';
                            _mostrarSelectorTallaPromo(p, promo, promoIndex, setModal);
                          },
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Items de la promo ───────────────────────
                Expanded(
                  child: promo.items.isEmpty
                      ? Center(
                    child: Text(
                      'Sin productos aún.\nBusca arriba para agregar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                      : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: promo.items.length,
                    itemBuilder: (_, i) {
                      final item = promo.items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade50,
                          child: Text(item.talla,
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              )),
                        ),
                        title: Text('${item.codigo} · ${item.color}'),
                        subtitle: Text('×${item.cantidad}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => setModal(() {
                            setState(() => promo.items.removeAt(i));
                          }),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Listo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _mostrarSelectorTallaPromo(
      Map<String, dynamic> producto,
      _Promo promo,
      int promoIndex,
      StateSetter setModal,
      ) {
    final tallas = Map<String, int>.from(producto['tallas'] ?? {});
    final tallasConStock =
    tallas.entries.where((e) => e.value > 0).toList();
    if (tallasConStock.isEmpty) return;

    String? tallaSeleccionada;
    int cantidad = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('${producto['codigo']} — ${producto['color']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Talla:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: tallasConStock.map((e) {
                  final sel = tallaSeleccionada == e.key;
                  return GestureDetector(
                    onTap: () => setDlg(() => tallaSeleccionada = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.blue.shade700
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('T${e.key}',
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Cantidad:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(
                    onPressed: cantidad > 1
                        ? () => setDlg(() => cantidad--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$cantidad',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setDlg(() => cantidad++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: tallaSeleccionada == null
                  ? null
                  : () {
                setState(() {
                  promo.items.add(_ItemPedido(
                    codigo:   producto['codigo'] ?? '',
                    color:    producto['color']  ?? '',
                    talla:    tallaSeleccionada!,
                    cantidad: cantidad,
                  ));
                });
                setModal(() {});
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PASO 4 — RESUMEN
  // ══════════════════════════════════════════════════════════
  Widget _buildPaso4Resumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📋 Resumen del Pedido'),
          const SizedBox(height: 16),
          _resumenCard(
            titulo: '👤 Datos',
            color: Colors.blue,
            children: [
              _resumenFila('WhastApp', _whastAppCtrl.text),
            ],
          ),
          const SizedBox(height: 16),
          // Cliente
          _resumenCard(
            titulo: '👤 Datos de Envio',
            color: Colors.blue,
            children: [
              _resumenFila('Nombre', _nombreCtrl.text),
              _resumenFila('DNI', _dniCtrl.text),
              _resumenFila('Celular', _celularCtrl.text),
              _resumenFila('Departamento', _selectedDepartamento ?? 'No seleccionado'),
              _resumenFila('Provincia', _selectedProvincia ?? 'No seleccionado'),
              _resumenFila('Oficina', _oficinaCtrl.text),
            ],
          ),
          const SizedBox(height: 12),

          // Productos
          if (_productos.isNotEmpty)
            _resumenCard(
              titulo: '📦 Productos (${_productos.length})',
              color: Colors.green,
              children: _productos
                  .map((p) => _resumenFila(
                '${p.codigo} · ${p.color} · T${p.talla}',
                '×${p.cantidad}',
              ))
                  .toList(),
            ),

          if (_productos.isNotEmpty) const SizedBox(height: 12),

          // Promos
          if (_promos.isNotEmpty)
            _resumenCard(
              titulo: '🎯 Promociones (${_promos.length})',
              color: Colors.purple,
              children: _promos
                  .map((promo) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo.tipo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      )),
                  ...promo.items.map((i) => Padding(
                    padding: const EdgeInsets.only(
                        left: 12, top: 2),
                    child: Text(
                      '· ${i.codigo} · T${i.talla} · ×${i.cantidad}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              ))
                  .toList(),
            ),

          if (_promos.isNotEmpty) const SizedBox(height: 12),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total productos',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                Text('$_totalProductos pares',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _guardando ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: _guardando
                  ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 22),
                  SizedBox(width: 10),
                  Text('Confirmar Pedido',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenCard({
    required String titulo,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              )),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _resumenFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          Text(valor,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CONFIRMAR PEDIDO
  // ══════════════════════════════════════════════════════════
  Future<void> _confirmarPedido() async {
    // Validar que se haya seleccionado un departamento
    if (_selectedDepartamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un departamento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedProvincia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una provincia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_productos.isEmpty && _promos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto o promo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final body = {
        'cliente': {
          'nombre':      _nombreCtrl.text.trim(),
          'dni':         _dniCtrl.text.trim(),
          'celular':     _celularCtrl.text.trim(),
          'departamento':_selectedDepartamento,
          'provincia':   _selectedProvincia,
          'oficina':     _oficinaCtrl.text.trim(),
        },
        'whastApp': _whastAppCtrl.text.trim(),
        'productos': _productos.map((p) => p.toJson()).toList(),
        'promos':    _promos.map((p) => p.toJson()).toList(),
      };

      final resultado = await ApiService.crearPedido(body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Pedido creado — Total: S/${resultado['total'] ?? 0}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // true = recargar lista de pedidos
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  // NAVEGACIÓN ENTRE PASOS
  // ══════════════════════════════════════════════════════════
  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _retroceder,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Atrás'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          if (_currentStep < 3)
            Expanded(
              child: ElevatedButton(
                onPressed: _avanzar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentStep == 2 ? 'Ver resumen' : 'Siguiente',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _avanzar() {
    if (_currentStep == 0) {
      if (!_clienteFormKey.currentState!.validate()) return;
    }
    if (_currentStep == 1 && _productos.isEmpty && _promos.isEmpty) {
      // Puede avanzar aunque no haya productos aún (los pone en promos)
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _retroceder() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS UI
  // ══════════════════════════════════════════════════════════
  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _emptyState(String mensaje, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}