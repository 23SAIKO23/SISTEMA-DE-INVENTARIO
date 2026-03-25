// Modelos del módulo Ventas
enum TipoProducto { simple, doble, metros }
enum ModalidadPago  { contado, credito, parcial }
enum EstadoPago { sinAbono, vaPagando, casiSaldado, saldado }

// ─── Abono individual ─────────────────────────────────────────────────────
class AbonoVenta {
  final double monto;
  final DateTime fecha;
  final String nota;
  final String? comprobante;
  AbonoVenta({required this.monto, required this.fecha, this.nota = '', this.comprobante});
}

// ─── Modelo principal de Venta ────────────────────────────────────────────
class Venta {
  final int id;
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

  bool get generaCobranza =>
      pago == ModalidadPago.credito || pago == ModalidadPago.parcial;

  EstadoPago get estadoPago {
    if (saldado)          return EstadoPago.saldado;
    if (progreso >= 0.75) return EstadoPago.casiSaldado;
    if (progreso >= 0.25) return EstadoPago.vaPagando;
    return EstadoPago.sinAbono;
  }

  /// Construir desde el JSON que devuelve la API PHP
  factory Venta.fromJson(Map<String, dynamic> json) {
    TipoProducto tipo;
    switch ((json['tipo'] ?? 'simple').toString()) {
      case 'doble':  tipo = TipoProducto.doble; break;
      case 'metros': tipo = TipoProducto.metros; break;
      default:       tipo = TipoProducto.simple;
    }
    ModalidadPago pago;
    switch ((json['pago'] ?? 'contado').toString()) {
      case 'credito': pago = ModalidadPago.credito; break;
      case 'parcial': pago = ModalidadPago.parcial; break;
      default:        pago = ModalidadPago.contado;
    }
    
    // Parsear historial de abonos
    final listaAbonos = json['historialAbonos'] as List<dynamic>? ?? [];
    final historial = listaAbonos.map((a) => AbonoVenta(
      monto: double.tryParse(a['monto'].toString()) ?? 0,
      fecha: DateTime.tryParse(a['fecha'] ?? '') ?? DateTime.now(),
      nota: a['nota'] ?? '',
      comprobante: a['comprobante']?.toString(),
    )).toList();

    return Venta(
      id:           int.tryParse(json['id'].toString()) ?? 0,
      cliente:      json['cliente'] ?? '',
      tipo:         tipo,
      color:        json['color'] ?? '',
      cantidad:     double.tryParse(json['cantidad'].toString()) ?? 0,
      destino:      json['destino'] ?? '',
      precioUnit:   double.tryParse(json['precio_unit'].toString()) ?? 0,
      pago:         pago,
      montoPagado:  double.tryParse(json['monto_pagado'].toString()) ?? 0,
      fecha:        DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      historialAbonos: historial,
    );
  }
}
