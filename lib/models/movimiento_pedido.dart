import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class MovimientoPedido {
  const MovimientoPedido({
    required this.id,
    required this.idpedido,
    required this.idbase,
    required this.esProvincia,
    required this.fecharegistro,
    this.baseNombre,
    this.estadoTexto,
  });

  final String id;
  final String idpedido;
  final String idbase;
  final String? baseNombre;
  final bool esProvincia;
  final DateTime fecharegistro;
  final String? estadoTexto;

  factory MovimientoPedido.fromJson(Map<String, dynamic> json) {
    final dynamic fechaValue = json['fecharegistro'];
    final Map<String, dynamic>? base = json['bases'] as Map<String, dynamic>?;
    final Map<String, dynamic>? estadoView =
        json['v_movimiento_estado'] as Map<String, dynamic>?;
    return MovimientoPedido(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      idbase: json['idbase'] as String? ?? '',
      esProvincia: json['es_provincia'] as bool? ?? false,
      fecharegistro: fechaValue is String
          ? DateTime.parse(fechaValue)
          : (fechaValue is DateTime ? fechaValue : DateTime.now()),
      baseNombre: base?['nombre'] as String?,
      estadoTexto: estadoView?['estado_texto'] as String?,
    );
  }

  MovimientoPedido copyWith({
    String? id,
    String? idpedido,
    String? idbase,
    bool? esProvincia,
    DateTime? fecharegistro,
  }) {
    return MovimientoPedido(
      id: id ?? this.id,
      idpedido: idpedido ?? this.idpedido,
      idbase: idbase ?? this.idbase,
      esProvincia: esProvincia ?? this.esProvincia,
      fecharegistro: fecharegistro ?? this.fecharegistro,
      baseNombre: baseNombre, // Not copied
      estadoTexto: estadoTexto, // Not copied
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idpedido': idpedido,
      'idbase': idbase.isEmpty ? null : idbase,
      'es_provincia': esProvincia,
      'fecharegistro': fecharegistro.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idbase': idbase.isEmpty ? null : idbase,
      'es_provincia': esProvincia,
      'fecharegistro': fecharegistro.toIso8601String(),
    };
  }

  static Future<List<MovimientoPedido>> getByPedido(String pedidoId) async {
    final List<dynamic> movimientos = await _supabase
        .from('movimientopedidos')
        .select('*, bases(nombre)')
        .eq('idpedido', pedidoId)
        .order('fecharegistro', ascending: false);

    if (movimientos.isEmpty) {
      return <MovimientoPedido>[];
    }

    final List<String> movimientoIds = movimientos
        .map(
          (dynamic item) => (item as Map<String, dynamic>)['id'] as String,
        )
        .toList(growable: false);

    final List<dynamic> estados = await _supabase
        .from('v_movimiento_estado')
        .select('id, estado_texto')
        .inFilter('id', movimientoIds);

    final Map<String, Map<String, dynamic>> estadosPorId =
        <String, Map<String, dynamic>>{
      for (final dynamic estado in estados)
        (estado as Map<String, dynamic>)['id'] as String:
            Map<String, dynamic>.from(estado),
    };

    return movimientos.map((dynamic item) {
      final Map<String, dynamic> movimiento =
          Map<String, dynamic>.from(item as Map<String, dynamic>);
      final String movimientoId = movimiento['id'] as String;
      final Map<String, dynamic>? estado = estadosPorId[movimientoId];
      if (estado != null) {
        movimiento['v_movimiento_estado'] = estado;
      }
      return MovimientoPedido.fromJson(movimiento);
    }).toList(growable: false);
  }

  static Future<String> insert(MovimientoPedido movimiento) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('movimientopedidos')
        .insert(movimiento.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('movimientopedidos').delete().eq('id', id);
  }

  static Future<void> update(MovimientoPedido movimiento) async {
    await _supabase
        .from('movimientopedidos')
        .update(movimiento.toUpdateJson())
        .eq('id', movimiento.id);
  }

  static Future<MovimientoPedido?> getById(String id) async {
    final Map<String, dynamic>? movimiento = await _supabase
        .from('movimientopedidos')
        .select('*, bases(nombre)')
        .eq('id', id)
        .maybeSingle();
    if (movimiento == null) {
      return null;
    }
    final Map<String, dynamic>? estado = await _supabase
        .from('v_movimiento_estado')
        .select('estado_texto')
        .eq('id', id)
        .maybeSingle();
    if (estado != null) {
      movimiento['v_movimiento_estado'] = estado;
    }
    return MovimientoPedido.fromJson(movimiento);
  }
}
