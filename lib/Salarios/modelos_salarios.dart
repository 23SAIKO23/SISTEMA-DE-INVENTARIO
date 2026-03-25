import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notificaciones_service.dart';

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
  final DateTime fechaIngreso;
  final List<Pago> historialPagos;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.salarioBase,
    required this.fechaIngreso,
    List<Pago>? historialPagos,
  }) : historialPagos = historialPagos ?? [];
}

// ─────────────────────────────────────────────
// Servicio Compartido usando un Singleton simple
// ─────────────────────────────────────────────
class SalariosService extends ChangeNotifier {
  static final SalariosService instance = SalariosService._();
  SalariosService._() {
    cargarDesdeServidor();
  }

  List<Trabajador> _trabajadores = [];
  bool isLoading = true;

  List<Trabajador> get trabajadores => List.unmodifiable(_trabajadores);

  Future<void> refresh() => cargarDesdeServidor();

  Future<void> cargarDesdeServidor() async {
    isLoading = true;
    notifyListeners();
    try {
      final List data = await ApiService.instance.listarTrabajadores();
      
      // Reiniciar pool de alarmas (opcional, no debería bloquear la carga)
      try {
        await NotificacionesService.instance.cancelarTodas();
      } catch (e) {
        debugPrint('Error al cancelar notificaciones: $e');
      }
      
      _trabajadores = data.map((e) {
        final List pagosData = e['historialPagos'] ?? [];
        return Trabajador(
          id: e['id'].toString(),
          nombre: e['nombre'] ?? '',
          cargo: e['cargo'] ?? '',
          salarioBase: double.tryParse(e['salario_base'].toString()) ?? 0.0,
          fechaIngreso: DateTime.tryParse(e['fecha_ingreso']?.toString() ?? '') ?? DateTime.now(),
          historialPagos: pagosData.map((p) => Pago(
            id: p['id'].toString(),
            fecha: DateTime.tryParse(p['fecha'].toString()) ?? DateTime.now(),
            monto: double.tryParse(p['monto'].toString()) ?? 0.0,
            mesCorrespondiente: p['mesCorrespondiente'] ?? '',
          )).toList(),
        );
      }).toList();

      for (var t in _trabajadores) {
        NotificacionesService.instance.programarRecordatorioPago(
          idNotificacion: t.id.hashCode,
          nombreTrabajador: t.nombre,
          fechaIngreso: t.fechaIngreso,
        );
      }
    } catch (e) {
      debugPrint('Error cargando salarios/nómina: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> agregarTrabajador(String nombre, String cargo, double salarioBase, DateTime fechaIngreso) async {
    // Optimistic local update
    final t = Trabajador(
      id: 'T${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre, cargo: cargo, salarioBase: salarioBase,
      fechaIngreso: fechaIngreso,
    );
    _trabajadores.add(t);
    notifyListeners();

    try {
      await ApiService.instance.agregarTrabajador(
        nombre: nombre, cargo: cargo, salarioBase: salarioBase,
        fechaIngreso: fechaIngreso.toIso8601String().split('T')[0],
      );
      await cargarDesdeServidor();
    } catch(e) {
      debugPrint('Error agregando trabajador: $e');
    }
  }

  Future<void> registrarPago(Trabajador trabajador, double monto, String mesCorrespondiente) async {
    // Optimistic
    trabajador.historialPagos.insert(0, Pago(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      monto: monto,
      mesCorrespondiente: mesCorrespondiente,
    ));
    notifyListeners();

    try {
      await ApiService.instance.registrarPago(
        trabajadorId: int.parse(trabajador.id),
        monto: monto,
        mesCorrespondiente: mesCorrespondiente,
      );
      await cargarDesdeServidor();
    } catch(e) {
      debugPrint('Error registrando pago: $e');
    }
  }
}
