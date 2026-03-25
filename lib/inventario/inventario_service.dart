import 'package:flutter/foundation.dart';
import '../services/app_service.dart';
import '../produccion/produccion.dart';
import '../services/api_service.dart';

class InventarioService extends ChangeNotifier {
  InventarioService._() {
    // Escuchar cambios tanto de Ventas como de Producción
    // para recalcular automáticamente el stock.
    AppService.instance.addListener(_onDependenciaCambio);
    ProduccionService.instance.addListener(_onDependenciaCambio);
    cargarInventario();
  }

  static final InventarioService instance = InventarioService._();

  // Se llama cada vez que hay una nueva venta o producción registrada
  void _onDependenciaCambio() {
    cargarInventario();
  }

  // ── Lógica Central: Matemáticas del Inventario ──────────────────────────
  
  Map<String, int> _stockDesdeDB = {};
  bool cargando = false;

  Future<void> cargarInventario() async {
    cargando = true;
    notifyListeners();
    try {
      final List data = await ApiService.instance.listarInventario();
      _stockDesdeDB.clear();
      for (var item in data) {
        final String col = item['color'] ?? '';
        final int cant = (item['cantidad'] as num).toInt();
        if (col.isNotEmpty) {
          _stockDesdeDB[col] = cant;
        }
      }
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
    }
    cargando = false;
    notifyListeners();
  }

  // Devuelve el stock actual desde la base de datos
  Map<String, int> get inventarioActual => Map.unmodifiable(_stockDesdeDB);

  // Limpia el nombre del color para que sea "color entero" (ej: "Rojo/Negro" -> "Rojo")
  String normalizarColor(String color) {
    if (color.contains('/')) {
      return color.split('/')[0].trim();
    }
    return color.trim();
  }

  // Stock de un color específico
  int stockDe(String color) {
    return inventarioActual[color] ?? 0;
  }

  // Utilidad para extraer todos los colores que han existido históricamente
  // (Incluso si no hay stock actual en la base de datos)
  List<String> get todosLosColoresConocidos {
    final Set<String> colores = {..._stockDesdeDB.keys};
    
    // Fallback: Sumar colores de Producción
    for (var m in ProduccionService.instance.maquinas) {
      for (var s in m.historialProduccion) {
        for (var c in s.produccionPorColor.keys) {
          colores.add(normalizarColor(c));
        }
      }
    }
    
    // Fallback: Sumar colores de Ventas
    for (var v in AppService.instance.ventas) {
      if (v.color.isNotEmpty) {
        colores.add(normalizarColor(v.color));
      }
    }
    
    return colores.toList()..sort();
  }

  // Nueva utilidad: Devuelve una cadena con cortes de 20, cortes de 10 y chullas
  String formatearCortes(int totalUnidades) {
    if (totalUnidades <= 0) return "0 cortes";
    
    int c20 = totalUnidades ~/ 20;
    int resto = totalUnidades % 20;
    int c10 = resto >= 10 ? 1 : 0;
    int chullas = resto % 10;
    
    List<String> partes = [];
    if (c20 > 0) partes.add(c20 == 1 ? "1 corte de 20" : "$c20 cortes de 20");
    if (c10 > 0) partes.add("1 corte de 10");
    if (chullas > 0) partes.add(chullas == 1 ? "1 chulla" : "$chullas chullas");
    
    return partes.join(", ");
  }

  // --- MÉTODOS DE INSIGHTS (INTELIGENCIA) ---

  // Obtener el color más vendido históricamente
  String obtenerTopVendido() {
    final ventMap = _calcularVentasPorColor();
    if (ventMap.isEmpty) return "Sin datos";
    
    var entries = ventMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return entries.first.key;
  }

  // Colores con mucho stock y pocas ventas (Dinero estancado)
  List<String> obtenerStockDormido() {
    final stockMap = inventarioActual;
    final ventMap = _calcularVentasPorColor();
    
    // Un color está dormido si tiene más de 60 aguayos (3 cortes) y ventas menores a 5
    return stockMap.entries
      .where((e) => e.value >= 60 && (ventMap[e.key] ?? 0) < 5)
      .map((e) => e.key)
      .toList();
  }

  // Recomendación inteligente: Estrella vs Stock Quieto
  String generarRecomendacion() {
    final stockMap = inventarioActual;
    final ventMap = _calcularVentasPorColor();
    
    if (stockMap.isEmpty || ventMap.isEmpty) {
      return "Aún no hay suficientes ventas para dar un consejo. ¡Sigue produciendo tus básicos!";
    }

    // 1. EL REY (Color estrella por ventas)
    var listaVentas = ventMap.entries.where((e) => e.value >= 5).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (listaVentas.isEmpty) return "Tus ventas son muy bajas para dar consejos de producción.";
    
    String estrella = listaVentas.first.key;
    int ventasEstrella = ventMap[estrella] ?? 0;
    
    // 2. EL DORMIDO (Color que menos sale pero tiene mucho stock)
    var listaSanti = stockMap.entries
      .where((e) => e.value >= 20) // Solo colores que tenemos
      .map((e) => MapEntry(e.key, ventMap[e.key] ?? 0))
      .toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // De menos ventas a más
    
    String? dormido;
    if (listaSanti.isNotEmpty && listaSanti.first.key != estrella) {
      dormido = listaSanti.first.key;
    }

    // 3. CONSTRUIR RESPUESTA
    String consejo = "Tu color estrella es el **$estrella** con $ventasEstrella ventas. Te recomiendo seguirle dando a ese color.";
    
    if (dormido != null) {
      consejo += " Por otro lado, el **$dormido** casi no está saliendo, así que mejor no hagas mucho de ese por ahora.";
    }

    return consejo;
  }

  // Helper privado para cálculos internos
  Map<String, int> _calcularVentasPorColor() {
    final Map<String, int> ventMap = {};
    for (var venta in AppService.instance.ventas) {
      if (venta.color.isNotEmpty && venta.color.toLowerCase() != 'sin color') {
        final color = normalizarColor(venta.color);
        ventMap[color] = (ventMap[color] ?? 0) + venta.cantidad.toInt();
      }
    }
    return ventMap;
  }
}
