import 'package:demo_pedidos/features/pedidos/presentation/detail/pedidos_detalle_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/form/pedidos_form_view.dart';
import 'package:demo_pedidos/models/pedido.dart';
import 'package:flutter/material.dart';

/// Acciones maestras del módulo de pedidos.
/// Mantenerlas centralizadas permite reutilizarlas desde las vistas
/// (tabla, detalle, formularios inline) como en AppSheet.
class PedidosActions {
  const PedidosActions._();

  /// Abre el formulario en modo creación.
  /// Devuelve `true` si se guardaron cambios.
  static Future<bool> create(BuildContext context) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const PedidosFormView(),
      ),
    );
    return result == true;
  }

  /// Abre el formulario en modo edición.
  static Future<bool> edit(BuildContext context, Pedido pedido) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PedidosFormView(pedido: pedido),
      ),
    );
    return result == true;
  }

  /// Abre la vista detalle de un pedido.
  static Future<bool> openDetail(BuildContext context, String pedidoId) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PedidosDetalleView(pedidoId: pedidoId),
      ),
    );
    return changed == true;
  }

  /// Ejecuta la eliminación de un conjunto de pedidos.
  static Future<void> deleteByIds(Iterable<String> ids) async {
    for (final String id in ids) {
      await Pedido.deleteById(id);
    }
  }
}
