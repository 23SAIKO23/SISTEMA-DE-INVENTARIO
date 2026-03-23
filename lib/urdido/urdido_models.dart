import 'package:flutter/material.dart';

class RecetaUrdido {
  final String modelo;
  final int totalHilos;
  final int anchoPeine;
  final List<Armada> armadas;

  RecetaUrdido({
    required this.modelo,
    required this.totalHilos,
    required this.anchoPeine,
    required this.armadas,
  });
}

class Armada {
  final String titulo;
  final String descripcion;
  final int repeticiones;
  final List<String> posicionesUrdidor;
  final List<List<Color>> matrizHilos;

  Armada({
    required this.titulo,
    required this.descripcion,
    required this.repeticiones,
    required this.posicionesUrdidor,
    required this.matrizHilos,
  });
}
