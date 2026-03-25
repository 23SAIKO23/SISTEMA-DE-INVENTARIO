import 'package:flutter/foundation.dart';
import '../ventas/modelos_venta.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppService — fuente de verdad para Ventas y Cobranza
//  Ahora los datos vienen de MySQL vía la API PHP en XAMPP
// ─────────────────────────────────────────────────────────────────────────────
class AppService extends ChangeNotifier {
  AppService._();
  static final AppService instance = AppService._();

  final _api = ApiService.instance;
  final List<Venta> _ventas = [];
  bool cargando = false;

  // ── Getters ───────────────────────────────────────────────────
  List<Venta> get ventas           => List.unmodifiable(_ventas);
  List<Venta> get cuentasPorCobrar => _ventas.where((v) => v.generaCobranza).toList();
  List<Venta> get pendientes       => _ventas.where((v) => v.generaCobranza && !v.saldado).toList();
  List<Venta> get vencidos         => _ventas.where((v) => v.generaCobranza && !v.saldado && DateTime.now().difference(v.fecha).inDays > 30).toList();
  List<Venta> get saldados         => _ventas.where((v) => v.generaCobranza && v.saldado).toList();

  double get totalVentas    => _ventas.fold(0.0, (s, v) => s + v.total);
  double get totalCobrado   => _ventas.fold(0.0, (s, v) => s + v.montoPagado);
  double get totalPendiente => _ventas.fold(0.0, (s, v) => s + v.pendiente);

  // ── Cargar ventas desde MySQL ──────────────────────────────────
  Future<void> cargarVentas() async {
    cargando = true;
    notifyListeners();
    try {
      final data = await _api.listarVentas();
      _ventas.clear();
      for (final j in data) {
        _ventas.add(Venta.fromJson(j as Map<String, dynamic>));
      }
    } catch (_) {}
    cargando = false;
    notifyListeners();
  }

  // ── Agregar venta → MySQL ──────────────────────────────────────
  Future<void> agregarVenta(Venta venta) async {
    await _api.agregarVenta(
      cliente:    venta.cliente,
      tipo:       venta.tipo.name,
      color:      venta.color,
      cantidad:   venta.cantidad,
      destino:    venta.destino,
      precioUnit: venta.precioUnit,
      pago:       venta.pago.name,
      montoPagado: venta.montoPagado,
    );
    await cargarVentas();
  }

  // ── Registrar abono → MySQL ────────────────────────────────────
  Future<void> registrarAbono(int ventaId, double monto, {String nota = '', String? comprobanteB64}) async {
    if (monto <= 0) return;
    await _api.abonarVenta(ventaId: ventaId, monto: monto, nota: nota, comprobanteB64: comprobanteB64);
    await cargarVentas();
  }

  // Compatibilidad: registrarAbono con String id (por si hay código viejo)
  Future<void> registrarAbonoStr(String ventaId, double monto, {String nota = ''}) async {
    final id = int.tryParse(ventaId) ?? 0;
    await registrarAbono(id, monto, nota: nota);
  }
}
