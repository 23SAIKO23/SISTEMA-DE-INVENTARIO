import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_service.dart';
import '../inventario/inventario_service.dart';
import '../ventas/modelos_venta.dart';

// ── Colores del Módulo Analítico ──────────────
const _kFondo = Color(0xFF0A1628);
const _kFondo2 = Color(0xFF0D2145);
const _kCardBg = Color(0xFF14294F); 
const _kVerde = Color(0xFF00C853);
const _kAmarillo = Color(0xFFFFB300);
const _kRojo = Color(0xFFEF4444);
const _kAzulClaro = Color(0xFF42A5F5);

class AnaliticaPage extends StatefulWidget {
  const AnaliticaPage({super.key});

  @override
  State<AnaliticaPage> createState() => _AnaliticaPageState();
}

class _AnaliticaPageState extends State<AnaliticaPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appSvc = AppService.instance;
  final _invSvc = InventarioService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _appSvc.addListener(_onUpdate);
    _invSvc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appSvc.removeListener(_onUpdate);
    _invSvc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LÓGICAS DE NEGOCIO
  // ─────────────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _calcularRotacion() {
    Map<String, int> sold = {};
    for (var v in _appSvc.ventas) {
      if (v.color.isNotEmpty && v.color.toLowerCase() != 'sin color') {
        sold[v.color] = (sold[v.color] ?? 0) + v.cantidad.toInt();
      }
    }

    final realStock = _invSvc.inventarioActual;
    List<Map<String, dynamic>> resultados = [];
    Set<String> todosLosColores = {...sold.keys, ...realStock.keys};

    for (var color in todosLosColores) {
      int stockActual = realStock[color] ?? 0;
      int ventasTotales = sold[color] ?? 0;
      
      double rotacion = ventasTotales / (stockActual == 0 ? 1 : stockActual);
      
      String recomendacion;
      Color colorBadge;
      IconData iconBadge;

      if (rotacion > 1.5 || (stockActual <= 5 && ventasTotales > 0)) {
        recomendacion = '🔥 Alta (Producir)';
        colorBadge = _kRojo;
        iconBadge = Icons.local_fire_department_rounded;
      } else if (rotacion > 0.5) {
        recomendacion = '⚡ Media (Mantener)';
        colorBadge = _kAmarillo;
        iconBadge = Icons.trending_flat_rounded;
      } else {
        recomendacion = '❄️ Baja (Pausar)';
        colorBadge = _kAzulClaro;
        iconBadge = Icons.ac_unit_rounded;
      }

      resultados.add({
        'color': color,
        'ventas': ventasTotales,
        'stock': stockActual,
        'rotacion': rotacion,
        'recomendacion': recomendacion,
        'colorBadge': colorBadge,
        'icon': iconBadge
      });
    }

    resultados.sort((a, b) => b['rotacion'].compareTo(a['rotacion']));
    return resultados;
  }

  List<Map<String, dynamic>> _calcularRiesgoMorosidad() {
    Map<String, Map<String, dynamic>> clientesData = {};

    for (var v in _appSvc.ventas) {
      if (!v.generaCobranza) continue;

      if (!clientesData.containsKey(v.cliente)) {
        clientesData[v.cliente] = {
          'totalComprado': 0.0,
          'totalPagado': 0.0,
          'deudaVencida': 0.0,
          'maxDiasAtraso': 0,
        };
      }

      clientesData[v.cliente]!['totalComprado'] += v.total;
      clientesData[v.cliente]!['totalPagado'] += v.montoPagado;

      if (!v.saldado) {
        int dias = DateTime.now().difference(v.fecha).inDays;
        if (dias > clientesData[v.cliente]!['maxDiasAtraso']) {
          clientesData[v.cliente]!['maxDiasAtraso'] = dias;
        }
        if (dias > 30) {
          clientesData[v.cliente]!['deudaVencida'] += v.pendiente;
        }
      }
    }

    List<Map<String, dynamic>> resultados = [];

    clientesData.forEach((cliente, data) {
      double totalComprado = data['totalComprado'];
      double totalPagado = data['totalPagado'];
      double deudaVencida = data['deudaVencida'];
      int maxDiasAtraso = data['maxDiasAtraso'];

      double ratioPago = totalComprado == 0 ? 0 : totalPagado / totalComprado;
      
      String riesgo;
      Color colorBadge;
      String desc;

      if (deudaVencida > 0 || maxDiasAtraso > 60 || ratioPago < 0.4) {
        riesgo = 'Alto Riesgo';
        colorBadge = _kRojo;
        desc = 'Historial crítico o deudas vencidas (+30d).';
      } else if (maxDiasAtraso > 15 || ratioPago < 0.8) {
        riesgo = 'Riesgo Medio';
        colorBadge = _kAmarillo;
        desc = 'Pagos atrasados o saldo parcial grande.';
      } else {
        riesgo = 'Bajo Riesgo';
        colorBadge = _kVerde;
        desc = 'Cliente puntual y con buen porcentaje de pago.';
      }

      resultados.add({
        'cliente': cliente,
        'ratio': ratioPago,
        'deudaVencida': deudaVencida,
        'maxDias': maxDiasAtraso,
        'riesgo': riesgo,
        'colorBadge': colorBadge,
        'desc': desc
      });
    });

    resultados.sort((a, b) {
      if (a['riesgo'] == 'Alto Riesgo' && b['riesgo'] != 'Alto Riesgo') return -1;
      if (b['riesgo'] == 'Alto Riesgo' && a['riesgo'] != 'Alto Riesgo') return 1;
      if (a['riesgo'] == 'Riesgo Medio' && b['riesgo'] == 'Bajo Riesgo') return -1;
      if (b['riesgo'] == 'Riesgo Medio' && a['riesgo'] == 'Bajo Riesgo') return 1;
      return 0;
    });

    return resultados;
  }

  Map<String, dynamic> _calcularEstacionalidad() {
    Map<int, double> ventasPorMes = {for (var i = 1; i <= 12; i++) i: 0.0};
    
    for (var v in _appSvc.ventas) {
      if (v.fecha.year == DateTime.now().year) {
        ventasPorMes[v.fecha.month] = ventasPorMes[v.fecha.month]! + v.cantidad.toDouble();
      }
    }

    int mejorMes = 1;
    int peorMes = 1;
    double maxVentas = 0;
    double minVentas = double.infinity;
    
    final curMonth = DateTime.now().month;

    for (int i = 1; i <= curMonth; i++) {
       final v = ventasPorMes[i]!;
       if (v >= maxVentas) {
         maxVentas = v;
         mejorMes = i;
       }
       if (v <= minVentas) {
         minVentas = v;
         peorMes = i;
       }
    }

    return {
      'ventasPorMes': ventasPorMes,
      'mejorMes': mejorMes,
      'peorMes': peorMes,
      'maxVentas': maxVentas,
      'minVentas': minVentas == double.infinity ? 0.0 : minVentas,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  UI
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabProduccion(),
                    _buildTabEstacionalidad(),
                    _buildTabMorosidad(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analítica Avanzada',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              Text('Decisiones basadas en Inteligencia Comercial',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: _kAzulClaro.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAzulClaro.withValues(alpha: 0.5))
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: "Producción"),
          Tab(text: "Tendencias"),
          Tab(text: "Riesgos"),
        ],
      ),
    );
  }

  // ── Helper: Tarjeta Asistente IA ──────────────────────────────────────────
  Widget _buildAIInsightCard(String title, String message, {Color color = _kAzulClaro}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── Tab 1: Producción ─────────────────────────────────────────────
  Widget _buildTabProduccion() {
    final datos = _calcularRotacion();
    
    // Generar Insight
    String aiMessage = "No hay datos suficientes para sugerir producción.";
    if (datos.isNotEmpty) {
      final top = datos.first;
      final bottom = datos.last;
      aiMessage = "El color '${top['color']}' se vende muy rápido y quedan solo ${top['stock']} unds en stock. ¡Prioriza su producción! ";
      if (bottom['rotacion'] == 0 && bottom['stock'] > 0) {
        aiMessage += "Por otro lado, tienes ${bottom['stock']} unds de '${bottom['color']}' estancadas, considera pausar su producción.";
      }
    }

    return Column(
      children: [
        _buildAIInsightCard('Asistente de Producción', aiMessage, color: _kAmarillo),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: datos.length,
            itemBuilder: (context, i) {
              final d = datos[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 50, decoration: BoxDecoration(color: d['colorBadge'], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['color'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStat('Vendido', '${d['ventas']} und'),
                              const SizedBox(width: 16),
                              _buildStat('En Stock', '${d['stock']} und'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: d['colorBadge'].withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(d['icon'], color: d['colorBadge'], size: 14),
                                    const SizedBox(width: 4),
                                    Text(d['recomendacion'], style: TextStyle(color: d['colorBadge'], fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Estacionalidad (NEW) ──────────────────────────────────
  Widget _buildTabEstacionalidad() {
    final est = _calcularEstacionalidad();
    final Map<int, double> ventas = est['ventasPorMes'];
    
    const mesesNombres = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    String aiMessage = "Aún no hay suficientes registros de ventas para este año.";
    if (est['maxVentas'] > 0) {
       String nombreMejor = mesesNombres[est['mejorMes'] - 1];
       String nombrePeor = mesesNombres[est['peorMes'] - 1];
       aiMessage = "Hasta ahora, $nombreMejor ha sido tu mes más alto con ${est['maxVentas'].toInt()} unds vendidas. En contraste, $nombrePeor fue el más bajo con ${est['minVentas'].toInt()} unds. Deberías prepararte para cubrir picos de demanda en meses similares a $nombreMejor.";
    }

    return Column(
      children: [
        _buildAIInsightCard('Análisis de Tendencia Anual', aiMessage, color: _kAzulClaro),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.only(top: 32, right: 16, left: 0, bottom: 16),
            decoration: BoxDecoration(
              color: _kCardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (est['maxVentas'] as double) * 1.2 == 0 ? 10 : (est['maxVentas'] as double) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${mesesNombres[group.x.toInt() - 1]}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} unds',
                            style: TextStyle(color: _kAzulClaro, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            mesesNombres[value.toInt() - 1],
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                          textAlign: TextAlign.end,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                    dashArray: [4, 4]
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: ventas.entries.where((e) => e.key <= DateTime.now().month || e.value > 0).map((e) {
                  final isMax = e.key == est['mejorMes'];
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: 16,
                        color: isMax ? _kAzulClaro : _kAzulClaro.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  // ── Tab 3: Morosidad ─────────────────────────────────────────────
  Widget _buildTabMorosidad() {
    final datos = _calcularRiesgoMorosidad();

    String aiMessage = "Todos tus clientes están al día. ¡Excelente trabajo y flujo de caja!";
    Color aiColor = _kVerde;

    if (datos.isNotEmpty) {
      final altos = datos.where((d) => d['riesgo'] == 'Alto Riesgo').toList();
      if (altos.isNotEmpty) {
        final peor = altos.first;
        final formatCurrency = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);
        aiMessage = "Cuidado. Tienes ${altos.length} cliente(s) en Alto Riesgo de morosidad. La deuda más crítica es la de '${peor['cliente']}' por ${formatCurrency.format(peor['deudaVencida'])} con más de 30 días de retraso. Se sugiere contactar a la brevedad.";
        aiColor = _kRojo;
      } else {
        final medios = datos.where((d) => d['riesgo'] == 'Riesgo Medio').toList();
        if (medios.isNotEmpty) {
           aiMessage = "Tienes ${medios.length} cliente(s) con Riesgo Medio (pagos parciales atrasados). Mantén un monitoreo constante, pero sin peligro crítico.";
           aiColor = _kAmarillo;
        }
      }
    }

    return Column(
      children: [
        _buildAIInsightCard('Riesgo Crediticio', aiMessage, color: aiColor),
        Expanded(
          child: datos.isEmpty 
          ? Center(child: Text("Sin historial crediticio registrado.", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: datos.length,
            itemBuilder: (context, i) {
              final d = datos[i];
              final pctStr = (d['ratio'] * 100).toStringAsFixed(0);
              final formatCurrency = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: d['colorBadge'].withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(d['cliente'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: d['colorBadge'], borderRadius: BorderRadius.circular(12)),
                          child: Text(d['riesgo'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(d['desc'], style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nivel de Cumplimiento ($pctStr%)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (d['ratio'] as double).clamp(0.0, 1.0),
                                  child: Container(decoration: BoxDecoration(color: d['colorBadge'], borderRadius: BorderRadius.circular(3))),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Vencido', style: TextStyle(color: Colors.white, fontSize: 10)),
                            Text(formatCurrency.format(d['deudaVencida']), style: TextStyle(color: _kRojo, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

