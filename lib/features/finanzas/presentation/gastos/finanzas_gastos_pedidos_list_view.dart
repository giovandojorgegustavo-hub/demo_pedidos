import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/pedidos/presentation/detail/pedidos_detalle_view.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/models/gasto_pedido.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FinanzasGastosPedidosListView extends StatefulWidget {
  const FinanzasGastosPedidosListView({super.key});

  @override
  State<FinanzasGastosPedidosListView> createState() =>
      _FinanzasGastosPedidosListViewState();
}

class _FinanzasGastosPedidosListViewState
    extends State<FinanzasGastosPedidosListView> {
  late Future<List<GastoPedido>> _future = _load();
  DateTimeRange? _dateRange;
  String? _tipoFilter;
  String? _cuentaFilter;
  String? _cuentaContableFilter;
  final TextEditingController _tipoController = TextEditingController();
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  List<CuentaContable> _cuentasContables = <CuentaContable>[];
  Future<void>? _catalogosFuture;

  @override
  void initState() {
    super.initState();
    _catalogosFuture = _loadCatalogos();
  }

  @override
  void dispose() {
    _tipoController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      CuentaBancaria.getCuentas(),
      CuentaContable.fetchTerminales(tipo: 'gasto'),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentas = results[0] as List<CuentaBancaria>;
      _cuentasContables = results[1] as List<CuentaContable>;
    });
  }

  Future<List<GastoPedido>> _load() {
    return GastoPedido.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      tipo: _tipoFilter,
      cuentaId: _cuentaFilter,
      cuentaContableId: _cuentaContableFilter,
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

  Future<void> _applyTipoFilter() async {
    setState(() {
      final String text = _tipoController.text.trim();
      _tipoFilter = text.isEmpty ? null : text;
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Gastos de pedidos',
      currentSection: AppSection.finanzasGastosPedidos,
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
          _Filters(
            dateLabel: _dateRangeLabel(),
            onDateTap: _selectDateRange,
            tipoController: _tipoController,
            onTipoSubmitted: (_) => _applyTipoFilter(),
            onClearTipo: () {
              _tipoController.clear();
              _applyTipoFilter();
            },
            cuentaFilter: _cuentaFilter,
            cuentaContableFilter: _cuentaContableFilter,
            onCuentaChanged: (String? value) async {
              setState(() {
                _cuentaFilter = value;
              });
              await _reload();
            },
            onCuentaContableChanged: (String? value) async {
              setState(() {
                _cuentaContableFilter = value;
              });
              await _reload();
            },
            cuentas: _cuentas,
            cuentasContables: _cuentasContables,
            catalogosFuture: _catalogosFuture,
          ),
          Expanded(
            child: FutureBuilder<List<GastoPedido>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<GastoPedido>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar los gastos.'),
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
                final List<GastoPedido> data =
                    snapshot.data ?? <GastoPedido>[];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin gastos registrados.'));
                }
                return TableSection<GastoPedido>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1100,
                  searchPlaceholder: 'Buscar cliente, pedido o descripción',
                  searchTextBuilder: (GastoPedido gasto) =>
                      '${gasto.clienteNombre ?? ''} ${gasto.idPedido} ${gasto.descripcion}',
                  onRowTap: (GastoPedido gasto) async {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => PedidosDetalleView(
                          pedidoId: gasto.idPedido,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<GastoPedido>> get _columns {
    return <TableColumnConfig<GastoPedido>>[
      TableColumnConfig<GastoPedido>(
        label: 'Fecha',
        sortAccessor: (GastoPedido gasto) =>
            gasto.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (GastoPedido gasto) =>
            Text(_formatDate(gasto.registradoAt)),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Pedido',
        sortAccessor: (GastoPedido gasto) => gasto.idPedido,
        cellBuilder: (GastoPedido gasto) => Text(gasto.idPedido),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Cliente',
        sortAccessor: (GastoPedido gasto) => gasto.clienteNombre ?? '',
        cellBuilder: (GastoPedido gasto) =>
            Text(gasto.clienteNombre ?? 'Sin cliente'),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Tipo',
        sortAccessor: (GastoPedido gasto) => gasto.tipo,
        cellBuilder: (GastoPedido gasto) => Text(gasto.tipo),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Descripción',
        sortAccessor: (GastoPedido gasto) => gasto.descripcion,
        cellBuilder: (GastoPedido gasto) => Text(gasto.descripcion),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Cuenta bancaria',
        sortAccessor: (GastoPedido gasto) => gasto.cuentaNombre ?? '',
        cellBuilder: (GastoPedido gasto) =>
            Text(gasto.cuentaNombre ?? 'Sin cuenta'),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Cuenta contable',
        sortAccessor: (GastoPedido gasto) =>
            gasto.cuentaContableCodigo ?? '',
        cellBuilder: (GastoPedido gasto) => gasto.cuentaContableNombre == null
            ? const Text('-')
            : Text(
                '${gasto.cuentaContableCodigo ?? ''} · ${gasto.cuentaContableNombre}',
              ),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (GastoPedido gasto) => gasto.monto,
        cellBuilder: (GastoPedido gasto) =>
            Text('S/ ${gasto.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<GastoPedido>(
        label: 'Registrado por',
        sortAccessor: (GastoPedido gasto) => gasto.registradoPor ?? '',
        cellBuilder: (GastoPedido gasto) =>
            Text(gasto.registradoPor ?? '-'),
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
    required this.tipoController,
    required this.onTipoSubmitted,
    required this.onClearTipo,
    required this.cuentaFilter,
    required this.cuentaContableFilter,
    required this.onCuentaChanged,
    required this.onCuentaContableChanged,
    required this.cuentas,
    required this.cuentasContables,
    this.catalogosFuture,
  });

  final String dateLabel;
  final VoidCallback onDateTap;
  final TextEditingController tipoController;
  final ValueChanged<String> onTipoSubmitted;
  final VoidCallback onClearTipo;
  final String? cuentaFilter;
  final String? cuentaContableFilter;
  final ValueChanged<String?> onCuentaChanged;
  final ValueChanged<String?> onCuentaContableChanged;
  final List<CuentaBancaria> cuentas;
  final List<CuentaContable> cuentasContables;
  final Future<void>? catalogosFuture;

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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: tipoController,
              builder: (
                BuildContext context,
                TextEditingValue value,
                Widget? child,
              ) {
                return TextField(
                  controller: tipoController,
                  decoration: InputDecoration(
                    labelText: 'Tipo de gasto',
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClearTipo,
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: onTipoSubmitted,
                );
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: FutureBuilder<void>(
              future: catalogosFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>('cuenta-${cuentaFilter ?? 'all'}'),
                  initialValue: cuentaFilter,
                  decoration: const InputDecoration(labelText: 'Cuenta bancaria'),
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
                  onChanged: onCuentaChanged,
                );
              },
            ),
          ),
          SizedBox(
            width: 240,
            child: FutureBuilder<void>(
              future: catalogosFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>(
                      'cuentaContable-${cuentaContableFilter ?? 'all'}'),
                  initialValue: cuentaContableFilter,
                  decoration:
                      const InputDecoration(labelText: 'Cuenta contable'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
