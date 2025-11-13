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

class Ajuste {
  const Ajuste({
    required this.id,
    required this.idbase,
    this.observacion,
    this.registradoAt,
  });

  final String id;
  final String idbase;
  final String? observacion;
  final DateTime? registradoAt;

  factory Ajuste.fromJson(Map<String, dynamic> json) {
    return Ajuste(
      id: json['id'] as String,
      idbase: json['idbase'] as String,
      observacion: json['observacion'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
    );
  }

  static Future<List<Ajuste>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('ajustes')
        .select('id,idbase,observacion,registrado_at')
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => Ajuste.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(Ajuste ajuste) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'idbase': ajuste.idbase,
      'observacion': ajuste.observacion,
    };
    final Map<String, dynamic> inserted = await _supabase
        .from('ajustes')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Ajuste ajuste) async {
    await _supabase
        .from('ajustes')
        .update(<String, dynamic>{
          'idbase': ajuste.idbase,
          'observacion': ajuste.observacion,
        })
        .eq('id', ajuste.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('ajustes').delete().eq('id', id);
  }

  static Future<Ajuste?> fetchById(String id) async {
    final Map<String, dynamic>? row = await _supabase
        .from('ajustes')
        .select('id,idbase,observacion,registrado_at')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Ajuste.fromJson(row);
  }
}
