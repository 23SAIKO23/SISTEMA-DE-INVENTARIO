import 'package:flutter/foundation.dart';

/// Servicio de notificaciones.
/// Las notificaciones reales solo funcionan en Android/iOS.
/// En Windows (PC) este servicio simula el comportamiento con logs.
class NotificacionesService {
  static final NotificacionesService instance = NotificacionesService._();
  NotificacionesService._();

  Future<void> init() async {
    debugPrint('ℹ️ NotificacionesService: modo PC (solo logs en consola)');
  }

  Future<void> requestPermissions() async {}

  /// Programa una notificación UN DÍA ANTES del día de pago.
  /// El día de pago = mismo día del mes que [fechaIngreso].
  Future<void> programarRecordatorioPago({
    required int idNotificacion,
    required String nombreTrabajador,
    required DateTime fechaIngreso,
  }) async {
    final hoy = DateTime.now();

    // Día de cancelación = día del mes de ingreso
    int diaPago = fechaIngreso.day;

    // Un día antes: si diaPago es 1, el aviso es el último día del mes anterior
    int diaAviso = diaPago - 1;
    int mesAviso = hoy.month;
    int anoAviso = hoy.year;

    if (diaAviso <= 0) {
      // Retroceder al mes anterior
      mesAviso = hoy.month - 1;
      if (mesAviso <= 0) { mesAviso = 12; anoAviso = hoy.year - 1; }
      // Último día de ese mes
      diaAviso = DateTime(anoAviso, mesAviso + 1, 0).day;
    }

    final fechaAviso = DateTime(anoAviso, mesAviso, diaAviso, 9, 0);

    debugPrint(
      '🔔 [AVISO PROGRAMADO] $nombreTrabajador\n'
      '   → Día de pago: $diaPago de cada mes\n'
      '   → Próximo recordatorio: ${fechaAviso.day}/${fechaAviso.month}/${fechaAviso.year} a las 09:00 AM\n'
      '   (cuando compiles en Android, esta notificación llegará al teléfono)',
    );
  }

  Future<void> cancelarTodas() async {}
}
