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

class TransferenciaDetalle {
  const TransferenciaDetalle({
    this.id,
    required this.idtransferencia,
    required this.idproducto,
    required this.cantidad,
    this.productoNombre,
  });

  final String? id;
  final String idtransferencia;
  final String idproducto;
  final double cantidad;
  final String? productoNombre;

  factory TransferenciaDetalle.fromJson(Map<String, dynamic> json) {
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
    return TransferenciaDetalle(
      id: json['id'] as String?,
      idtransferencia: json['idtransferencia'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      productoNombre: productoNombre,
    );
  }

  static Future<List<TransferenciaDetalle>> fetchByTransferencia(
    String transferenciaId,
  ) async {
    final List<dynamic> rows = await _supabase
        .from('transferencias_detalle')
        .select(
          'id,idtransferencia,idproducto,cantidad,producto_nombre:productos(nombre)',
        )
        .eq('idtransferencia', transferenciaId)
        .order('registrado_at');
    return rows
        .map((dynamic row) =>
            TransferenciaDetalle.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<void> replaceForTransferencia(
    String transferenciaId,
    List<TransferenciaDetalle> detalles,
  ) async {
    await _supabase
        .from('transferencias_detalle')
        .delete()
        .eq('idtransferencia', transferenciaId);
    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map(
          (TransferenciaDetalle detalle) => <String, dynamic>{
            'idtransferencia': transferenciaId,
            'idproducto': detalle.idproducto,
            'cantidad': detalle.cantidad,
          },
        )
        .toList(growable: false);
    await _supabase.from('transferencias_detalle').insert(payload);
  }
}
