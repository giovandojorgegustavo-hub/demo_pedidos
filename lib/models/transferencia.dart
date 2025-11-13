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

class Transferencia {
  const Transferencia({
    required this.id,
    required this.idbaseOrigen,
    required this.idbaseDestino,
    this.observacion,
    this.registradoAt,
  });

  final String id;
  final String idbaseOrigen;
  final String idbaseDestino;
  final String? observacion;
  final DateTime? registradoAt;

  factory Transferencia.fromJson(Map<String, dynamic> json) {
    return Transferencia(
      id: json['id'] as String,
      idbaseOrigen: json['idbase_origen'] as String,
      idbaseDestino: json['idbase_destino'] as String,
      observacion: json['observacion'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
    );
  }

  static Future<List<Transferencia>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('transferencias')
        .select('id,idbase_origen,idbase_destino,observacion,registrado_at')
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) =>
            Transferencia.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(Transferencia transferencia) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'idbase_origen': transferencia.idbaseOrigen,
      'idbase_destino': transferencia.idbaseDestino,
      'observacion': transferencia.observacion,
    };
    final Map<String, dynamic> inserted = await _supabase
        .from('transferencias')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Transferencia transferencia) async {
    await _supabase
        .from('transferencias')
        .update(<String, dynamic>{
          'idbase_origen': transferencia.idbaseOrigen,
          'idbase_destino': transferencia.idbaseDestino,
          'observacion': transferencia.observacion,
        })
        .eq('id', transferencia.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('transferencias').delete().eq('id', id);
  }
}
