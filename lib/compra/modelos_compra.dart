import 'package:flutter/material.dart';

enum TipoTransaccion { entregaMaterial, pagoEfectivo }

class TransaccionCompra {
  final String id;
  final DateTime fecha;
  final TipoTransaccion tipo;
  // Solo aplica para entregaMaterial
  final String? detalleMateriaPrima; // Ej: "38 bolsas"
  final double? kilos;
  final double? importeCobrado; 
  // Solo aplica para pagoEfectivo
  final double? montoPagado;
  
  // Notas adicionales del usuario (Ej: "Acuenta de la próxima semana")
  final String? detalleExtra;
  
  // Ruta de la foto adjunta del comprobante de transferencia o recibo (opcional)
  final String? comprobantePath;

  // Saldo resultante después de aplicar esta transacción
  double saldoDespuesTransaccion;

  TransaccionCompra({
    required this.id,
    required this.fecha,
    required this.tipo,
    this.detalleMateriaPrima,
    this.kilos,
    this.importeCobrado,
    this.montoPagado,
    this.detalleExtra,
    this.comprobantePath,
    this.saldoDespuesTransaccion = 0.0,
  });
}

class Proveedor {
  final String id;
  final String nombre;
  final String empresa;
  final List<TransaccionCompra> historial;

  // El saldo actual es la suma de los importes cobrados menos la suma de los montos pagados
  double get saldoDeudorActual {
    double saldo = 0;
    for (var tx in historial) {
      if (tx.tipo == TipoTransaccion.entregaMaterial) {
        saldo += (tx.importeCobrado ?? 0);
      } else if (tx.tipo == TipoTransaccion.pagoEfectivo) {
        saldo -= (tx.montoPagado ?? 0);
      }
    }
    return saldo;
  }

  Proveedor({
    required this.id,
    required this.nombre,
    required this.empresa,
    List<TransaccionCompra>? historial,
  }) : historial = historial ?? [];
}

// ─────────────────────────────────────────────
// Servicio Compartido para el Módulo de Compras
// ─────────────────────────────────────────────
class ComprasService extends ChangeNotifier {
  static final ComprasService instance = ComprasService._();
  ComprasService._();

  final List<Proveedor> _proveedores = [
    Proveedor(
      id: 'PRV001', nombre: 'Juan Pérez', empresa: 'Distribuidora San Juan',
      historial: [
        TransaccionCompra(
          id: 'TX001', fecha: DateTime(2026, 2, 10, 8, 30),
          tipo: TipoTransaccion.entregaMaterial,
          detalleMateriaPrima: '38 bolsas a 6kg', kilos: 228.0, importeCobrado: 18924.0,
        )..saldoDespuesTransaccion = 18924.0,
        TransaccionCompra(
          id: 'TX002', fecha: DateTime(2026, 2, 10, 8, 35),
          tipo: TipoTransaccion.pagoEfectivo, montoPagado: 15000.0,
        )..saldoDespuesTransaccion = 3924.0, 
        // Modificado a un abono de 15,000 para que refleje una deuda pendiente real en rojo
      ]
    ),
    Proveedor(
      id: 'PRV002', nombre: 'María Gómez', empresa: 'Hilos El Sol',
    ),
  ];

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);

  void agregarProveedor(String nombre, String empresa) {
    _proveedores.add(Proveedor(
      id: 'PRV${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      empresa: empresa,
    ));
    notifyListeners();
  }

  void registrarEntregaMaterial(Proveedor proveedor, String detalle, double kilos, double importeCobrado, {String? comprobantePath, DateTime? fechaRegistro, String? detalleExtra}) {
    double saldoPrevio = proveedor.saldoDeudorActual;
    final tx = TransaccionCompra(
      id: 'TX${DateTime.now().millisecondsSinceEpoch}',
      fecha: fechaRegistro ?? DateTime.now(),
      tipo: TipoTransaccion.entregaMaterial,
      detalleMateriaPrima: detalle,
      kilos: kilos,
      importeCobrado: importeCobrado,
      comprobantePath: comprobantePath,
      detalleExtra: detalleExtra,
    );
    tx.saldoDespuesTransaccion = saldoPrevio + importeCobrado;
    proveedor.historial.insert(0, tx); // Al principio para ver el más reciente arriba
    notifyListeners();
  }

  void registrarPagoEfectivo(Proveedor proveedor, double montoPagado, {String? comprobantePath, DateTime? fechaRegistro, String? detalleExtra}) {
    double saldoPrevio = proveedor.saldoDeudorActual;
    final tx = TransaccionCompra(
      id: 'TX${DateTime.now().millisecondsSinceEpoch}',
      fecha: fechaRegistro ?? DateTime.now(),
      tipo: TipoTransaccion.pagoEfectivo,
      montoPagado: montoPagado,
      comprobantePath: comprobantePath,
      detalleExtra: detalleExtra,
    );
    tx.saldoDespuesTransaccion = saldoPrevio - montoPagado;
    proveedor.historial.insert(0, tx);
    notifyListeners();
  }
}
