// sessions_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calzados_luciana/services/firestore_service.dart';
import 'package:calzados_luciana/models/order_model.dart';
/*
class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  //State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: StreamBuilder<List<Pedido>>(
        stream: firestoreService.getSessions(), // Pedidos no confirmados
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sessions = snapshot.data ?? [];

          return Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(),

              // Resumen de sesiones
              _buildSessionsSummary(sessions),

              // Lista de sesiones
              Expanded(
                child: _buildSessionsList(sessions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar sesiones por teléfono o nombre...',
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
    );
  }

  Widget _buildSessionsSummary(List<Pedido> sessions) {
    final totalSessions = sessions.length;
    final sessionsWithProducts = sessions.where((s) => s.productos.isNotEmpty).length;
    final sessionsWithoutProducts = sessions.where((s) => s.productos.isEmpty).length;
    final urgentSessions = sessions.where((s) => s.isUrgente).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSessionStat('Total', totalSessions.toString(), Colors.blue),
          _buildSessionStat('Con Productos', sessionsWithProducts.toString(), Colors.green),
          _buildSessionStat('Sin Productos', sessionsWithoutProducts.toString(), Colors.orange),
          _buildSessionStat('Urgentes', urgentSessions.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String label, String value, Color color) {
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

  List<Pedido> _getFilteredSessions(List<Pedido> sessions) {
    if (_searchQuery.isEmpty) {
      return sessions;
    }

    return sessions.where((session) {
      final phone = session.numero.toLowerCase();
      final name = session.clienteNombre.toLowerCase();
      final query = _searchQuery.toLowerCase();

      return phone.contains(query) || name.contains(query);
    }).toList();
  }

  Widget _buildSessionsList(List<Pedido> sessions) {
    final filteredSessions = _getFilteredSessions(sessions);

    if (filteredSessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron sesiones activas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return _buildSessionItem(session);
      },
    );
  }

  Widget _buildSessionItem(Pedido session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showSessionDetails(session);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de estado de la sesión
              _buildSessionStatusIcon(session),

              const SizedBox(width: 12),

              // Información de la sesión
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente y teléfono
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.clienteNombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          session.numero,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Productos en el carrito
                    Text(
                      _getProductsSummary(session),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Tiempo transcurrido
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeElapsed(session.timestamp.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Barra de progreso de tiempo
                    if (session.isUrgente)
                      _buildTimeProgressBar(session),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Indicadores
              Column(
                children: [
                  // Indicador de urgencia
                  if (session.isUrgente)
                    _buildUrgentIndicator(),

                  const SizedBox(height: 4),

                  // Contador de productos
                  _buildProductCount(session),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatusIcon(Pedido session) {
    Color color;
    IconData icon;

    if (session.productos.isEmpty) {
      color = Colors.grey;
      icon = Icons.shopping_cart_outlined;
    } else if (session.isUrgente) {
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      color = Colors.blue;
      icon = Icons.shopping_cart;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildUrgentIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Text(
        'URGENTE',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductCount(Pedido session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '${session.cantidadTotal}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeProgressBar(Pedido session) {
    final now = DateTime.now();
    final sessionDate = session.timestamp.toDate();
    final difference = now.difference(sessionDate);
    final days = difference.inDays;

    // Calcula el progreso (máximo 7 días para ser urgente)
    double progress = days / 7.0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.red : Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$days días transcurridos',
          style: TextStyle(
            fontSize: 10,
            color: progress >= 1.0 ? Colors.red : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getProductsSummary(Pedido session) {
    if (session.productos.isEmpty) {
      return 'Carrito vacío';
    }

    final productCount = session.cantidadTotal;
    final totalPrice = session.total;

    return '$productCount productos - Total: \$${totalPrice.toStringAsFixed(2)}';
  }

  String _getTimeElapsed(DateTime startTime) {
    final now = DateTime.now();
    final difference = now.difference(startTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Recién iniciada';
    }
  }

  void _showSessionDetails(Pedido session) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _buildSessionStatusIcon(session),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesión de ${session.clienteNombre}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeElapsed(session.timestamp.toDate()),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.isUrgente)
                      _buildUrgentIndicator(),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Información del cliente
                _buildInfoSection(
                  'Información del Cliente',
                  [
                    _buildInfoRow('Nombre', session.clienteNombre),
                    _buildInfoRow('Teléfono', session.numero),
                    _buildInfoRow('Departamento', session.clienteDepartamento),
                    _buildInfoRow('Provincia', session.clienteProvincia),
                  ],
                ),

                const SizedBox(height: 16),

                // Productos en el carrito
                _buildInfoSection(
                  'Productos en Carrito (${session.cantidadTotal})',
                  session.productos.isNotEmpty
                      ? [
                    ...session.productos.map((producto) => _buildProductItem(producto)),
                  ]
                      : [
                    const Center(
                      child: Text(
                        'No hay productos en el carrito',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Resumen
                if (session.productos.isNotEmpty)
                  _buildInfoSection(
                    'Resumen',
                    [
                      _buildInfoRow('Subtotal', '\$${session.total.toStringAsFixed(2)}'),
                      _buildInfoRow('Total', '\$${session.total.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    if (session.productos.isNotEmpty)
                      ElevatedButton(
                        onPressed: () => _convertToOrder(session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Convertir a Pedido'),
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

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
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
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> producto) {
    final talla = producto['talla']?.toString() ?? 'N/A';
    final color = producto['color']?.toString() ?? 'N/A';
    final cantidad = _safeToInt(producto['cantidad']);
    final imagen = producto['imagen']?.toString();
    final precio = _safeToDouble(producto['precio']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Imagen del producto
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: imagen != null && imagen.isNotEmpty
                ? Image.network(
              imagen,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shopping_bag, size: 20);
              },
            )
                : const Icon(Icons.shopping_bag, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talla $talla - $color',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Cantidad: $cantidad - Precio: \$${precio.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para conversión segura
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _convertToOrder(Pedido session) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Actualizar el estado de la sesión a "confirmando_datos_envio"
    firestoreService.updateOrderStatus(session.codigo, 'confirmando_datos_envio').then((_) {
      Navigator.pop(context); // Cerrar diálogo de detalles
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión convertida a pedido exitosamente')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al convertir: $error')),
      );
    });
  }
}*/