import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    this.categoriaId,
    this.categoriaNombre,
  });

  final String id;
  final String nombre;
  final String? categoriaId;
  final String? categoriaNombre;

  factory Producto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? categoria =
        json['categorias'] as Map<String, dynamic>?;
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoriaId: json['idcategoria'] as String?,
      categoriaNombre:
          categoria == null ? null : categoria['nombre'] as String?,
    );
  }

  static Future<List<Producto>> getProductos() async {
    final List<dynamic> data = await _supabase
        .from('productos')
        .select('id,nombre,idcategoria,categorias(nombre)')
        .order('nombre', ascending: true);
    return data
        .map((dynamic item) => Producto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<String> insert(Producto producto) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('productos')
        .insert(<String, dynamic>{
          'nombre': producto.nombre,
          'idcategoria': producto.categoriaId,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }
}
