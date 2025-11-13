import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/models/logistica_base.dart';

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

String? _coerceString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    final dynamic nombre = value['nombre'];
    if (nombre is String) {
      return nombre;
    }
  }
  return value.toString();
}

class CompraMovimiento {
  const CompraMovimiento({
    required this.id,
    required this.idcompra,
    required this.idbase,
    this.observacion,
    this.baseNombre,
    this.registradoAt,
    this.editadoAt,
  });

  final String id;
  final String idcompra;
  final String idbase;
  final String? observacion;
  final String? baseNombre;
  final DateTime? registradoAt;
  final DateTime? editadoAt;

  factory CompraMovimiento.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? baseJson =
        json['bases'] as Map<String, dynamic>?;
    return CompraMovimiento(
      id: json['id'] as String,
      idcompra: json['idcompra'] as String,
      idbase: json['idbase'] as String,
      observacion: json['observacion'] as String?,
      baseNombre: _coerceString(json['base_nombre']) ??
          _coerceString(baseJson) ??
          '-',
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idcompra': idcompra,
      'idbase': idbase,
      'observacion': observacion,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idbase': idbase,
      'observacion': observacion,
      'editado_at': DateTime.now().toIso8601String(),
    };
  }

  CompraMovimiento copyWith({
    String? id,
    String? idcompra,
    String? idbase,
    String? observacion,
    String? baseNombre,
    DateTime? registradoAt,
    DateTime? editadoAt,
  }) {
    return CompraMovimiento(
      id: id ?? this.id,
      idcompra: idcompra ?? this.idcompra,
      idbase: idbase ?? this.idbase,
      observacion: observacion ?? this.observacion,
      baseNombre: baseNombre ?? this.baseNombre,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
    );
  }

  static Future<List<CompraMovimiento>> fetchByCompra(String compraId) async {
    final List<dynamic> rows = await _supabase
        .from('compras_movimientos')
        .select(
          'id,idcompra,idbase,observacion,registrado_at,editado_at,bases(nombre)',
        )
        .eq('idcompra', compraId)
        .order('registrado_at');
    return rows
        .map(
          (dynamic row) =>
              CompraMovimiento.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<String> insert(CompraMovimiento movimiento) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('compras_movimientos')
        .insert(movimiento.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(CompraMovimiento movimiento) async {
    await _supabase
        .from('compras_movimientos')
        .update(movimiento.toUpdateJson())
        .eq('id', movimiento.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('compras_movimientos').delete().eq('id', id);
  }

  static Future<List<LogisticaBase>> fetchBases() {
    return LogisticaBase.getBases();
  }
}
