import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_service.dart';
import '../ventas/modelos_venta.dart';
import '../produccion/modelos_produccion.dart';
import '../compra/modelos_compra.dart';

// ── Paleta de colores BI ────────────────────────────────────────────────────
const _kFondo  = Color(0xFF060D1F);
const _kFondo2 = Color(0xFF0C1A3A);
const _kCard   = Color(0xFF0F1F3D);
const _kBorde  = Color(0xFF1A3060);

const _kCyan    = Color(0xFF00D4FF);
const _kGreen   = Color(0xFF00E5A0);
const _kPurple  = Color(0xFF8B5CF6);
const _kOrange  = Color(0xFFF97316);
const _kYellow  = Color(0xFFFBBF24);
const _kRed     = Color(0xFFEF4444);
const _kBlue    = Color(0xFF3B82F6);
const _kPink    = Color(0xFFEC4899);

// ── Clase Principal ─────────────────────────────────────────────────────────
class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage>
    with TickerProviderStateMixin {
  final _appSvc  = AppService.instance;
  final _prodSvc = ProduccionService.instance;
  final _compSvc = ComprasService.instance;

  int _touchedPie = -1;

  // Controladores de animación para las KPI cards
  late List<AnimationController> _kpiControllers;
  late List<Animation<double>> _kpiAnimations;

  @override
  void initState() {
    super.initState();
    // 6 KPIs
    _kpiControllers = List.generate(6, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + i * 120),
    ));
    _kpiAnimations = _kpiControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();

    _appSvc.addListener(_onUpdate);
    _prodSvc.addListener(_onUpdate);
    _compSvc.addListener(_onUpdate);

    // ── Cargar datos frescos al abrir la pantalla ──
    // Sin esto, la página aparecía vacía si el usuario no había
    // visitado el módulo Ventas ni Producción antes.
    _appSvc.cargarVentas();
    _prodSvc.cargarDesdeServidor();

    // Disparar animaciones con retardo
    for (int i = 0; i < _kpiControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) _kpiControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _kpiControllers) { c.dispose(); }
    _appSvc.removeListener(_onUpdate);
    _prodSvc.removeListener(_onUpdate);
    _compSvc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() { if (mounted) setState(() {}); }

  // ── Cálculos ────────────────────────────────────────────────────────────
  double get _ventas   => _appSvc.totalVentas;
  double get _pendiente => _appSvc.totalPendiente;

  double get _compras {
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

  double get _utilidad => _ventas - _compras;

  double get _unidadesVendidas =>
      _appSvc.ventas.fold(0.0, (s, v) => s + v.cantidad);

  int get _clientesActivos =>
      _appSvc.ventas.map((v) => v.cliente).toSet().length;

  // Ventas y cobrado por mes (últimos 6 meses)
  List<double> _ventasPorMes() {
    final ahora = DateTime.now();
    final result = List.filled(6, 0.0);
    for (var v in _appSvc.ventas) {
      int diff = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diff >= 0 && diff < 6) result[5 - diff] += v.total;
    }
    return result;
  }

  List<double> _cobradoPorMes() {
    final ahora = DateTime.now();
    final result = List.filled(6, 0.0);
    for (var v in _appSvc.ventas) {
      int diff = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diff >= 0 && diff < 6) result[5 - diff] += v.montoPagado;
    }
    return result;
  }

  List<String> _etiquetasMeses() {
    final ahora = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(ahora.year, ahora.month - (5 - i));
      return DateFormat('MMM', 'es').format(m).toUpperCase();
    });
  }

  // Colores más vendidos
  List<MapEntry<String, double>> _topColores() {
    final Map<String, double> conteo = {};
    for (var v in _appSvc.ventas) {
      if (v.color.isNotEmpty && v.color.trim().toLowerCase() != 'sin color') {
        conteo[v.color] = (conteo[v.color] ?? 0) + v.cantidad;
      }
    }
    return (conteo.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).toList();
  }

  // Producción por trabajador
  List<MapEntry<String, double>> _topTrabajadores() {
    final prod = _prodSvc.produccionPorTrabajador;
    return (prod.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).toList();
  }

  // Deudas por cliente
  List<MapEntry<String, double>> _topDeudas() {
    final Map<String, double> d = {};
    for (var v in _appSvc.pendientes) {
      d[v.cliente] = (d[v.cliente] ?? 0) + v.pendiente;
    }
    return (d.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).toList();
  }

  // Últimas ventas (max 5)
  List<Venta> get _ultimasVentas {
    final sorted = List<Venta>.from(_appSvc.ventas)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return sorted.take(5).toList();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  child: Column(
                    children: [
                      _buildKPIGrid(),
                      const SizedBox(height: 16),
                      _buildTendenciaCard(),
                      const SizedBox(height: 16),
                      _buildSectionLabel('DISTRIBUCIÓN & PRODUCCIÓN',
                          Icons.donut_large_rounded),
                      const SizedBox(height: 10),
                      _buildChartsRow(),
                      const SizedBox(height: 16),
                      _buildSectionLabel('CUENTAS POR COBRAR',
                          Icons.assignment_late_rounded),
                      const SizedBox(height: 10),
                      _buildDeudasBarCard(),
                      const SizedBox(height: 16),
                      _buildSectionLabel('ÚLTIMAS VENTAS',
                          Icons.receipt_long_rounded),
                      const SizedBox(height: 10),
                      _buildUltimasVentasCard(),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final ahora = DateTime.now();
    final fecha = DateFormat("EEEE, d 'de' MMMM yyyy", 'es').format(ahora);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kCard, _kCard.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Botón volver
          _glassButton(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 14),
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_kCyan, _kGreen],
                      ).createShader(b),
                      child: const Text(
                        'Estadísticas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kGreen.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: _kGreen, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          const Text('EN VIVO',
                              style: TextStyle(
                                  color: _kGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(fecha,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11)),
              ],
            ),
          ),
          // Ícono BI
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kCyan, _kBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: _kCyan.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kCyan.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _kBorde.withValues(alpha: 0.8),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── KPI Grid (6 cards) ────────────────────────────────────────────────────
  Widget _buildKPIGrid() {
    final fmt = NumberFormat.compactCurrency(symbol: 'Bs ', decimalDigits: 1);
    final fmtN = NumberFormat.compact(locale: 'es');

    final kpis = [
      _KPIData('Ingresos Totales', fmt.format(_ventas),
          Icons.trending_up_rounded, _kGreen, _ventas > 0),
      _KPIData('Egresos (Compras)', fmt.format(_compras),
          Icons.shopping_cart_checkout_rounded, _kOrange, true),
      _KPIData('Utilidad Neta', fmt.format(_utilidad),
          Icons.account_balance_wallet_rounded,
          _utilidad >= 0 ? _kCyan : _kRed, true,
          subtitle: _utilidad >= 0 ? '▲ positiva' : '▼ negativa'),
      _KPIData('Cuentas x Cobrar', fmt.format(_pendiente),
          Icons.warning_amber_rounded, _kYellow, true),
      _KPIData('Unidades Vendidas', '${fmtN.format(_unidadesVendidas)} und',
          Icons.inventory_2_rounded, _kPurple, true),
      _KPIData('Clientes Activos', '$_clientesActivos',
          Icons.people_alt_rounded, _kPink, true),
    ];

    return LayoutBuilder(builder: (ctx, cst) {
      final cols = cst.maxWidth > 800 ? 3 : 2;
      final ratio = cst.maxWidth > 800 ? 2.6 : 1.9;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: ratio,
        children: List.generate(kpis.length, (i) {
          return AnimatedBuilder(
            animation: _kpiAnimations[i],
            builder: (_, __) => Opacity(
              opacity: _kpiAnimations[i].value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _kpiAnimations[i].value)),
                child: _buildKPICard(kpis[i]),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildKPICard(_KPIData d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: d.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: d.color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(d.icon, color: d.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.title,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(d.value,
              style: TextStyle(
                  color: d.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          if (d.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(d.subtitle,
                style: TextStyle(
                    color: d.color.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // ── Tendencia doble línea ─────────────────────────────────────────────────
  Widget _buildTendenciaCard() {
    final vMes = _ventasPorMes();
    final cMes = _cobradoPorMes();
    final labels = _etiquetasMeses();
    final maxV = vMes.isEmpty ? 100.0 : vMes.reduce(max) * 1.25;
    final maxY = max(maxV, 1.0);

    List<FlSpot> spotsV = [for (int i = 0; i < vMes.length; i++) FlSpot(i.toDouble(), vMes[i])];
    List<FlSpot> spotsC = [for (int i = 0; i < cMes.length; i++) FlSpot(i.toDouble(), cMes[i])];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Tendencia Financiera',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              _legend(_kGreen, 'Ventas'),
              const SizedBox(width: 14),
              _legend(_kCyan, 'Cobrado'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Últimos 6 meses',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, m) => SideTitleWidget(
                        meta: m,
                        child: Text(
                          v.toInt() < labels.length ? labels[v.toInt()] : '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 4,
                      getTitlesWidget: (v, m) => Text(
                        NumberFormat.compact().format(v),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 5,
                minY: 0, maxY: maxY,
                lineBarsData: [
                  _lineBar(spotsV, _kGreen),
                  _lineBar(spotsC, _kCyan, dashed: true),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      'Bs ${NumberFormat('#,##0', 'es').format(s.y)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color,
      {bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: dashed ? 2 : 3,
      isStrokeCapRound: true,
      dashArray: dashed ? [6, 4] : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(
        show: !dashed,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11)),
      ],
    );
  }

  // ── Fila de gráficos (pie + barra) ────────────────────────────────────────
  Widget _buildChartsRow() {
    return LayoutBuilder(builder: (ctx, cst) {
      if (cst.maxWidth > 620) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPieCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildProduccionCard()),
          ],
        );
      }
      return Column(children: [
        _buildPieCard(),
        const SizedBox(height: 12),
        _buildProduccionCard(),
      ]);
    });
  }

  // ── Pie Chart ─────────────────────────────────────────────────────────────
  Widget _buildPieCard() {
    final top = _topColores();
    final List<Color> pal = [_kCyan, _kPurple, _kGreen, _kOrange, _kPink];
    final total = top.fold(0.0, (s, e) => s + e.value);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Colores Vendidos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Por unidades despachadas',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Sin datos',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4))),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (ev, resp) {
                                setState(() {
                                  if (!ev.isInterestedForInteractions ||
                                      resp?.touchedSection == null) {
                                    _touchedPie = -1;
                                  } else {
                                    _touchedPie = resp!
                                        .touchedSection!.touchedSectionIndex;
                                  }
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                            sections: List.generate(top.length, (i) {
                              final touched = i == _touchedPie;
                              final pct = total > 0
                                  ? (top[i].value / total * 100)
                                  : 0;
                              return PieChartSectionData(
                                color: pal[i % pal.length],
                                value: top[i].value,
                                title: touched
                                    ? '${pct.toStringAsFixed(0)}%'
                                    : '',
                                radius: touched ? 40 : 30,
                                titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              );
                            }),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.45),
                                    fontSize: 10)),
                            Text(NumberFormat.compact().format(total),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            Text('und',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.35),
                                    fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(top.length, (i) {
                      final touched = i == _touchedPie;
                      final pct = total > 0
                          ? (top[i].value / total * 100).toStringAsFixed(1)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: pal[i % pal.length],
                                shape: BoxShape.circle,
                                border: touched
                                    ? Border.all(
                                        color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(top[i].key,
                                  style: TextStyle(
                                      color: touched
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.65),
                                      fontSize: 11,
                                      fontWeight: touched
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('$pct%',
                                style: TextStyle(
                                    color: pal[i % pal.length],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Barra Producción ──────────────────────────────────────────────────────
  Widget _buildProduccionCard() {
    final top = _topTrabajadores();
    final maxY = top.isEmpty ? 100.0 : top.first.value * 1.3;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Producción por Trabajador',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Top 5 por unidades producidas',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Sin datos de producción',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4))),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        '${top[gi].key.split(' ').first}\n${rod.toY.toInt()} und',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final idx = v.toInt();
                          if (idx >= top.length) return const SizedBox();
                          return SideTitleWidget(
                            meta: m,
                            child: Text(
                              top[idx].key.split(' ').first,
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(top.length, (i) {
                    // Color de barra basado en el rank
                    final barColors = [_kCyan, _kGreen, _kPurple, _kOrange, _kPink];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: top[i].value,
                          gradient: LinearGradient(
                            colors: [
                              barColors[i % barColors.length],
                              barColors[i % barColors.length]
                                  .withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
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

  // ── Deudas — Barras horizontales ──────────────────────────────────────────
  Widget _buildDeudasBarCard() {
    final deudas = _topDeudas();
    final fmt = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);
    final maxD = deudas.isEmpty ? 1.0 : deudas.first.value;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Top Deudores',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kYellow.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Total: ${fmt.format(_pendiente)}',
                  style: const TextStyle(
                      color: _kYellow,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (deudas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: _kGreen.withValues(alpha: 0.6), size: 40),
                    const SizedBox(height: 8),
                    Text('¡Sin deudas pendientes!',
                        style: TextStyle(
                            color: _kGreen.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            ...deudas.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final fill = maxD > 0 ? d.value / maxD : 0.0;
              final colors = [_kRed, _kOrange, _kYellow, _kCyan, _kGreen];
              final c = colors[min(i, colors.length - 1)];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                  color: c, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(d.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        Text(fmt.format(d.value),
                            style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fill,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                c,
                                c.withValues(alpha: 0.5)
                              ]),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 6)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Tabla últimas ventas ──────────────────────────────────────────────────
  Widget _buildUltimasVentasCard() {
    final ventas = _ultimasVentas;
    final fmtMoneda = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);
    final fmtFecha = DateFormat('dd/MM', 'es');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Últimas Ventas',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_appSvc.ventas.length} total',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          if (ventas.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Sin ventas registradas',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4))),
              ),
            )
          else ...[
            // Encabezado tabla
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('CLIENTE',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('COLOR',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text('ESTADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            Container(height: 1,
                color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            // Filas
            ...ventas.map((v) {
              final (statusColor, statusLabel) = _estadoVenta(v);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.cliente,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text(fmtFecha.format(v.fecha),
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(v.color.isEmpty ? '—' : v.color,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(fmtMoneda.format(v.total),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(statusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  (Color, String) _estadoVenta(Venta v) {
    if (v.saldado) return (_kGreen, 'SALDADO');
    if (!v.generaCobranza) return (_kCyan, 'CONTADO');
    if (v.progreso >= 0.75) return (_kYellow, 'CASI');
    if (v.progreso >= 0.25) return (_kOrange, 'PARCIAL');
    return (_kRed, 'DEUDA');
  }

  // ── Card base ─────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorde.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Modelo de datos KPI ────────────────────────────────────────────────────
class _KPIData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasData;
  final String subtitle;

  const _KPIData(this.title, this.value, this.icon, this.color, this.hasData,
      {this.subtitle = ''});
}
