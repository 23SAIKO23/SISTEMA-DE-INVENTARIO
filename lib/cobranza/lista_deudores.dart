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
//  Lista de Clientes con Deuda
//  Fuente: AppService.cuentasPorCobrar (ventas a crédito/parcial)
// ─────────────────────────────────────────────
class ListaDeudores extends StatefulWidget {
  const ListaDeudores({super.key});
  @override
  State<ListaDeudores> createState() => _ListaDeudoresState();
}

class _ListaDeudoresState extends State<ListaDeudores>
    with SingleTickerProviderStateMixin {
  final _svc = AppService.instance;
  late TabController _tab;
  String _busqueda = '';
  String _orden    = 'nombre';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _svc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _tab.dispose();
    _svc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<Venta> _filtrar(List<Venta> lista) {
    var r = lista.where((v) =>
        v.cliente.toLowerCase().contains(_busqueda.toLowerCase())).toList();
    switch (_orden) {
      case 'nombre': r.sort((a, b) => a.cliente.compareTo(b.cliente)); break;
      case 'deuda':  r.sort((a, b) => b.pendiente.compareTo(a.pendiente)); break;
      case 'fecha':  r.sort((a, b) => a.fecha.compareTo(b.fecha)); break;
    }
    return r;
  }

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
          child: Column(children: [
            CobAppBar(
              titulo: 'CLIENTES CON DEUDA',
              subtitulo: 'Fechas de pago · sincronizado con Ventas',
            ),

            // Chips resumen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                CobChip(label: '${_svc.pendientes.length} pendientes',
                    color: _kAzulClaro, icono: Icons.pending_actions_rounded),
                const SizedBox(width: 8),
                CobChip(label: '${_svc.vencidos.length} vencidos',
                    color: _kRojo, icono: Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                CobChip(label: '${_svc.saldados.length} saldados',
                    color: _kVerde, icono: Icons.check_circle_rounded),
              ]),
            ),
            const SizedBox(height: 10),

            // Buscador + orden
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _busqueda = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30),
                            fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: _kAzulClaro.withValues(alpha: 0.70),
                            size: 18),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _orden = v),
                  color: _kFondo2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'nombre',
                        child: Text('Por nombre',
                            style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'deuda',
                        child: Text('Mayor deuda',
                            style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'fecha',
                        child: Text('Más antiguo',
                            style: TextStyle(color: Colors.white))),
                  ],
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: _kAzul.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _kAzulClaro.withValues(alpha: 0.40)),
                    ),
                    child: const Icon(Icons.sort_rounded,
                        color: _kAzulClaro, size: 20),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),

            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAzul, _kAzulClaro]),
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Pendientes'),
                  Tab(text: 'Vencidos'),
                  Tab(text: 'Saldados'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ListaDeudores(lista: _filtrar(_svc.pendientes),
                      onAbonar: (v) => _dialogAbonar(context, v)),
                  _ListaDeudores(lista: _filtrar(_svc.vencidos),
                      onAbonar: (v) => _dialogAbonar(context, v)),
                  _ListaDeudores(lista: _filtrar(_svc.saldados),
                      onAbonar: null),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _dialogAbonar(BuildContext ctx, Venta v) {
    final montoCtrl = TextEditingController();
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
          CobFilaInfo('Deuda total', 'Bs ${v.total.toStringAsFixed(2)}', Colors.white70),
          const SizedBox(height: 4),
          CobFilaInfo('Pendiente', 'Bs ${v.pendiente.toStringAsFixed(2)}', _kRojo),
          const SizedBox(height: 14),
          CobCampo(ctrl: montoCtrl, label: 'Monto abono (Bs)',
              icono: Icons.attach_money_rounded, numerico: true),
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
              if (m > 0) _svc.registrarAbono(v.id, m);
              Navigator.pop(ctx);
            },
            child: const Text('Abonar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-lista interna ─────────────────────────
class _ListaDeudores extends StatelessWidget {
  final List<Venta> lista;
  final Function(Venta)? onAbonar;
  const _ListaDeudores({required this.lista, required this.onAbonar});

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) return const CobEmpty('Sin registros en esta categoría');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: lista.length,
      itemBuilder: (_, i) => _TarjetaDeudor(
        venta: lista[i],
        onAbonar: onAbonar != null ? () => onAbonar!(lista[i]) : null,
      ),
    );
  }
}

// ── Tarjeta de deudor ─────────────────────────
class _TarjetaDeudor extends StatelessWidget {
  final Venta venta;
  final VoidCallback? onAbonar;
  const _TarjetaDeudor({required this.venta, this.onAbonar});

  Color get _color {
    if (venta.saldado) return _kVerde;
    if (DateTime.now().difference(venta.fecha).inDays > 30) return _kRojo;
    if (venta.progreso >= 0.5) return _kVerdeClaro;
    return _kAzulClaro;
  }

  String get _estado {
    if (venta.saldado) return '✅ Saldado';
    if (DateTime.now().difference(venta.fecha).inDays > 30) return '🔴 Vencido';
    if (venta.progreso >= 0.5) return '🔵 Buen avance';
    return '🟡 Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final diasDesdeFecha = DateTime.now().difference(venta.fecha).inDays;

    return Container(
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kAzul, color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(
                    venta.cliente[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900,
                        fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(venta.cliente,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(venta.color.isEmpty ? 'Venta #${venta.id}' : venta.color,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11)),
                const SizedBox(height: 4),
                CobBadgeFecha(
                  texto: diasDesdeFecha > 30
                      ? 'Vencido hace $diasDesdeFecha días'
                      : 'Hace $diasDesdeFecha día(s)',
                  color: color,
                ),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Bs ${venta.pendiente.toStringAsFixed(0)}',
                    style: TextStyle(color: color,
                        fontWeight: FontWeight.w900, fontSize: 18)),
                Text('pendiente',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9)),
              ]),
            ]),
            const SizedBox(height: 10),

            Stack(children: [
              Container(height: 6, decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
              )),
              FractionallySizedBox(
                widthFactor: venta.progreso,
                child: Container(height: 6, decoration: BoxDecoration(
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
              Text('Bs ${venta.montoPagado.toStringAsFixed(0)} de '
                  'Bs ${venta.total.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10)),
            ]),

            if (!venta.saldado && onAbonar != null) ...[
              const SizedBox(height: 8),
              // Fecha de la venta
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Row(children: [
                    Icon(Icons.calendar_month_rounded, size: 12,
                        color: _kAzulClaro.withValues(alpha: 0.70)),
                    const SizedBox(width: 6),
                    Text(
                      'Fecha venta: ${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11),
                    ),
                  ]),
                  Text('${venta.historialAbonos.length} abono(s)',
                      style: TextStyle(
                          color: _kVerdeClaro.withValues(alpha: 0.70),
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.60)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
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

