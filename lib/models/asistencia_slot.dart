import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AsistenciaSlot {
  const AsistenciaSlot({
    required this.id,
    required this.nombre,
    required this.hora,
    this.descripcion,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final String hora; // formato HH:mm:ss
  final String? descripcion;
  final bool activo;

  factory AsistenciaSlot.fromJson(Map<String, dynamic> json) {
    return AsistenciaSlot(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      hora: json['hora'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  static Future<List<AsistenciaSlot>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('asistencias_slots')
        .select('id,nombre,hora,descripcion,activo')
        .order('hora');
    return rows
        .map((dynamic row) =>
            AsistenciaSlot.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create({
    required String nombre,
    required String hora,
    String? descripcion,
    bool activo = true,
  }) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('asistencias_slots')
        .insert(<String, dynamic>{
          'nombre': nombre,
          'hora': hora,
          'descripcion': descripcion,
          'activo': activo,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String nombre,
    required String hora,
    String? descripcion,
    required bool activo,
  }) async {
    await _supabase
        .from('asistencias_slots')
        .update(<String, dynamic>{
          'nombre': nombre,
          'hora': hora,
          'descripcion': descripcion,
          'activo': activo,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('asistencias_slots').delete().eq('id', id);
  }
}
