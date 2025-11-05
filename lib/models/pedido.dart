import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Pedido {
  const Pedido({
    required this.id,
    required this.idcliente,
    required this.fechapedido,
    this.observacion,
    this.clienteNombre,
    this.estadoPago,
    this.estadoEntrega,
    this.estadoGeneral,
  });

  final String id;
  final String idcliente;
  final DateTime fechapedido;
  final String? observacion;
  final String? clienteNombre;
  final String? estadoPago;
  final String? estadoEntrega;
  final String? estadoGeneral;

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final dynamic fechaValue =
        json['fechapedido'] ?? json['created_at'] ?? json['fecharegistro'];
    final Map<String, dynamic>? clienteJson =
        json['clientes'] as Map<String, dynamic>?;
    return Pedido(
      id: json['id'] as String,
      idcliente: json['idcliente'] as String,
      fechapedido: fechaValue is String
          ? DateTime.parse(fechaValue)
          : (fechaValue is DateTime ? fechaValue : DateTime.now()),
      observacion: json['observacion'] as String?,
      clienteNombre:
          json['cliente_nombre'] as String? ?? clienteJson?['nombre'] as String?,
      estadoPago: json['estado_pago'] as String?,
      estadoEntrega: json['estado_entrega'] as String?,
      estadoGeneral: json['estado_general'] as String?,
    );
  }

  Pedido copyWith({
    String? id,
    String? idcliente,
    DateTime? fechapedido,
    String? observacion,
    String? clienteNombre,
    String? estadoPago,
    String? estadoEntrega,
    String? estadoGeneral,
  }) {
    return Pedido(
      id: id ?? this.id,
      idcliente: idcliente ?? this.idcliente,
      fechapedido: fechapedido ?? this.fechapedido,
      observacion: observacion ?? this.observacion,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      estadoPago: estadoPago ?? this.estadoPago,
      estadoEntrega: estadoEntrega ?? this.estadoEntrega,
      estadoGeneral: estadoGeneral ?? this.estadoGeneral,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idcliente': idcliente,
      'created_at': fechapedido.toIso8601String(),
      'observacion': observacion,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idcliente': idcliente,
      'created_at': fechapedido.toIso8601String(),
      'observacion': observacion,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Pedido>> getPedidos() async {
    final List<dynamic> data = await _supabase
        .from('pedidos')
        .select('id,idcliente,created_at,observacion,clientes!inner(nombre)')
        .order('created_at', ascending: false);

    final List<dynamic> estadosPagoRaw = await _supabase
        .from('v_pedido_estado_pago')
        .select('pedido_id,estado_pago');
    final List<dynamic> estadosEntregaRaw = await _supabase
        .from('v_pedido_estado_envio_global')
        .select('pedido_id,estado_entrega');
    final List<dynamic> estadosGeneralesRaw = await _supabase
        .from('v_pedido_estado_general')
        .select('pedido_id,estado_general');

    final Map<String, String> estadoPagoMap = <String, String>{
      for (final dynamic item in estadosPagoRaw)
        (item as Map<String, dynamic>)['pedido_id'] as String:
            (item)['estado_pago'] as String
    };
    final Map<String, String> estadoEntregaMap = <String, String>{
      for (final dynamic item in estadosEntregaRaw)
        (item as Map<String, dynamic>)['pedido_id'] as String:
            (item)['estado_entrega'] as String
    };
    final Map<String, String> estadoGeneralMap = <String, String>{
      for (final dynamic item in estadosGeneralesRaw)
        (item as Map<String, dynamic>)['pedido_id'] as String:
            (item)['estado_general'] as String
    };

    return data
        .map((dynamic item) => Pedido.fromJson(item as Map<String, dynamic>))
        .map(
          (Pedido pedido) => pedido.copyWith(
            estadoPago: estadoPagoMap[pedido.id],
            estadoEntrega: estadoEntregaMap[pedido.id],
            estadoGeneral: estadoGeneralMap[pedido.id],
          ),
        )
        .toList();
  }

  static Future<Pedido?> getById(String id) async {
    final Map<String, dynamic>? data = await _supabase
        .from('pedidos')
        .select(
            'id,idcliente,created_at,observacion,clientes!inner(nombre)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    final Pedido base = Pedido.fromJson(data);

    final Map<String, dynamic>? estadoPago = await _supabase
        .from('v_pedido_estado_pago')
        .select('estado_pago')
        .eq('pedido_id', id)
        .maybeSingle();
    final Map<String, dynamic>? estadoEntrega = await _supabase
        .from('v_pedido_estado_envio_global')
        .select('estado_entrega')
        .eq('pedido_id', id)
        .maybeSingle();
    final Map<String, dynamic>? estadoGeneral = await _supabase
        .from('v_pedido_estado_general')
        .select('estado_general')
        .eq('pedido_id', id)
        .maybeSingle();

    return base.copyWith(
      estadoPago: estadoPago?['estado_pago'] as String?,
      estadoEntrega: estadoEntrega?['estado_entrega'] as String?,
      estadoGeneral: estadoGeneral?['estado_general'] as String?,
    );
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
