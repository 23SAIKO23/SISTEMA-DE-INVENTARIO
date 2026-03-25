// Modelos compartidos del módulo de Clientes

enum EstadoPago { puntual, seRetrasa, riesgo }
enum TipoCliente { tienda, casera, departamento }

class Cliente {
  final int id;
  String nombre;
  String telefono;
  String direccion;
  String ciudad; // Added 'ciudad' field
  TipoCliente tipo;
  double saldoPendiente;
  DateTime fechaRegistro;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.tipo,
    this.ciudad = '', // Added 'ciudad' to constructor
    this.saldoPendiente = 0.0,
    required this.fechaRegistro,
  });

  /// Estado calculado según saldo
  EstadoPago get estadoPago {
    if (saldoPendiente <= 0) return EstadoPago.puntual;
    if (saldoPendiente < 500) return EstadoPago.seRetrasa;
    return EstadoPago.riesgo;
  }

  /// Construir desde el JSON que devuelve la API PHP
  factory Cliente.fromJson(Map<String, dynamic> json) {
    final tipoStr = (json['tipo'] ?? 'tienda').toString();
    TipoCliente tipo;
    switch (tipoStr) {
      case 'casera':      tipo = TipoCliente.casera; break;
      case 'departamento': tipo = TipoCliente.departamento; break;
      default:            tipo = TipoCliente.tienda;
    }
    return Cliente(
      id:             int.tryParse(json['id'].toString()) ?? 0,
      nombre:         json['nombre'] ?? '',
      telefono:       json['telefono'] ?? '',
      direccion:      json['direccion'] ?? '',
      ciudad:         json['ciudad'] ?? '', // Parsing 'ciudad' from JSON
      tipo:           tipo,
      saldoPendiente: double.tryParse(json['saldo_pendiente'].toString()) ?? 0,
      fechaRegistro:  DateTime.tryParse(json['fecha_registro'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'telefono': telefono,
    'direccion': direccion, 'tipo': tipo.name,
    'saldo_pendiente': saldoPendiente,
  };
}
