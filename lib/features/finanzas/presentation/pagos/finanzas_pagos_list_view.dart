import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/pagos/presentation/form/pagos_form_view.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/finanzas_pago.dart';
import 'package:demo_pedidos/models/pago.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FinanzasPagosListView extends StatefulWidget {
  const FinanzasPagosListView({super.key});

  @override
  State<FinanzasPagosListView> createState() => _FinanzasPagosListViewState();
}

class _FinanzasPagosListViewState extends State<FinanzasPagosListView> {
  late Future<List<FinanzasPago>> _future = _load();
  DateTimeRange? _dateRange;
  String? _selectedCuentaId;
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  bool _isLoadingCuentas = false;

  Future<List<FinanzasPago>> _load() {
    final DateTime? from = _dateRange?.start;
    final DateTime? to = _dateRange?.end;
    return FinanzasPago.fetchAll(
      from: from,
      to: to,
      cuentaId: _selectedCuentaId,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _reload();
    }
  }

  Future<void> _loadCuentas() async {
    if (_cuentas.isNotEmpty || _isLoadingCuentas) {
      return;
    }
    setState(() => _isLoadingCuentas = true);
    try {
      final List<CuentaBancaria> cuentas = await CuentaBancaria.getCuentas();
      if (!mounted) {
        return;
      }
      setState(() {
        _cuentas = cuentas;
        _isLoadingCuentas = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCuentas = false);
    }
  }

  String _rangeLabel() {
    if (_dateRange == null) {
      return 'Rango de fechas';
    }
    final DateTime start = _dateRange!.start;
    final DateTime end = _dateRange!.end;
    return '${_formatDate(start)} · ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Pagos',
      currentSection: AppSection.finanzasPagos,
      actions: <Widget>[
        IconButton(
          tooltip: 'Filtrar por fecha',
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range_outlined),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(_rangeLabel()),
                ),
                FutureBuilder<void>(
                  future: _loadCuentas(),
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    return DropdownButton<String?>(
                      value: _selectedCuentaId,
                      hint: const Text('Cuenta bancaria'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._cuentas.map(
                          (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                            value: cuenta.id,
                            child: Text(cuenta.nombre),
                          ),
                        ),
                      ],
                      onChanged: (String? value) async {
                        setState(() {
                          _selectedCuentaId = value;
                        });
                        await _reload();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FinanzasPago>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<FinanzasPago>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar los pagos.'),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final List<FinanzasPago> data = snapshot.data ?? <FinanzasPago>[];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin pagos registrados.'));
                }
                return TableSection<FinanzasPago>(
                  items: data,
                  columns: _columns,
                  searchPlaceholder: 'Buscar por cliente, pedido o cuenta',
                  searchTextBuilder: (FinanzasPago pago) =>
                      '${pago.clienteNombre ?? ''} ${pago.idpedido} ${pago.cuentaNombre ?? ''}',
                  onRowTap: (FinanzasPago pago) async {
                    final Pago pedidoPago = pago.toPedidoPago();
                    final bool? changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => PagosFormView(
                          pedidoId: pago.idpedido,
                          pago: pedidoPago,
                        ),
                      ),
                    );
                    if (changed == true) {
                      await _reload();
                    }
                  },
                  minTableWidth: 900,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<FinanzasPago>> get _columns {
    return <TableColumnConfig<FinanzasPago>>[
      TableColumnConfig<FinanzasPago>(
        label: 'Fecha de pago',
        sortAccessor: (FinanzasPago pago) => pago.fechapago,
        cellBuilder: (FinanzasPago pago) => Text(_formatDate(pago.fechapago)),
      ),
      TableColumnConfig<FinanzasPago>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (FinanzasPago pago) => pago.monto,
        cellBuilder: (FinanzasPago pago) =>
            Text('S/ ${pago.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<FinanzasPago>(
        label: 'Cliente',
        sortAccessor: (FinanzasPago pago) => pago.clienteNombre ?? '',
        cellBuilder: (FinanzasPago pago) =>
            Text(pago.clienteNombre ?? 'Sin cliente'),
      ),
      TableColumnConfig<FinanzasPago>(
        label: 'Pedido',
        sortAccessor: (FinanzasPago pago) => pago.idpedido,
        cellBuilder: (FinanzasPago pago) => Text(pago.idpedido),
      ),
      TableColumnConfig<FinanzasPago>(
        label: 'Cuenta',
        sortAccessor: (FinanzasPago pago) => pago.cuentaNombre ?? '',
        cellBuilder: (FinanzasPago pago) =>
            Text(pago.cuentaNombre ?? 'Sin cuenta'),
      ),
      TableColumnConfig<FinanzasPago>(
        label: 'Registrado',
        sortAccessor: (FinanzasPago pago) =>
            pago.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (FinanzasPago pago) => pago.registradoAt == null
            ? const Text('-')
            : Text(_formatDate(pago.registradoAt!)),
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
