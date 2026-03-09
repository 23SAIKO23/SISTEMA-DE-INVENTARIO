import 'package:flutter/material.dart';

class Pago {
  final String id;
  final DateTime fecha;
  final double monto;
  final String mesCorrespondiente;

  Pago({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.mesCorrespondiente,
  });
}

class Trabajador {
  final String id;
  final String nombre;
  final String cargo;
  final double salarioBase;
  final List<Pago> historialPagos;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.salarioBase,
    List<Pago>? historialPagos,
  }) : historialPagos = historialPagos ?? [];
}

// ─────────────────────────────────────────────
// Servicio Compartido usando un Singleton simple
// ─────────────────────────────────────────────
class SalariosService extends ChangeNotifier {
  static final SalariosService instance = SalariosService._();
  SalariosService._();

  final List<Trabajador> _trabajadores = [
    Trabajador(
      id: 'T001', nombre: 'Carlos Mendoza', cargo: 'Tejedor Principal', salarioBase: 3500.0,
      historialPagos: [
        Pago(id: 'P001', fecha: DateTime(2026, 1, 31, 15, 30), monto: 3500.0, mesCorrespondiente: 'Enero 2026'),
        Pago(id: 'P002', fecha: DateTime(2026, 2, 28, 10, 15), monto: 3500.0, mesCorrespondiente: 'Febrero 2026'),
      ],
    ),
    Trabajador(
      id: 'T002', nombre: 'Ana Choque', cargo: 'Costurera', salarioBase: 2800.0,
      historialPagos: [
        Pago(id: 'P003', fecha: DateTime(2026, 2, 28, 9, 45), monto: 2800.0, mesCorrespondiente: 'Febrero 2026'),
      ],
    ),
    Trabajador(
      id: 'T003', nombre: 'Luis Mamani', cargo: 'Urdidor', salarioBase: 3000.0,
    ),
  ];

  List<Trabajador> get trabajadores => List.unmodifiable(_trabajadores);

  void registrarPago(Trabajador trabajador, double monto, String mesCorrespondiente) {
    trabajador.historialPagos.insert(0, Pago(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      monto: monto,
      mesCorrespondiente: mesCorrespondiente,
    ));
    notifyListeners();
  }
}
