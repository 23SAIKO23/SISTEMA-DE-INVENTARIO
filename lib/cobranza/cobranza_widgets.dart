import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../ventas/modelos_venta.dart';

// ── Paleta compartida ─────────────────────────
const kCobAzul       = Color(0xFF1565C0);
const kCobAzulClaro  = Color(0xFF42A5F5);
const kCobVerde      = Color(0xFF00C853);
const kCobVerdeClaro = Color(0xFF69F0AE);
const kCobFondo      = Color(0xFF0A1628);
const kCobFondo2     = Color(0xFF0D2145);
const kCobRojo       = Color(0xFFEF5350);

// ─────────────────────────────────────────────
//  AppBar compartida de cobranza
// ─────────────────────────────────────────────
class CobAppBar extends StatelessWidget {
  final String titulo, subtitulo;
  const CobAppBar({super.key, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [kCobAzulClaro, kCobVerdeClaro],
            ).createShader(b),
            child: Text(titulo, style: const TextStyle(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
          Text(subtitulo, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10, letterSpacing: 0.8)),
        ]),
      ]),
    ),
    Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [kCobAzul, kCobAzulClaro, kCobVerde, kCobVerdeClaro]),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    const SizedBox(height: 12),
  ]);
}

// ─────────────────────────────────────────────
//  Ícono decorativo para diálogos
// ─────────────────────────────────────────────
class CobIconoDialog extends StatelessWidget {
  final IconData icono;
  final Color color;
  const CobIconoDialog({super.key, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.50)),
    ),
    child: Icon(icono, color: color, size: 18),
  );
}

// ─────────────────────────────────────────────
//  Fila etiqueta → valor para diálogos
// ─────────────────────────────────────────────
class CobFilaInfo extends StatelessWidget {
  final String etiqueta, valor;
  final Color colorValor;
  const CobFilaInfo(this.etiqueta, this.valor, this.colorValor, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(etiqueta, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
      Text(valor, style: TextStyle(color: colorValor,
          fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );
}

// ─────────────────────────────────────────────
//  Campo de texto estilizado
// ─────────────────────────────────────────────
class CobCampo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icono;
  final bool numerico;
  const CobCampo({super.key, required this.ctrl, required this.label,
      required this.icono, this.numerico = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: numerico ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
      prefixIcon: Icon(icono, color: kCobAzulClaro, size: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kCobAzulClaro, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
    ),
  );
}

// ─────────────────────────────────────────────
//  Resumen de venta para diálogos de abono
// ─────────────────────────────────────────────
class CobResumenVenta extends StatelessWidget {
  final Venta v;
  const CobResumenVenta(this.v, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Column(children: [
      CobFilaInfo('Producto', v.tipo.name.toUpperCase(), Colors.white70),
      const SizedBox(height: 4),
      CobFilaInfo('Cantidad', '${v.cantidad.toStringAsFixed(0)} aguayos', Colors.white70),
      const SizedBox(height: 4),
      CobFilaInfo('Precio Unit.', 'Bs ${v.precioUnit.toStringAsFixed(2)}', Colors.white70),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Colors.white24, height: 1),
      ),

      CobFilaInfo('Total (Venta)', 'Bs ${v.total.toStringAsFixed(2)}', Colors.white),
      const SizedBox(height: 4),
      CobFilaInfo('Cobrado',
          'Bs ${v.montoPagado.toStringAsFixed(2)}', kCobVerdeClaro),
      const SizedBox(height: 4),
      CobFilaInfo('Pendiente',
          'Bs ${v.pendiente.toStringAsFixed(2)}', kCobAzulClaro),
    ]),
  );
}

// ─────────────────────────────────────────────
//  Widget de "lista vacía"
// ─────────────────────────────────────────────
class CobEmpty extends StatelessWidget {
  final String mensaje;
  const CobEmpty(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline_rounded,
          color: kCobVerde.withValues(alpha: 0.40), size: 60),
      const SizedBox(height: 12),
      Text(mensaje, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
    ]),
  );
}

// ─────────────────────────────────────────────
//  Card de resumen (Bs totales, cobrado, etc.)
// ─────────────────────────────────────────────
class CobResCard extends StatelessWidget {
  final String label, valor;
  final Color color;
  final IconData icono;
  final bool full;
  const CobResCard({super.key, required this.label, required this.valor,
      required this.color, required this.icono, this.full = false});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCobFondo2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.10), blurRadius: 12)],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.40)),
          ),
          child: Icon(icono, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(color: color,
              fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
        ]),
      ]),
    );
    return full
        ? SizedBox(width: double.infinity, child: child)
        : Expanded(child: child);
  }
}

// ─────────────────────────────────────────────
//  Chip de estado (pendientes / vencidos / saldados)
// ─────────────────────────────────────────────
class CobChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icono;
  const CobChip({super.key, required this.label,
      required this.color, required this.icono});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 14),
        const SizedBox(width: 5),
        Expanded(child: Text(label, style: TextStyle(color: color,
            fontSize: 10, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
//  Badge de fecha / estado de vencimiento
// ─────────────────────────────────────────────
class CobBadgeFecha extends StatelessWidget {
  final String texto;
  final Color color;
  const CobBadgeFecha({super.key, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(texto, style: TextStyle(color: color, fontSize: 9,
        fontWeight: FontWeight.w700)),
  );
}

// ─────────────────────────────────────────────
//  Cuadro de Firma Digital
// ─────────────────────────────────────────────
class CobDialogFirma extends StatefulWidget {
  const CobDialogFirma({super.key});

  @override
  State<CobDialogFirma> createState() => _CobDialogFirmaState();
}

class _CobDialogFirmaState extends State<CobDialogFirma> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3.5,
    penColor: const Color(0xFF0A1628),
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCobFondo2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kCobAzulClaro.withValues(alpha: 0.40)),
      ),
      title: Row(children: [
        const CobIconoDialog(icono: Icons.draw_rounded, color: kCobVerde),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Firma del Cliente',
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Text('Dibuje la firma de conformidad',
              style: TextStyle(
                  color: kCobAzulClaro.withValues(alpha: 0.80),
                  fontSize: 11)),
        ]),
      ]),
      content: Container(
        width: 400,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Signature(
          controller: _controller,
          backgroundColor: Colors.white,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _controller.clear(),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Limpiar'),
          style: TextButton.styleFrom(
            foregroundColor: kCobRojo.withValues(alpha: 0.8),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Cancelar',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kCobVerde, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (_controller.isNotEmpty) {
              final Uint8List? data = await _controller.toPngBytes();
              if (context.mounted) Navigator.pop(context, data);
            } else {
              Navigator.pop(context, null);
            }
          },
          child: const Text('Guardar Firma',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
