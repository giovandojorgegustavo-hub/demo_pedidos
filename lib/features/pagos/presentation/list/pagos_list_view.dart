import 'package:demo_pedidos/features/pagos/presentation/form/pagos_form_view.dart';
import 'package:demo_pedidos/models/pago.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class PagosListView extends StatelessWidget {
  const PagosListView({
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
    return EntityTablePage<Pago>(
      title: 'Pagos del pedido',
      currentSection: AppSection.pedidos,
      includeDrawer: includeDrawer,
      returnResult: returnResult,
      loadItems: () => Pago.getByPedido(pedidoId),
      columns: _columns,
      emptyMessage: 'Sin pagos registrados.',
      minTableWidth: 600,
      searchTextBuilder: (Pago pago) =>
          '${_formatDate(pago.fechapago)} ${pago.cuentaNombre ?? ''} ${pago.monto.toStringAsFixed(2)}',
      searchPlaceholder: 'Buscar por cuenta o fecha',
      onCreate: (BuildContext context) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PagosFormView(pedidoId: pedidoId),
          ),
        );
        return changed ?? false;
      },
      onRowTap: (BuildContext context, Pago pago) async {
        final bool? changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PagosFormView(
              pedidoId: pedidoId,
              pago: pago,
            ),
          ),
        );
        return changed ?? false;
      },
      onDeleteSelected: (BuildContext context, List<Pago> seleccionados) async {
        for (final Pago pago in seleccionados) {
          if (pago.id.isNotEmpty) {
            await Pago.deleteById(pago.id);
          }
        }
      },
    );
  }

  List<TableColumnConfig<Pago>> get _columns {
    return <TableColumnConfig<Pago>>[
      TableColumnConfig<Pago>(
        label: 'Fecha de pago',
        sortAccessor: (Pago pago) => pago.fechapago,
        cellBuilder: (Pago pago) => Text(_formatDate(pago.fechapago)),
      ),
      TableColumnConfig<Pago>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (Pago pago) => pago.monto,
        cellBuilder: (Pago pago) => Text('S/ ${pago.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<Pago>(
        label: 'Cuenta bancaria',
        sortAccessor: (Pago pago) => pago.cuentaNombre ?? '',
        cellBuilder: (Pago pago) => Text(pago.cuentaNombre ?? 'Sin cuenta'),
      ),
      TableColumnConfig<Pago>(
        label: 'Registrado',
        sortAccessor: (Pago pago) =>
            pago.fecharegistro ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (Pago pago) => pago.fecharegistro == null
            ? const Text('-')
            : Text(_formatDate(pago.fecharegistro!)),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}
