import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
    
    String? comprobanteB64;
    Uint8List? previewBytes;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _kFondo2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.40)),
            ),
            title: Row(children: [
              const CobIconoDialog(icono: Icons.add_card_rounded, color: _kVerde),
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
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CobResumenVenta(v),
                const SizedBox(height: 14),
                CobCampo(ctrl: montoCtrl, label: 'Monto abono (Bs)',
                    icono: Icons.attach_money_rounded, numerico: true),
                const SizedBox(height: 14),
                
                // Botones de respaldo
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kAzulClaro,
                        side: BorderSide(color: _kAzulClaro.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text('Foto Comp.', style: TextStyle(fontSize: 10)),
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                            allowMultiple: false,
                          );
                          
                          if (result != null && result.files.single.bytes != null) {
                            final bytes = result.files.single.bytes!;
                            final b64 = await compute(base64Encode, bytes);
                            await Future.delayed(const Duration(milliseconds: 50));
                            if (context.mounted) {
                              setDialogState(() {
                                previewBytes = bytes;
                                comprobanteB64 = b64;
                              });
                            }
                          }
                        } catch (e) {
                          debugPrint('Error picking file: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kVerdeClaro,
                        side: BorderSide(color: _kVerdeClaro.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.draw_rounded, size: 18),
                      label: const Text('Firma Digital', style: TextStyle(fontSize: 10)),
                      onPressed: () async {
                        final Uint8List? bytes = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const CobDialogFirma(),
                        );
                        if (bytes != null) {
                          final b64 = await compute(base64Encode, bytes);
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (context.mounted) {
                            setDialogState(() {
                              previewBytes = bytes;
                              comprobanteB64 = b64;
                            });
                          }
                        }
                      },
                    ),
                  ),
                ]),
                
                // Preview imagen
                if (previewBytes != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(previewBytes!, height: 120, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                        onPressed: () => setDialogState(() {
                          previewBytes = null;
                          comprobanteB64 = null;
                        }),
                      )
                    ],
                  ),
                ],
              ]),
            ),
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
                  if (m > 0) _svc.registrarAbono(v.id, m, comprobanteB64: comprobanteB64);
                  Navigator.pop(ctx);
                },
                child: const Text('Abonar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        }
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: _kFondo2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kAzul.withValues(alpha: 0.15),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Cliente', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Tipo / Color', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Detalle Compra', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Vencimiento', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Pendiente', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12)))),
                Expanded(flex: 2, child: Text('Acciones', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Cuerpo
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final venta = lista[i];
                final color = venta.saldado ? _kVerde : (DateTime.now().difference(venta.fecha).inDays > 30 ? _kRojo : (venta.progreso >= 0.5 ? _kVerdeClaro : _kAzulClaro));
                final diasDesdeFecha = DateTime.now().difference(venta.fecha).inDays;
                String vencimiento = diasDesdeFecha > 30 ? 'Vencido hace $diasDesdeFecha d.' : 'Hace $diasDesdeFecha d.';
                String estado = venta.saldado ? '✅ Saldado' : (diasDesdeFecha > 30 ? '🔴 Vencido' : (venta.progreso >= 0.5 ? '🔵 Buen avance' : '🟡 Pendiente'));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: i.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(venta.cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
                      Expanded(flex: 2, child: Text(venta.color.isEmpty ? venta.tipo.name.toUpperCase() : '${venta.tipo.name.toUpperCase()} · ${venta.color}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                      Expanded(flex: 2, child: Text('${venta.cantidad.toStringAsFixed(0)} u. x Bs ${venta.precioUnit.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                      Expanded(flex: 2, child: Text(vencimiento, style: TextStyle(color: diasDesdeFecha > 30 ? _kRojo : Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text('Bs ${venta.pendiente.toStringAsFixed(0)}', textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)))),
                      Expanded(flex: 2, child: Align(
                        alignment: Alignment.centerRight,
                        child: onAbonar == null ? const SizedBox.shrink() : 
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kVerde.withValues(alpha: 0.15),
                              foregroundColor: _kVerdeClaro,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: _kVerde.withValues(alpha: 0.3)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Abonar', style: TextStyle(fontSize: 12)),
                            onPressed: () => onAbonar!(venta),
                          ),
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


