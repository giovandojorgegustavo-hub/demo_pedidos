import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class LogisticaBase {
  const LogisticaBase({
    required this.id,
    required this.nombre,
  });

  final String id;
  final String nombre;

  factory LogisticaBase.fromJson(Map<String, dynamic> json) {
    return LogisticaBase(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  static Future<List<LogisticaBase>> getBases() async {
    final List<dynamic> data =
        await _supabase.from('bases').select('id,nombre').order('nombre');
    return data
        .map(
          (dynamic item) =>
              LogisticaBase.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<String> insert(LogisticaBase base) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('bases')
        .insert(<String, dynamic>{'nombre': base.nombre})
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(LogisticaBase base) async {
    await _supabase
        .from('bases')
        .update(<String, dynamic>{'nombre': base.nombre})
        .eq('id', base.id);
  }

  static Future<LogisticaBase?> getById(String id) async {
    final Map<String, dynamic>? row = await _supabase
        .from('bases')
        .select('id,nombre')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return LogisticaBase.fromJson(row);
  }
}
