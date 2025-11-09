import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Proveedor {
  const Proveedor({
    required this.id,
    required this.nombre,
    required this.numero,
    this.registradoAt,
    this.editadoAt,
  });

  final String id;
  final String nombre;
  final String numero;
  final DateTime? registradoAt;
  final DateTime? editadoAt;

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
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

  Proveedor copyWith({
    String? id,
    String? nombre,
    String? numero,
    DateTime? registradoAt,
    DateTime? editadoAt,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numero: numero ?? this.numero,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'numero': numero,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'numero': numero,
      'editado_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Proveedor>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('proveedores')
        .select('id,nombre,numero,registrado_at,editado_at')
        .order('nombre');
    return rows
        .map((dynamic row) =>
            Proveedor.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(Proveedor proveedor) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('proveedores')
        .insert(proveedor.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Proveedor proveedor) async {
    await _supabase
        .from('proveedores')
        .update(proveedor.toUpdateJson())
        .eq('id', proveedor.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('proveedores').delete().eq('id', id);
  }

  static Future<bool> numeroExists(
    String numero, {
    String? excludeId,
  }) async {
    final PostgrestFilterBuilder query = _supabase
        .from('proveedores')
        .select('id')
        .eq('numero', numero)
      ..limit(1);
    if (excludeId != null && excludeId.isNotEmpty) {
      query.neq('id', excludeId);
    }
    final Map<String, dynamic>? existing = await query.maybeSingle();
    return existing != null;
  }
}
