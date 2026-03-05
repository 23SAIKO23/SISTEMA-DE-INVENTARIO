import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../ventas/modelos_venta.dart';
import 'cobranza_widgets.dart';

// ── Paleta ────────────────────────────────────
const _kAzul       = Color(0xFF1565C0);
const _kAzulClaro  = Color(0xFF42A5F5);
const _kVerde      = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kFondo      = Color(0xFF0A1628);
const _kFondo2     = Color(0xFF0D2145);
const _kRojo       = Color(0xFFEF5350);
const _kAmbar      = Color(0xFFFFB300);

// ─────────────────────────────────────────────
//  Historial de Pagos por Cliente
//  Lee historialAbonos directamente desde Venta (via AppService)
// ─────────────────────────────────────────────
class HistorialPagos extends StatefulWidget {
  const HistorialPagos({super.key});
  @override
  State<HistorialPagos> createState() => _HistorialPagosState();
}

class _HistorialPagosState extends State<HistorialPagos> {
  final _svc = AppService.instance;
  String _busqueda = '';
  Venta? _seleccionada;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  // Solo ventas con al menos 1 abono
  List<Venta> get _conHistorial => _svc.cuentasPorCobrar
      .where((v) =>
          v.historialAbonos.isNotEmpty &&
          v.cliente.toLowerCase().contains(_busqueda.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kFondo, _kFondo2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _seleccionada == null
              ? _vistaListado(context)
              : _vistaDetalle(context, _seleccionada!),
        ),
      ),
    );
  }

  // ── Vista listado ─────────────────────────
  Widget _vistaListado(BuildContext context) {
    final totalAbonos = _svc.cuentasPorCobrar
        .fold<int>(0, (s, v) => s + v.historialAbonos.length);

    return Column(children: [
      CobAppBar(titulo: 'HISTORIAL DE PAGOS',
          subtitulo: 'Por cliente · sincronizado con Ventas'),

      // Resumen global
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _MiniCard(label: 'Total abonos',
              valor: '$totalAbonos',
              color: _kAzulClaro,
              icono: Icons.receipt_long_rounded),
          const SizedBox(width: 10),
          _MiniCard(label: 'Cobrado',
              valor: 'Bs ${_svc.totalCobrado.toStringAsFixed(0)}',
              color: _kVerde,
              icono: Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _MiniCard(label: 'Pendiente',
              valor: 'Bs ${_svc.totalPendiente.toStringAsFixed(0)}',
              color: _kAmbar,
              icono: Icons.hourglass_top_rounded),
        ]),
      ),
      const SizedBox(height: 12),

      // Buscador
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _kAzulClaro.withValues(alpha: 0.70), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Lista
      Expanded(
        child: _conHistorial.isEmpty
            ? const CobEmpty('Sin historial de abonos registrados')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: _conHistorial.length,
                itemBuilder: (_, i) => _TarjetaResumenCliente(
                  venta: _conHistorial[i],
                  onTap: () =>
                      setState(() => _seleccionada = _conHistorial[i]),
                ),
              ),
      ),
    ]);
  }

  // ── Vista detalle ─────────────────────────
  Widget _vistaDetalle(BuildContext context, Venta v) {
    final pagos = List<AbonoVenta>.from(v.historialAbonos)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Column(children: [
      // AppBar detalle
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => setState(() => _seleccionada = null),
          ),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_kAzulClaro, _kVerdeClaro],
              ).createShader(b),
              child: Text(v.cliente.toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ),
            Text('Venta #${v.id}  ·  ${v.color}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10)),
          ])),
        ]),
      ),
      Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(height: 12),

      // Resumen del cliente
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _TarjetaResumenDetalle(venta: v),
      ),
      const SizedBox(height: 14),

      // Título línea de tiempo
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kAzulClaro, _kVerdeClaro],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('Línea de tiempo — ${pagos.length} abono(s)',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 10),

      // Línea de tiempo
      Expanded(
        child: pagos.isEmpty
            ? const CobEmpty('Sin abonos registrados')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: pagos.length,
                itemBuilder: (_, i) {
                  final acumulado = pagos
                      .sublist(i)
                      .fold(0.0, (s, p) => s + p.monto);
                  return _ItemLineaTiempo(
                    pago: pagos[i],
                    numero: pagos.length - i,
                    esUltimo: i == pagos.length - 1,
                    acumulado: acumulado,
                  );
                },
              ),
      ),
    ]);
  }
}

