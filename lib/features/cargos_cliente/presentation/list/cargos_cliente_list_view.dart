import 'package:demo_pedidos/features/pedidos/presentation/detail/pedidos_detalle_view.dart';
import 'package:demo_pedidos/models/cargo_cliente.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class CargosClienteListView extends StatelessWidget {
  const CargosClienteListView({
    super.key,
    required this.pedidoId,
    this.includeDrawer = false,
    this.returnResult = false,
  });

  final String pedidoId;
  final bool includeDrawer;
  final bool returnResult;

  @override
  Widget build(BuildContext context) {
    return EntityTablePage<CargoCliente>(
      title: 'Cargos al cliente',
      currentSection: AppSection.pedidos,
      includeDrawer: includeDrawer,
      returnResult: returnResult,
      loadItems: () => CargoCliente.getByPedido(pedidoId),
      columns: _columns,
      emptyMessage: 'Sin cargos registrados.',
      minTableWidth: 600,
      searchTextBuilder: (CargoCliente cargo) =>
          '${cargo.concepto} ${cargo.monto.toStringAsFixed(2)}',
      searchPlaceholder: 'Buscar por concepto o monto',
      onCreate: (BuildContext context) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PedidosDetalleView(pedidoId: pedidoId),
          ),
        );
        return changed ?? false;
      },
      onRowTap: (BuildContext context, CargoCliente cargo) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PedidosDetalleView(pedidoId: pedidoId),
          ),
        );
        return changed ?? false;
      },
      onDeleteSelected:
          (BuildContext context, List<CargoCliente> selected) async {
        for (final CargoCliente cargo in selected) {
          if (cargo.id.isNotEmpty) {
            await CargoCliente.deleteById(cargo.id);
          }
        }
      },
    );
  }

  List<TableColumnConfig<CargoCliente>> get _columns {
    return <TableColumnConfig<CargoCliente>>[
      TableColumnConfig<CargoCliente>(
        label: 'Concepto',
        sortAccessor: (CargoCliente cargo) => cargo.concepto,
        cellBuilder: (CargoCliente cargo) => Text(cargo.concepto),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (CargoCliente cargo) => cargo.monto,
        cellBuilder: (CargoCliente cargo) =>
            Text('S/ ${cargo.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Registrado',
        sortAccessor: (CargoCliente cargo) =>
            cargo.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (CargoCliente cargo) => cargo.createdAt == null
            ? const Text('-')
            : Text(_formatDateTime(cargo.createdAt!)),
      ),
    ];
  }

  String _formatDateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String year = value.year.toString();
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
