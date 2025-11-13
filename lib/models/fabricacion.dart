import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

DateTime? _parseDate(dynamic value) {
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

class Fabricacion {
  const Fabricacion({
    required this.id,
    required this.idbase,
    this.observacion,
    this.registradoAt,
  });

  final String id;
  final String idbase;
  final String? observacion;
  final DateTime? registradoAt;

  factory Fabricacion.fromJson(Map<String, dynamic> json) {
    return Fabricacion(
      id: json['id'] as String,
      idbase: json['idbase'] as String,
      observacion: json['observacion'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
    );
  }

  static Future<List<Fabricacion>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('fabricaciones')
        .select('id,idbase,observacion,registrado_at')
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => Fabricacion.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(Fabricacion fabricacion) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'idbase': fabricacion.idbase,
      'observacion': fabricacion.observacion,
    };
    final Map<String, dynamic> inserted = await _supabase
        .from('fabricaciones')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Fabricacion fabricacion) async {
    await _supabase
        .from('fabricaciones')
        .update(<String, dynamic>{
          'idbase': fabricacion.idbase,
          'observacion': fabricacion.observacion,
        })
        .eq('id', fabricacion.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('fabricaciones').delete().eq('id', id);
  }
}
