import 'package:flutter/foundation.dart';

// ─── Registro Semanal por Máquina ──────────────────────────────────────────
class RegistroSemana {
  final String id; // ej. "2026-W10" (Año y número de semana)
  final DateTime fechaInicio; // Lunes
  final DateTime fechaFin;    // Domingo
  Map<String, double> produccionPorColor;
  bool cerrada;

  RegistroSemana({
    required this.id,
    required this.fechaInicio,
    required this.fechaFin,
    Map<String, double>? produccionPorColor,
    this.cerrada = false,
  }) : produccionPorColor = produccionPorColor ?? {};

  double get cantidadAcumulada => produccionPorColor.values.fold(0.0, (s, e) => s + e);

  String get etiquetaSemana =>
      '${fechaInicio.day.toString().padLeft(2,'0')}/${fechaInicio.month.toString().padLeft(2,'0')} - '
      '${fechaFin.day.toString().padLeft(2,'0')}/${fechaFin.month.toString().padLeft(2,'0')}';
}

// ─── Máquina ─────────────────────────────────────────────────────────────
class Maquina {
  final String id;
  String nombre;
  String trabajadorAsignado;
  
  // Historial de semanas
  List<RegistroSemana> historialProduccion;

  Maquina({
    required this.id,
    required this.nombre,
    required this.trabajadorAsignado,
    List<RegistroSemana>? historialProduccion,
  }) : historialProduccion = historialProduccion ?? [];

  // Total producido por esta máquina en toda su historia
  double get produccionTotal =>
      historialProduccion.fold(0.0, (s, r) => s + r.cantidadAcumulada);

  // Obtener la semana actual (abierta) o null si no hay
  RegistroSemana? get semanaActual {
    try {
      return historialProduccion.firstWhere((s) => !s.cerrada);
    } catch (_) {
      return null;
    }
  }

  // Sumar a la semana actual abierta
  void sumarASemanaActual(String color, double cant) {
    var actual = semanaActual;
    if (actual != null) {
      actual.produccionPorColor[color] = (actual.produccionPorColor[color] ?? 0.0) + cant;
    }
  }
}

// ─── Servicio singleton de Producción ─────────────────────────────────────
class ProduccionService extends ChangeNotifier {
  ProduccionService._() {
    // Al iniciar, verifica si hay que abrir semana para maquinas vacias
    _asegurarSemanaAbierta();
  }
  
  static final ProduccionService instance = ProduccionService._();

  final List<Maquina> _maquinas = [
    Maquina(
      id: 'M01', nombre: 'Máquina 1', trabajadorAsignado: 'Juan Mamani',
      historialProduccion: [
        RegistroSemana(
          id: '2026-W09', 
          fechaInicio: DateTime(2026, 2, 23), fechaFin: DateTime(2026, 3, 1),
          produccionPorColor: {'Verde': 120, 'Azul': 200}, cerrada: true,
        ),
      ],
    ),
    Maquina(
      id: 'M02', nombre: 'Máquina 2', trabajadorAsignado: 'María Quispe',
      historialProduccion: [
        RegistroSemana(
          id: '2026-W09', 
          fechaInicio: DateTime(2026, 2, 23), fechaFin: DateTime(2026, 3, 1),
          produccionPorColor: {'Rojo': 180, 'Negro': 100}, cerrada: true,
        ),
      ],
    ),
    Maquina(
      id: 'M03', nombre: 'Máquina 3', trabajadorAsignado: 'Carlos Condori',
    ),
    Maquina(
      id: 'M04', nombre: 'Máquina 4', trabajadorAsignado: 'Ana Flores',
    ),
  ];

  List<Maquina> get maquinas => List.unmodifiable(_maquinas);

