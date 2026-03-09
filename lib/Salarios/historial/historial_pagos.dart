import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../modelos_salarios.dart';

const _kVerdeAcento = Color(0xFF14B8A6);
const _kVerdeClaro = Color(0xFF2DD4BF);
const _kAzulOscuro = Color(0xFF0D1424);
const _kCardBg = Color(0xFF172036);
const _kTextoSecundario = Color(0xFF94A3B8);

class HistorialPagosPage extends StatefulWidget {
  const HistorialPagosPage({super.key});

  @override
  State<HistorialPagosPage> createState() => _HistorialPagosPageState();
}

class _HistorialPagosPageState extends State<HistorialPagosPage> {
  final _srv = SalariosService.instance;
  final _formatoMoneda = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  final _formatoFecha = DateFormat('dd MMM yyyy');

  String? _trabajadorSeleccionadoId;
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    // Iniciar con el mes actual como rango por defecto
    final now = DateTime.now();
    _rangoFechas = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  List<Map<String, dynamic>> get _pagosFiltrados {
    List<Map<String, dynamic>> list = [];
    
    for (var trabajador in _srv.trabajadores) {
      // Filtrar por trabajador si hay uno seleccionado
      if (_trabajadorSeleccionadoId != null && trabajador.id != _trabajadorSeleccionadoId) {
        continue;
      }

      for (var pago in trabajador.historialPagos) {
        // Filtrar por fechas
        if (_rangoFechas != null) {
          if (pago.fecha.isBefore(_rangoFechas!.start) || 
              pago.fecha.isAfter(_rangoFechas!.end.add(const Duration(days: 1)))) {
            continue;
          }
        }
        
        list.add({
          'pago': pago,
          'trabajador': trabajador,
        });
      }
    }
    
    // Ordenar por fecha más reciente
    list.sort((a, b) => (b['pago'] as Pago).fecha.compareTo((a['pago'] as Pago).fecha));
    return list;
  }

  double get _totalEnRango {
    return _pagosFiltrados.fold(0, (sum, item) => sum + (item['pago'] as Pago).monto);
  }

  void _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _rangoFechas,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kVerdeAcento,
              onPrimary: Colors.white,
              surface: _kCardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() => _rangoFechas = rango);
    }
  }

  Future<void> _exportarAExcel() async {
    if (_pagosFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar con estos filtros.')),
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      var sheet = excel['Reporte Salarios'];
      excel.setDefaultSheet('Reporte Salarios');

      // Estilos para cabeceras
      CellStyle cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );

      // Cabeceras
      var headers = ['Fecha de Pago', 'Mes de Pago', 'Trabajador', 'Cargo', 'Monto (Bs.)'];
      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
      
      for (int c = 0; c < headers.length; c++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.cellStyle = cellStyle;
      }

      // Datos
      for (var item in _pagosFiltrados) {
        final pago = item['pago'] as Pago;
        final trabajador = item['trabajador'] as Trabajador;
        sheet.appendRow([
          TextCellValue(_formatoFecha.format(pago.fecha)),
          TextCellValue(pago.mesCorrespondiente),
          TextCellValue(trabajador.nombre),
          TextCellValue(trabajador.cargo),
          DoubleCellValue(pago.monto),
        ]);
      }

      // Fila de Total
      sheet.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('TOTAL:'), DoubleCellValue(_totalEnRango)]);
      var totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: _pagosFiltrados.length + 1));
      totalCell.cellStyle = CellStyle(bold: true);

      // Guardar el archivo temporalmente
      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final String filePath = '${directory.path}/Reporte_Salarios_$timestamp.xlsx';
      
      final bytes = excel.save();
      if (bytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
          
        // Compartir archivo (abre diálogo nativo de Windows / Android)
        await Share.shareXFiles([XFile(filePath)], text: 'Reporte de Salarios Exportado');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagos = _pagosFiltrados;

    return Scaffold(
      backgroundColor: _kAzulOscuro,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildFiltros(),
            _buildTarjetaResumen(pagos.length),
            Expanded(
              child: pagos.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pagos.length,
                      itemBuilder: (context, index) {
                        final item = pagos[index];
                        return _PagoReporteCard(
                          pago: item['pago'] as Pago,
                          trabajador: item['trabajador'] as Trabajador,
                          formatoMoneda: _formatoMoneda,
                          formatoFecha: _formatoFecha,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reporte de Pagos', style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text('Historial filtrado de movimientos', style: TextStyle(
                    color: _kTextoSecundario, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _exportarAExcel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kVerdeAcento.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kVerdeAcento.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download_rounded, color: _kVerdeClaro, size: 18),
                  const SizedBox(width: 6),
                  const Text('Excel', style: TextStyle(color: _kVerdeClaro, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Selector de Trabajador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _trabajadorSeleccionadoId,
                isExpanded: true,
                dropdownColor: _kCardBg,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: _kVerdeAcento),
                hint: const Text('Todos los trabajadores', style: TextStyle(color: Colors.white)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos los trabajadores', style: TextStyle(color: Colors.white))),
                  ..._srv.trabajadores.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.nombre, style: const TextStyle(color: Colors.white)),
                  )),
                ],
                onChanged: (val) => setState(() => _trabajadorSeleccionadoId = val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Selector de Fechas
          GestureDetector(
            onTap: _seleccionarRangoFechas,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: _kVerdeAcento, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _rangoFechas == null 
                          ? 'Seleccionar fechas...'
                          : '${_formatoFecha.format(_rangoFechas!.start)} - ${_formatoFecha.format(_rangoFechas!.end)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  if (_rangoFechas != null)
                    GestureDetector(
                      onTap: () => setState(() => _rangoFechas = null),
                      child: const Icon(Icons.close_rounded, color: _kTextoSecundario, size: 18),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaResumen(int totalTransacciones) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kVerdeAcento, _kVerdeClaro],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kVerdeAcento.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PAGADO', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              Text(_formatoMoneda.format(_totalEnRango), style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('CANTIDAD', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                Text('$totalTransacciones', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('No hay pagos en este filtro', style: TextStyle(color: _kTextoSecundario, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PagoReporteCard extends StatelessWidget {
  final Pago pago;
  final Trabajador trabajador;
  final NumberFormat formatoMoneda;
  final DateFormat formatoFecha;

  const _PagoReporteCard({
    required this.pago,
    required this.trabajador,
    required this.formatoMoneda,
    required this.formatoFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Avatar Inicial
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(trabajador.nombre.substring(0, 1).toUpperCase(), 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          // Info Central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trabajador.nombre, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 12, color: _kTextoSecundario),
                    const SizedBox(width: 4),
                    Text(pago.mesCorrespondiente, style: const TextStyle(color: _kTextoSecundario, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(formatoFecha.format(pago.fecha), style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ),
          ),
          // Monto
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatoMoneda.format(pago.monto), style: const TextStyle(
                  color: _kVerdeAcento, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kVerdeAcento.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('Completado', style: TextStyle(color: _kVerdeClaro, fontSize: 9, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
