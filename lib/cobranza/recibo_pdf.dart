import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../ventas/modelos_venta.dart';

class ReciboPdf {
  static Future<void> generarEImprimir(Venta venta, BuildContext context) async {
    final pdf = pw.Document();

    final fmtDinero = NumberFormat.currency(symbol: 'Bs ', decimalDigits: 2);
    final fmtFecha = DateFormat('dd/MM/yyyy HH:mm');

    // Orden cronológico estricto
    final abonosChronological = List<AbonoVenta>.from(venta.historialAbonos)..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Precargar imágenes de comprobantes y asignar ID de Anexo
    final anexosInfo = <AbonoVenta, int>{};
    final comprobantesImgs = <int, pw.ImageProvider>{};
    var anexoCounter = 1;

    for (var pago in abonosChronological) {
      if (pago.comprobante != null && pago.comprobante!.isNotEmpty) {
        anexosInfo[pago] = anexoCounter;
        try {
          final url = 'http://localhost/marcali/uploads/comprobantes/${pago.comprobante}';
          final img = await networkImage(url);
          comprobantesImgs[anexoCounter] = img;
        } catch (e) {
          debugPrint('Error al cargar PDF comprobante: $e');
        }
        anexoCounter++;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('MARCALI - TALLER TEXTIL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Comprobante de Venta y Estado de Pagos', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('N. Venta: #${venta.id}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Emision: ${fmtFecha.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
                    ]
                  ),
                ]
              ),
              pw.Divider(thickness: 2, height: 30),

              // Datos del cliente
              pw.Text('DATOS DEL CLIENTE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Senor(a): ${venta.cliente.toUpperCase()}', style: const pw.TextStyle(fontSize: 12))),
                  pw.Expanded(child: pw.Text('Fecha de venta: ${fmtFecha.format(venta.fecha)}', style: const pw.TextStyle(fontSize: 12))),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Text('Producto: ${venta.cantidad.toStringAsFixed(0)} aguayos - ${venta.tipo.name.toUpperCase()} ${venta.color.isEmpty ? "" : "(${venta.color})"}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Destino: ${venta.destino.isEmpty ? "No especificado" : venta.destino}', style: const pw.TextStyle(fontSize: 12)),
              
              pw.SizedBox(height: 20),

              // Resumen económico
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [
                      pw.Text('TOTAL VENTA', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(fmtDinero.format(venta.total), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(children: [
                      pw.Text('TOTAL COBRADO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(fmtDinero.format(venta.montoPagado), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ]),
                    pw.Column(children: [
                      pw.Text('SALDO PENDIENTE', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(fmtDinero.format(venta.pendiente), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: venta.saldado ? PdfColors.grey700 : PdfColors.red700)),
                    ]),
                  ]
                )
              ),

              pw.SizedBox(height: 20),

              // Historial de pagos
              pw.Text('HISTORIAL DE PAGOS REALIZADOS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              if (venta.historialAbonos.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text('No se registran abonos en esta cuenta.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600))
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.8),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(3.5),
                    3: const pw.FlexColumnWidth(1.8),
                    4: const pw.FlexColumnWidth(2.0),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Fecha y Hora', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Nota', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Importe', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Firma/Ref', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ]
                    ),
                    // Table Body
                    ...List.generate(abonosChronological.length, (index) {
                      final pago = abonosChronological[index];
                      String notaFinal = pago.nota.isEmpty ? '-' : pago.nota;
                      pw.Widget anexoWidget = pw.Text('-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600));
                      
                      if (anexosInfo.containsKey(pago)) {
                        final nAnexo = anexosInfo[pago]!;
                        notaFinal += '\n(Anexo $nAnexo)';
                        
                        final img = comprobantesImgs[nAnexo];
                        if (img != null) {
                          anexoWidget = pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Image(img, height: 26, fit: pw.BoxFit.contain),
                            ]
                          );
                        }
                      }
                      
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(fmtFecha.format(pago.fecha), style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(notaFinal, style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(fmtDinero.format(pago.monto), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: anexoWidget)),
                        ]
                      );
                    })
                  ]
                ),

              pw.Spacer(),
              
              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  venta.saldado ? '¡CUENTA TOTALMENTE SALDADA! Gracias por su preferencia.' : 'Este documento es un comprobante no fiscal para fines de control interno de pago.',
                  style: pw.TextStyle(fontSize: 10, color: venta.saldado ? PdfColors.green700 : PdfColors.grey600, fontWeight: venta.saldado ? pw.FontWeight.bold : pw.FontWeight.normal)
                )
              )
            ],
          );
        },
      ),
    );

    // Página de anexos si hay comprobantes
    if (comprobantesImgs.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Text('ANEXOS - COMPROBANTES DE TRANSFERENCIA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, height: 20),
              pw.SizedBox(height: 10),
              ...comprobantesImgs.entries.map((e) {
                final pagoRef = anexosInfo.entries.firstWhere((element) => element.value == e.key).key;
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ANEXO ${e.key} - Del abono fechado en ${fmtFecha.format(pagoRef.fecha)} por ${fmtDinero.format(pagoRef.monto)}', 
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 10),
                    pw.Center(child: pw.Image(e.value, width: 400)),
                    pw.SizedBox(height: 40),
                  ]
                );
              }),
            ];
          }
        )
      );
    }

    // Navegar a la pantalla de vista previa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Visor de Comprobante'),
            backgroundColor: const Color(0xFF0D2145), // _kFondo
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) async => pdf.save(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'Comprobante_${venta.cliente}_Venta${venta.id}.pdf',
          ),
        ),
      ),
    );
  }
}
