import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
  });

  final String id;
  final String nombre;
  final double precio;

  factory Producto.fromJson(Map<String, dynamic> json) {
    final dynamic precioValue = json['precio'];
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: precioValue is num
          ? precioValue.toDouble()
          : double.tryParse('$precioValue') ?? 0,
    );
  }

  static Future<List<Producto>> getProductos() async {
    final List<dynamic> data = await _supabase
        .from('productos')
        .select('id,nombre,precio')
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
          'precio': producto.precio,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }
}
