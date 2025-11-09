class PedidoDetalleSnapshot {
  const PedidoDetalleSnapshot({
    required this.idProducto,
    required this.cantidad,
    this.nombre,
  });

  final String idProducto;
  final double cantidad;
  final String? nombre;
}
