import 'package:demo_pedidos/features/bases/presentation/form/bases_form_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/form/direccion_form_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/form/direccion_provincia_form_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/form/numrecibe_form_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/shared/detalle_movimiento_form_view.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/movimiento_pedido.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/pedido.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MovimientoFormView extends StatefulWidget {
  const MovimientoFormView({
    super.key,
    required this.pedidoId,
    this.clienteId,
    this.movimiento,
    this.detalles,
    this.resumen,
  });

  final String pedidoId;
  final String? clienteId;
  final MovimientoPedido? movimiento;
  final List<DetalleMovimiento>? detalles;
  final MovimientoResumen? resumen;

  @override
  State<MovimientoFormView> createState() => _MovimientoFormViewState();
}

class _MovimientoFormViewState extends State<MovimientoFormView> {
  static const String _newBaseValue = '__new_base__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<DetalleMovimiento> _detalles = <DetalleMovimiento>[];
  bool _isLoadingBases = true;
  bool _isLoadingProductos = true;
  bool _isSaving = false;
  String? _selectedBaseId;
  MovimientoResumen? _resumen;
  bool _esProvincia = false;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  String? _movimientoId;
  String? _clienteId;
  bool _isLoadingClienteData = false;
  List<_ClienteDireccion> _clienteDirecciones = <_ClienteDireccion>[];
  List<_ClienteContacto> _clienteContactos = <_ClienteContacto>[];
  List<_ClienteDireccionProvincia> _clienteDireccionesProvincia =
      <_ClienteDireccionProvincia>[];
  String? _selectedDireccionId;
  String? _selectedContactoId;
  String? _selectedProvinciaDireccionId;
  Map<String, _ProductoPedidoInfo> _productosPedido =
      <String, _ProductoPedidoInfo>{};
  bool _isLoadingPendientes = false;
  bool _isCompletingPedido = false;

  bool get _isEditing => widget.movimiento != null;

