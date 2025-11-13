import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
  });

  final String id;
  final String nombre;

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  static Future<List<Categoria>> getCategorias() async {
    final List<dynamic> rows =
        await _supabase.from('categorias').select('id,nombre').order('nombre');
    return rows
        .map((dynamic row) => Categoria.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create(String nombre) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('categorias')
        .insert(<String, dynamic>{'nombre': nombre})
        .select('id')
        .single();
    return inserted['id'] as String;
  }
}
