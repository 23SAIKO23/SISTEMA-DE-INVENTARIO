// Modelos del módulo Ventas
enum TipoProducto { simple, doble, metros }
enum ModalidadPago  { contado, credito, parcial }

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
  });

  double get total    => cantidad * precioUnit;
  double get pendiente => (total - montoPagado).clamp(0, total);
  double get progreso  => total > 0 ? (montoPagado / total).clamp(0, 1) : 0;
  bool   get saldado   => pendiente == 0;

  /// Estado automático según progreso de pago
  EstadoPago get estadoPago {
    if (saldado)          return EstadoPago.saldado;
    if (progreso >= 0.75) return EstadoPago.casiSaldado;
    if (progreso >= 0.25) return EstadoPago.vaPagando;
    return EstadoPago.sinAbono;
  }
}

enum EstadoPago { sinAbono, vaPagando, casiSaldado, saldado }
