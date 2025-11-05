import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.canal,
    this.referidoPor,
  });

  final String id;
  final String nombre;
  final String numero;
  final String canal;
  final String? referidoPor;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      numero: json['numero'] as String,
      canal: json['canal'] as String? ?? 'telegram',
      referidoPor: json['referido_por'] as String?,
    );
  }

  Cliente copyWith({
    String? id,
    String? nombre,
    String? numero,
    String? canal,
    String? referidoPor,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numero: numero ?? this.numero,
      canal: canal ?? this.canal,
      referidoPor: referidoPor ?? this.referidoPor,
    );
  }

  static Future<List<Cliente>> getClientes() async {
    final List<dynamic> data = await _supabase
        .from('clientes')
        .select('id,nombre,numero,canal,referido_por')
        .order('nombre', ascending: true);
    return data
        .map((dynamic item) => Cliente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<String> insert(Cliente cliente) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('clientes')
        .insert(<String, dynamic>{
          'nombre': cliente.nombre,
          'numero': cliente.numero,
          'canal': cliente.canal,
          'referido_por': cliente.referidoPor,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }
}
