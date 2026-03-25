import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio central que conecta Flutter con la API PHP en XAMPP
class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  static const String _base = 'http://localhost/marcali';

  // ── Helper genérico ───────────────────────────────────────────
  Future<dynamic> _get(String ruta) async {
    final res = await http.get(Uri.parse('$_base/$ruta'));
    final body = utf8.decode(res.bodyBytes);
    try {
      return jsonDecode(body);
    } catch (e) {
      print('❌ ERROR API [GET] en $ruta: $e');
      print('📄 RESPUESTA DEL SERVIDOR: $body');
      rethrow;
    }
  }

  Future<dynamic> _post(String ruta, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base/$ruta'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final responseBody = utf8.decode(res.bodyBytes);
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      print('❌ ERROR API [POST] en $ruta: $e');
      print('📄 RESPUESTA DEL SERVIDOR: $responseBody');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // 🔐 AUTH
  // ════════════════════════════════════════════════════
  Future<Map> registrar(String nombre, String email, String password) async =>
      await _post('auth/registrar.php', {'nombre': nombre, 'email': email, 'password': password});

  Future<Map> login(String email, String password) async =>
      await _post('auth/login.php', {'email': email, 'password': password});

  // ════════════════════════════════════════════════════
  // 👥 CLIENTES
  // ════════════════════════════════════════════════════
  Future<List> listarClientes() async => await _get('clientes/listar.php');

  Future<Map> agregarCliente({required String nombre, String telefono = '', String ciudad = '', String direccion = '', String tipo = 'tienda'}) async =>
      await _post('clientes/agregar.php', {'nombre': nombre, 'telefono': telefono, 'ciudad': ciudad, 'direccion': direccion, 'tipo': tipo});

  Future<Map> editarCliente({required int id, required String nombre, String telefono = '', String ciudad = '', String direccion = '', String tipo = 'tienda'}) async =>
      await _post('clientes/editar.php', {'id': id, 'nombre': nombre, 'telefono': telefono, 'ciudad': ciudad, 'direccion': direccion, 'tipo': tipo});

  Future<Map> eliminarCliente(int id) async =>
      await _post('clientes/eliminar.php', {'id': id});

  // ════════════════════════════════════════════════════
  // 🛒 VENTAS
  // ════════════════════════════════════════════════════
  Future<List> listarVentas() async => await _get('ventas/listar.php');

  Future<Map> agregarVenta({
    required String cliente, required String tipo, String color = '',
    required double cantidad, String destino = '',
    required double precioUnit, required String pago, double montoPagado = 0,
  }) async => await _post('ventas/agregar.php', {
    'cliente': cliente, 'tipo': tipo, 'color': color,
    'cantidad': cantidad, 'destino': destino,
    'precio_unit': precioUnit, 'pago': pago, 'monto_pagado': montoPagado,
  });

  Future<Map> abonarVenta({required int ventaId, required double monto, String nota = '', String? comprobanteB64}) async =>
      await _post('ventas/abonar.php', {'venta_id': ventaId, 'monto': monto, 'nota': nota, 'comprobante_b64': comprobanteB64});

  Future<Map> eliminarVenta(int id) async =>
      await _post('ventas/eliminar.php', {'id': id});

  // ════════════════════════════════════════════════════
  // 📦 COMPRAS
  // ════════════════════════════════════════════════════
  Future<List> listarProveedores() async => await _get('compras/listar_proveedores.php');

  Future<Map> agregarProveedor(String nombre, String empresa) async =>
      await _post('compras/agregar_proveedor.php', {'nombre': nombre, 'empresa': empresa});

  Future<List> listarTransacciones(int proveedorId) async =>
      await _get('compras/listar_transacciones.php?proveedor_id=$proveedorId');

  Future<Map> agregarTransaccion(Map<String, dynamic> datos) async =>
      await _post('compras/agregar_transaccion.php', datos);

  // ════════════════════════════════════════════════════
  // 🏭 PRODUCCIÓN
  // ════════════════════════════════════════════════════
  Future<List> obtenerProduccionCompleta() async => await _get('produccion/obtener_produccion_completa.php');

  Future<List> listarMaquinas() async => await _get('produccion/listar_maquinas.php');

  Future<Map> agregarMaquina(String nombre, String trabajador) async =>
      await _post('produccion/agregar_maquina.php', {'nombre': nombre, 'trabajador_asignado': trabajador});

  Future<Map> registrarProduccion({
    required int maquinaId, required String semanaId,
    required String fechaInicio, required String fechaFin,
    required String color, required double cantidad,
  }) async => await _post('produccion/registrar_produccion.php', {
    'maquina_id': maquinaId, 'semana_id': semanaId,
    'fecha_inicio': fechaInicio, 'fecha_fin': fechaFin,
    'color': color, 'cantidad': cantidad,
  });

  Future<Map> cerrarSemanasGlobal() async => await _post('produccion/cerrar_semanas.php', {});
  // 💰 SALARIOS
  // ════════════════════════════════════════════════════
  Future<List> listarTrabajadores() async => await _get('salarios/listar.php');

  Future<Map> agregarTrabajador({required String nombre, String cargo = '', double salarioBase = 0, String? fechaIngreso}) async =>
      await _post('salarios/agregar_trabajador.php', {'nombre': nombre, 'cargo': cargo, 'salario_base': salarioBase, 'fecha_ingreso': fechaIngreso ?? DateTime.now().toIso8601String().split('T')[0]});

  Future<Map> registrarPago({required int trabajadorId, required double monto, required String mesCorrespondiente}) async =>
      await _post('salarios/registrar_pago.php', {'trabajador_id': trabajadorId, 'monto': monto, 'mes_correspondiente': mesCorrespondiente});

  // ════════════════════════════════════════════════════
  // 🧵 URDIDO
  // ════════════════════════════════════════════════════
  Future<List> listarUrdido() async => await _get('urdido/listar.php');

  Future<Map> guardarArmada(Map<String, dynamic> datos) async =>
      await _post('urdido/guardar_armada.php', datos);

  Future<Map> eliminarArmada(int id) async =>
      await _post('urdido/eliminar_armada.php', {'id': id});

  // ════════════════════════════════════════════════════
  // 📦 INVENTARIO
  // ════════════════════════════════════════════════════
  Future<List> listarInventario() async => await _get('inventario/listar.php');
}