  // Helpers para fechas (Semana Lunes-Domingo)
  static DateTime _obtenerLunes(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  static DateTime _obtenerDomingo(DateTime d) {
    return _obtenerLunes(d).add(const Duration(days: 6));
  }

  void _asegurarSemanaAbierta() {
    final hoy = DateTime.now();
    final lunes = _obtenerLunes(hoy);
    final domingo = _obtenerDomingo(hoy);
    final idSemana = '${lunes.year}-W${((lunes.difference(DateTime(lunes.year, 1, 1)).inDays) / 7).ceil()}';

    for (var m in _maquinas) {
      final actual = m.semanaActual;

      // 1. Si NO tiene semana abierta, creamos la de hoy
      if (actual == null) {
        m.historialProduccion.insert(0, RegistroSemana(
          id: idSemana,
          fechaInicio: lunes,
          fechaFin: domingo,
          produccionPorColor: {},
          cerrada: false,
        ));
      } 
      // 2. Si TIENE semana abierta, pero es de una semana que ya pasó (su fechaFin fue antes de este Lunes)
      else if (actual.fechaFin.isBefore(lunes)) {
        actual.cerrada = true; // La cerramos automáticamente
        
        // Y abrimos la semana actual
        m.historialProduccion.insert(0, RegistroSemana(
          id: idSemana,
          fechaInicio: lunes,
          fechaFin: domingo,
          produccionPorColor: {},
          cerrada: false,
        ));
      }
    }
  }

  // ── Totales globales ───────────────────────────────────────────────────
  double get totalProduccionGobal => _maquinas.fold(0.0, (s, m) => s + m.produccionTotal);
  
  double get totalSemanaActual => _maquinas.fold(0.0, (s, m) => s + (m.semanaActual?.cantidadAcumulada ?? 0));

  // ── Totales semanales por color ─────────────────────────────────────────
  Map<String, double> get totalSemanaActualPorColor {
    final Map<String, double> totales = {};
    for (var m in _maquinas) {
      final actual = m.semanaActual;
      if (actual != null) {
        actual.produccionPorColor.forEach((color, cantidad) {
          totales[color] = (totales[color] ?? 0.0) + cantidad;
        });
      }
    }
    return totales;
  }

  // ── Por trabajador ─────────────────────────────────────────────────────
  Map<String, double> get produccionPorTrabajador {
    final m = <String, double>{};
    for (final maq in _maquinas) {
      m[maq.trabajadorAsignado] = (m[maq.trabajadorAsignado] ?? 0) + maq.produccionTotal;
    }
    return m;
  }

  // ── Productividad (aguayos por SEMANA) global ─────────────────────────────
  double productividadSemanalTrabajador(String trabajador) {
    final maq = _maquinas.where((m) => m.trabajadorAsignado == trabajador).toList();
    if (maq.isEmpty) return 0;
    
    double total = 0;
    Set<String> semanasTrabajadas = {};
    for (var m in maq) {
      total += m.produccionTotal;
      semanasTrabajadas.addAll(m.historialProduccion.map((r) => r.id));
    }
    
    return semanasTrabajadas.isNotEmpty ? total / semanasTrabajadas.length : 0;
  }
  
  int semanasTrabajadasPorTrabajador(String trabajador) {
    final maq = _maquinas.where((m) => m.trabajadorAsignado == trabajador).toList();
    Set<String> semanasTrabajadas = {};
    for (var m in maq) {
      semanasTrabajadas.addAll(m.historialProduccion.map((r) => r.id));
    }
    return semanasTrabajadas.length;
  }

  // ── Mutaciones ─────────────────────────────────────────────────────────
  void registrarProduccionActual(String maquinaId, String color, double cantidadAgregada) {
    final mq = _maquinas.firstWhere((m) => m.id == maquinaId);
    mq.sumarASemanaActual(color, cantidadAgregada);
    notifyListeners();
  }

  void cerrarSemanaTodos() {
    for (var m in _maquinas) {
      if (m.semanaActual != null) {
        m.semanaActual!.cerrada = true;
      }
    }
    // Automáticamente abrir la siguiente semana para todos
    _asegurarSemanaAbierta();
    notifyListeners();
  }

  void agregarMaquina(Maquina m) {
    _maquinas.add(m);
    _asegurarSemanaAbierta(); // si se agrega, abrirle semana si no tiene
    notifyListeners();
  }

  void editarMaquina(String id, String nuevoNombre, String nuevoTrabajador) {
    final idx = _maquinas.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _maquinas[idx].nombre = nuevoNombre;
      _maquinas[idx].trabajadorAsignado = nuevoTrabajador;
      notifyListeners();
    }
  }

  void eliminarMaquina(String id) {
    _maquinas.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
