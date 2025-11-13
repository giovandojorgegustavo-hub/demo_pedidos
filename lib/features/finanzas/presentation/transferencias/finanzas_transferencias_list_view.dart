import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/finanzas/presentation/transferencias/finanzas_transferencia_form_view.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/finanzas_transferencia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FinanzasTransferenciasListView extends StatefulWidget {
  const FinanzasTransferenciasListView({super.key});

  @override
  State<FinanzasTransferenciasListView> createState() =>
      _FinanzasTransferenciasListViewState();
}

class _FinanzasTransferenciasListViewState
    extends State<FinanzasTransferenciasListView> {
  late Future<List<FinanzasTransferencia>> _future = _load();
  DateTimeRange? _dateRange;
  String? _cuentaOrigenFilter;
  String? _cuentaDestinoFilter;
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  Future<void>? _basesFuture;

  @override
  void initState() {
    super.initState();
    _basesFuture = _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    final List<CuentaBancaria> cuentas = await CuentaBancaria.getCuentas();
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentas = cuentas;
    });
  }

  Future<List<FinanzasTransferencia>> _load() {
    return FinanzasTransferencia.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      cuentaOrigenId: _cuentaOrigenFilter,
      cuentaDestinoId: _cuentaDestinoFilter,
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
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _reload();
    }
  }

  Future<void> _openForm({FinanzasTransferencia? transferencia}) async {
    await _basesFuture;
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => FinanzasTransferenciaFormView(
          transferencia: transferencia,
          cuentas: _cuentas,
        ),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Transferencias de bancos',
      currentSection: AppSection.finanzasTransferencias,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.swap_horiz),
      ),
      body: Column(
        children: <Widget>[
          _Filters(
            dateLabel: _dateRangeLabel(),
            onDateTap: _selectDateRange,
            cuentaOrigenFilter: _cuentaOrigenFilter,
            cuentaDestinoFilter: _cuentaDestinoFilter,
            onCuentaOrigenChanged: (String? value) async {
              setState(() {
                _cuentaOrigenFilter = value;
              });
              await _reload();
            },
            onCuentaDestinoChanged: (String? value) async {
              setState(() {
                _cuentaDestinoFilter = value;
              });
              await _reload();
            },
            cuentas: _cuentas,
            cuentasFuture: _basesFuture,
          ),
          Expanded(
            child: FutureBuilder<List<FinanzasTransferencia>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<FinanzasTransferencia>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar las transferencias.'),
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
                final List<FinanzasTransferencia> data =
                    snapshot.data ?? <FinanzasTransferencia>[];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin transferencias.'));
                }
                return TableSection<FinanzasTransferencia>(
                  items: data,
                  columns: _columns,
                  searchPlaceholder: 'Buscar por descripción o cuenta',
                  searchTextBuilder: (FinanzasTransferencia item) =>
                      '${item.descripcion} ${item.cuentaOrigenNombre ?? ''} ${item.cuentaDestinoNombre ?? ''}',
                  minTableWidth: 1000,
                  onRowTap: (FinanzasTransferencia item) =>
                      _openForm(transferencia: item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<FinanzasTransferencia>> get _columns {
    return <TableColumnConfig<FinanzasTransferencia>>[
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Fecha',
        sortAccessor: (FinanzasTransferencia item) =>
            item.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (FinanzasTransferencia item) =>
            Text(_formatDate(item.registradoAt)),
      ),
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Descripción',
        sortAccessor: (FinanzasTransferencia item) => item.descripcion,
        cellBuilder: (FinanzasTransferencia item) => Text(item.descripcion),
      ),
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Cuenta origen',
        sortAccessor: (FinanzasTransferencia item) =>
            item.cuentaOrigenNombre ?? '',
        cellBuilder: (FinanzasTransferencia item) =>
            Text(item.cuentaOrigenNombre ?? '-'),
      ),
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Cuenta destino',
        sortAccessor: (FinanzasTransferencia item) =>
            item.cuentaDestinoNombre ?? '',
        cellBuilder: (FinanzasTransferencia item) =>
            Text(item.cuentaDestinoNombre ?? '-'),
      ),
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (FinanzasTransferencia item) => item.monto,
        cellBuilder: (FinanzasTransferencia item) =>
            Text('S/ ${item.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<FinanzasTransferencia>(
        label: 'Registrado por',
        sortAccessor: (FinanzasTransferencia item) =>
            item.registradoPor ?? '',
        cellBuilder: (FinanzasTransferencia item) =>
            Text(item.registradoPor ?? '-'),
      ),
    ];
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Rango de fechas';
    }
    final DateTime start = _dateRange!.start;
    final DateTime end = _dateRange!.end;
    return '${_formatDate(start)} · ${_formatDate(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.dateLabel,
    required this.onDateTap,
    required this.cuentaOrigenFilter,
    required this.cuentaDestinoFilter,
    required this.onCuentaOrigenChanged,
    required this.onCuentaDestinoChanged,
    required this.cuentas,
    this.cuentasFuture,
  });

  final String dateLabel;
  final VoidCallback onDateTap;
  final String? cuentaOrigenFilter;
  final String? cuentaDestinoFilter;
  final ValueChanged<String?> onCuentaOrigenChanged;
  final ValueChanged<String?> onCuentaDestinoChanged;
  final List<CuentaBancaria> cuentas;
  final Future<void>? cuentasFuture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: onDateTap,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(dateLabel),
          ),
          SizedBox(
            width: 220,
            child: FutureBuilder<void>(
              future: cuentasFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>('origen-${cuentaOrigenFilter ?? 'all'}'),
                  initialValue: cuentaOrigenFilter,
                  decoration:
                      const InputDecoration(labelText: 'Cuenta origen'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...cuentas.map(
                      (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                        value: cuenta.id,
                        child: Text(cuenta.nombre),
                      ),
                    ),
                  ],
                  onChanged: onCuentaOrigenChanged,
                );
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: FutureBuilder<void>(
              future: cuentasFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key:
                      ValueKey<String>('destino-${cuentaDestinoFilter ?? 'all'}'),
                  initialValue: cuentaDestinoFilter,
                  decoration:
                      const InputDecoration(labelText: 'Cuenta destino'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...cuentas.map(
                      (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                        value: cuenta.id,
                        child: Text(cuenta.nombre),
                      ),
                    ),
                  ],
                  onChanged: onCuentaDestinoChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
