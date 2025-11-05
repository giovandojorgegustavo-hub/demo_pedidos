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
  });

  final String id;
  final String idpedido;
  final String? baseNombre;
  final String idbase;
  final bool esProvincia;
  final DateTime fecharegistro;

  factory MovimientoPedido.fromJson(Map<String, dynamic> json) {
    final dynamic fechaValue = json['fecharegistro'];
    final Map<String, dynamic>? base =
        json['bases'] as Map<String, dynamic>?;
    return MovimientoPedido(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      idbase: json['idbase'] as String? ?? '',
      esProvincia: json['es_provincia'] as bool? ?? false,
      fecharegistro: fechaValue is String
          ? DateTime.parse(fechaValue)
          : (fechaValue is DateTime ? fechaValue : DateTime.now()),
      baseNombre: base?['nombre'] as String?,
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
    final List<dynamic> data = await _supabase
        .from('movimientopedidos')
        .select(
          'id,idpedido,idbase,es_provincia,fecharegistro,bases(nombre)',
        )
        .eq('idpedido', pedidoId)
        .order('fecharegistro', ascending: false);
    return data
        .map(
          (dynamic item) =>
              MovimientoPedido.fromJson(item as Map<String, dynamic>),
        )
        .toList();
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
}
