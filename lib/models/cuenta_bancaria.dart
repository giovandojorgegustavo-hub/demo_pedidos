import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class CuentaBancaria {
  const CuentaBancaria({
    required this.id,
    required this.nombre,
    this.banco,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final String? banco;
  final bool activa;

  factory CuentaBancaria.fromJson(Map<String, dynamic> json) {
    return CuentaBancaria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      banco: json['banco'] as String?,
      activa: json['activa'] as bool? ?? true,
    );
  }

  static Future<List<CuentaBancaria>> getCuentas() async {
    final List<dynamic> data = await _supabase
        .from('cuentas_bancarias')
        .select('id,nombre,banco,activa')
        .eq('activa', true)
        .order('nombre');
    return data
        .map(
          (dynamic item) =>
              CuentaBancaria.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<List<CuentaBancaria>> getTodas() async {
    final List<dynamic> data = await _supabase
        .from('cuentas_bancarias')
        .select('id,nombre,banco,activa')
        .order('nombre');
    return data
        .map(
          (dynamic item) =>
              CuentaBancaria.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<String> insert({
    required String nombre,
    required String banco,
    bool activa = true,
  }) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('cuentas_bancarias')
        .insert(<String, dynamic>{
          'nombre': nombre,
          'banco': banco,
          'activa': activa,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> updateEstado({
    required String id,
    required bool activa,
  }) async {
    await _supabase
        .from('cuentas_bancarias')
        .update(<String, dynamic>{'activa': activa}).eq('id', id);
  }
}
