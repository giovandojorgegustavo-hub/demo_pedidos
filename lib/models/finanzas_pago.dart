import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/models/pago.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class FinanzasPago {
  const FinanzasPago({
    required this.id,
    required this.idpedido,
    required this.monto,
    required this.fechapago,
    this.clienteNombre,
    this.pedidoRegistradoAt,
    this.idcuenta,
    this.cuentaNombre,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String idpedido;
  final double monto;
  final DateTime fechapago;
  final DateTime? pedidoRegistradoAt;
  final String? clienteNombre;
  final String? idcuenta;
  final String? cuentaNombre;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory FinanzasPago.fromJson(Map<String, dynamic> json) {
    return FinanzasPago(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechapago: DateTime.parse(json['fechapago'] as String),
      pedidoRegistradoAt: json['pedido_registrado_at'] == null
          ? null
          : DateTime.tryParse(json['pedido_registrado_at'] as String),
      clienteNombre: json['cliente_nombre'] as String?,
      idcuenta: json['idcuenta'] as String?,
      cuentaNombre: json['cuenta_nombre'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<FinanzasPago>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? cuentaId,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('v_finanzas_pagos_pedidos')
        .select(
          'id,idpedido,monto,fechapago,pedido_registrado_at,cliente_nombre,idcuenta,cuenta_nombre,registrado_at,registrado_por',
        );

    if (from != null) {
      query = query.gte('fechapago', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('fechapago', to.toIso8601String());
    }
    if (cuentaId != null && cuentaId.isNotEmpty) {
      query = query.eq('idcuenta', cuentaId);
    }

    final List<dynamic> rows =
        await query.order('fechapago', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              FinanzasPago.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Pago toPedidoPago() => Pago(
        id: id,
        idpedido: idpedido,
        monto: monto,
        fechapago: fechapago,
        idcuenta: idcuenta,
        fecharegistro: registradoAt,
        cuentaNombre: cuentaNombre,
      );
}
