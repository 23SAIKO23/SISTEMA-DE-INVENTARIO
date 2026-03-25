import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_service.dart';
import '../produccion/modelos_produccion.dart';

// ── Paleta Premium ─────────────────────────────────────────────────────────
const _kFondo  = Color(0xFF060D1F);
const _kFondo2 = Color(0xFF0B1830);
const _kCard   = Color(0xFF0F1F3D);
const _kBorde  = Color(0xFF1A3060);
const _kCyan   = Color(0xFF00D4FF);
const _kGreen  = Color(0xFF00E5A0);
const _kPurple = Color(0xFF8B5CF6);
const _kOrange = Color(0xFFF97316);
const _kYellow = Color(0xFFFBBF24);
const _kRed    = Color(0xFFEF4444);
const _kPink   = Color(0xFFEC4899);

// ── Motor de IA ─────────────────────────────────────────────────────────────
class _IAEngine {
  // Regresión lineal simple (mínimos cuadrados)
  static ({double slope, double intercept, double r2}) linearRegression(List<double> y) {
    final n = y.length;
    if (n < 2) return (slope: 0, intercept: y.isEmpty ? 0 : y[0], r2: 0);
    final xs = List.generate(n, (i) => i.toDouble());
    final mx = xs.fold(0.0, (s, x) => s + x) / n;
    final my = y.fold(0.0, (s, v) => s + v) / n;
    double num = 0, den = 0, ssTot = 0, ssRes = 0;
    for (int i = 0; i < n; i++) {
      num += (xs[i] - mx) * (y[i] - my);
      den += pow(xs[i] - mx, 2);
    }
    final slope = den == 0 ? 0 : num / den;
    final intercept = my - slope * mx;
    for (int i = 0; i < n; i++) {
      final pred = slope * i + intercept;
      ssRes += pow(y[i] - pred, 2);
      ssTot += pow(y[i] - my, 2);
    }
    final r2 = ssTot == 0 ? 1.0 : (1 - ssRes / ssTot).clamp(0.0, 1.0);
    return (slope: slope.toDouble(), intercept: intercept, r2: r2);
  }

  // Predice el próximo valor
  static double predecirProximo(List<double> historia) {
    final reg = linearRegression(historia);
    return max(0, reg.slope * historia.length + reg.intercept);
  }

  // Score crediticio 0-100
  static double scoreCredito(double ratioPago, int diasAtraso, double deudaVencida, double totalHistorico) {
    double score = 100;
    score -= (1 - ratioPago.clamp(0, 1)) * 40;
    if (diasAtraso > 60) score -= 30;
    else if (diasAtraso > 30) score -= 20;
    else if (diasAtraso > 15) score -= 10;
    if (totalHistorico > 0) score -= (deudaVencida / totalHistorico * 30).clamp(0, 30);
    return score.clamp(0, 100);
  }


}

// ── Página Principal ─────────────────────────────────────────────────────────
class AnaliticaPage extends StatefulWidget {
  const AnaliticaPage({super.key});
  @override
  State<AnaliticaPage> createState() => _AnaliticaPageState();
}

