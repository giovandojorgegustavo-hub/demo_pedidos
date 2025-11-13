import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AsistenciaAsignacion {
  const AsistenciaAsignacion({
    required this.id,
    required this.idbase,
    required this.baseNombre,
    required this.idslot,
    required this.slotNombre,
    required this.slotHora,
    required this.diasSemana,
    required this.activo,
  });

  final String id;
  final String idbase;
  final String baseNombre;
  final String idslot;
  final String slotNombre;
  final String slotHora;
  final List<String> diasSemana;
  final bool activo;

  factory AsistenciaAsignacion.fromJson(Map<String, dynamic> json) {
    return AsistenciaAsignacion(
      id: json['id'] as String,
      idbase: json['idbase'] as String,
      baseNombre: json['base_nombre'] as String,
      idslot: json['idslot'] as String,
      slotNombre: json['slot_nombre'] as String,
      slotHora: json['slot_hora'] as String,
      diasSemana: (json['dias_semana'] as List<dynamic>)
          .map((dynamic dia) => dia.toString())
          .toList(),
      activo: json['activo'] as bool? ?? true,
    );
  }

  static Future<List<AsistenciaAsignacion>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('v_asistencias_base_slots')
        .select(
          'id,idbase,base_nombre,idslot,slot_nombre,slot_hora,dias_semana,activo',
        )
        .order('base_nombre')
        .order('slot_hora');
    return rows
        .map(
          (dynamic row) =>
              AsistenciaAsignacion.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<String> create({
    required String idbase,
    required String idslot,
    required List<String> diasSemana,
    bool activo = true,
  }) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('asistencias_base_slots')
        .insert(<String, dynamic>{
          'idbase': idbase,
          'idslot': idslot,
          'dias_semana': diasSemana,
          'activo': activo,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String idbase,
    required String idslot,
    required List<String> diasSemana,
    required bool activo,
  }) async {
    await _supabase
        .from('asistencias_base_slots')
        .update(<String, dynamic>{
          'idbase': idbase,
          'idslot': idslot,
          'dias_semana': diasSemana,
          'activo': activo,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('asistencias_base_slots').delete().eq('id', id);
  }
}
