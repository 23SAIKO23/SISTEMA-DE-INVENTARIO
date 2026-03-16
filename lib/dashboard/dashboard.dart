import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_service.dart';
import '../ventas/modelos_venta.dart';
import '../produccion/modelos_produccion.dart';
import '../compra/modelos_compra.dart';

// ── Colores del Dashboard Tipo BI ──────────────
const _kFondo = Color(0xFF0A1628);
const _kFondo2 = Color(0xFF0D2145);
const _kCardBg = Color(0xFF14294F); // Color mas solido para las tarjetas
const _kAzul = Color(0xFF1565C0);
const _kAzulClaro = Color(0xFF42A5F5);
const _kVerde = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kMorado = Color(0xFF8B5CF6);
const _kMoradoClaro = Color(0xFFA78BFA);
const _kNaranja = Color(0xFFF97316);
const _kNaranjaClaro = Color(0xFFFB923C);
const _kRojo = Color(0xFFEF4444);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _appSvc = AppService.instance;
  final _prodSvc = ProduccionService.instance;
  final _compSvc = ComprasService.instance;

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _appSvc.addListener(_onUpdate);
    _prodSvc.addListener(_onUpdate);
    _compSvc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _appSvc.removeListener(_onUpdate);
    _prodSvc.removeListener(_onUpdate);
    _compSvc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // ── 1. Cálculos de KPIs Top
  double _calcularVentasTotal() {
    return _appSvc.totalVentas;
  }

  double _calcularComprasTotal() {
    double total = 0;
    for (var p in _compSvc.proveedores) {
      for (var tx in p.historial) {
        if (tx.tipo == TipoTransaccion.entregaMaterial) {
          total += (tx.importeCobrado ?? 0);
        }
      }
    }
    return total;
  }

  double _calcularDeudaTotal() {
    return _appSvc.totalPendiente;
  }

  // ── 2. Datos para Gráfico de Ventas (Últimos 6 meses)
  List<double> _calcularVentasUltimosMeses() {
    final ahora = DateTime.now();
    List<double> ventasMeses = List.filled(6, 0.0);
    for (var v in _appSvc.ventas) {
      int diffMeses = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diffMeses >= 0 && diffMeses < 6) {
        ventasMeses[5 - diffMeses] += v.total;
      }
    }
    return ventasMeses;
  }

  // ── 3. Datos para Pie Chart (Colores más vendidos)
  List<MapEntry<String, double>> _calcularColoresMasVendidos() {
    Map<String, double> conteo = {};
    for (var v in _appSvc.ventas) {
      if (v.color.isNotEmpty && v.color.trim().toLowerCase() != 'sin color') {
        conteo[v.color] = (conteo[v.color] ?? 0) + v.cantidad;
      }
    }
    final lista = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista.take(4).toList(); // Top 4 para Pie Chart
  }

  // ── 4. Datos para Bar Chart (Producción por Trabajador)
  List<MapEntry<String, double>> _calcularProduccionPorTrabajador() {
    Map<String, double> prod = _prodSvc.produccionPorTrabajador;
    final lista = prod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista.take(5).toList();
  }

  // ── 5. Datos para Deudas por cliente
  List<MapEntry<String, double>> _calcularDeudasPorCliente() {
    Map<String, double> deudas = {};
    for (var v in _appSvc.pendientes) {
      deudas[v.cliente] = (deudas[v.cliente] ?? 0) + v.pendiente;
    }
    final lista = deudas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista.take(5).toList(); 
  }

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
              // ── Header Custom ────────────────
              _buildHeader(context),

              // ── Contenido Scrollable ────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  child: Column(
                    children: [
                      // KPIs Row
                      _buildKPIGrid(),
                      const SizedBox(height: 16),

                      // Sales Trend Line Chart
                      _buildSalesTrendCard(),
                      const SizedBox(height: 16),

                      // Bottom Grid (Pie Chart, Bar Chart, List)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 1, child: _buildColorsPieChartCard()),
                                const SizedBox(width: 16),
                                Expanded(flex: 1, child: _buildProductionBarChartCard()),
                                const SizedBox(width: 16),
                                Expanded(flex: 1, child: _buildDeudasCard()),
                              ],
                            );
                          } else if (constraints.maxWidth > 600) {
                             return Column(
                               children: [
                                 Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Expanded(flex: 1, child: _buildColorsPieChartCard()),
                                     const SizedBox(width: 16),
                                     Expanded(flex: 1, child: _buildProductionBarChartCard()),
                                   ],
                                 ),
                                 const SizedBox(height: 16),
                                 _buildDeudasCard(),
                               ],
                             );
                          } else {
                            return Column(
                              children: [
                                _buildColorsPieChartCard(),
                                const SizedBox(height: 16),
                                _buildProductionBarChartCard(),
                                const SizedBox(height: 16),
                                _buildDeudasCard(),
                              ],
                            );
                          }
                        },
                      )
                    ],
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard BI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  Text('Resumen Gerencial a Tiempo Real',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kAzulClaro.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kAzulClaro.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: _kAzulClaro, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat("MMM yyyy", "es").format(DateTime.now()).toUpperCase(),
                    style: const TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    final formatCurrency = NumberFormat.compactCurrency(symbol: 'Bs', decimalDigits: 1);
    
    double ventas = _calcularVentasTotal();
    double compras = _calcularComprasTotal();
    double utilidad = ventas - compras;
    double deudas = _calcularDeudaTotal();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 800 ? 2.2 : 1.8,
          children: [
            _buildKPIBox('Ingresos Totales', formatCurrency.format(ventas), Icons.trending_up_rounded, _kVerdeClaro),
            _buildKPIBox('Egresos (Compras)', formatCurrency.format(compras), Icons.shopping_cart_checkout_rounded, _kNaranjaClaro),
            _buildKPIBox('Utilidad Neta', formatCurrency.format(utilidad), Icons.account_balance_wallet_rounded, utilidad >= 0 ? _kAzulClaro : _kRojo),
            _buildKPIBox('Cuentas x Cobrar', formatCurrency.format(deudas), Icons.warning_amber_rounded, const Color(0xFFFBBF24)),
          ],
        );
      }
    );
  }

  Widget _buildKPIBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ── 1. LineChart (Sales Trend)
  Widget _buildSalesTrendCard() {
    List<double> ventasMes = _calcularVentasUltimosMeses();
    double maxY = ventasMes.isEmpty ? 100 : ventasMes.reduce((a, b) => a > b ? a : b) * 1.2;
    if(maxY == 0) maxY = 100;

    final mesesLabels = ['M-5', 'M-4', 'M-3', 'M-2', 'M-1', 'Mes Actual'];

    List<FlSpot> spots = [];
    for (int i = 0; i < ventasMes.length; i++) {
      spots.add(FlSpot(i.toDouble(), ventasMes[i]));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tendencia de Ventas (6 Meses)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(mesesLabels[value.toInt()], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(NumberFormat.compact().format(value), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _kVerdeClaro,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _kVerdeClaro.withValues(alpha: 0.3),
                          _kVerdeClaro.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                         return LineTooltipItem(
                           NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0).format(spot.y),
                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                         );
                      }).toList();
                    }
                  )
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. PieChart (Top Colors)
  Widget _buildColorsPieChartCard() {
    final topColores = _calcularColoresMasVendidos();
    final List<Color> palette = [_kAzulClaro, _kMoradoClaro, _kVerdeClaro, _kNaranjaClaro, _kRojo];
    
    double totalColores = 0;
    for (var c in topColores) {
      totalColores += c.value;
    }

    return Container(
      padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Colores', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (topColores.isEmpty) 
             Center(child: Text('Sin datos', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          if (topColores.isNotEmpty)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: List.generate(topColores.length, (i) {
                        final isTouched = i == _touchedPieIndex;
                        final double radius = isTouched ? 35 : 25;
                        return PieChartSectionData(
                          color: palette[i % palette.length],
                          value: topColores[i].value,
                          title: isTouched ? '${topColores[i].value.toInt()}' : '', // Show value on tap
                          radius: radius,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }),
                    ),
                  ),
                  // Texto estático en el centro
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      Text('${totalColores.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Leyenda lateral
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(topColores.length, (i) {
                final isTouched = i == _touchedPieIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          shape: BoxShape.circle,
                          border: isTouched ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topColores[i].key, 
                          style: TextStyle(
                            color: isTouched ? Colors.white : Colors.white.withValues(alpha: 0.7), 
                            fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${topColores[i].value.toInt()} und',
                        style: TextStyle(
                          color: isTouched ? Colors.white : Colors.white.withValues(alpha: 0.5), 
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      )
        ],
      ),
    );
  }

  // ── 3. BarChart (Worker Productivity)
  Widget _buildProductionBarChartCard() {
    final prod = _calcularProduccionPorTrabajador();
    double maxY = prod.isEmpty ? 100 : prod.first.value * 1.2;
    if(maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Producción por Trabajador', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (prod.isEmpty) 
             Center(child: Text('Sin datos', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
          if (prod.isNotEmpty)
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem('${prod[groupIndex].key}\n${rod.toY.toInt()} und', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                      }
                    )
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= prod.length) return const SizedBox();
                          // Extraemos solo el primer nombre
                          String nombre = prod[value.toInt()].key.split(' ').first;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(nombre, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(prod.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: prod[i].value,
                          color: _kNaranjaClaro,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.white.withValues(alpha: 0.05)
                          )
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 4. Deudas Card (Lista Refinada)
  Widget _buildDeudasCard() {
    final deudas = _calcularDeudasPorCliente();
    final formatCurrency = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuentas por Cobrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if(deudas.isEmpty) Text('Sin deudas pendientes', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ...deudas.map((d) {
            // Un pequeño indicador visual de peligro relativo a la deuda max
             double fillLevel = d.value / (deudas.first.value > 0 ? deudas.first.value : 1);
             return Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(child: Text(d.key, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                       Text(formatCurrency.format(d.value), style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Container(
                     height: 4,
                     alignment: Alignment.centerLeft,
                     decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2)),
                     child: FractionallySizedBox(
                       widthFactor: fillLevel,
                       child: Container(decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(2))),
                     ),
                   )
                 ],
               ),
             );
          })
        ],
      ),
    );
  }
}
