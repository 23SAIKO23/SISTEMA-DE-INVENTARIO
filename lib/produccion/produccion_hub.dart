import 'package:flutter/material.dart';
import 'produccion.dart';

// ── Paleta ─────────────────────────────────────
const _kAzul       = Color(0xFF1565C0);
const _kAzulClaro  = Color(0xFF42A5F5);
const _kVerde      = Color(0xFF00C853);
const _kVerdeClaro = Color(0xFF69F0AE);
const _kFondo      = Color(0xFF0A1628);
const _kFondo2     = Color(0xFF0D2145);

class ProduccionHubPage extends StatelessWidget {
  const ProduccionHubPage({super.key});

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
        child: SafeArea(child: Column(children: [
          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_kAzulClaro, _kVerdeClaro],
                    ).createShader(b),
                    child: const Text('PRODUCCIÓN', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                  Text('Control Semanal por Máquina', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10, letterSpacing: 0.8)),
                ],
              )),
              const Icon(Icons.factory_rounded, color: _kVerdeClaro, size: 24),
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

          // Opciones
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: const [
              _MenuCard(
                titulo: 'Registro Semanal',
                desc: 'Abonar a la semana actual y cerrar domingos',
                icono: Icons.date_range_rounded,
                colorTema: _kAzulClaro,
                destino: RegistroSemanalPage(),
              ),
              SizedBox(height: 14),
              _MenuCard(
                titulo: 'Productividad',
                desc: 'Promedio de aguayos por semana y trabajador',
                icono: Icons.trending_up_rounded,
                colorTema: Color(0xFFFFB300),
                destino: ProductividadPage(),
              ),
            ],
          )),
        ])),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String titulo, desc;
  final IconData icono;
  final Color colorTema;
  final Widget destino;

  const _MenuCard({required this.titulo, required this.desc,
      required this.icono, required this.colorTema, required this.destino});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => destino)),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kFondo2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorTema.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: colorTema.withValues(alpha: 0.08),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: colorTema.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorTema.withValues(alpha: 0.40)),
          ),
          child: Icon(icono, color: colorTema, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50), fontSize: 11)),
        ])),
        Icon(Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.20)),
      ]),
    ),
  );
}
