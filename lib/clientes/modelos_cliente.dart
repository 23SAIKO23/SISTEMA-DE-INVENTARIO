// Modelos compartidos del módulo de Clientes
// Este archivo NO importa ningún otro archivo del módulo.

// ─────────────────────────────────────────────
//  Estado de pago (semáforo)
// ─────────────────────────────────────────────
enum EstadoPago { puntual, seRetrasa, riesgo }

// ─────────────────────────────────────────────
//  Tipo de cliente
// ─────────────────────────────────────────────
enum TipoCliente { tienda, casera, departamento }

// ─────────────────────────────────────────────
//  Modelo Cliente
// ─────────────────────────────────────────────
class Cliente {
  final String id;
  String nombre;
  String telefono;
  String direccion;
  TipoCliente tipo;
  double saldoPendiente;
  EstadoPago estadoPago;
  DateTime fechaRegistro;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.tipo,
    this.saldoPendiente = 0.0,
    this.estadoPago = EstadoPago.puntual,
    required this.fechaRegistro,
  });
}
