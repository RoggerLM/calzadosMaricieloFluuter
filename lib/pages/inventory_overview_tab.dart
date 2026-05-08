import 'package:flutter/material.dart';

import '../services/api_service.dart';

class InventoryOverviewTab extends StatefulWidget {
  const InventoryOverviewTab({super.key});

  @override
  State<InventoryOverviewTab> createState() => _InventoryOverviewTabState();
}

class _InventoryOverviewTabState extends State<InventoryOverviewTab> {
  // Cada sección tiene su propio Future — si una falla, las otras siguen funcionando
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _alertasFuture;
  late Future<List<Map<String, dynamic>>> _masVendidosFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAlertas();
    _loadMasVendidos();
  }

  // ── Cargas individuales — cada una puede reintentarse sola ──
  void _loadStats()       => setState(() { _statsFuture       = ApiService.getDashboardStats(); });
  void _loadAlertas()     => setState(() { _alertasFuture     = ApiService.getDashboardAlertas(); });
  void _loadMasVendidos() => setState(() { _masVendidosFuture = ApiService.getMasVendidos(limit: 5); });

  // Pull-to-refresh: lanza las 3 en paralelo, cada una maneja su propio error
  Future<void> _refreshAll() async {
    _loadStats();
    _loadAlertas();
    _loadMasVendidos();
    await Future.wait([
      _statsFuture.catchError((_) => <String, dynamic>{}),
      _alertasFuture.catchError((_) => <Map<String, dynamic>>[]),
      _masVendidosFuture.catchError((_) => <Map<String, dynamic>>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildAlertasSection(),
            const SizedBox(height: 20),
            _buildMasVendidosSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATS RÁPIDOS
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final error   = snapshot.hasError;

        final total     = snapshot.data?['total_productos'];
        final sinStock  = snapshot.data?['sin_stock'];
        final stockBajo = snapshot.data?['stock_bajo'];

        return Row(
          children: [
            Expanded(child: _buildStatCard('Productos',  loading ? null : (error ? '!' : '$total'),     Icons.inventory_2_outlined, Colors.blue,   onRetry: error ? _loadStats : null)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Stock bajo', loading ? null : (error ? '!' : '$stockBajo'), Icons.warning_amber_outlined, Colors.orange, onRetry: error ? _loadStats : null)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Sin stock',  loading ? null : (error ? '!' : '$sinStock'),  Icons.error_outline,         Colors.red,    onRetry: error ? _loadStats : null)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String? value, IconData icon, Color color, {VoidCallback? onRetry}) {
    final isError = value == '!';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isError ? onRetry : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(isError ? Icons.refresh : icon, color: isError ? Colors.grey : color, size: 22),
              const SizedBox(height: 6),
              value == null
                  ? SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
                  : Text(
                isError ? 'Tap' : value,
                style: TextStyle(
                  fontSize: isError ? 12 : 20,
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.grey : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isError ? 'Reintentar' : title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ALERTAS DE STOCK
  // ═══════════════════════════════════════════════════════════

  Widget _buildAlertasSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _alertasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionShell(titulo: 'Alertas de Stock', icono: Icons.warning, color: Colors.red, child: _loadingWidget());
        }
        if (snapshot.hasError) {
          return _sectionShell(
            titulo: 'Alertas de Stock', icono: Icons.warning, color: Colors.red,
            child: _errorWidget(snapshot.error.toString(), onRetry: _loadAlertas),
          );
        }

        final alertas = snapshot.data ?? [];

        if (alertas.isEmpty) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Text('Todo en orden — sin alertas de stock',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        final sinStockCount  = alertas.where((p) => (p['alertas'] as List).any((a) => a['tipo'] == 'sin_stock')).length;
        final stockBajoCount = alertas.where((p) => (p['alertas'] as List).any((a) => a['tipo'] == 'stock_bajo')).length;

        return _sectionShell(
          titulo: 'Alertas de Stock (${alertas.length})',
          icono: Icons.warning,
          color: Colors.red,
          subtitulo: _buildAlertaSubtitulo(sinStockCount, stockBajoCount),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: alertas.map((p) => _buildAlertaChip(p)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAlertaSubtitulo(int sinStock, int stockBajo) {
    return Row(
      children: [
        if (sinStock > 0) ...[_badge('$sinStock sin stock', Colors.red), const SizedBox(width: 6)],
        if (stockBajo > 0) _badge('$stockBajo stock bajo', Colors.orange),
      ],
    );
  }

  Widget _badge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(texto, style: TextStyle(fontSize: 11, color:  Colors.red.shade700, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAlertaChip(Map<String, dynamic> producto) {
    final alertas  = List<Map<String, dynamic>>.from(producto['alertas']);
    final tieneSin = alertas.any((a) => a['tipo'] == 'sin_stock');
    final color    = tieneSin ? Colors.red : Colors.orange;
    final codigo   = producto['codigo'] ?? '';
    final colorPrd = producto['color']  ?? '';

    return GestureDetector(
      onTap: () => _showDetalleAlerta(producto),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tieneSin ? Icons.error : Icons.warning_amber, color: color, size: 14),
            const SizedBox(width: 5),
            Text('$codigo · $colorPrd',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('${alertas.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetalleAlerta(Map<String, dynamic> producto) {
    final alertas  = List<Map<String, dynamic>>.from(producto['alertas']);
    final codigo   = producto['codigo'] ?? '';
    final colorPrd = producto['color']  ?? '';
    final imagen   = producto['imagen'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                if (imagen != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imagen, width: 52, height: 52, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagenFallback()),
                  ),
                  const SizedBox(width: 12),
                ],
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(codigo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(colorPrd, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Tallas con alerta',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            ...alertas.map((alerta) {
              final esSinStock = alerta['tipo'] == 'sin_stock';
              final color = esSinStock ? Colors.red : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(esSinStock ? Icons.error_outline : Icons.warning_amber, color: color, size: 18),
                    const SizedBox(width: 10),
                    Text('Talla ${alerta['talla']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(
                      esSinStock ? 'Sin stock' : 'Stock bajo: ${alerta['stock']}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MÁS VENDIDOS
  // ═══════════════════════════════════════════════════════════

  Widget _buildMasVendidosSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _masVendidosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionShell(titulo: 'Más Vendidos', icono: Icons.trending_up, color: Colors.green, child: _loadingWidget());
        }
        if (snapshot.hasError) {
          return _sectionShell(
            titulo: 'Más Vendidos', icono: Icons.trending_up, color: Colors.green,
            child: _errorWidget(snapshot.error.toString(), onRetry: _loadMasVendidos),
          );
        }

        final vendidos = snapshot.data ?? [];

        if (vendidos.isEmpty) {
          return _sectionShell(
            titulo: 'Más Vendidos', icono: Icons.trending_up, color: Colors.green,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Aún no hay datos de ventas',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),
          );
        }

        return _sectionShell(
          titulo: 'Más Vendidos', icono: Icons.trending_up, color: Colors.green,
          child: Column(
            children: vendidos.asMap().entries.map((e) => _buildVendidoItem(e.key + 1, e.value)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildVendidoItem(int rank, Map<String, dynamic> product) {
    final codigo = product['codigo'] ?? '';
    final color  = product['color']  ?? '';
    final ventas = product['ventas'] ?? 0;
    final imagen = product['imagen'];

    final rankColors = [Colors.amber.shade600, Colors.grey.shade500, Colors.brown.shade400];
    final rankColor  = rank <= 3 ? rankColors[rank - 1] : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15), shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Center(child: Text('$rank',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rankColor))),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imagen != null
                ? Image.network(imagen, width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagenFallback(size: 40))
                : _imagenFallback(size: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(color, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text('$ventas ventas',
                style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionShell({
    required String titulo,
    required IconData icono,
    required Color color,
    required Widget child,
    Widget? subtitulo,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Text(titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            if (subtitulo != null) ...[const SizedBox(height: 6), subtitulo],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _loadingWidget() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _errorWidget(String msg, {required VoidCallback onRetry}) {
    final texto = msg.replaceAll('Exception: ', '').replaceAll('TimeoutException after', 'Timeout:');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ],
      ),
    );
  }

  Widget _imagenFallback({double size = 52}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: size * 0.5),
    );
  }
}