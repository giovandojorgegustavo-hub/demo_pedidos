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

class CompraMovimientoDetalle {
  const CompraMovimientoDetalle({
    this.id,
    required this.idmovimiento,
    required this.idproducto,
    required this.cantidad,
    this.productoNombre,
  });

  final String? id;
  final String idmovimiento;
  final String idproducto;
  final double cantidad;
  final String? productoNombre;

  factory CompraMovimientoDetalle.fromJson(Map<String, dynamic> json) {
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
    return CompraMovimientoDetalle(
      id: json['id'] as String?,
      idmovimiento: json['idmovimiento'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      productoNombre: productoNombre,
    );
  }

  Map<String, dynamic> toInsertJson({required String movimientoId}) {
    return <String, dynamic>{
      'idmovimiento': movimientoId,
      'idproducto': idproducto,
      'cantidad': cantidad,
    };
  }

  static Future<List<CompraMovimientoDetalle>> fetchByMovimiento(
    String movimientoId,
  ) async {
    final List<dynamic> rows = await _supabase
        .from('compras_movimiento_detalle')
        .select(
          'id,idmovimiento,idproducto,cantidad,producto_nombre:productos(nombre)',
        )
        .eq('idmovimiento', movimientoId)
        .order('registrado_at');
    return rows
        .map(
          (dynamic row) =>
              CompraMovimientoDetalle.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<void> replaceForMovimiento(
    String movimientoId,
    List<CompraMovimientoDetalle> detalles,
  ) async {
    await _supabase
        .from('compras_movimiento_detalle')
        .delete()
        .eq('idmovimiento', movimientoId);
    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map(
          (CompraMovimientoDetalle detalle) =>
              detalle.toInsertJson(movimientoId: movimientoId),
        )
        .toList(growable: false);
    await _supabase.from('compras_movimiento_detalle').insert(payload);
  }

  static Future<void> deleteByMovimiento(String movimientoId) async {
    await _supabase
        .from('compras_movimiento_detalle')
        .delete()
        .eq('idmovimiento', movimientoId);
  }
}
