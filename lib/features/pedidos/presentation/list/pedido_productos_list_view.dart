import 'package:demo_pedidos/features/pedidos/presentation/detail/pedidos_detalle_view.dart';
import 'package:demo_pedidos/models/detalle_pedido.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class PedidoProductosListView extends StatelessWidget {
  const PedidoProductosListView({
    super.key,
    required this.pedidoId,
    this.includeDrawer = false,
    this.returnResult = false,
  });

  final String pedidoId;
  final bool includeDrawer;
  final bool returnResult;

  Future<List<_DetalleProductoItem>> _loadItems() async {
    final SupabaseClient client = Supabase.instance.client;
    final List<dynamic> data = await client
        .from('detallepedidos')
        .select(
          'id,idproducto,cantidad,precioventa,productos(nombre,precio)',
        )
        .eq('idpedido', pedidoId)
        .order('registrado_at');
    return data
        .map(
          (dynamic item) =>
              _DetalleProductoItem.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return EntityTablePage<_DetalleProductoItem>(
      title: 'Productos del pedido',
      currentSection: AppSection.pedidos,
      includeDrawer: includeDrawer,
      returnResult: returnResult,
      loadItems: _loadItems,
      columns: _columns,
      emptyMessage: 'Sin productos registrados.',
      minTableWidth: 640,
      searchTextBuilder: (_DetalleProductoItem item) =>
          '${item.productoNombre ?? ''} '
          '${item.detalle.precioventa.toStringAsFixed(2)} '
          '${item.detalle.cantidad.toStringAsFixed(2)}',
      searchPlaceholder: 'Buscar producto',
      onCreate: (BuildContext context) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PedidosDetalleView(pedidoId: pedidoId),
          ),
        );
        return changed ?? false;
      },
      onRowTap: (BuildContext context, _DetalleProductoItem item) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PedidosDetalleView(pedidoId: pedidoId),
          ),
        );
        return changed ?? false;
      },
      onDeleteSelected: (
        BuildContext context,
        List<_DetalleProductoItem> selected,
      ) async {
        final SupabaseClient client = Supabase.instance.client;
        for (final _DetalleProductoItem item in selected) {
          final String? id = item.detalle.id;
          if (id != null) {
            await client.from('detallepedidos').delete().eq('id', id);
          }
        }
      },
    );
  }

  List<TableColumnConfig<_DetalleProductoItem>> get _columns {
    return <TableColumnConfig<_DetalleProductoItem>>[
      TableColumnConfig<_DetalleProductoItem>(
        label: 'Producto',
        sortAccessor: (_DetalleProductoItem item) => item.productoNombre ?? '',
        cellBuilder: (_DetalleProductoItem item) =>
            Text(item.productoNombre ?? 'Producto'),
      ),
      TableColumnConfig<_DetalleProductoItem>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (_DetalleProductoItem item) => item.detalle.cantidad,
        cellBuilder: (_DetalleProductoItem item) =>
            Text(item.detalle.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<_DetalleProductoItem>(
        label: 'Precio unitario',
        isNumeric: true,
        sortAccessor: (_DetalleProductoItem item) => item.detalle.precioventa,
        cellBuilder: (_DetalleProductoItem item) =>
            Text('S/ ${item.detalle.precioventa.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<_DetalleProductoItem>(
        label: 'Subtotal',
        isNumeric: true,
        sortAccessor: (_DetalleProductoItem item) => item.subtotal,
        cellBuilder: (_DetalleProductoItem item) =>
            Text('S/ ${item.subtotal.toStringAsFixed(2)}'),
      ),
    ];
  }
}

class _DetalleProductoItem {
  const _DetalleProductoItem({
    required this.detalle,
    this.productoNombre,
    this.productoPrecio,
  });

  final DetallePedido detalle;
  final String? productoNombre;
  final double? productoPrecio;

  double get subtotal => detalle.cantidad * detalle.precioventa;

  factory _DetalleProductoItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? producto =
        json['productos'] as Map<String, dynamic>?;
    return _DetalleProductoItem(
      detalle: DetallePedido.fromJson(json),
      productoNombre: producto?['nombre'] as String?,
      productoPrecio: producto?['precio'] is num
          ? (producto?['precio'] as num).toDouble()
          : null,
    );
  }
}