// ── Tarjeta resumen en listado ─────────────────
class _TarjetaResumenCliente extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;
  const _TarjetaResumenCliente({required this.venta, required this.onTap});

  Color get _color => venta.saldado ? _kVerde
      : venta.progreso >= 0.5 ? _kVerdeClaro
      : _kAzulClaro;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kFondo2, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10),
              blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(height: 3, decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kAzul, color],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(venta.cliente[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w900, fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(venta.cliente,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(venta.color.isEmpty
                          ? 'Venta #${venta.id}' : venta.color,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.receipt_long_rounded, size: 11,
                        color: _kAzulClaro.withValues(alpha: 0.70)),
                    const SizedBox(width: 4),
                    Text('${venta.historialAbonos.length} abono(s) registrado(s)',
                        style: TextStyle(
                            color: _kAzulClaro.withValues(alpha: 0.70),
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Bs ${venta.montoPagado.toStringAsFixed(0)}',
                      style: TextStyle(color: color,
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('cobrado',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 9)),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white38, size: 18),
                ]),
              ]),
              const SizedBox(height: 8),
              Stack(children: [
                Container(height: 5, decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                )),
                FractionallySizedBox(widthFactor: venta.progreso,
                  child: Container(height: 5, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kAzulClaro, color]),
                    borderRadius: BorderRadius.circular(6),
                  )),
                ),
              ]),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(venta.saldado ? '✅ Saldado'
                    : '${(venta.progreso * 100).toStringAsFixed(0)}% cobrado',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w700)),
                Text('Bs ${venta.pendiente.toStringAsFixed(0)} pendiente',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 10)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Tarjeta resumen en detalle ─────────────────
class _TarjetaResumenDetalle extends StatelessWidget {
  final Venta venta;
  const _TarjetaResumenDetalle({required this.venta});
  @override
  Widget build(BuildContext context) {
    final color = venta.saldado ? _kVerde : _kAzulClaro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _Col('Total', 'Bs ${venta.total.toStringAsFixed(2)}',
              Colors.white70),
          _Col('Cobrado', 'Bs ${venta.montoPagado.toStringAsFixed(2)}',
              _kVerde),
          _Col('Pendiente', 'Bs ${venta.pendiente.toStringAsFixed(2)}',
              venta.saldado ? Colors.white38 : _kRojo),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          Container(height: 10, decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          )),
          FractionallySizedBox(widthFactor: venta.progreso,
            child: Container(height: 10, decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_kAzul, _kAzulClaro, color]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.50),
                  blurRadius: 8)],
            )),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          venta.saldado
              ? '✅ Cuenta totalmente saldada'
              : '${(venta.progreso * 100).toStringAsFixed(1)}% completado — '
                'Bs ${venta.pendiente.toStringAsFixed(2)} por cobrar',
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _Col extends StatelessWidget {
  final String l, v; final Color c;
  const _Col(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900,
        fontSize: 15)),
    Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.40),
        fontSize: 9)),
  ]);
}

// ── Ítem de línea de tiempo ───────────────────
class _ItemLineaTiempo extends StatelessWidget {
  final AbonoVenta pago;
  final int numero;
  final bool esUltimo;
  final double acumulado;
  const _ItemLineaTiempo({required this.pago, required this.numero,
      required this.esUltimo, required this.acumulado});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = numero == 1 ? _kVerdeClaro : _kAzulClaro;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 36, child: Column(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kAzul, color]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.50),
                  blurRadius: 8)],
            ),
            child: Center(child: Text('$numero',
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w900))),
          ),
          if (!esUltimo)
            Expanded(child: Container(width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0.60),
                  color.withValues(alpha: 0.10),
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            )),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kFondo2, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.40), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.40)),
                ),
                child: Text('Abono #$numero',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
              Text('Bs ${pago.monto.toStringAsFixed(2)}',
                  style: TextStyle(color: color,
                      fontWeight: FontWeight.w900, fontSize: 18)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 11,
                  color: Colors.white.withValues(alpha: 0.40)),
              const SizedBox(width: 5),
              Text(_fmt(pago.fecha), style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
            ]),
            if (pago.nota.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.notes_rounded, size: 11,
                    color: _kVerdeClaro.withValues(alpha: 0.60)),
                const SizedBox(width: 5),
                Expanded(child: Text(pago.nota, style: TextStyle(
                    color: _kVerdeClaro.withValues(alpha: 0.80),
                    fontSize: 11, fontStyle: FontStyle.italic))),
              ]),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.account_balance_wallet_rounded, size: 11,
                    color: _kVerde.withValues(alpha: 0.70)),
                const SizedBox(width: 5),
                Text('Acumulado hasta aquí: Bs ${acumulado.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 10)),
              ]),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ── Widgets auxiliares ────────────────────────
class _MiniCard extends StatelessWidget {
  final String label, valor; final Color color; final IconData icono;
  const _MiniCard({required this.label, required this.valor,
      required this.color, required this.icono});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 16),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: color,
            fontWeight: FontWeight.w900, fontSize: 13)),
        Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40), fontSize: 9)),
      ]),
    ),
  );
}