  @override
  void initState() {
    super.initState();
    final MovimientoPedido? movimiento = widget.movimiento;
    if (movimiento != null) {
      _movimientoId = movimiento.id;
      _selectedBaseId = movimiento.idbase.isEmpty ? null : movimiento.idbase;
      _esProvincia = movimiento.esProvincia;
      _fecha = movimiento.fecharegistro;
      _hora = TimeOfDay(
          hour: movimiento.fecharegistro.hour,
          minute: movimiento.fecharegistro.minute);
    }
    final List<DetalleMovimiento>? detalles = widget.detalles;
    if (detalles != null && detalles.isNotEmpty) {
      _detalles = detalles
          .map(
            (DetalleMovimiento detalle) => DetalleMovimiento(
              id: detalle.id,
              idmovimiento: detalle.idmovimiento,
              idproducto: detalle.idproducto,
              cantidad: detalle.cantidad,
              productoNombre: detalle.productoNombre,
            ),
          )
          .toList();
    }
    _clienteId = widget.clienteId;
    _initialLoad();
    _loadProductosPedido();
    if (_clienteId != null) {
      _loadClienteCatalogos();
    } else {
      _fetchClienteId();
    }
    _resumen = widget.resumen;
    if (_isEditing && _movimientoId != null) {
      _loadResumen();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await Future.wait<void>(<Future<void>>[
      _loadBases(
        selectId: _selectedBaseId,
        fallbackName: widget.movimiento?.baseNombre,
      ),
      _loadProductos(),
    ]);
  }

  Future<void> _loadResumen() async {
    final String? movimientoId = _movimientoId;
    if (!_isEditing || movimientoId == null) {
      return;
    }
    final MovimientoResumen? resumen =
        await MovimientoResumen.fetchById(movimientoId);
    if (!mounted || resumen == null) {
      return;
    }
    setState(() {
      _resumen = resumen;
    });
  }

  Future<void> _loadProductosPedido() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingPendientes = true;
    });
    try {
      final Map<String, _ProductoPedidoInfo> productos =
          await _fetchProductosPedido();
      if (!mounted) {
        return;
      }
      setState(() {
        _productosPedido = productos;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron calcular los pendientes: $error'),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPendientes = false;
      });
    }
  }

  Future<void> _fetchClienteId() async {
    try {
      final Pedido? pedido =
          await Pedido.getById(widget.movimiento?.idpedido ?? widget.pedidoId);
      if (!mounted) {
        return;
      }
      _clienteId = pedido?.idcliente ?? widget.clienteId;
      if (_clienteId != null) {
        await _loadClienteCatalogos();
      }
    } catch (_) {
      // Ignorado: el usuario podrá ingresar los datos manualmente.
    }
  }

  Future<Map<String, _ProductoPedidoInfo>> _fetchProductosPedido() async {
    final String pedidoId = widget.movimiento?.idpedido ?? widget.pedidoId;
    final List<dynamic> solicitados = await _supabase
        .from('detallepedidos')
        .select('idproducto,cantidad,productos(nombre)')
        .eq('idpedido', pedidoId);
    if (solicitados.isEmpty) {
      return <String, _ProductoPedidoInfo>{};
    }
    final Map<String, double> cantidades = <String, double>{};
    final Map<String, String> nombres = <String, String>{};
    for (final dynamic item in solicitados) {
      final Map<String, dynamic> row = item as Map<String, dynamic>;
      final String productoId = row['idproducto'] as String;
      cantidades[productoId] = _parseCantidad(row['cantidad']);
      final Map<String, dynamic>? producto =
          row['productos'] as Map<String, dynamic>?;
      nombres[productoId] =
          (producto?['nombre'] as String?) ?? 'Producto sin nombre';
    }
    final List<dynamic> enviados = await _supabase
        .from('detallemovimientopedidos')
        .select('idproducto,cantidad,movimientopedidos!inner(idpedido)')
        .eq('movimientopedidos.idpedido', pedidoId);
    final Map<String, double> enviadosPorProducto = <String, double>{};
    for (final dynamic item in enviados) {
      final Map<String, dynamic> row = item as Map<String, dynamic>;
      final String productoId = row['idproducto'] as String;
      final double cantidad = _parseCantidad(row['cantidad']);
      enviadosPorProducto[productoId] =
          (enviadosPorProducto[productoId] ?? 0) + cantidad;
    }

    final Map<String, _ProductoPedidoInfo> productos =
        <String, _ProductoPedidoInfo>{};
    cantidades.forEach((String productoId, double solicitado) {
      final double enviado = enviadosPorProducto[productoId] ?? 0;
      productos[productoId] = _ProductoPedidoInfo(
        idProducto: productoId,
        nombre: nombres[productoId] ?? 'Producto',
        solicitado: solicitado,
        enviado: enviado,
      );
    });
    return productos;
  }

  Future<void> _loadClienteCatalogos() async {
    final String? clienteId = _clienteId;
    if (clienteId == null) {
      return;
    }
    setState(() {
      _isLoadingClienteData = true;
    });
    try {
      final List<_ClienteDireccion> direcciones =
          await _fetchDirecciones(clienteId);
      final List<_ClienteContacto> contactos = await _fetchContactos(clienteId);
      final List<_ClienteDireccionProvincia> provincias =
          await _fetchDireccionesProvincia(clienteId);
      if (!mounted) {
        return;
      }
      setState(() {
        _clienteDirecciones = direcciones;
        _clienteContactos = contactos;
        _clienteDireccionesProvincia = provincias;
      });
      await _loadDestinoActual();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClienteData = false;
        });
      }
    }
  }

  double _parseCantidad(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _loadBases({String? selectId, String? fallbackName}) async {
    setState(() {
      _isLoadingBases = true;
    });
    try {
      final List<LogisticaBase> bases = await LogisticaBase.getBases();
      if (!mounted) {
        return;
      }
      if (selectId != null &&
          selectId.isNotEmpty &&
          bases.every((LogisticaBase base) => base.id != selectId)) {
        bases.insert(
          0,
          LogisticaBase(
            id: selectId,
            nombre: fallbackName ?? 'Base asignada',
          ),
        );
      }
      setState(() {
        _bases = bases;
        _isLoadingBases = false;
        if (selectId != null &&
            bases.any((LogisticaBase base) => base.id == selectId)) {
          _selectedBaseId = selectId;
        } else if (_selectedBaseId == null && bases.isNotEmpty) {
          _selectedBaseId = bases.first.id;
        } else if (bases
            .every((LogisticaBase base) => base.id != _selectedBaseId)) {
          _selectedBaseId = bases.isNotEmpty ? bases.first.id : null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBases = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
      );
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoadingProductos = true;
    });
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
      setState(() {
        _isLoadingProductos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<List<_ClienteDireccion>> _fetchDirecciones(String clienteId) async {
    final List<dynamic> data = await _supabase
        .from('direccion')
        .select('id,direccion,referencia')
        .eq('idcliente', clienteId)
        .order('registrado_at', ascending: false);
    return data
        .map(
          (dynamic item) => _ClienteDireccion(
            id: item['id'] as String,
            direccion: (item['direccion'] as String?) ?? '',
            referencia: item['referencia'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<_ClienteContacto>> _fetchContactos(String clienteId) async {
    final List<dynamic> data = await _supabase
        .from('numrecibe')
        .select('id,numero,nombre_contacto')
        .eq('idcliente', clienteId)
        .order('registrado_at', ascending: false);
    return data
        .map(
          (dynamic item) => _ClienteContacto(
            id: item['id'] as String,
            numero: (item['numero'] as String?) ?? '',
            nombre: item['nombre_contacto'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<_ClienteDireccionProvincia>> _fetchDireccionesProvincia(
      String clienteId) async {
    final List<dynamic> data = await _supabase
        .from('direccion_provincia')
        .select('id,lugar_llegada,nombre_completo,dni')
        .eq('idcliente', clienteId)
        .order('registrado_at', ascending: false);
    return data
        .map(
          (dynamic item) => _ClienteDireccionProvincia(
            id: item['id'] as String,
            destino: (item['lugar_llegada'] as String?) ?? '',
            destinatario: item['nombre_completo'] as String?,
            dni: item['dni'] as String?,
          ),
        )
        .toList(growable: false);
  }

  _ClienteDireccion? _findDireccionById(String? id) {
    if (id == null) {
      return null;
    }
    for (final _ClienteDireccion direccion in _clienteDirecciones) {
      if (direccion.id == id) {
        return direccion;
      }
    }
    return null;
  }

  _ClienteContacto? _findContactoById(String? id) {
    if (id == null) {
      return null;
    }
    for (final _ClienteContacto contacto in _clienteContactos) {
      if (contacto.id == id) {
        return contacto;
      }
    }
    return null;
  }

  _ClienteDireccionProvincia? _findProvinciaById(String? id) {
    if (id == null) {
      return null;
    }
    for (final _ClienteDireccionProvincia dir in _clienteDireccionesProvincia) {
      if (dir.id == id) {
        return dir;
      }
    }
    return null;
  }

  Future<void> _loadDestinoActual() async {
    if (_movimientoId == null) {
      return;
    }
    try {
      if (_esProvincia) {
        final Map<String, dynamic>? data = await _supabase
            .from('mov_destino_provincia')
            .select('iddir_provincia')
            .eq('idmovimiento', _movimientoId!)
            .maybeSingle();
        final String? dirId = data?['iddir_provincia'] as String?;
        if (dirId == null) {
          return;
        }
        final Map<String, dynamic>? dir = await _supabase
            .from('direccion_provincia')
            .select('id,lugar_llegada,nombre_completo,dni')
            .eq('id', dirId)
            .maybeSingle();
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedProvinciaDireccionId = dirId;
          if (dir != null &&
              _clienteDireccionesProvincia.every(
                  (_ClienteDireccionProvincia item) => item.id != dirId)) {
            _clienteDireccionesProvincia.insert(
              0,
              _ClienteDireccionProvincia(
                id: dirId,
                destino: dir['lugar_llegada'] as String? ?? '',
                destinatario: dir['nombre_completo'] as String?,
                dni: dir['dni'] as String?,
              ),
            );
          }
        });
      } else {
        final Map<String, dynamic>? data = await _supabase
            .from('mov_destino_lima')
            .select('iddireccion,idnumrecibe')
            .eq('idmovimiento', _movimientoId!)
            .maybeSingle();
        if (data == null) {
          return;
        }
        final String? dirId = data['iddireccion'] as String?;
        final String? contactoId = data['idnumrecibe'] as String?;
        final Map<String, dynamic>? dir = dirId == null
            ? null
            : await _supabase
                .from('direccion')
                .select('id,direccion,referencia')
                .eq('id', dirId)
                .maybeSingle();
        final Map<String, dynamic>? contacto = contactoId == null
            ? null
            : await _supabase
                .from('numrecibe')
                .select('id,numero,nombre_contacto')
                .eq('id', contactoId)
                .maybeSingle();
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedDireccionId = dirId;
          _selectedContactoId = contactoId;
          if (dirId != null &&
              dir != null &&
              _clienteDirecciones
                  .every((_ClienteDireccion item) => item.id != dirId)) {
            _clienteDirecciones.insert(
              0,
              _ClienteDireccion(
                id: dirId,
                direccion: dir['direccion'] as String? ?? '',
                referencia: dir['referencia'] as String?,
              ),
            );
          }
          if (contactoId != null &&
              contacto != null &&
              _clienteContactos
                  .every((_ClienteContacto item) => item.id != contactoId)) {
            _clienteContactos.insert(
              0,
              _ClienteContacto(
                id: contactoId,
                numero: contacto['numero'] as String? ?? '',
                nombre: contacto['nombre_contacto'] as String?,
              ),
            );
          }
        });
      }
    } catch (_) {
      // No interrumpir si no se puede cargar el destino existente.
    }
  }

  Future<void> _openNuevaBase() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const BasesFormView(),
      ),
    );
    if (newId != null) {
      await _loadBases(selectId: newId);
    }
  }

  Future<void> _selectFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  Future<void> _selectHora() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _hora);
    if (picked != null) {
      setState(() {
        _hora = picked;
      });
    }
  }

  String _formatFecha() {
    final String day = _fecha.day.toString().padLeft(2, '0');
    final String month = _fecha.month.toString().padLeft(2, '0');
    return '$day/$month/${_fecha.year}';
  }

  Future<void> _openDetalleForm(
      {DetalleMovimiento? detalle, int? index}) async {
    List<Producto> productosDisponibles = _productos;
    Map<String, double>? autoFill;
    bool allowNewProduct = true;
    if (_productosPedido.isNotEmpty) {
      final Map<String, double> restantes =
          _buildRestantesPorProducto(excluir: detalle);
      if (restantes.isEmpty && detalle == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay productos pendientes por entregar.'),
            ),
          );
        }
        return;
      }
      productosDisponibles = restantes.entries
          .map(
            (MapEntry<String, double> entry) => Producto(
              id: entry.key,
              nombre: _productosPedido[entry.key]?.nombre ?? 'Producto',
              precio: 0,
            ),
          )
          .toList();
      productosDisponibles.sort(
        (Producto a, Producto b) => a.nombre.compareTo(b.nombre),
      );
      autoFill = restantes;
      allowNewProduct = false;
    }
    final DetalleMovimientoFormResult? result =
        await Navigator.push<DetalleMovimientoFormResult>(
      context,
      MaterialPageRoute<DetalleMovimientoFormResult>(
        builder: (_) => DetalleMovimientoFormView(
          detalle: detalle,
          productos: productosDisponibles,
          allowNewProduct: allowNewProduct,
          autoFillByProduct: autoFill,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _loadProductos();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (index != null) {
        _detalles[index] = result.detalle;
      } else {
        _detalles.add(result.detalle);
      }
    });
  }

  String _productoNombre(DetalleMovimiento detalle) {
    final String? nombre = detalle.productoNombre;
    if (nombre != null && nombre.isNotEmpty) {
      return nombre;
    }
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == detalle.idproducto,
      orElse: () => Producto(
          id: detalle.idproducto, nombre: 'Producto desconocido', precio: 0),
    );
    return producto?.nombre ?? 'Producto desconocido';
  }

  bool get _hasProductosPedido => _productosPedido.isNotEmpty;

  bool get _shouldShowCompletarPedidoButton {
    if (_isLoadingPendientes || _productosPedido.isEmpty) {
      return false;
    }
    final Map<String, double> faltantesBase = <String, double>{
      for (final MapEntry<String, _ProductoPedidoInfo> entry
          in _productosPedido.entries)
        entry.key: entry.value.faltante,
    };
    final Map<String, double> cantidadesFormulario = <String, double>{};
    for (final DetalleMovimiento detalle in _detalles) {
      cantidadesFormulario[detalle.idproducto] =
          (cantidadesFormulario[detalle.idproducto] ?? 0) + detalle.cantidad;
    }
    for (final MapEntry<String, double> entry in faltantesBase.entries) {
      final double restante =
          entry.value - (cantidadesFormulario[entry.key] ?? 0);
      if (restante > 0.0001) {
        return true;
      }
    }
    return false;
  }

  void _removeDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  Map<String, double> _buildRestantesPorProducto({DetalleMovimiento? excluir}) {
    if (_productosPedido.isEmpty) {
      return <String, double>{};
    }
    final Map<String, double> restantes = <String, double>{
      for (final MapEntry<String, _ProductoPedidoInfo> entry
          in _productosPedido.entries)
        entry.key: entry.value.faltante,
    };
    for (final DetalleMovimiento detalle in _detalles) {
      if (excluir != null && detalle == excluir) {
        continue;
      }
      final String productoId = detalle.idproducto;
      if (!restantes.containsKey(productoId)) {
        continue;
      }
      final double nuevoValor = (restantes[productoId]! - detalle.cantidad)
          .clamp(0, double.infinity) as double;
      restantes[productoId] = nuevoValor;
    }
    final String? productoEditado = excluir?.idproducto;
    restantes.removeWhere((String key, double value) {
      if (value > 0.0001) {
        return false;
      }
      if (productoEditado != null && key == productoEditado) {
        return false;
      }
      return true;
    });
    return restantes;
  }

  Future<void> _completarPedidoAutomaticamente() async {
    if (_isCompletingPedido || _productosPedido.isEmpty) {
      return;
    }
    setState(() {
      _isCompletingPedido = true;
    });
    try {
      final List<DetalleMovimiento> updated =
          List<DetalleMovimiento>.from(_detalles);
      bool added = false;
      for (final MapEntry<String, _ProductoPedidoInfo> entry
          in _productosPedido.entries) {
        final _ProductoPedidoInfo info = entry.value;
        final double cantidadEnFormulario = updated
            .where((DetalleMovimiento detalle) =>
                detalle.idproducto == info.idProducto)
            .fold<double>(
              0,
              (double previousValue, DetalleMovimiento detalle) =>
                  previousValue + detalle.cantidad,
            );
        final double restante = info.faltante - cantidadEnFormulario;
        if (restante <= 0.0001) {
          continue;
        }
        final int existingIndex = updated.indexWhere(
          (DetalleMovimiento detalle) => detalle.idproducto == info.idProducto,
        );
        if (existingIndex >= 0) {
          final DetalleMovimiento existente = updated[existingIndex];
          updated[existingIndex] = DetalleMovimiento(
            id: existente.id,
            idmovimiento: existente.idmovimiento,
            idproducto: existente.idproducto,
            cantidad: existente.cantidad + restante,
            productoNombre: existente.productoNombre ?? info.nombre,
          );
        } else {
          updated.add(
            DetalleMovimiento(
              idproducto: info.idProducto,
              cantidad: restante,
              productoNombre: info.nombre,
            ),
          );
        }
        added = true;
      }
      if (!added) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El pedido ya está completo.')),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _detalles = updated;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompletingPedido = false;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_clienteId == null) {
      await _fetchClienteId();
    }
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar al cliente del movimiento.'),
        ),
      );
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta registrar el detalle del movimiento.'),
        ),
      );
      return;
    }
    if (!_esProvincia && _selectedDireccionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección de entrega.')),
      );
      return;
    }
    if (_esProvincia && _selectedProvinciaDireccionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un destino de provincia.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final DateTime fechaMovimiento = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final MovimientoPedido payload = MovimientoPedido(
      id: _movimientoId ?? '',
      idpedido: widget.movimiento?.idpedido ?? widget.pedidoId,
      idbase: _selectedBaseId ?? '',
      esProvincia: _esProvincia,
      fecharegistro: fechaMovimiento,
    );

    try {
      final String movimientoId;
      if (_isEditing && _movimientoId != null) {
        await MovimientoPedido.update(payload);
        movimientoId = _movimientoId!;
      } else {
        movimientoId = await MovimientoPedido.insert(payload);
      }
      await DetalleMovimiento.replaceForMovimiento(movimientoId, _detalles);
      await _saveDestinos(movimientoId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el movimiento: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveDestinos(String movimientoId) async {
    await _supabase
        .from('mov_destino_provincia')
        .delete()
        .eq('idmovimiento', movimientoId);
    await _supabase
        .from('mov_destino_lima')
        .delete()
        .eq('idmovimiento', movimientoId);
    if (_esProvincia) {
      final String dirProvId = _selectedProvinciaDireccionId!;
      await _supabase.from('mov_destino_provincia').insert(
        <String, dynamic>{
          'idmovimiento': movimientoId,
          'iddir_provincia': dirProvId,
        },
      );
    } else {
      final String direccionId = _selectedDireccionId!;
      await _supabase.from('mov_destino_lima').insert(
        <String, dynamic>{
          'idmovimiento': movimientoId,
          'iddireccion': direccionId,
          'idnumrecibe': _selectedContactoId,
        },
      );
    }
  }

  void _showMissingClienteMessage() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Primero selecciona o crea un cliente.'),
      ),
    );
  }

  Future<void> _openDireccionClienteForm() async {
    final String? clienteId = _clienteId;
    if (clienteId == null) {
      _showMissingClienteMessage();
      return;
    }
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => DireccionFormView(clienteId: clienteId),
      ),
    );
    if (newId != null) {
      await _loadClienteCatalogos();
      setState(() {
        _selectedDireccionId = newId;
      });
    }
  }

  Future<void> _openContactoClienteForm() async {
    final String? clienteId = _clienteId;
    if (clienteId == null) {
      _showMissingClienteMessage();
      return;
    }
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => NumRecibeFormView(clienteId: clienteId),
      ),
    );
    if (newId != null) {
      await _loadClienteCatalogos();
      setState(() {
        _selectedContactoId = newId;
      });
    }
  }

  Future<void> _openDestinoProvinciaForm() async {
    final String? clienteId = _clienteId;
    if (clienteId == null) {
      _showMissingClienteMessage();
      return;
    }
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => DireccionProvinciaFormView(clienteId: clienteId),
      ),
    );
    if (newId != null) {
      await _loadClienteCatalogos();
      setState(() {
        _selectedProvinciaDireccionId = newId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar movimiento' : 'Registrar movimiento',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      contentPadding: EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_isLoadingBases)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedBaseId,
                decoration: const InputDecoration(
                  labelText: 'Base logística',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String>>[
                  ..._bases.map(
                    (LogisticaBase base) => DropdownMenuItem<String>(
                      value: base.id,
                      child: Text(base.nombre),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: _newBaseValue,
                    child: Text('➕ Agregar nueva base'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == _newBaseValue) {
                    _openNuevaBase();
                    return;
                  }
                  setState(() {
                    _selectedBaseId = value;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una base';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _openNuevaBase,
                child: const Text('Nueva base'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('¿Provincia?'),
              value: _esProvincia,
              onChanged: (bool value) {
                setState(() {
                  _esProvincia = value;
                  if (value) {
                    _selectedDireccionId = null;
                    _selectedContactoId = null;
                  } else {
                    _selectedProvinciaDireccionId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            if (_esProvincia) _buildProvinciaFields() else _buildLimaFields(),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectFecha,
                    child: Text('Fecha: ${_formatFecha()}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectHora,
                    child: Text('Hora: ${_hora.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoadingProductos)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Detalle del movimiento',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _openDetalleForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isCompletingPedido ||
                                    !_shouldShowCompletarPedidoButton
                                ? null
                                : _completarPedidoAutomaticamente,
                            icon: _isCompletingPedido
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.playlist_add_check),
                            label: Text(
                              _isCompletingPedido
                                  ? 'Completando...'
                                  : _isLoadingPendientes
                                      ? 'Calculando...'
                                      : _hasProductosPedido
                                          ? (_shouldShowCompletarPedidoButton
                                              ? 'Completar pedido'
                                              : 'Sin pendientes')
                                          : 'Sin productos',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isLoadingPendientes)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_detalles.isEmpty)
                    const Text('Sin productos agregados.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _detalles.length,
                      itemBuilder: (BuildContext context, int index) {
                        final DetalleMovimiento detalle = _detalles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(_productoNombre(detalle)),
                            subtitle: Text(
                              'Cantidad: ${detalle.cantidad.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _openDetalleForm(
                                    detalle: detalle,
                                    index: index,
                                  ),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _removeDetalle(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLimaFields() {
    final bool hasDirecciones = _clienteDirecciones.isNotEmpty;
    final bool hasContactos = _clienteContactos.isNotEmpty;
    final List<Widget> children = <Widget>[];
    if (_isLoadingClienteData) {
      children.add(const LinearProgressIndicator());
      children.add(const SizedBox(height: 12));
    }
    children.add(
      DropdownButtonFormField<String?>(
        value: _selectedDireccionId,
        decoration: const InputDecoration(
          labelText: 'Dirección de entrega',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              hasDirecciones
                  ? 'Selecciona una dirección'
                  : (_clienteId == null
                      ? 'Selecciona primero un cliente'
                      : 'Sin direcciones guardadas'),
            ),
          ),
          ..._clienteDirecciones.map(
            (_ClienteDireccion dir) => DropdownMenuItem<String?>(
              value: dir.id,
              child: Text(
                dir.referencia == null || dir.referencia!.trim().isEmpty
                    ? dir.direccion
                    : '${dir.direccion} · ${dir.referencia}',
              ),
            ),
          ),
          if (_clienteId != null)
            const DropdownMenuItem<String?>(
              value: '__new__',
              child: Text('➕ Agregar dirección'),
            ),
        ],
        onChanged: (String? value) {
          if (value == '__new__') {
            _openDireccionClienteForm();
            return;
          }
          setState(() {
            _selectedDireccionId = value;
          });
        },
      ),
    );
    children.add(const SizedBox(height: 16));
    children.add(
      DropdownButtonFormField<String?>(
        value: _selectedContactoId,
        decoration: const InputDecoration(
          labelText: 'Número de contacto',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              hasContactos
                  ? 'Selecciona un número'
                  : (_clienteId == null
                      ? 'Selecciona primero un cliente'
                      : 'Sin números guardados'),
            ),
          ),
          ..._clienteContactos.map(
            (_ClienteContacto contacto) => DropdownMenuItem<String?>(
              value: contacto.id,
              child: Text(contacto.display),
            ),
          ),
          if (_clienteId != null)
            const DropdownMenuItem<String?>(
              value: '__new__',
              child: Text('➕ Agregar número'),
            ),
        ],
        onChanged: (String? value) {
          if (value == '__new__') {
            _openContactoClienteForm();
            return;
          }
          setState(() {
            _selectedContactoId = value;
          });
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildProvinciaFields() {
    final List<Widget> children = <Widget>[];
    if (_isLoadingClienteData) {
      children.add(const LinearProgressIndicator());
      children.add(const SizedBox(height: 12));
    }
    children.add(
      DropdownButtonFormField<String?>(
        value: _selectedProvinciaDireccionId,
        decoration: const InputDecoration(
          labelText: 'Destino (provincia)',
          border: OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              _clienteDireccionesProvincia.isNotEmpty
                  ? 'Selecciona un destino'
                  : (_clienteId == null
                      ? 'Selecciona primero un cliente'
                      : 'Sin destinos guardados'),
            ),
          ),
          ..._clienteDireccionesProvincia.map(
            (_ClienteDireccionProvincia dir) => DropdownMenuItem<String?>(
              value: dir.id,
              child: Text(dir.display),
            ),
          ),
          if (_clienteId != null)
            const DropdownMenuItem<String?>(
              value: '__new__',
              child: Text('➕ Agregar destino'),
            ),
        ],
        onChanged: (String? value) {
          if (value == '__new__') {
            _openDestinoProvinciaForm();
            return;
          }
          setState(() {
            _selectedProvinciaDireccionId = value;
          });
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _ClienteDireccion {
  const _ClienteDireccion({
    required this.id,
    required this.direccion,
    this.referencia,
  });

  final String id;
  final String direccion;
  final String? referencia;
}

class _ClienteContacto {
  const _ClienteContacto({
    required this.id,
    required this.numero,
    this.nombre,
  });

  final String id;
  final String numero;
  final String? nombre;

  String get display =>
      nombre == null || nombre!.trim().isEmpty ? numero : '$numero · $nombre';
}

class _ClienteDireccionProvincia {
  const _ClienteDireccionProvincia({
    required this.id,
    required this.destino,
    this.destinatario,
    this.dni,
  });

  final String id;
  final String destino;
  final String? destinatario;
  final String? dni;

  String get display {
    final StringBuffer buffer = StringBuffer(destino);
    if (destinatario != null && destinatario!.trim().isNotEmpty) {
      buffer.write(' · $destinatario');
    }
    return buffer.toString();
  }
}

class _ProductoPedidoInfo {
  const _ProductoPedidoInfo({
    required this.idProducto,
    required this.nombre,
    required this.solicitado,
    required this.enviado,
  });

  final String idProducto;
  final String nombre;
  final double solicitado;
  final double enviado;

  double get faltante {
    final double value = solicitado - enviado;
    return value < 0 ? 0 : value;
  }
}
