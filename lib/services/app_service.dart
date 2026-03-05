import 'package:flutter/foundation.dart';
import '../ventas/modelos_venta.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppService — fuente de verdad centralizada
//  Comparte datos entre el módulo de Ventas y el módulo de Cobranza.
//  Usa ChangeNotifier para que las pantallas se actualicen automáticamente.
// ─────────────────────────────────────────────────────────────────────────────
class AppService extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────────────────
  AppService._();
  static final AppService instance = AppService._();

  // ── Lista única de ventas (fuente de verdad) ──────────────────────────────
  final List<Venta> _ventas = [
    Venta(
      id: '001', cliente: 'Tienda Don Pepe', tipo: TipoProducto.doble,
      color: 'Rojo / Negro', cantidad: 5, destino: 'Av. Potosí 123',
      precioUnit: 120, pago: ModalidadPago.credito,
      montoPagado: 200, fecha: DateTime(2025, 3, 1),
      historialAbonos: [
        AbonoVenta(monto: 200, fecha: DateTime(2025, 3, 1), nota: 'Primer abono'),
      ],
    ),
    Venta(
      id: '002', cliente: 'Doña Carmen', tipo: TipoProducto.simple,
      color: 'Azul / Blanco', cantidad: 3, destino: 'Calle Junín 45',
      precioUnit: 80, pago: ModalidadPago.parcial,
      montoPagado: 120, fecha: DateTime(2025, 3, 3),
      historialAbonos: [
        AbonoVenta(monto: 60, fecha: DateTime(2025, 3, 2), nota: 'Efectivo'),
        AbonoVenta(monto: 60, fecha: DateTime(2025, 3, 5), nota: 'Transferencia'),
      ],
    ),
    Venta(
      id: '003', cliente: 'Distribuidora Alteña', tipo: TipoProducto.metros,
      color: 'Verde / Amarillo', cantidad: 10, destino: 'El Alto, 16 de Julio',
      precioUnit: 35, pago: ModalidadPago.contado,
      montoPagado: 350, fecha: DateTime(2025, 2, 20),
    ),
    Venta(
      id: '004', cliente: 'Tienda La Estrella', tipo: TipoProducto.doble,
      color: 'Morado / Rosa', cantidad: 2, destino: 'Mercado Rodríguez',
      precioUnit: 150, pago: ModalidadPago.credito,
      montoPagado: 0, fecha: DateTime(2025, 3, 5),
    ),
    Venta(
      id: '005', cliente: 'Mercado Central', tipo: TipoProducto.simple,
      color: 'Rojo / Dorado', cantidad: 8, destino: 'Calle Comercio 77',
      precioUnit: 80, pago: ModalidadPago.parcial,
      montoPagado: 500, fecha: DateTime(2025, 3, 6),
      historialAbonos: [
        AbonoVenta(monto: 300, fecha: DateTime(2025, 3, 1), nota: 'Primera parte'),
        AbonoVenta(monto: 200, fecha: DateTime(2025, 3, 6), nota: 'Segunda parte'),
      ],
    ),
  ];

  // ── Getters ───────────────────────────────────────────────────────────────

  /// Todas las ventas (para VentasPage)
  List<Venta> get ventas => List.unmodifiable(_ventas);

  /// Ventas que generan cuenta por cobrar (crédito + parcial)
  List<Venta> get cuentasPorCobrar =>
      _ventas.where((v) => v.generaCobranza).toList();

  /// Ventas con deuda pendiente
  List<Venta> get pendientes =>
      _ventas.where((v) => v.generaCobranza && !v.saldado).toList();

  /// Ventas vencidas (sin fecha de vencimiento explícita, usamos 30 días desde la venta)
  List<Venta> get vencidos => _ventas
      .where((v) =>
          v.generaCobranza &&
          !v.saldado &&
          DateTime.now().difference(v.fecha).inDays > 30)
      .toList();

  /// Ventas saldadas que tenían crédito/parcial
  List<Venta> get saldados =>
      _ventas.where((v) => v.generaCobranza && v.saldado).toList();

  // ── Resumen ───────────────────────────────────────────────────────────────
  double get totalVentas => _ventas.fold(0.0, (s, v) => s + v.total);
  double get totalCobrado => _ventas.fold(0.0, (s, v) => s + v.montoPagado);
  double get totalPendiente => _ventas.fold(0.0, (s, v) => s + v.pendiente);

  // ── Mutaciones ────────────────────────────────────────────────────────────

  /// Registrar una nueva venta
  void agregarVenta(Venta venta) {
    _ventas.insert(0, venta);
    notifyListeners();
  }

  /// Registrar un abono sobre una venta existente (por ID)
  void registrarAbono(String ventaId, double monto, {String nota = ''}) {
    final idx = _ventas.indexWhere((v) => v.id == ventaId);
    if (idx == -1 || monto <= 0) return;

    final venta = _ventas[idx];
    venta.montoPagado =
        (venta.montoPagado + monto).clamp(0, venta.total);
    venta.historialAbonos.add(AbonoVenta(
      monto: monto,
      fecha: DateTime.now(),
      nota: nota,
    ));
    notifyListeners();
  }

  /// Genera un ID único para nueva venta
  String nuevoId() {
    final n = _ventas.length + 1;
    return n.toString().padLeft(3, '0');
  }
}
