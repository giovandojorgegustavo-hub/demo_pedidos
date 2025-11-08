import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Pedido {
  const Pedido({
    required this.id,
    required this.idcliente,
    required this.fechapedido,
    this.observacion,
    this.clienteNombre,
    this.clienteNumero,
    this.estadoPago,
    this.estadoEntrega,
    this.estadoGeneral,
    this.registradoAt,
    this.editadoAt,
    this.registradoPor,
    this.editadoPor,
    this.registradoPorNombre,
    this.editadoPorNombre,
  });

  final String id;
  final String idcliente;
  final DateTime fechapedido;
  final String? observacion;
  final String? clienteNombre;
  final String? clienteNumero;
  final String? estadoPago;
  final String? estadoEntrega;
  final String? estadoGeneral;
  final DateTime? registradoAt;
  final DateTime? editadoAt;
  final String? registradoPor;
  final String? editadoPor;
  final String? registradoPorNombre;
  final String? editadoPorNombre;

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final dynamic fechaValue =
        json['fechapedido'] ?? json['registrado_at'] ?? json['created_at'];
    final Map<String, dynamic>? clienteJson =
        json['clientes'] as Map<String, dynamic>?;
    return Pedido(
      id: json['id'] as String,
      idcliente: json['idcliente'] as String,
      fechapedido: fechaValue is String
          ? DateTime.parse(fechaValue)
          : (fechaValue is DateTime ? fechaValue : DateTime.now()),
      observacion: json['observacion'] as String?,
      clienteNombre: json['cliente_nombre'] as String? ??
          clienteJson?['nombre'] as String?,
      clienteNumero: json['cliente_numero'] as String? ??
          clienteJson?['numero'] as String?,
      estadoPago: json['estado_pago'] as String?,
      estadoEntrega: json['estado_entrega'] as String?,
      estadoGeneral: json['estado_general'] as String?,
      registradoAt: _parseDateNullable(json['registrado_at']),
      editadoAt: _parseDateNullable(json['editado_at']),
      registradoPor: json['registrado_por'] as String?,
      editadoPor: json['editado_por'] as String?,
      registradoPorNombre: json['registrado_por_nombre'] as String?,
      editadoPorNombre: json['editado_por_nombre'] as String?,
    );
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Pedido copyWith({
    String? id,
    String? idcliente,
    DateTime? fechapedido,
    String? observacion,
    String? clienteNombre,
    String? clienteNumero,
    String? estadoPago,
    String? estadoEntrega,
    String? estadoGeneral,
    DateTime? registradoAt,
    DateTime? editadoAt,
    String? registradoPor,
    String? editadoPor,
    String? registradoPorNombre,
    String? editadoPorNombre,
  }) {
    return Pedido(
      id: id ?? this.id,
      idcliente: idcliente ?? this.idcliente,
      fechapedido: fechapedido ?? this.fechapedido,
      observacion: observacion ?? this.observacion,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteNumero: clienteNumero ?? this.clienteNumero,
      estadoPago: estadoPago ?? this.estadoPago,
      estadoEntrega: estadoEntrega ?? this.estadoEntrega,
      estadoGeneral: estadoGeneral ?? this.estadoGeneral,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
      registradoPor: registradoPor ?? this.registradoPor,
      editadoPor: editadoPor ?? this.editadoPor,
      registradoPorNombre: registradoPorNombre ?? this.registradoPorNombre,
      editadoPorNombre: editadoPorNombre ?? this.editadoPorNombre,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idcliente': idcliente,
      'registrado_at':
          (registradoAt ?? fechapedido).toIso8601String(),
      'observacion': observacion,
      if (registradoPor != null) 'registrado_por': registradoPor,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idcliente': idcliente,
      'registrado_at': (registradoAt ?? fechapedido).toIso8601String(),
      'observacion': observacion,
      if (registradoPor != null) 'registrado_por': registradoPor,
      'editado_at': (editadoAt ?? DateTime.now()).toIso8601String(),
      if (editadoPor != null) 'editado_por': editadoPor,
    };
  }

  static Future<List<Pedido>> getPedidos() async {
    final List<dynamic> data = await _supabase
        .from('v_pedido_vistageneral')
        .select(
          'id,fechapedido,observacion,idcliente,cliente_nombre,cliente_numero,estado_pago,estado_entrega,estado_general,registrado_at,editado_at,registrado_por,editado_por,registrado_por_nombre,editado_por_nombre',
        )
        .order('fechapedido', ascending: false);

    return data
        .map(
          (dynamic item) => Pedido.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<Pedido?> getById(String id) async {
    final Map<String, dynamic>? data = await _supabase
        .from('v_pedido_vistageneral')
        .select(
          'id,fechapedido,observacion,idcliente,cliente_nombre,cliente_numero,estado_pago,estado_entrega,estado_general,registrado_at,editado_at,registrado_por,editado_por,registrado_por_nombre,editado_por_nombre',
        )
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return Pedido.fromJson(data);
  }

  static Future<String> insert(Pedido pedido) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('pedidos')
        .insert(pedido.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Pedido pedido) async {
    await _supabase
        .from('pedidos')
        .update(pedido.toUpdateJson())
        .eq('id', pedido.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('pedidos').delete().eq('id', id);
  }
}
