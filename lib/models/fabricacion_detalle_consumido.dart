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

class FabricacionDetalleConsumido {
  const FabricacionDetalleConsumido({
    this.id,
    required this.idfabricacion,
    required this.idproducto,
    required this.cantidad,
    this.productoNombre,
  });

  final String? id;
  final String idfabricacion;
  final String idproducto;
  final double cantidad;
  final String? productoNombre;

  factory FabricacionDetalleConsumido.fromJson(Map<String, dynamic> json) {
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
    return FabricacionDetalleConsumido(
      id: json['id'] as String?,
      idfabricacion: json['idfabricacion'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      productoNombre: productoNombre,
    );
  }

  static Future<List<FabricacionDetalleConsumido>> fetchByFabricacion(
    String fabricacionId,
  ) async {
    final List<dynamic> rows = await _supabase
        .from('fabricacion_det_consumido')
        .select(
          'id,idfabricacion,idproducto,cantidad,producto_nombre:productos(nombre)',
        )
        .eq('idfabricacion', fabricacionId)
        .order('registrado_at');
    return rows
        .map((dynamic row) => FabricacionDetalleConsumido.fromJson(
              row as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }

  static Future<void> replaceForFabricacion(
    String fabricacionId,
    List<FabricacionDetalleConsumido> detalles,
  ) async {
    await _supabase
        .from('fabricacion_det_consumido')
        .delete()
        .eq('idfabricacion', fabricacionId);
    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map(
          (FabricacionDetalleConsumido detalle) => <String, dynamic>{
            'idfabricacion': fabricacionId,
            'idproducto': detalle.idproducto,
            'cantidad': detalle.cantidad,
          },
        )
        .toList(growable: false);
    await _supabase.from('fabricacion_det_consumido').insert(payload);
  }
}
