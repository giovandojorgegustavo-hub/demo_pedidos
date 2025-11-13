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

class FabricacionGasto {
  const FabricacionGasto({
    this.id,
    required this.idfabricacion,
    required this.concepto,
    required this.monto,
    this.observacion,
  });

  final String? id;
  final String idfabricacion;
  final String concepto;
  final double monto;
  final String? observacion;

  factory FabricacionGasto.fromJson(Map<String, dynamic> json) {
    return FabricacionGasto(
      id: json['id'] as String?,
      idfabricacion: json['idfabricacion'] as String,
      concepto: json['concepto'] as String,
      monto: _toDouble(json['monto']),
      observacion: json['observacion'] as String?,
    );
  }

  FabricacionGasto copyWith({
    String? id,
    String? idfabricacion,
    String? concepto,
    double? monto,
    String? observacion,
  }) {
    return FabricacionGasto(
      id: id ?? this.id,
      idfabricacion: idfabricacion ?? this.idfabricacion,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      observacion: observacion ?? this.observacion,
    );
  }

  Map<String, dynamic> toJsonForInsert(String fabricacionId) {
    return <String, dynamic>{
      'idfabricacion': fabricacionId,
      'concepto': concepto,
      'monto': monto,
      'observacion': observacion,
    };
  }

  static Future<List<FabricacionGasto>> fetchByFabricacion(
    String fabricacionId,
  ) async {
    final List<dynamic> rows = await _supabase
        .from('fabricaciones_gastos')
        .select('id,idfabricacion,concepto,monto,observacion')
        .eq('idfabricacion', fabricacionId)
        .order('registrado_at');
    return rows
        .map(
          (dynamic row) =>
              FabricacionGasto.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<void> replaceForFabricacion(
    String fabricacionId,
    List<FabricacionGasto> gastos,
  ) async {
    await _supabase
        .from('fabricaciones_gastos')
        .delete()
        .eq('idfabricacion', fabricacionId);
    if (gastos.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = gastos
        .map(
          (FabricacionGasto gasto) => gasto.toJsonForInsert(fabricacionId),
        )
        .toList(growable: false);
    await _supabase.from('fabricaciones_gastos').insert(payload);
  }
}
