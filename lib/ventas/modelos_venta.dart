// Modelos del módulo Ventas
enum TipoProducto { simple, doble, metros }
enum ModalidadPago  { contado, credito, parcial }
enum EstadoPago { sinAbono, vaPagando, casiSaldado, saldado }

// ─── Abono individual ─────────────────────────────────────────────────────
class AbonoVenta {
  final double monto;
  final DateTime fecha;
  final String nota;
  AbonoVenta({required this.monto, required this.fecha, this.nota = ''});
}

// ─── Modelo principal de Venta ────────────────────────────────────────────
class Venta {
  final String id;
  String cliente;
  TipoProducto tipo;
  String color;
  double cantidad;
  String destino;
  double precioUnit;
  ModalidadPago pago;
  double montoPagado;
  DateTime fecha;
  final List<AbonoVenta> historialAbonos;

  Venta({
    required this.id,
    required this.cliente,
    required this.tipo,
    required this.color,
    required this.cantidad,
    required this.destino,
    required this.precioUnit,
    this.pago = ModalidadPago.contado,
    this.montoPagado = 0,
    required this.fecha,
    List<AbonoVenta>? historialAbonos,
  }) : historialAbonos = historialAbonos ?? [];

  double get total     => cantidad * precioUnit;
  double get pendiente => (total - montoPagado).clamp(0, total);
  double get progreso  => total > 0 ? (montoPagado / total).clamp(0, 1) : 0;
  bool   get saldado   => pendiente == 0;

  /// ¿Genera cuenta por cobrar en cobranza?
  bool get generaCobranza =>
      pago == ModalidadPago.credito || pago == ModalidadPago.parcial;

  /// Estado automático según progreso de pago
  EstadoPago get estadoPago {
    if (saldado)          return EstadoPago.saldado;
    if (progreso >= 0.75) return EstadoPago.casiSaldado;
    if (progreso >= 0.25) return EstadoPago.vaPagando;
    return EstadoPago.sinAbono;
  }
}
