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

// ─────────────────────────────────────────────
//  Pagos Parciales — Cuentas por Cobrar
//  Lee directamente desde AppService (mismos datos que Ventas)
// ─────────────────────────────────────────────
class PagosParciales extends StatefulWidget {
  const PagosParciales({super.key});
  @override
  State<PagosParciales> createState() => _PagosParcialesState();
}

class _PagosParcialesState extends State<PagosParciales> {
  final _svc = AppService.instance;

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

  // Resúmenes
  double get _totalDeuda =>
      _svc.cuentasPorCobrar.fold(0.0, (s, v) => s + v.total);
  double get _totalCobrado =>
      _svc.cuentasPorCobrar.fold(0.0, (s, v) => s + v.montoPagado);
  double get _totalPendiente =>
      _svc.cuentasPorCobrar.fold(0.0, (s, v) => s + v.pendiente);

  @override
  Widget build(BuildContext context) {
    final cuentas = _svc.cuentasPorCobrar;

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
          child: Column(
            children: [
              CobAppBar(titulo: 'PAGOS PARCIALES',
                  subtitulo: 'Cuentas por cobrar · sincronizado con Ventas'),

              // Resumen
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(children: [
                  Row(children: [
                    CobResCard(label: 'Total deuda',
                        valor: 'Bs ${_totalDeuda.toStringAsFixed(0)}',
                        color: _kRojo,
                        icono: Icons.monetization_on_rounded),
                    const SizedBox(width: 10),
                    CobResCard(label: 'Cobrado',
                        valor: 'Bs ${_totalCobrado.toStringAsFixed(0)}',
                        color: _kVerde,
                        icono: Icons.check_circle_rounded),
                  ]),
                  const SizedBox(height: 10),
                  CobResCard(label: 'Pendiente por cobrar',
                      valor: 'Bs ${_totalPendiente.toStringAsFixed(0)}',
                      color: _kAzulClaro,
                      icono: Icons.hourglass_top_rounded,
                      full: true),
                ]),
              ),

              // Lista
              Expanded(
                child: cuentas.isEmpty
                    ? const CobEmpty('No hay ventas a crédito o parcial')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: cuentas.length,
                        itemBuilder: (_, i) => _TarjetaCuenta(
                          venta: cuentas[i],
                          onAbonar: () =>
                              _dialogAbonar(context, cuentas[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dialogAbonar(BuildContext ctx, Venta v) {
    final montoCtrl = TextEditingController();
    final notaCtrl  = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _kFondo2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.40)),
        ),
        title: Row(children: [
          CobIconoDialog(icono: Icons.add_card_rounded, color: _kVerde),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Registrar abono',
                  style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(v.cliente,
                  style: TextStyle(
                      color: _kAzulClaro.withValues(alpha: 0.80),
                      fontSize: 11)),
            ]),
          ),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CobResumenVenta(v),
          const SizedBox(height: 14),
          CobCampo(ctrl: montoCtrl, label: 'Monto abono (Bs)',
              icono: Icons.attach_money_rounded, numerico: true),
          const SizedBox(height: 8),
          CobCampo(ctrl: notaCtrl, label: 'Nota (opcional)',
              icono: Icons.notes_rounded),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerde, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final m = double.tryParse(montoCtrl.text) ?? 0;
              if (m > 0) {
                // ← actualiza ventas Y cobranza al mismo tiempo
                _svc.registrarAbono(v.id, m, nota: notaCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tarjeta de cuenta
// ─────────────────────────────────────────────
class _TarjetaCuenta extends StatelessWidget {
  final Venta venta;
  final VoidCallback onAbonar;
  const _TarjetaCuenta({required this.venta, required this.onAbonar});

  Color get _color {
    if (venta.saldado)          return _kVerde;
    if (venta.progreso >= 0.5)  return _kVerdeClaro;
    if (venta.montoPagado == 0) return _kRojo;
    return _kAzulClaro;
  }

  String get _estado {
    if (venta.saldado)          return '✅ Saldado';
    if (venta.montoPagado == 0) return '🔴 Sin abono';
    if (venta.progreso >= 0.75) return '🟢 Casi saldado';
    return '🔵 Va pagando';
  }

  String get _labelPago {
    switch (venta.pago) {
      case ModalidadPago.credito: return 'Crédito';
      case ModalidadPago.parcial: return 'Parcial';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kFondo2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.50), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        // Franja
        Container(height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(17)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ID + modalidad
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.50)),
                ),
                child: Center(child: Text('#${venta.id}',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(venta.cliente,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(venta.color.isEmpty
                          ? '${_labelPago}'
                          : '${venta.color}  ·  $_labelPago',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 11)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.sync_rounded,
                        size: 10, color: _kAzulClaro),
                    const SizedBox(width: 4),
                    Text('Venta #${venta.id} · ${venta.historialAbonos.length} abono(s)',
                        style: TextStyle(
                            color: _kAzulClaro.withValues(alpha: 0.70),
                            fontSize: 10)),
                  ]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Bs ${venta.total.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 18)),
                Text('debe Bs ${venta.pendiente.toStringAsFixed(0)}',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ]),
            const SizedBox(height: 12),

            // Barra de progreso
            Stack(children: [
              Container(height: 8, decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
              )),
              FractionallySizedBox(
                widthFactor: venta.progreso,
                child: Container(height: 8, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_kAzulClaro, color]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(
                      color: color.withValues(alpha: 0.50), blurRadius: 6)],
                )),
              ),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_estado, style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              Text('${(venta.progreso * 100).toStringAsFixed(0)}% cobrado',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10)),
            ]),

            if (!venta.saldado) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.60)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Registrar abono',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  onPressed: onAbonar,
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

