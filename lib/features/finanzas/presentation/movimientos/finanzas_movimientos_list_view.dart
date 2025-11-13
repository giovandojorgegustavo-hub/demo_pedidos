import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/finanzas/presentation/movimientos/finanzas_movimiento_form_view.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/models/finanzas_movimiento.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FinanzasMovimientosListView extends StatefulWidget {
  const FinanzasMovimientosListView({super.key});

  @override
  State<FinanzasMovimientosListView> createState() =>
      _FinanzasMovimientosListViewState();
}

class _FinanzasMovimientosListViewState
    extends State<FinanzasMovimientosListView> {
  late Future<List<FinanzasMovimiento>> _future = _load();
  DateTimeRange? _dateRange;
  String? _tipoFilter;
  String? _cuentaContableFilter;
  String? _cuentaBancariaFilter;
  List<CuentaContable> _cuentasContables = <CuentaContable>[];
  List<CuentaBancaria> _cuentasBancarias = <CuentaBancaria>[];
  Future<void>? _catalogosFuture;

  @override
  void initState() {
    super.initState();
    _catalogosFuture = _loadCatalogos();
  }

  Future<void> _ensureCatalogosLoaded() async {
    if (_catalogosFuture == null) {
      _catalogosFuture = _loadCatalogos();
    }
    await _catalogosFuture;
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      CuentaContable.fetchTerminales(),
      CuentaBancaria.getCuentas(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentasContables = results[0] as List<CuentaContable>;
      _cuentasBancarias = results[1] as List<CuentaBancaria>;
    });
  }

  Future<List<FinanzasMovimiento>> _load() {
    final DateTime? from = _dateRange?.start;
    final DateTime? to = _dateRange?.end;
    return FinanzasMovimiento.fetchAll(
      from: from,
      to: to,
      tipo: _tipoFilter,
      cuentaContableId: _cuentaContableFilter,
      cuentaBancariaId: _cuentaBancariaFilter,
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

  Future<void> _openForm({FinanzasMovimiento? movimiento}) async {
    await _ensureCatalogosLoaded();
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => FinanzasMovimientoFormView(
          movimiento: movimiento,
          cuentasContables: _cuentasContables,
          cuentasBancarias: _cuentasBancarias,
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
      title: 'Gastos e ingresos',
      currentSection: AppSection.finanzasGastos,
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
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          _Filters(
            onDateRangeTap: _selectDateRange,
            dateRangeLabel: _rangeLabel(),
            tipoFilter: _tipoFilter,
            onTipoChanged: (String? value) async {
              setState(() {
                _tipoFilter = value;
              });
              await _reload();
            },
            cuentaContableFilter: _cuentaContableFilter,
            onCuentaContableChanged: (String? value) async {
              setState(() {
                _cuentaContableFilter = value;
              });
              await _reload();
            },
            cuentaBancariaFilter: _cuentaBancariaFilter,
            onCuentaBancariaChanged: (String? value) async {
              setState(() {
                _cuentaBancariaFilter = value;
              });
              await _reload();
            },
            cuentasContables: _cuentasContables,
            cuentasBancarias: _cuentasBancarias,
          ),
          Expanded(
            child: FutureBuilder<List<FinanzasMovimiento>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<FinanzasMovimiento>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar los movimientos.'),
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
                final List<FinanzasMovimiento> data =
                    snapshot.data ?? <FinanzasMovimiento>[];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin movimientos.'));
                }
                return TableSection<FinanzasMovimiento>(
                  items: data,
                  columns: _columns,
                  searchPlaceholder: 'Buscar por descripción o cuenta',
                  searchTextBuilder: (FinanzasMovimiento movimiento) =>
                      '${movimiento.descripcion} ${movimiento.cuentaContableNombre ?? ''} ${movimiento.cuentaBancariaNombre ?? ''}',
                  onRowTap: (FinanzasMovimiento movimiento) =>
                      _openForm(movimiento: movimiento),
                  minTableWidth: 950,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<FinanzasMovimiento>> get _columns {
    return <TableColumnConfig<FinanzasMovimiento>>[
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Fecha',
        sortAccessor: (FinanzasMovimiento movimiento) =>
            movimiento.registradoAt ??
            DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (FinanzasMovimiento movimiento) =>
            Text(_formatDate(movimiento.registradoAt)),
      ),
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Tipo',
        sortAccessor: (FinanzasMovimiento movimiento) => movimiento.tipo,
        cellBuilder: (FinanzasMovimiento movimiento) =>
            Text(_tipoLabel(movimiento.tipo)),
      ),
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Descripción',
        sortAccessor: (FinanzasMovimiento movimiento) =>
            movimiento.descripcion,
        cellBuilder: (FinanzasMovimiento movimiento) =>
            Text(movimiento.descripcion),
      ),
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Cuenta contable',
        sortAccessor: (FinanzasMovimiento movimiento) =>
            movimiento.cuentaContableCodigo ?? '',
        cellBuilder: (FinanzasMovimiento movimiento) =>
            movimiento.cuentaContableNombre == null
                ? const Text('-')
                : Text(
                    '${movimiento.cuentaContableCodigo ?? ''} · ${movimiento.cuentaContableNombre}',
                  ),
      ),
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Cuenta bancaria',
        sortAccessor: (FinanzasMovimiento movimiento) =>
            movimiento.cuentaBancariaNombre ?? '',
        cellBuilder: (FinanzasMovimiento movimiento) =>
            Text(movimiento.cuentaBancariaNombre ?? '-'),
      ),
      TableColumnConfig<FinanzasMovimiento>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (FinanzasMovimiento movimiento) => movimiento.monto,
        cellBuilder: (FinanzasMovimiento movimiento) => Text(
          'S/ ${movimiento.monto.toStringAsFixed(2)}',
          style: TextStyle(
            color: movimiento.monto < 0 ? Colors.red : Colors.green,
          ),
        ),
      ),
    ];
  }

  String _rangeLabel() {
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

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'ingreso':
        return 'Ingreso';
      case 'gasto':
        return 'Gasto';
      case 'ajuste':
        return 'Ajuste';
      default:
        return tipo;
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.onDateRangeTap,
    required this.dateRangeLabel,
    required this.tipoFilter,
    required this.onTipoChanged,
    required this.cuentaContableFilter,
    required this.cuentasContables,
    required this.onCuentaContableChanged,
    required this.cuentaBancariaFilter,
    required this.cuentasBancarias,
    required this.onCuentaBancariaChanged,
  });

  final VoidCallback onDateRangeTap;
  final String dateRangeLabel;
  final String? tipoFilter;
  final ValueChanged<String?> onTipoChanged;
  final String? cuentaContableFilter;
  final List<CuentaContable> cuentasContables;
  final ValueChanged<String?> onCuentaContableChanged;
  final String? cuentaBancariaFilter;
  final List<CuentaBancaria> cuentasBancarias;
  final ValueChanged<String?> onCuentaBancariaChanged;

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
            onPressed: onDateRangeTap,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(dateRangeLabel),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String>('f-tipo-${tipoFilter ?? 'all'}'),
              decoration: const InputDecoration(labelText: 'Tipo'),
              initialValue: tipoFilter,
              items: const <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos'),
                ),
                DropdownMenuItem<String?>(
                  value: 'gasto',
                  child: Text('Gastos'),
                ),
                DropdownMenuItem<String?>(
                  value: 'ingreso',
                  child: Text('Ingresos'),
                ),
              ],
              onChanged: onTipoChanged,
            ),
          ),
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String>('f-cc-${cuentaContableFilter ?? 'all'}'),
              decoration: const InputDecoration(labelText: 'Cuenta contable'),
              initialValue: cuentaContableFilter,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...cuentasContables.map(
                  (CuentaContable cuenta) => DropdownMenuItem<String?>(
                    value: cuenta.id,
                    child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                  ),
                ),
              ],
              onChanged: onCuentaContableChanged,
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              key: ValueKey<String>('f-cb-${cuentaBancariaFilter ?? 'all'}'),
              decoration: const InputDecoration(labelText: 'Cuenta bancaria'),
              initialValue: cuentaBancariaFilter,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...cuentasBancarias.map(
                  (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                    value: cuenta.id,
                    child: Text(cuenta.nombre),
                  ),
                ),
              ],
              onChanged: onCuentaBancariaChanged,
            ),
          ),
        ],
      ),
    );
  }
}
