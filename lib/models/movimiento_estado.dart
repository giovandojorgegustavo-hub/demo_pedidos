import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class MovimientoEstado {
  const MovimientoEstado({
    required this.id,
    required this.idpedido,
    required this.idcliente,
    required this.estadoTexto,
    required this.estadoCodigo,
    this.idbase,
    this.asignadoAt,
    this.llegadaAt,
  });

  final String id;
  final String idpedido;
  final String idcliente;
  final String estadoTexto;
  final int estadoCodigo;
  final String? idbase;
  final DateTime? asignadoAt;
  final DateTime? llegadaAt;

  factory MovimientoEstado.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return MovimientoEstado(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      idcliente: json['idcliente'] as String,
      estadoTexto: json['estado_texto'] as String? ?? 'desconocido',
      estadoCodigo: json['estado'] as int? ?? 0,
      idbase: json['idbase'] as String?,
      asignadoAt: parseDate(json['asignado_at']),
      llegadaAt: parseDate(json['llegada_at']),
    );
  }

  static Future<List<MovimientoEstado>> fetchAll() async {
    final List<dynamic> data = await _supabase
        .from('v_movimiento_estado')
        .select(
          'id,idpedido,idcliente,idbase,estado,estado_texto,asignado_at,llegada_at',
        )
        .order('estado')
        .order('asignado_at', ascending: false);
    return data
        .map(
          (dynamic item) =>
              MovimientoEstado.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
