import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:demo_pedidos/models/ajuste.dart';
import 'package:demo_pedidos/models/ajuste_detalle.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/models/stock_por_base.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class AjustesFormView extends StatefulWidget {
  const AjustesFormView({super.key, this.ajuste});

  final Ajuste? ajuste;

  @override
  State<AjustesFormView> createState() => _AjustesFormViewState();
}

class _AjustesFormViewState extends State<AjustesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<AjusteDetalle> _initialDetalles = <AjusteDetalle>[];
  List<_StockInput> _stockInputs = <_StockInput>[];

  bool _isLoadingBases = true;
  bool _isLoadingProductos = true;
  bool _isLoadingStock = false;
  bool _isSaving = false;
  String? _baseId;

  bool get _isEditing => widget.ajuste != null;

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
    final Ajuste? ajuste = widget.ajuste;
    if (ajuste != null) {
      _baseId = ajuste.idbase;
      _observacionController.text = ajuste.observacion ?? '';
      await _loadStockForBase(_baseId);
      await _loadDetalles();
    } else if (_baseId != null) {
      await _loadStockForBase(_baseId);
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

  Future<void> _loadStockForBase(String? baseId) async {
    _disposeStockInputs();
    if (baseId == null) {
      setState(() {
        _stockInputs = <_StockInput>[];
      });
      return;
    }
    setState(() => _isLoadingStock = true);
    try {
      final List<StockPorBase> stock =
          await StockPorBase.fetchByBase(baseId);
      if (!mounted) {
        return;
      }
      setState(() {
        _stockInputs = stock
            .map(
              (StockPorBase item) => _StockInput(
                productId: item.idproducto,
                productName: item.productoNombre,
                sistema: item.cantidad,
              ),
            )
            .toList(growable: false);
        _isLoadingStock = false;
      });
      _prefillStockInputs();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingStock = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el stock: $error')),
      );
    }
  }

  void _disposeStockInputs() {
    for (final _StockInput input in _stockInputs) {
      input.dispose();
    }
    _stockInputs = <_StockInput>[];
  }

  Future<void> _loadDetalles() async {
    final Ajuste? ajuste = widget.ajuste;
    if (ajuste == null) {
      return;
    }
    try {
      final List<AjusteDetalle> detalles =
          await AjusteDetalle.fetchByAjuste(ajuste.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialDetalles = detalles;
      });
      _prefillStockInputs();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los detalles: $error')),
      );
    }
  }

  void _prefillStockInputs() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_initialDetalles.isEmpty) {
        for (final _StockInput input in _stockInputs) {
          input.controller.clear();
        }
      } else {
        for (final AjusteDetalle detalle in _initialDetalles) {
          final _StockInput input = _ensureStockInput(
            productId: detalle.idproducto,
            productName:
                detalle.productoNombre ?? _productNameFor(detalle.idproducto),
            overrideSistema: detalle.cantidadSistema,
          );
          if (detalle.cantidadSistema != null) {
            input.sistema = detalle.cantidadSistema!;
          }
          final double real = detalle.cantidadReal ??
              (input.sistema + detalle.cantidad);
          input.controller.text = _formatDecimal(real);
        }
      }
    });
  }

  AjusteDetalle? _findDetalleForProduct(String productId) {
    for (final AjusteDetalle detalle in _initialDetalles) {
      if (detalle.idproducto == productId) {
        return detalle;
      }
    }
    return null;
  }

  String _productNameFor(String productId) {
    for (final Producto producto in _productos) {
      if (producto.id == productId) {
        return producto.nombre;
      }
    }
    return 'Producto';
  }

  List<_DetalleDraft> _collectPendingDetalles() {
    final List<_DetalleDraft> drafts = <_DetalleDraft>[];
    for (final _StockInput input in _stockInputs) {
      final double? real = input.realValue;
      if (real == null) {
        continue;
      }
      final double diff = double.parse(
        (real - input.sistema).toStringAsFixed(4),
      );
      if (diff == 0) {
        continue;
      }
      drafts.add(
        _DetalleDraft(
          productId: input.productId,
          productName: input.productName,
          cantidad: diff,
          cantidadSistema: input.sistema,
          cantidadReal: real,
        ),
      );
    }
    return drafts;
  }

  _StockInput _ensureStockInput({
    required String productId,
    required String productName,
    double sistema = 0,
    double? overrideSistema,
    bool prepend = false,
  }) {
    final int index = _stockInputs.indexWhere(
      (_StockInput input) => input.productId == productId,
    );
    if (index >= 0) {
      final _StockInput existing = _stockInputs[index];
      if (overrideSistema != null) {
        existing.sistema = overrideSistema;
      }
      return existing;
    }
    final _StockInput input = _StockInput(
      productId: productId,
      productName: productName,
      sistema: overrideSistema ?? sistema,
    );
    _stockInputs = prepend
        ? <_StockInput>[input, ..._stockInputs]
        : <_StockInput>[..._stockInputs, input];
    return input;
  }

  Future<Producto?> _pickProductoForStockInput() async {
    if (_productos.isEmpty) {
      return null;
    }
    String? selectedId = _productos.first.id;
    return showDialog<Producto>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Seleccionar producto'),
              content: DropdownMenu<String>(
                initialSelection: selectedId,
                label: const Text('Producto'),
                dropdownMenuEntries: _productos
                    .map(
                      (Producto producto) => DropdownMenuEntry<String>(
                        value: producto.id,
                        label: producto.nombre,
                      ),
                    )
                    .toList(growable: false),
                onSelected: (String? value) {
                  setModalState(() {
                    selectedId = value;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selectedId == null
                      ? null
                      : () {
                          final Producto producto = _productos.firstWhere(
                            (Producto item) => item.id == selectedId,
                          );
                          Navigator.pop(dialogContext, producto);
                        },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addManualStockInput() async {
    if (_isLoadingProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registra productos primero.')),
      );
      return;
    }
    final Producto? producto = await _pickProductoForStockInput();
    if (producto == null) {
      return;
    }
    if (_stockInputs.any(
      (_StockInput input) => input.productId == producto.id,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${producto.nombre} ya está en la lista.')),
      );
      return;
    }
    setState(() {
      final _StockInput input = _ensureStockInput(
        productId: producto.id,
        productName: producto.nombre,
        sistema: 0,
        prepend: true,
      );
      input.controller.text = '0';
    });
  }

  void _handleBaseChanged(String? value) {
    if (value == _baseId) {
      return;
    }
    setState(() {
      _baseId = value;
      _initialDetalles = <AjusteDetalle>[];
    });
    _loadStockForBase(value);
  }

  String _formatDecimal(double value) {
    final double rounded = double.parse(value.toStringAsFixed(4));
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(2);
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
    final List<_DetalleDraft> drafts = _collectPendingDetalles();
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un producto con cantidad real.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      String ajusteId = widget.ajuste?.id ?? '';
      final Ajuste payload = Ajuste(
        id: ajusteId,
        idbase: _baseId!,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        registradoAt: widget.ajuste?.registradoAt,
      );
      if (widget.ajuste == null) {
        ajusteId = await Ajuste.insert(payload);
      } else {
        await Ajuste.update(payload);
      }
      await AjusteDetalle.replaceForAjuste(
        ajusteId,
        drafts
            .map(
              (_DetalleDraft draft) => AjusteDetalle(
                id: null,
                idajuste: ajusteId,
                idproducto: draft.productId,
                cantidad: draft.cantidad,
                cantidadSistema: draft.cantidadSistema,
                cantidadReal: draft.cantidadReal,
                productoNombre: draft.productName,
              ),
            )
            .toList(growable: false),
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
    _disposeStockInputs();
    super.dispose();
  }

  Widget _buildStockSection() {
    final String? baseId = _baseId;
    if (baseId == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Detalle de ajuste',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _isLoadingStock ? null : () => _addManualStockInput(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo registro'),
                ),
                IconButton(
                  onPressed: _isLoadingStock
                      ? null
                      : () => _loadStockForBase(baseId),
                  tooltip: 'Actualizar stock',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa la cantidad real; registraremos automáticamente la diferencia.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_isLoadingStock)
              const Center(child: CircularProgressIndicator())
            else if (_stockInputs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Esta base aún no tiene productos en stock.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Sistema')),
                    DataColumn(label: Text('Real')),
                    DataColumn(label: Text('Diferencia')),
                  ],
                  rows: _buildStockRows(),
                  columnSpacing: 24,
                  headingRowHeight: 36,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 72,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildStockRows() {
    final ThemeData theme = Theme.of(context);
    return _stockInputs.map((_StockInput input) {
      final double sistema = input.sistema;
      final double? real = input.realValue;
      final double? diff = real != null ? real - sistema : null;
      final AjusteDetalle? registrado =
          _findDetalleForProduct(input.productId);
      Color diffColor = theme.textTheme.bodyMedium?.color ?? Colors.black54;
      String diffText = '-';
      if (diff != null) {
        if (diff.abs() < 0.0001) {
          diffText = '0';
        } else {
          diffText =
              diff > 0 ? '+${_formatDecimal(diff)}' : _formatDecimal(diff);
          diffColor = diff > 0 ? Colors.green : Colors.redAccent;
        }
      }
      return DataRow(
        cells: <DataCell>[
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(input.productName),
                if (registrado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Ajuste actual: ${_formatDecimal(registrado.cantidad)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DataCell(Text(_formatDecimal(sistema))),
          DataCell(
            SizedBox(
              width: 120,
              child: TextField(
                controller: input.controller,
                decoration: const InputDecoration(
                  hintText: 'Real',
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          DataCell(
            Text(
              diffText,
              style: TextStyle(color: diffColor),
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar ajuste' : 'Nuevo ajuste',
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
            if (_baseId != null) ...<Widget>[
              _buildStockSection(),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _observacionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
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
      initialValue: _baseId,
      items: _bases
          .map(
            (LogisticaBase base) => DropdownMenuItem<String>(
              value: base.id,
              child: Text(base.nombre),
            ),
          )
          .toList(growable: false),
      onChanged: (String? value) => _handleBaseChanged(value),
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

}

class _StockInput {
  _StockInput({
    required this.productId,
    required this.productName,
    required double sistema,
    String? initialReal,
  })  : _sistema = sistema,
        controller = TextEditingController(text: initialReal);

  final String productId;
  final String productName;
  double _sistema;
  final TextEditingController controller;

  double get sistema => _sistema;
  set sistema(double value) => _sistema = value;

  double? get realValue {
    final String text = controller.text.replaceAll(',', '.');
    if (text.trim().isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  void dispose() {
    controller.dispose();
  }
}

class _DetalleDraft {
  const _DetalleDraft({
    required this.productId,
    required this.productName,
    required this.cantidad,
    required this.cantidadSistema,
    required this.cantidadReal,
  });

  final String productId;
  final String productName;
  final double cantidad;
  final double cantidadSistema;
  final double cantidadReal;
}
