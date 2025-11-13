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

class CompraDetalle {
  const CompraDetalle({
    this.id,
    required this.idcompra,
    required this.idproducto,
    required this.cantidad,
    required this.costoTotal,
    this.productoNombre,
  });

  final String? id;
  final String idcompra;
  final String idproducto;
  final double cantidad;
  final double costoTotal;
  final String? productoNombre;

  factory CompraDetalle.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? productoJson =
        json['productos'] as Map<String, dynamic>?;
    final dynamic productoNombreRaw = json['producto_nombre'];
    String? productoNombre;
    if (productoNombreRaw is String) {
      productoNombre = productoNombreRaw;
    } else if (productoNombreRaw is Map<String, dynamic>) {
      final dynamic nombre = productoNombreRaw['nombre'];
      if (nombre is String) {
        productoNombre = nombre;
      }
    }
    productoNombre ??= productoJson?['nombre'] as String?;

    return CompraDetalle(
      id: json['id'] as String?,
      idcompra: json['idcompra'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      costoTotal: _toDouble(json['costo_total']),
      productoNombre: productoNombre,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idcompra': idcompra,
      'idproducto': idproducto,
      'cantidad': cantidad,
      'costo_total': costoTotal,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'idproducto': idproducto,
      'cantidad': cantidad,
      'costo_total': costoTotal,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'idcompra': idcompra,
      'idproducto': idproducto,
      'cantidad': cantidad,
      'costo_total': costoTotal,
    };
  }

  static Future<List<CompraDetalle>> fetchByCompra(String compraId) async {
    final List<dynamic> rows = await _supabase
        .from('compras_detalle')
        .select(
          'id,idcompra,idproducto,cantidad,costo_total,producto_nombre:productos(nombre)',
        )
        .eq('idcompra', compraId)
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => CompraDetalle.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(CompraDetalle detalle) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('compras_detalle')
        .insert(detalle.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(CompraDetalle detalle) async {
    final String? id = detalle.id;
    if (id == null) {
      throw ArgumentError('El detalle debe tener id para poder actualizarse');
    }
    await _supabase
        .from('compras_detalle')
        .update(detalle.toUpdateJson())
        .eq('id', id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('compras_detalle').delete().eq('id', id);
  }
}
