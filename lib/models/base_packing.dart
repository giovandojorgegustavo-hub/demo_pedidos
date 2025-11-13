import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class BasePacking {
  const BasePacking({
    required this.id,
    required this.idBase,
    required this.nombre,
    this.activo = true,
  });

  final String id;
  final String idBase;
  final String nombre;
  final bool activo;

  factory BasePacking.fromJson(Map<String, dynamic> json) {
    return BasePacking(
      id: json['id'] as String,
      idBase: json['idbase'] as String,
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool? ?? true,
    );
  }

  static Future<List<BasePacking>> fetchByBase(String baseId) async {
    final List<dynamic> rows = await _supabase
        .from('base_packings')
        .select('id,idbase,nombre,activo')
        .eq('idbase', baseId)
        .order('nombre');
    return rows
        .map((dynamic row) => BasePacking.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create({
    required String baseId,
    required String nombre,
    bool activo = true,
  }) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('base_packings')
        .insert(<String, dynamic>{
          'idbase': baseId,
          'nombre': nombre,
          'activo': activo,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String nombre,
    required bool activo,
  }) async {
    await _supabase
        .from('base_packings')
        .update(<String, dynamic>{
          'nombre': nombre,
          'activo': activo,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('base_packings').delete().eq('id', id);
  }
}
