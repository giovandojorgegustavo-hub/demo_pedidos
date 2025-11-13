import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

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
    final dynamic nombre = value['nombre'] ?? value['label'];
    if (nombre is String) {
      return nombre;
    }
  }
  return value.toString();
}

class Compra {
  const Compra({
    required this.id,
    required this.idproveedor,
    this.idbase,
    this.observacion,
    this.proveedorNombre,
    this.proveedorNumero,
    this.baseNombre,
    this.totalDetalle,
    this.totalPagado,
    this.saldo,
    this.estadoPago,
    this.cantidadTotal,
    this.cantidadEnviada,
    this.estadoEntrega,
    this.registradoAt,
    this.editadoAt,
  });

  final String id;
  final String idproveedor;
  final String? idbase;
  final String? observacion;
  final String? proveedorNombre;
  final String? proveedorNumero;
  final String? baseNombre;
  final double? totalDetalle;
  final double? totalPagado;
  final double? saldo;
  final String? estadoPago;
  final double? cantidadTotal;
  final double? cantidadEnviada;
  final String? estadoEntrega;
  final DateTime? registradoAt;
  final DateTime? editadoAt;

  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      id: json['id'] as String,
      idproveedor: json['idproveedor'] as String,
      idbase: json['idbase'] as String?,
      observacion: json['observacion'] as String?,
      proveedorNombre: _coerceString(json['proveedor_nombre']),
      proveedorNumero: _coerceString(json['proveedor_numero']),
      baseNombre: _coerceString(json['base_nombre']),
      totalDetalle: _toDouble(json['total_detalle']),
      totalPagado: _toDouble(json['total_pagado']),
      saldo: _toDouble(json['saldo']),
      estadoPago: json['estado_pago'] as String?,
      cantidadTotal: _toDouble(json['cantidad_total']),
      cantidadEnviada: _toDouble(json['cantidad_enviada']),
      estadoEntrega: json['estado_entrega'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idproveedor': idproveedor,
      'observacion': observacion,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idproveedor': idproveedor,
      'observacion': observacion,
      'editado_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Compra>> fetchAll() async {
    final List<dynamic> rows = await _supabase
        .from('v_compras_vistageneral')
        .select(
          'id,idproveedor,idbase,observacion,proveedor_nombre,proveedor_numero,base_nombre,total_detalle,total_pagado,saldo,estado_pago,cantidad_total,cantidad_enviada,estado_entrega,registrado_at,editado_at',
        )
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => Compra.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<Compra?> getById(String id) async {
    final Map<String, dynamic>? data = await _supabase
        .from('v_compras_vistageneral')
        .select(
          'id,idproveedor,idbase,observacion,proveedor_nombre,proveedor_numero,base_nombre,total_detalle,total_pagado,saldo,estado_pago,cantidad_total,cantidad_enviada,estado_entrega,registrado_at,editado_at',
        )
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return Compra.fromJson(data);
  }

  static Future<String> insert(Compra compra) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('compras')
        .insert(compra.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(Compra compra) async {
    await _supabase.from('compras').update(compra.toUpdateJson()).eq('id', compra.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('compras').delete().eq('id', id);
  }

  Compra copyWith({
    String? id,
    String? idproveedor,
    String? idbase,
    String? observacion,
    DateTime? registradoAt,
    DateTime? editadoAt,
  }) {
    return Compra(
      id: id ?? this.id,
      idproveedor: idproveedor ?? this.idproveedor,
      idbase: idbase ?? this.idbase,
      observacion: observacion ?? this.observacion,
      proveedorNombre: proveedorNombre,
      proveedorNumero: proveedorNumero,
      baseNombre: baseNombre,
      totalDetalle: totalDetalle,
      totalPagado: totalPagado,
      saldo: saldo,
      estadoPago: estadoPago,
      cantidadTotal: cantidadTotal,
      cantidadEnviada: cantidadEnviada,
      estadoEntrega: estadoEntrega,
      registradoAt: registradoAt ?? this.registradoAt,
      editadoAt: editadoAt ?? this.editadoAt,
    );
  }
}