class _AnaliticaPageState extends State<AnaliticaPage> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final _appSvc  = AppService.instance;
  final _prodSvc = ProduccionService.instance;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _appSvc.addListener(_onUpdate);
    _prodSvc.addListener(_onUpdate);
    _appSvc.cargarVentas();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _appSvc.removeListener(_onUpdate);
    _prodSvc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() { if (mounted) setState(() {}); }

  // ── Datos computados ────────────────────────────────────────────────────
  List<double> _ventasPorMes(int meses) {
    final ahora = DateTime.now();
    final result = List.filled(meses, 0.0);
    for (var v in _appSvc.ventas) {
      int diff = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diff >= 0 && diff < meses) result[meses - 1 - diff] += v.total;
    }
    return result;
  }

  List<double> _unidadesPorMes(int meses) {
    final ahora = DateTime.now();
    final result = List.filled(meses, 0.0);
    for (var v in _appSvc.ventas) {
      int diff = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diff >= 0 && diff < meses) result[meses - 1 - diff] += v.cantidad;
    }
    return result;
  }

  List<String> _etiquetasMeses(int meses) {
    final ahora = DateTime.now();
    return List.generate(meses, (i) {
      final m = DateTime(ahora.year, ahora.month - (meses - 1 - i));
      return DateFormat('MMM', 'es').format(m).toUpperCase();
    });
  }



  List<Map<String, dynamic>> _analisisCredito() {
    final Map<String, Map<String, dynamic>> data = {};
    for (var v in _appSvc.ventas) {
      if (!v.generaCobranza) continue;
      data.putIfAbsent(v.cliente, () => {
        'total': 0.0, 'pagado': 0.0, 'vencida': 0.0, 'maxDias': 0, 'ventas': 0
      });
      data[v.cliente]!['total'] = (data[v.cliente]!['total'] as double) + v.total;
      data[v.cliente]!['pagado'] = (data[v.cliente]!['pagado'] as double) + v.montoPagado;
      data[v.cliente]!['ventas'] = (data[v.cliente]!['ventas'] as int) + 1;
      if (!v.saldado) {
        final dias = DateTime.now().difference(v.fecha).inDays;
        if (dias > (data[v.cliente]!['maxDias'] as int)) {
          data[v.cliente]!['maxDias'] = dias;
        }
        if (dias > 30) data[v.cliente]!['vencida'] = (data[v.cliente]!['vencida'] as double) + v.pendiente;
      }
    }
    return data.entries.map((e) {
      final ratio = e.value['total'] > 0 ? e.value['pagado'] / e.value['total'] : 1.0;
      final score = _IAEngine.scoreCredito(ratio, e.value['maxDias'], e.value['vencida'], e.value['total']);
      return {'cliente': e.key, 'score': score, 'ratio': ratio, ...e.value};
    }).toList()..sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kFondo, _kFondo2],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildTabPrediccion(),
                  _buildTabDemanda(),
                  _buildTabCredito(),
                  _buildTabProduccion(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [_kPurple, _kPink]).createShader(b),
              child: const Text('Analítica IA', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPurple.withValues(alpha: 0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.auto_awesome_rounded, color: _kPurple, size: 10),
                    SizedBox(width: 4),
                    Text('PREDICTIVO', style: TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ]),
                ),
              ),
            ),
          ]),
          Text('Motor de análisis predictivo basado en tendencias',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
        ])),
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPurple, _kPink], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24)),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorde.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPurple, _kPink]),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: '🔮 Predicción'),
          Tab(text: '📦 Demanda'),
          Tab(text: '💳 Crédito'),
          Tab(text: '🏭 Producción'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: PREDICCIÓN DE VENTAS (regresión lineal)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabPrediccion() {
    final historia = _ventasPorMes(6);
    final histUnid = _unidadesPorMes(6);
    final labels = _etiquetasMeses(6);
    final regV = _IAEngine.linearRegression(historia);
    final predMonto = _IAEngine.predecirProximo(historia);
    final predUnid = _IAEngine.predecirProximo(histUnid);
    final confianza = (regV.r2 * 100).toStringAsFixed(0);
    final fmt = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);
    final tendencia = regV.slope > 50 ? '📈 Ascendente' : regV.slope < -50 ? '📉 Descendente' : '➡️ Estable';
    final colorTend = regV.slope > 50 ? _kGreen : regV.slope < -50 ? _kRed : _kYellow;

    // Spots reales + proyección
    List<FlSpot> spotsReal = [for (int i = 0; i < historia.length; i++) FlSpot(i.toDouble(), historia[i])];
    List<FlSpot> spotsProyec = [
      FlSpot((historia.length - 1).toDouble(), historia.last),
      FlSpot(historia.length.toDouble(), predMonto),
    ];
    final maxY = max([...historia, predMonto].fold(0.0, max), 1.0) * 1.3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // KPI Predicción
        Row(children: [
          Expanded(child: _kpiCard('Predicción Próximo Mes', fmt.format(predMonto), Icons.trending_up_rounded, _kPurple,
            sub: '${predUnid.toInt()} unidades')),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Tendencia', tendencia, Icons.show_chart_rounded, colorTend,
            sub: 'R² = $confianza% confianza')),
        ]),
        const SizedBox(height: 12),

        // Insight IA
        _iaCard(
          icon: Icons.auto_awesome_rounded,
          color: _kPurple,
          title: 'Predicción IA — Próximo Mes',
          msg: historia.every((v) => v == 0)
            ? 'Aún no hay datos históricos suficientes. Registra ventas para activar el motor predictivo.'
            : 'Basándome en la regresión lineal de los últimos 6 meses (R²=$confianza%), el próximo mes deberías facturar aproximadamente ${fmt.format(predMonto)} con ${predUnid.toInt()} unidades. La tendencia es $tendencia. ${regV.slope > 0 ? "¡Vas en buen camino!" : "Considera revisar tu estrategia de ventas."}',
        ),
        const SizedBox(height: 12),

        // Gráfico histórico + proyección
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Histórico + Proyección', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            _dot(_kCyan, 'Real'),
            const SizedBox(width: 12),
            _dot(_kPurple, 'Proyectado', dashed: true),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  final allLabels = [...labels, 'Pred'];
                  if (idx < 0 || idx >= allLabels.length) return const SizedBox();
                  return SideTitleWidget(meta: m, child: Text(allLabels[idx],
                    style: TextStyle(color: idx == labels.length ? _kPurple : Colors.white.withValues(alpha: 0.45),
                      fontSize: 10, fontWeight: FontWeight.w600)));
                })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 52, interval: maxY / 4,
                getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: historia.length.toDouble(), minY: 0, maxY: maxY,
            lineBarsData: [
              LineChartBarData(spots: spotsReal, isCurved: true, color: _kCyan, barWidth: 3,
                dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: _kCyan, strokeWidth: 0)),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  colors: [_kCyan.withValues(alpha: 0.2), _kCyan.withValues(alpha: 0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              LineChartBarData(spots: spotsProyec, isCurved: false, color: _kPurple, barWidth: 2,
                dashArray: [6, 4],
                dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 5,
                  color: i == 1 ? _kPurple : Colors.transparent,
                  strokeColor: i == 1 ? Colors.white : Colors.transparent, strokeWidth: 2))),
            ],
            lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                fmt.format(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList())),
          ))),
        ])),

        const SizedBox(height: 12),
        // Tabla mensual
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Detalle Mensual', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('vs Tendencia IA', style: TextStyle(color: _kPurple.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          ...List.generate(historia.length, (i) {
            final reg = regV;
            final predicted = max(0.0, reg.slope * i + reg.intercept);
            double diff = historia[i] - predicted;
            
            // Si no hay ventas, no mostramos el "negativo" de la tendencia 
            // técnica para no confundir al usuario con deudas inexistentes.
            if (historia[i] == 0 && diff < 0) diff = 0;
            
            final isPositive = diff >= 0;
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
              SizedBox(width: 40, child: Text(labels[i], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11))),
              const SizedBox(width: 8),
              Expanded(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(fmt.format(historia[i]), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(diff == 0 ? '+Bs 0' : '${isPositive ? "+" : ""}${fmt.format(diff)}',
                    style: TextStyle(color: diff == 0 ? _kGreen.withValues(alpha: 0.5) : (isPositive ? _kGreen : _kRed), 
                      fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: maxY > 0 ? (historia[i] / maxY).clamp(0, 1) : 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(_kCyan.withValues(alpha: 0.7)),
                  minHeight: 3, borderRadius: BorderRadius.circular(2)),
              ])),
            ]));
          }),
        ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: PREDICCIÓN DE DEMANDA POR COLOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabDemanda() {
    // Construir histórico de 3 meses por color
    final ahora = DateTime.now();
    final Map<String, List<double>> histPorColor = {};
    for (var v in _appSvc.ventas) {
      if (v.color.isEmpty || v.color.toLowerCase() == 'sin color') continue;
      histPorColor.putIfAbsent(v.color, () => List.filled(3, 0.0));
      int diff = (ahora.year - v.fecha.year) * 12 + ahora.month - v.fecha.month;
      if (diff >= 0 && diff < 3) histPorColor[v.color]![2 - diff] += v.cantidad;
    }

    final colores = histPorColor.entries.map((e) {
      final pred = _IAEngine.predecirProximo(e.value);
      final reg = _IAEngine.linearRegression(e.value);
      return {'color': e.key, 'hist': e.value, 'pred': pred, 'slope': reg.slope, 'r2': reg.r2};
    }).toList()..sort((a, b) => (b['pred'] as double).compareTo(a['pred'] as double));

    final topColor = colores.isNotEmpty ? colores.first['color'] as String : '';
    final topPred = colores.isNotEmpty ? colores.first['pred'] as double : 0.0;

    final palette = [_kCyan, _kPurple, _kGreen, _kOrange, _kPink, _kYellow];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _iaCard(
          icon: Icons.inventory_2_rounded,
          color: _kOrange,
          title: 'Predicción de Demanda',
          msg: colores.isEmpty
            ? 'Registra ventas para que el motor IA calcule qué colores necesitas producir más.'
            : 'El próximo mes, el color "$topColor" tendrá la mayor demanda estimada: ${topPred.toInt()} unidades. '
              'Programa tu producción con al menos 2 semanas de anticipación para cubrir esta demanda.',
        ),
        const SizedBox(height: 12),

        if (colores.isEmpty)
          _emptyState('Sin datos de ventas por color')
        else
          ...colores.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final slope = d['slope'] as double;
            final colorBarra = palette[i % palette.length];
            final pred = d['pred'] as double;
            final hist = d['hist'] as List<double>;
            final maxH = hist.fold(0.0, max);

            return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colorBarra, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: colorBarra.withValues(alpha: 0.6), blurRadius: 8)])),
                const SizedBox(width: 8),
                Expanded(child: Text(d['color'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
                _badge(slope > 0 ? '▲ Subiendo' : slope < 0 ? '▼ Bajando' : '→ Estable',
                  slope > 0 ? _kGreen : slope < 0 ? _kRed : _kYellow),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(children: [
                  ...['M-2', 'M-1', 'Actual'].asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 40, child: Text(e.value, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10))),
                      Expanded(child: Stack(children: [
                        Container(height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(widthFactor: maxH > 0 ? (hist[e.key] / maxH).clamp(0.0, 1.0) : 0,
                          child: Container(height: 6, decoration: BoxDecoration(
                            color: colorBarra.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)))),
                      ])),
                      const SizedBox(width: 8),
                      Text('${hist[e.key].toInt()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                    ]),
                  )),
                ])),
                const SizedBox(width: 16),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorBarra.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorBarra.withValues(alpha: 0.4))),
                  child: Column(children: [
                    Text('Pronóstico', style: TextStyle(color: colorBarra.withValues(alpha: 0.8), fontSize: 10)),
                    Text('${pred.toInt()}', style: TextStyle(color: colorBarra, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('unidades', style: TextStyle(color: colorBarra.withValues(alpha: 0.7), fontSize: 10)),
                  ]),
                ),
              ]),
            ]), mb: 10);
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: RIESGO CREDITICIO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabCredito() {
    final clientes = _analisisCredito();
    final fmt = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 0);
    final altos = clientes.where((c) => (c['score'] as double) < 40).length;
    final medios = clientes.where((c) {
      final s = c['score'] as double; return s >= 40 && s < 70;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Resumen
        Row(children: [
          Expanded(child: _kpiCard('Alto Riesgo', '$altos clientes', Icons.warning_rounded, _kRed)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Riesgo Medio', '$medios clientes', Icons.remove_circle_rounded, _kYellow)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Bajo Riesgo', '${clientes.length - altos - medios} clientes', Icons.check_circle_rounded, _kGreen)),
        ]),
        const SizedBox(height: 12),

        _iaCard(
          icon: Icons.credit_score_rounded,
          color: clientes.isEmpty ? _kGreen : (altos > 0 ? _kRed : _kYellow),
          title: 'Score Crediticio IA',
          msg: clientes.isEmpty
            ? '¡Sin cuentas por cobrar! Todos los clientes están al día.'
            : altos > 0
              ? 'ALERTA: $altos cliente(s) con score crítico (bajo 40/100). Riesgo real de impago. Prioriza el contacto y considera pausar crédito.'
              : medios > 0
                ? '$medios cliente(s) en zona de riesgo medio. Monitoreo recomendado cada semana.'
                : '¡Cartera sana! Todos tus clientes tienen buen historial de pago.',
        ),
        const SizedBox(height: 12),

        if (clientes.isEmpty)
          _emptyState('Sin historial crediticio')
        else
          ...clientes.map((c) {
            final score = c['score'] as double;
            final (col, label) = score < 40 ? (_kRed, 'ALTO RIESGO') : score < 70 ? (_kYellow, 'RIESGO MEDIO') : (_kGreen, 'CONFIABLE');
            final ratio = (c['ratio'] as double).clamp(0.0, 1.0);
            return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c['cliente'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
                _badge(label, col),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                // Score gauge
                SizedBox(width: 80, child: Column(children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, v, child) => Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 70, height: 70, child: CircularProgressIndicator(
                        value: v / 100, strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                        valueColor: AlwaysStoppedAnimation(col),
                      )),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${v.toInt()}', style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('/100', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
                      ]),
                    ]),
                  ),
                  Text('Score IA', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _statRow('Cumplimiento', '${(ratio * 100).toStringAsFixed(0)}%',
                    progressValue: ratio, progressColor: col),
                  const SizedBox(height: 8),
                  _statRow('Deuda vencida', fmt.format(c['vencida']), valueColor: c['vencida'] > 0 ? _kRed : _kGreen),
                  const SizedBox(height: 8),
                  _statRow('Días máx. atraso', '${c['maxDias']} días', valueColor: c['maxDias'] > 30 ? _kRed : _kYellow),
                ])),
              ]),
            ]), mb: 10);
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: PRODUCCIÓN — Eficiencia por Trabajador
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabProduccion() {
    final prodMap = _prodSvc.produccionPorTrabajador;
    final trabajadores = (prodMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8).toList();
    final totalProd = trabajadores.fold(0.0, (s, e) => s + e.value);
    final maxProd = trabajadores.isEmpty ? 1.0 : trabajadores.first.value;
    final palette = [_kCyan, _kGreen, _kPurple, _kOrange, _kPink, _kYellow, _kRed, _kCyan];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _kpiCard('Total Producido', '${totalProd.toInt()} und', Icons.precision_manufacturing_rounded, _kCyan)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('Trabajadores', '${trabajadores.length}', Icons.people_rounded, _kGreen)),
        ]),
        const SizedBox(height: 12),
        _iaCard(
          icon: Icons.psychology_alt_rounded,
          color: _kGreen,
          title: 'Eficiencia de Producción',
          msg: trabajadores.isEmpty
            ? 'No hay datos de producción registrados aún.'
            : 'El trabajador más productivo es "${trabajadores.first.key.split(" ").first}" con ${trabajadores.first.value.toInt()} unidades. '
              '${trabajadores.length > 1 ? "La brecha con el segundo lugar es de ${(trabajadores.first.value - trabajadores[1].value).toInt()} unds. " : ""}'
              'El promedio del equipo es ${(totalProd / max(trabajadores.length, 1)).toInt()} unds por persona.',
        ),
        const SizedBox(height: 12),

        if (trabajadores.isEmpty)
          _emptyState('Sin datos de producción')
        else
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ranking por Unidades Producidas',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...trabajadores.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final col = palette[i % palette.length];
              final fill = maxProd > 0 ? e.value / maxProd : 0.0;
              final pct = totalProd > 0 ? (e.value / totalProd * 100).toStringAsFixed(1) : '0';
              final firstName = e.key.split(' ').first;
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
                SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(
                  color: i == 0 ? _kYellow : Colors.white.withValues(alpha: 0.4),
                  fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Expanded(child: Stack(children: [
                  Container(height: 10, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(widthFactor: fill.clamp(0.0, 1.0), child: Container(height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [col, col.withValues(alpha: 0.5)]),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 6)]))),
                ])),
                const SizedBox(width: 8),
                SizedBox(width: 55, child: Text('${e.value.toInt()} u', style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                const SizedBox(width: 4),
                SizedBox(width: 42, child: Text('$pct%', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10), textAlign: TextAlign.right)),
              ]));
            }),
          ])),
      ]),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────
  Widget _card({required Widget child, double mb = 0}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: mb),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorde.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {String sub = ''}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16)),
        ]),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
        Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10), overflow: TextOverflow.ellipsis),
        if (sub.isNotEmpty) Text(sub, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _iaCard({required IconData icon, required Color color, required String title, required String msg}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)]),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _dot(Color color, String label, {bool dashed = false}) {
    return Row(children: [
      Container(width: 20, height: 3, decoration: BoxDecoration(
        color: dashed ? null : color,
        border: dashed ? Border(bottom: BorderSide(color: color, width: 2)) : null,
        borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]);
  }

  Widget _statRow(String label, String value, {Color valueColor = Colors.white, double? progressValue, Color? progressColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
      if (progressValue != null) ...[
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progressValue, backgroundColor: Colors.white.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation(progressColor ?? _kGreen), minHeight: 4,
          borderRadius: BorderRadius.circular(2)),
      ],
    ]);
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(Icons.data_exploration_rounded, color: Colors.white.withValues(alpha: 0.2), size: 48),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      ]),
    );
  }
}
