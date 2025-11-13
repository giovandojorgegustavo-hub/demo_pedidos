import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class GastoPedido {
  const GastoPedido({
    required this.id,
    required this.idPedido,
    required this.tipo,
    required this.descripcion,
    required this.monto,
    this.clienteNombre,
    this.pedidoRegistradoAt,
    this.idCuenta,
    this.cuentaNombre,
    this.idCuentaContable,
    this.cuentaContableCodigo,
    this.cuentaContableNombre,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String idPedido;
  final String tipo;
  final String descripcion;
  final double monto;
  final String? clienteNombre;
  final DateTime? pedidoRegistradoAt;
  final String? idCuenta;
  final String? cuentaNombre;
  final String? idCuentaContable;
  final String? cuentaContableCodigo;
  final String? cuentaContableNombre;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory GastoPedido.fromJson(Map<String, dynamic> json) {
    return GastoPedido(
      id: json['id'] as String,
      idPedido: json['idpedido'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      monto: (json['monto'] as num).toDouble(),
      clienteNombre: json['cliente_nombre'] as String?,
      pedidoRegistradoAt: json['pedido_registrado_at'] == null
          ? null
          : DateTime.tryParse(json['pedido_registrado_at'] as String),
      idCuenta: json['idcuenta'] as String?,
      cuentaNombre: json['cuenta_nombre'] as String?,
      idCuentaContable: json['idcuenta_contable'] as String?,
      cuentaContableCodigo: json['cuenta_contable_codigo'] as String?,
      cuentaContableNombre: json['cuenta_contable_nombre'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<GastoPedido>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? tipo,
    String? cuentaId,
    String? cuentaContableId,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('v_finanzas_gastos_pedidos')
        .select(
          'id,idpedido,cliente_nombre,pedido_registrado_at,tipo,descripcion,monto,idcuenta,cuenta_nombre,idcuenta_contable,cuenta_contable_codigo,cuenta_contable_nombre,registrado_at,registrado_por',
        );

    if (from != null) {
      query = query.gte('registrado_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('registrado_at', to.toIso8601String());
    }
    if (tipo != null && tipo.isNotEmpty) {
      query = query.ilike('tipo', '%$tipo%');
    }
    if (cuentaId != null && cuentaId.isNotEmpty) {
      query = query.eq('idcuenta', cuentaId);
    }
    if (cuentaContableId != null && cuentaContableId.isNotEmpty) {
      query = query.eq('idcuenta_contable', cuentaContableId);
    }

    final List<dynamic> rows =
        await query.order('registrado_at', ascending: false);
    return rows
        .map(
          (dynamic row) => GastoPedido.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
