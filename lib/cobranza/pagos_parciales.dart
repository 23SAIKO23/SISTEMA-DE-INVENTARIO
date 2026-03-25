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

              // Lista (Tabla tipo Excel)
              // Lista (Tabla tipo Excel)
              Expanded(
                child: cuentas.isEmpty
                    ? const CobEmpty('No hay ventas a crédito o parcial')
                    : Container(
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
                                  Expanded(flex: 1, child: Text('ID', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Cliente', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Tipo / Color', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Detalle Compra', style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Pendiente', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12)))),
                                  Expanded(flex: 2, child: Text('Acciones', textAlign: TextAlign.right, style: TextStyle(color: _kAzulClaro, fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                            ),
                            // Cuerpo
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: cuentas.length,
                                itemBuilder: (context, i) {
                                  final venta = cuentas[i];
                                  final bool saldado = venta.saldado;
                                  final color = saldado ? _kVerde : (venta.progreso >= 0.5 ? _kVerdeClaro : _kAzulClaro);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: i.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 1, child: Text('#${venta.id}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                                        Expanded(flex: 2, child: Text(venta.cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
                                        Expanded(flex: 2, child: Text(venta.color.isEmpty ? venta.tipo.name.toUpperCase() : '${venta.tipo.name.toUpperCase()} · ${venta.color}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('${venta.cantidad.toStringAsFixed(0)} u. x Bs ${venta.precioUnit.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('Bs ${venta.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                        Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text('Bs ${venta.pendiente.toStringAsFixed(0)}', textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)))),
                                        Expanded(flex: 2, child: Align(
                                          alignment: Alignment.centerRight,
                                          child: saldado ? const SizedBox.shrink() : 
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
                                              onPressed: () => _dialogAbonar(context, venta),
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
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CobResumenVenta(v),
                const SizedBox(height: 14),
                CobCampo(ctrl: montoCtrl, label: 'Monto abono (Bs)',
                    icono: Icons.attach_money_rounded, numerico: true),
                const SizedBox(height: 8),
                CobCampo(ctrl: notaCtrl, label: 'Nota (opcional)',
                    icono: Icons.notes_rounded),
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
                  if (m > 0) {
                    _svc.registrarAbono(v.id, m, nota: notaCtrl.text.trim(), comprobanteB64: comprobanteB64);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Confirmar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        }
      ),
    );
  }
}


