import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'inventario_service.dart';

class InventarioVoiceService {
  static final InventarioVoiceService instance = InventarioVoiceService._();
  InventarioVoiceService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isInitialized = false;
  List<stt.LocaleName> _locales = [];

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      // Solicitar permiso de micrófono explícitamente (Android/iOS)
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('>>> STT: Permiso de micrófono denegado');
          return false;
        }
      }

      print('>>> STT: Iniciando inicialización...');
      bool available = await _speech.initialize(
        onStatus: (status) => print('>>> STT Status: $status'),
        onError: (error) => print('>>> STT Error: ${error.errorMsg}'),
        debugLogging: true,
      );
      
      if (available) {
        _locales = await _speech.locales();
        print('>>> STT: Locales disponibles: ${_locales.map((l) => l.localeId).join(', ')}');
        
        await _tts.setLanguage("es");
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);
        _isInitialized = true;
      }
      return available;
    } catch (e) {
      print('>>> STT: Excepción en Init: $e');
      return false;
    }
  }

  bool get isInitialized => _isInitialized;

  bool get isListening => _speech.isListening;

  Future<bool> startListening(Function(String) onResult, Function(String) onResponse) async {
    if (!_isInitialized) {
      bool ok = await init();
      if (!ok) {
        onResponse("El sistema de voz no está disponible.");
        return false;
      }
    }
    
    // Intentamos buscar un locale de español
    String localeId = ""; // Dejar vacío para que use el default del sistema si no encontramos es-XX
    try {
      if (_locales.any((l) => l.localeId.toLowerCase().contains("es"))) {
        // Preferimos el que coincida exactamente con el del sistema o el primero de la lista
        localeId = _locales.firstWhere((l) => l.localeId.toLowerCase().contains("es")).localeId;
      }
    } catch (_) {}

    print('>>> STT: Iniciando escucha con locale: $localeId');
    try {
      await _speech.listen(
        onResult: (result) {
          print('>>> STT Result: ${result.recognizedWords}');
          onResult(result.recognizedWords);
          if (result.finalResult) {
            final respuesta = _procesarComando(result.recognizedWords);
            onResponse(respuesta);
          }
        },
        localeId: localeId.isEmpty ? null : localeId,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      return true;
    } catch (e) {
      print('>>> STT: Error al llamar a listen: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  // Método para que la IA hable
  Future<void> speak(String texto) async {
    // Limpiar asteriscos de markdown para que no los pronuncie
    final textoLimpio = texto.replaceAll('**', '');
    await _tts.speak(textoLimpio);
  }

  // Permite procesar texto directamente (útil para el chat manual)
  String interpretarTexto(String texto) {
    return _procesarComando(texto);
  }

  String? _detectarColorEspecifico(String comando, Map<String, int> stockMap) {
    for (var color in stockMap.keys) {
      if (comando.contains(color.toLowerCase())) {
        return color;
      }
    }
    return null;
  }

  String _normalizarTexto(String s) {
    var str = s.toLowerCase();
    // Quitar tildes básicas
    str = str.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
    // Quitar signos de puntuación comunes
    str = str.replaceAll(RegExp(r'[?¿!¡.,]'), '');
    return str.trim();
  }

  String _procesarComando(String texto) {
    final comando = _normalizarTexto(texto);
    final stockMap = InventarioService.instance.inventarioActual;
    String respuesta = "";

    // 1. INSIGHTS INTELIGENTES (Prioridad Máxima)
    
    // ¿Qué color se vende más?
    if (comando.contains('vende mas') || comando.contains('sale mas') || 
        comando.contains('mas vendido') || comando.contains('popular') || 
        comando.contains('estrella') || comando.contains('mejor color')) {
      final top = InventarioService.instance.obtenerTopVendido();
      if (top == "Sin datos") {
        respuesta = "Aún no tengo suficientes datos de ventas para decirte cuál es el más popular.";
      } else {
        respuesta = "Tu color estrella es el **$top**. Es el que más ha salido hasta ahora.";
      }
    }
    // ¿Qué producir? (Recomendaciones)
    else if (comando.contains('producir') || comando.contains('recomienda') || 
             comando.contains('consejo') || comando.contains('que hago')) {
      respuesta = InventarioService.instance.generarRecomendacion();
    }
    // ¿Qué no sale? (Stock dormido)
    else if (comando.contains('no sale') || comando.contains('no se mueve') || 
             comando.contains('dormido') || comando.contains('estancado')) {
      final dormidos = InventarioService.instance.obtenerStockDormido();
      if (dormidos.isEmpty) {
        respuesta = "¡Todo se está moviendo bien! No tienes stock estancado por ahora.";
      } else {
        respuesta = "Ojo, los colores **${dormidos.join(", ")}** tienen mucho stock pero casi no se están vendiendo.";
      }
    }
    // 2. Consulta de stock de CADA color
    else if (comando.contains('cada color') || (comando.contains('stock') && comando.contains('cada')) || 
             comando.contains('detalle') || comando.contains('lista')) {
      if (stockMap.isEmpty) {
        respuesta = "El inventario está totalmente vacío.";
      } else {
        final listado = stockMap.entries.map((e) {
          final txtCortes = InventarioService.instance.formatearCortes(e.value);
          return "${e.key}: ${e.value} aguayos ($txtCortes)";
        }).join(", ");
        respuesta = "El stock por color es: $listado.";
      }
    }
    // 3. Consulta de colores agotados
    else if (comando.contains('no tengo') || comando.contains('agotado') || 
             comando.contains('falta') || comando.contains('sin stock')) {
      final agotados = stockMap.entries.where((e) => e.value <= 0).map((e) => e.key).toList();
      if (agotados.isEmpty) {
        respuesta = "¡Buenas noticias! Tienes stock de todos los colores registrados.";
      } else {
        respuesta = "Los colores agotados son: ${agotados.join(", ")}.";
      }
    }
    // 4. Consulta de color ESPECÍFICO
    else if (_detectarColorEspecifico(comando, stockMap) != null) {
      final colorEncontrado = _detectarColorEspecifico(comando, stockMap)!;
      final cantidad = stockMap[colorEncontrado] ?? 0;
      final txtCortes = InventarioService.instance.formatearCortes(cantidad);
      respuesta = "El stock actual de $colorEncontrado es de $cantidad aguayos. Eso equivale a $txtCortes.";
    }
    // 5. Resumen general o Total
    else if (comando.contains('resumen') || comando.contains('general') || 
             comando.contains('todo') || comando.contains('total')) {
      int total = stockMap.values.fold(0, (sum, val) => sum + val);
      final txtCortes = InventarioService.instance.formatearCortes(total);
      respuesta = "En total tienes $total aguayos en el inventario, lo que son $txtCortes.";
    }
    // 6. Consulta general de nombres de colores
    else if (comando.contains('colores') || comando.contains('color') || 
             comando.contains('tengo') || comando.contains('hay') || comando == 'etb') {
      final coloresConStock = stockMap.entries.where((e) => e.value > 0).map((e) => e.key).toList();
      if (coloresConStock.isEmpty) {
        respuesta = "No detecto stock de ningún color ahora mismo.";
      } else {
        respuesta = "Tienes ${coloresConStock.length} colores con stock: ${coloresConStock.join(", ")}.";
      }
    }
    else {
      respuesta = "No entendí '$texto'. Prueba preguntando qué colores hay o cuánto hay de un color.";
    }

    speak(respuesta);
    return respuesta;
  }
}
