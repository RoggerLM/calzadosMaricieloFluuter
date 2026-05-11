// services/promo_service.dart
import '../models/item_pedido.dart';
import '../models/promo_model.dart';
import '../models/promo_pedido.dart';

class PromoService {
  // Precio base de cada producto (esto debería venir del backend)
  static int precioBaseProducto = 35;

  // Promociones disponibles (reglas)
  static List<PromoRule> getPromocionesDisponibles() {
    return [
      PromoRule(
        id: 'promo_3x120',
        nombre: '3x120',
        tipo: '3x120',
        cantidadRequerida: 3,
        precioPromocional: 120,
        productosAplicables: [], // Vacío = todos los productos
        activo: true,
      ),
      PromoRule(
        id: 'promo_2x80',
        nombre: '2x80',
        tipo: '2x80',
        cantidadRequerida: 2,
        precioPromocional: 80,
        productosAplicables: [],
        activo: true,
      ),
      PromoRule(
        id: 'promo_6x200',
        nombre: '6x200',
        tipo: '6x200',
        cantidadRequerida: 6,
        precioPromocional: 200,
        productosAplicables: [],
        activo: true,
      ),
    ];
  }

  // Encontrar la mejor promoción para un conjunto de productos
  static PromoAplicada? encontrarMejorPromocion(
      List<ItemPedido> productos,
      List<PromoRule> promociones,
      ) {
    PromoAplicada? mejorPromo;
    int mayorAhorro = 0;

    for (final promo in promociones) {
      // Verificar productos aplicables
      final productosAplicables = promo.productosAplicables.isEmpty
          ? List<ItemPedido>.from(productos)
          : productos.where((p) => promo.productosAplicables.contains(p.codigo)).toList();

      if (productosAplicables.length >= promo.cantidadRequerida) {
        // Tomar los primeros N productos necesarios
        final productosSeleccionados = productosAplicables.take(promo.cantidadRequerida).toList();

        // Calcular precio normal
        final precioNormal = productosSeleccionados.length * precioBaseProducto;
        final ahorro = precioNormal - promo.precioPromocional;

        if (ahorro > mayorAhorro) {
          mayorAhorro = ahorro;
          mejorPromo = PromoAplicada(
            regla: promo,
            items: productosSeleccionados,
            ahorro: ahorro,
            precioFinal: promo.precioPromocional,
          );
        }
      }
    }

    return mejorPromo;
  }

  // Calcular total general del pedido
  static int calcularTotalGeneral(
      List<ItemPedido> productosNormales,
      List<PromoPedido> promos,
      ) {
    int total = 0;

    // Productos normales
    total += productosNormales.fold(0, (sum, item) => sum + (precioBaseProducto * item.cantidad));

    // Promociones
    for (final promo in promos) {
      total += promo.precioPromocional;
    }

    return total;
  }

  // Calcular total de productos (cantidad)
  static int calcularTotalProductos(
      List<ItemPedido> productosNormales,
      List<PromoPedido> promos,
      ) {
    final totalNormales = productosNormales.fold(0, (sum, item) => sum + item.cantidad);
    final totalPromos = promos.fold(0, (sum, promo) => sum + promo.totalProductos);
    return totalNormales + totalPromos;
  }

  // Validar si una promo puede ser aplicada
  static bool puedeAplicarPromo(
      PromoRule regla,
      List<ItemPedido> productosDisponibles,
      ) {
    final productosAplicables = regla.productosAplicables.isEmpty
        ? productosDisponibles
        : productosDisponibles.where((p) => regla.productosAplicables.contains(p.codigo)).toList();

    return productosAplicables.length >= regla.cantidadRequerida;
  }

  // Crear un objeto PromoPedido desde una regla y productos seleccionados
  static PromoPedido crearPromoDesdeRegla(
      PromoRule regla,
      List<ItemPedido> productosSeleccionados,
      ) {
    return PromoPedido(
      tipo: regla.nombre,
      items: productosSeleccionados,
    );
  }
}