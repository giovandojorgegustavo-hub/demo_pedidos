import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/operaciones/presentation/fabricacion_detalle_consumido_form_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/fabricacion_detalle_fabricado_form_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/fabricacion_gasto_form_view.dart';
import 'package:demo_pedidos/models/fabricacion.dart';
import 'package:demo_pedidos/models/fabricacion_detalle_consumido.dart';
import 'package:demo_pedidos/models/fabricacion_detalle_fabricado.dart';
import 'package:demo_pedidos/models/fabricacion_gasto.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/models/stock_por_base.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

class FabricacionesFormView extends StatefulWidget {
  const FabricacionesFormView({super.key, this.fabricacion});

  final Fabricacion? fabricacion;

  @override
  State<FabricacionesFormView> createState() => _FabricacionesFormViewState();
}

class _FabricacionesFormViewState extends State<FabricacionesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<FabricacionDetalleConsumido> _consumidos =
      <FabricacionDetalleConsumido>[];
  List<FabricacionDetalleFabricado> _fabricados =
      <FabricacionDetalleFabricado>[];
  List<FabricacionGasto> _gastos = <FabricacionGasto>[];
  Map<String, double> _productoCostos = <String, double>{};

  bool _isLoadingBases = true;
  bool _isLoadingProductos = true;
  bool _isLoadingConsumidos = false;
  bool _isLoadingFabricados = false;
  bool _isLoadingGastos = false;
  bool _isLoadingCostos = false;
  bool _isSaving = false;
  String? _baseId;

  bool get _isEditing => widget.fabricacion != null;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait<void>(<Future<void>>[
      _loadBases(),
      _loadProductos(),
    ]);
    await _loadCostosParaBase();
    final Fabricacion? fabricacion = widget.fabricacion;
    if (fabricacion != null) {
      _baseId = fabricacion.idbase;
      _observacionController.text = fabricacion.observacion ?? '';
      await Future.wait<void>(<Future<void>>[
        _loadConsumidos(),
        _loadFabricados(),
        _loadGastos(),
      ]);
    }
  }

  Future<void> _loadBases() async {
    setState(() => _isLoadingBases = true);
    try {
      final List<LogisticaBase> bases = await LogisticaBase.getBases();
      if (!mounted) {
        return;
      }
      setState(() {
        _bases = bases;
        _isLoadingBases = false;
        _baseId ??= bases.isNotEmpty ? bases.first.id : null;
      });
      await _loadCostosParaBase();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingBases = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
      );
    }
  }

  Future<void> _loadCostosParaBase() async {
    final String? baseId = _baseId;
    if (baseId == null) {
      setState(() {
        _productoCostos = <String, double>{};
      });
      return;
    }
    setState(() => _isLoadingCostos = true);
    try {
      final List<StockPorBase> stock = await StockPorBase.fetchByBase(baseId);
      if (!mounted) {
        return;
      }
      final Map<String, double> costos = <String, double>{
        for (final StockPorBase item in stock) item.idproducto: item.costoUnitario,
      };
      setState(() {
        _productoCostos = costos;
        _isLoadingCostos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCostos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron calcular costos: $error')),
      );
    }
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoadingProductos = true);
    try {
      final List<Producto> productos = await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productos;
        _isLoadingProductos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingProductos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<void> _loadConsumidos() async {
    final Fabricacion? fabricacion = widget.fabricacion;
    if (fabricacion == null) {
      return;
    }
    setState(() => _isLoadingConsumidos = true);
    try {
      final List<FabricacionDetalleConsumido> detalles =
          await FabricacionDetalleConsumido.fetchByFabricacion(
        fabricacion.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _consumidos = detalles;
        _isLoadingConsumidos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingConsumidos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los insumos: $error')),
      );
    }
  }

  Future<void> _loadFabricados() async {
    final Fabricacion? fabricacion = widget.fabricacion;
    if (fabricacion == null) {
      return;
    }
    setState(() => _isLoadingFabricados = true);
    try {
      final List<FabricacionDetalleFabricado> detalles =
          await FabricacionDetalleFabricado.fetchByFabricacion(
        fabricacion.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _fabricados = detalles;
        _isLoadingFabricados = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingFabricados = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<void> _loadGastos() async {
    final Fabricacion? fabricacion = widget.fabricacion;
    if (fabricacion == null) {
      return;
    }
    setState(() => _isLoadingGastos = true);
    try {
      final List<FabricacionGasto> rows =
          await FabricacionGasto.fetchByFabricacion(fabricacion.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _gastos = rows;
        _isLoadingGastos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingGastos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los gastos: $error')),
      );
    }
  }

  Future<void> _openConsumidoForm(
      {FabricacionDetalleConsumido? detalle}) async {
    if (_isLoadingProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    final FabricacionDetalleConsumidoResult? result =
        await Navigator.push<FabricacionDetalleConsumidoResult>(
      context,
      MaterialPageRoute<FabricacionDetalleConsumidoResult>(
        builder: (_) => FabricacionDetalleConsumidoFormView(
          productos: _productos,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    setState(() {
      if (detalle == null) {
        _consumidos = <FabricacionDetalleConsumido>[
          ..._consumidos,
          result.detalle,
        ];
      } else {
        _consumidos = _consumidos.map((FabricacionDetalleConsumido item) {
          if (item == detalle) {
            return result.detalle;
          }
          return item;
        }).toList();
      }
    });
  }

  Future<void> _openFabricadoForm(
      {FabricacionDetalleFabricado? detalle}) async {
    if (_isLoadingProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    final FabricacionDetalleFabricadoResult? result =
        await Navigator.push<FabricacionDetalleFabricadoResult>(
      context,
      MaterialPageRoute<FabricacionDetalleFabricadoResult>(
        builder: (_) => FabricacionDetalleFabricadoFormView(
          productos: _productos,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    setState(() {
      if (detalle == null) {
        _fabricados = <FabricacionDetalleFabricado>[
          ..._fabricados,
          result.detalle,
        ];
      } else {
        _fabricados = _fabricados.map((FabricacionDetalleFabricado item) {
          if (item == detalle) {
            return result.detalle;
          }
          return item;
        }).toList();
      }
    });
  }

  Future<void> _openGastoForm({FabricacionGasto? gasto}) async {
    final FabricacionGastoFormResult? result =
        await Navigator.push<FabricacionGastoFormResult>(
      context,
      MaterialPageRoute<FabricacionGastoFormResult>(
        builder: (_) => FabricacionGastoFormView(gasto: gasto),
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (gasto == null) {
        _gastos = <FabricacionGasto>[..._gastos, result.gasto];
      } else {
        _gastos = _gastos.map((FabricacionGasto item) {
          if (item == gasto) {
            return result.gasto.copyWith(
              id: gasto.id,
              idfabricacion: gasto.idfabricacion,
            );
          }
          return item;
        }).toList();
      }
    });
  }

  void _removeGasto(FabricacionGasto gasto) {
    setState(() {
      _gastos = _gastos.where((FabricacionGasto item) => item != gasto).toList();
    });
  }

  void _removeConsumido(FabricacionDetalleConsumido detalle) {
    setState(() {
      _consumidos = _consumidos
          .where((FabricacionDetalleConsumido item) => item != detalle)
          .toList();
    });
  }

  void _removeFabricado(FabricacionDetalleFabricado detalle) {
    setState(() {
      _fabricados = _fabricados
          .where((FabricacionDetalleFabricado item) => item != detalle)
          .toList();
    });
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_baseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la base.')),
      );
      return;
    }
    if (_consumidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un insumo consumido.'),
        ),
      );
      return;
    }
    if (_fabricados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto fabricado.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      String fabricacionId = widget.fabricacion?.id ?? '';
      final Fabricacion payload = Fabricacion(
        id: fabricacionId,
        idbase: _baseId!,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        registradoAt: widget.fabricacion?.registradoAt,
      );
      if (widget.fabricacion == null) {
        fabricacionId = await Fabricacion.insert(payload);
      } else {
        await Fabricacion.update(payload);
      }
      await FabricacionDetalleConsumido.replaceForFabricacion(
        fabricacionId,
        _consumidos.map((FabricacionDetalleConsumido detalle) {
          return FabricacionDetalleConsumido(
            id: detalle.id,
            idfabricacion: fabricacionId,
            idproducto: detalle.idproducto,
            cantidad: detalle.cantidad,
            productoNombre: detalle.productoNombre,
          );
        }).toList(growable: false),
      );
      await FabricacionDetalleFabricado.replaceForFabricacion(
        fabricacionId,
        _fabricados.map((FabricacionDetalleFabricado detalle) {
          return FabricacionDetalleFabricado(
            id: detalle.id,
            idfabricacion: fabricacionId,
            idproducto: detalle.idproducto,
            cantidad: detalle.cantidad,
            productoNombre: detalle.productoNombre,
          );
        }).toList(growable: false),
      );
      await FabricacionGasto.replaceForFabricacion(
        fabricacionId,
        _gastos.map((FabricacionGasto gasto) {
          return gasto.copyWith(idfabricacion: fabricacionId);
        }).toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar fabricación' : 'Nueva fabricación',
      onSave: () => _onSave(),
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildBaseField(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildConsumidosSection(),
            const SizedBox(height: 24),
            _buildFabricadosSection(),
            const SizedBox(height: 24),
            _buildGastosSection(),
            const SizedBox(height: 24),
            _buildResumenCostos(),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseField() {
    if (_isLoadingBases) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bases.isEmpty) {
      return const Text(
        'Registra al menos una base logística para continuar.',
        style: TextStyle(color: Colors.redAccent),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(_baseId),
      initialValue: _baseId,
      items: _bases
          .map(
            (LogisticaBase base) => DropdownMenuItem<String>(
              value: base.id,
              child: Text(base.nombre),
            ),
          )
          .toList(growable: false),
      onChanged: (String? value) async {
        if (value == _baseId) {
          return;
        }
        setState(() {
          _baseId = value;
          _consumidos = <FabricacionDetalleConsumido>[];
          _fabricados = <FabricacionDetalleFabricado>[];
          _gastos = <FabricacionGasto>[];
        });
        await _loadCostosParaBase();
      },
      decoration: const InputDecoration(
        labelText: 'Base',
        border: OutlineInputBorder(),
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona la base';
        }
        return null;
      },
    );
  }

  Widget _buildConsumidosSection() {
    if (_isLoadingConsumidos) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InlineFormTable<FabricacionDetalleConsumido>(
          title: 'Insumos consumidos',
          items: _consumidos,
          columns: _consumidoColumns(),
          emptyMessage: 'Aún no agregas insumos.',
          helperText:
              'Estos productos se descontarán del stock de la base seleccionada.',
          onAdd: _baseId == null ? null : () => _openConsumidoForm(),
          onRowTap: (FabricacionDetalleConsumido detalle) =>
              _openConsumidoForm(detalle: detalle),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total insumos: ${_consumidos.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFabricadosSection() {
    if (_isLoadingFabricados) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InlineFormTable<FabricacionDetalleFabricado>(
          title: 'Productos fabricados',
          items: _fabricados,
          columns: _fabricadoColumns(),
          emptyMessage: 'Aún no agregas productos.',
          helperText:
              'Estos productos se añadirán al stock de la base seleccionada.',
          onAdd: _baseId == null ? null : () => _openFabricadoForm(),
          onRowTap: (FabricacionDetalleFabricado detalle) =>
              _openFabricadoForm(detalle: detalle),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total productos: ${_fabricados.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildGastosSection() {
    if (_isLoadingGastos) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InlineFormTable<FabricacionGasto>(
          title: 'Gastos adicionales',
          items: _gastos,
          columns: _gastoColumns(),
          emptyMessage: 'Aún no registras gastos.',
          helperText:
              'Registra pagos extra (taxis, mano de obra, servicios) vinculados a esta fabricación.',
          onAdd: _baseId == null ? null : () => _openGastoForm(),
          onRowTap: (FabricacionGasto gasto) =>
              _openGastoForm(gasto: gasto),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total gastos: ${_formatCurrency(_totalGastos)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  List<TableColumnConfig<FabricacionDetalleConsumido>> _consumidoColumns() {
    return <TableColumnConfig<FabricacionDetalleConsumido>>[
      TableColumnConfig<FabricacionDetalleConsumido>(
        label: 'Producto',
        sortAccessor: (FabricacionDetalleConsumido detalle) =>
            detalle.productoNombre ?? '',
        cellBuilder: (FabricacionDetalleConsumido detalle) =>
            Text(detalle.productoNombre ?? '-'),
      ),
      TableColumnConfig<FabricacionDetalleConsumido>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (FabricacionDetalleConsumido detalle) =>
            detalle.cantidad,
        cellBuilder: (FabricacionDetalleConsumido detalle) =>
            Text(detalle.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<FabricacionDetalleConsumido>(
        label: 'Costo estimado',
        isNumeric: true,
        sortAccessor: (FabricacionDetalleConsumido detalle) =>
            detalle.cantidad * _costoProducto(detalle.idproducto),
        cellBuilder: (FabricacionDetalleConsumido detalle) =>
            Text(
              _formatCurrency(
                detalle.cantidad * _costoProducto(detalle.idproducto),
              ),
            ),
      ),
      TableColumnConfig<FabricacionDetalleConsumido>(
        label: 'Acciones',
        cellBuilder: (FabricacionDetalleConsumido detalle) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => _openConsumidoForm(detalle: detalle),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _removeConsumido(detalle),
            ),
          ],
        ),
      ),
    ];
  }

  List<TableColumnConfig<FabricacionDetalleFabricado>> _fabricadoColumns() {
    return <TableColumnConfig<FabricacionDetalleFabricado>>[
      TableColumnConfig<FabricacionDetalleFabricado>(
        label: 'Producto',
        sortAccessor: (FabricacionDetalleFabricado detalle) =>
            detalle.productoNombre ?? '',
        cellBuilder: (FabricacionDetalleFabricado detalle) =>
            Text(detalle.productoNombre ?? '-'),
      ),
      TableColumnConfig<FabricacionDetalleFabricado>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (FabricacionDetalleFabricado detalle) =>
            detalle.cantidad,
        cellBuilder: (FabricacionDetalleFabricado detalle) =>
            Text(detalle.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<FabricacionDetalleFabricado>(
        label: 'Costo unitario',
        isNumeric: true,
        cellBuilder: (_) =>
            Text(_formatCurrency(_costoUnitarioPromedio)),
        sortAccessor: (_) => _costoUnitarioPromedio,
      ),
      TableColumnConfig<FabricacionDetalleFabricado>(
        label: 'Costo total',
        isNumeric: true,
        sortAccessor: (FabricacionDetalleFabricado detalle) =>
            detalle.cantidad * _costoUnitarioPromedio,
        cellBuilder: (FabricacionDetalleFabricado detalle) =>
            Text(
              _formatCurrency(
                _costoUnitarioPromedio * detalle.cantidad,
              ),
            ),
      ),
      TableColumnConfig<FabricacionDetalleFabricado>(
        label: 'Acciones',
        cellBuilder: (FabricacionDetalleFabricado detalle) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => _openFabricadoForm(detalle: detalle),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _removeFabricado(detalle),
            ),
          ],
        ),
      ),
    ];
  }

  List<TableColumnConfig<FabricacionGasto>> _gastoColumns() {
    return <TableColumnConfig<FabricacionGasto>>[
      TableColumnConfig<FabricacionGasto>(
        label: 'Concepto',
        sortAccessor: (FabricacionGasto gasto) => gasto.concepto,
        cellBuilder: (FabricacionGasto gasto) => Text(gasto.concepto),
      ),
      TableColumnConfig<FabricacionGasto>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (FabricacionGasto gasto) => gasto.monto,
        cellBuilder: (FabricacionGasto gasto) =>
            Text(_formatCurrency(gasto.monto)),
      ),
      TableColumnConfig<FabricacionGasto>(
        label: 'Observación',
        cellBuilder: (FabricacionGasto gasto) =>
            Text(gasto.observacion?.isEmpty ?? true
                ? '-'
                : gasto.observacion!),
      ),
      TableColumnConfig<FabricacionGasto>(
        label: 'Acciones',
        cellBuilder: (FabricacionGasto gasto) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => _openGastoForm(gasto: gasto),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _removeGasto(gasto),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildResumenCostos() {
    if (_isLoadingCostos) {
      return const Center(child: CircularProgressIndicator());
    }
    final double costoInsumos = _totalInsumosCosto;
    final double costoGastos = _totalGastos;
    final double totalFabricado = _totalFabricadoCantidad;
    final double costoUnitario = _costoUnitarioPromedio;
    final double costoTotal = costoInsumos + costoGastos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumen de costos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ResumenRow(
              label: 'Costo insumos',
              value: _formatCurrency(costoInsumos),
            ),
            _ResumenRow(
              label: 'Gastos adicionales',
              value: _formatCurrency(costoGastos),
            ),
            const Divider(),
            _ResumenRow(
              label: 'Costo total de fabricación',
              value: _formatCurrency(costoTotal),
            ),
            _ResumenRow(
              label: 'Total fabricado (unidades)',
              value: totalFabricado.toStringAsFixed(2),
            ),
            _ResumenRow(
              label: 'Costo unitario promedio',
              value: _formatCurrency(
                totalFabricado > 0 ? costoUnitario : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _totalInsumosCosto {
    return _consumidos.fold<double>(
      0,
      (double sum, FabricacionDetalleConsumido detalle) =>
          sum + detalle.cantidad * _costoProducto(detalle.idproducto),
    );
  }

  double get _totalGastos {
    return _gastos.fold<double>(
      0,
      (double sum, FabricacionGasto gasto) => sum + gasto.monto,
    );
  }

  double get _totalFabricadoCantidad {
    return _fabricados.fold<double>(
      0,
      (double sum, FabricacionDetalleFabricado detalle) =>
          sum + detalle.cantidad,
    );
  }

  double get _costoUnitarioPromedio {
    final double totalFabricado = _totalFabricadoCantidad;
    if (totalFabricado == 0) {
      return 0;
    }
    return (_totalInsumosCosto + _totalGastos) / totalFabricado;
  }

  double _costoProducto(String productoId) {
    return _productoCostos[productoId] ?? 0;
  }

  String _formatCurrency(double value) => 'S/ ${value.toStringAsFixed(2)}';
}

class _ResumenRow extends StatelessWidget {
  const _ResumenRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
