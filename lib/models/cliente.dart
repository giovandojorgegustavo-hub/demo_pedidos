import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.canal,
    this.referidoPor,
    this.registradoAt,
    this.editadoAt,
    this.registradoPor,
    this.editadoPor,
  });

  final String id;
  final String nombre;
  final String numero;
  final String canal;
  final String? referidoPor;
  final DateTime? registradoAt;
  final DateTime? editadoAt;
  final String? registradoPor;
  final String? editadoPor;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      numero: json['numero'] as String,
      canal: json['canal'] as String? ?? 'telegram',
      referidoPor: json['referido_por'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
      registradoPor: json['registrado_por'] as String?,
      editadoPor: json['editado_por'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Cliente copyWith({
    String? id,
    String? nombre,
    String? numero,
    String? canal,
    String? referidoPor,
    DateTime? registradoAt,
    DateTime? editadoAt,
    String? registradoPor,
    String? editadoPor,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numero: numero ?? this.numero,
      canal: canal ?? this.canal,
      referidoPor: referidoPor ?? this.referidoPor,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
      registradoPor: registradoPor ?? this.registradoPor,
      editadoPor: editadoPor ?? this.editadoPor,
    );
  }

  static Future<List<Cliente>> getClientes() async {
    final List<dynamic> data = await _supabase
        .from('clientes')
        .select(
          'id,nombre,numero,canal,referido_por,registrado_at,editado_at,registrado_por,editado_por',
        )
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
          if (cliente.registradoAt != null)
            'registrado_at': cliente.registradoAt!.toIso8601String(),
          if (cliente.registradoPor != null)
            'registrado_por': cliente.registradoPor,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Cliente cliente) async {
    await _supabase
        .from('clientes')
        .update(<String, dynamic>{
          'nombre': cliente.nombre,
          'numero': cliente.numero,
          'canal': cliente.canal,
          'referido_por': cliente.referidoPor,
          if (cliente.registradoAt != null)
            'registrado_at': cliente.registradoAt!.toIso8601String(),
          if (cliente.registradoPor != null)
            'registrado_por': cliente.registradoPor,
          if (cliente.editadoAt != null)
            'editado_at': cliente.editadoAt!.toIso8601String(),
          if (cliente.editadoPor != null)
            'editado_por': cliente.editadoPor,
        })
        .eq('id', cliente.id);
  }

  static Future<bool> numeroExists(String numero) async {
    final Map<String, dynamic>? existing = await _supabase
        .from('clientes')
        .select('id')
        .eq('numero', numero)
        .maybeSingle();
    return existing != null;
  }
}
