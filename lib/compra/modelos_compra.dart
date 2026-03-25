import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  // Firma digital en formato Base64 (opcional)
  final String? firmaB64;

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
    this.firmaB64,
    this.saldoDespuesTransaccion = 0.0,
  });

  factory TransaccionCompra.fromJson(Map<String, dynamic> json) {
    return TransaccionCompra(
      id: json['id'].toString(),
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'] == 'entregaMaterial' ? TipoTransaccion.entregaMaterial : TipoTransaccion.pagoEfectivo,
      detalleMateriaPrima: json['detalle_materia_prima'],
      kilos: json['kilos'] != null ? double.parse(json['kilos'].toString()) : null,
      importeCobrado: json['importe_cobrado'] != null ? double.parse(json['importe_cobrado'].toString()) : null,
      montoPagado: json['monto_pagado'] != null ? double.parse(json['monto_pagado'].toString()) : null,
      detalleExtra: json['detalle_extra'],
      comprobantePath: json['comprobante_path'],
      firmaB64: json['firma_b64'],
      saldoDespuesTransaccion: json['saldo_acumulado'] != null ? double.parse(json['saldo_acumulado'].toString()) : 0.0,
    );
  }
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

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'].toString(),
      nombre: json['nombre'],
      empresa: json['empresa'],
    );
  }
}

// ─────────────────────────────────────────────
// Servicio Compartido para el Módulo de Compras
// ─────────────────────────────────────────────
class ComprasService extends ChangeNotifier {
  static final ComprasService instance = ComprasService._();
  ComprasService._();

  final _api = ApiService.instance;
  final List<Proveedor> _proveedores = [];
  bool cargando = false;

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);

  Future<void> cargarProveedores() async {
    cargando = true;
    notifyListeners();
    try {
      final data = await _api.listarProveedores();
      _proveedores.clear();
      for (final p in data) {
        final prov = Proveedor.fromJson(p as Map<String, dynamic>);
        // Cargar también transacciones para cada proveedor
        final txs = await _api.listarTransacciones(int.parse(prov.id));
        prov.historial.clear();
        for (final t in txs) {
          prov.historial.add(TransaccionCompra.fromJson(t as Map<String, dynamic>));
        }
        _proveedores.add(prov);
      }
    } catch (e) {
      debugPrint('Error cargando proveedores: $e');
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> agregarProveedor(String nombre, String empresa) async {
    try {
      await _api.agregarProveedor(nombre, empresa);
      await cargarProveedores();
    } catch (e) {
      debugPrint('Error al agregar proveedor: $e');
    }
  }

  Future<void> registrarEntregaMaterial(Proveedor proveedor, String detalle, double kilos, double importeCobrado, {String? comprobantePath, String? firmaB64, DateTime? fechaRegistro, String? detalleExtra}) async {
    try {
      await _api.agregarTransaccion({
        'proveedor_id': int.parse(proveedor.id),
        'tipo': 'entregaMaterial',
        'detalle_materia_prima': detalle,
        'kilos': kilos,
        'importe_cobrado': importeCobrado,
        'comprobante_path': comprobantePath,
        'firma_b64': firmaB64,
        'fecha': (fechaRegistro ?? DateTime.now()).toIso8601String(),
        'detalle_extra': detalleExtra,
      });
      await cargarProveedores();
    } catch (e) {
      debugPrint('Error al registrar entrega: $e');
    }
  }

  Future<void> registrarPagoEfectivo(Proveedor proveedor, double montoPagado, {String? comprobantePath, String? firmaB64, DateTime? fechaRegistro, String? detalleExtra}) async {
    try {
      await _api.agregarTransaccion({
        'proveedor_id': int.parse(proveedor.id),
        'tipo': 'pagoEfectivo',
        'monto_pagado': montoPagado,
        'comprobante_path': comprobantePath,
        'firma_b64': firmaB64,
        'fecha': (fechaRegistro ?? DateTime.now()).toIso8601String(),
        'detalle_extra': detalleExtra,
      });
      await cargarProveedores();
    } catch (e) {
      debugPrint('Error al registrar pago: $e');
    }
  }
}
