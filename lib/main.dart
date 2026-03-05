import 'package:flutter/material.dart';
import 'screens/presentacion.dart';
import 'clientes/clientes_page.dart';
import 'ventas/ventas_page.dart';
import 'cobranza/cobranza.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/home':       (_) => const HomePage(),
        '/clientes':   (_) => const ClientesPage(),
        '/ventas':     (_) => const VentasPage(),
        '/cobranzas':  (_) => const CobranzaHubPage(),
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Modelo de módulo
// ─────────────────────────────────────────────
class _Modulo {
  final String titulo;
  final IconData icono;
  final List<Color> gradiente;
  final String ruta;
  final String textura;

  const _Modulo({
    required this.titulo,
    required this.icono,
    required this.gradiente,
    required this.ruta,
    required this.textura,
  });
}

// ─────────────────────────────────────────────
//  Datos de los 11 módulos
// ─────────────────────────────────────────────
const List<_Modulo> _modulos = [
  _Modulo(
    titulo: 'Clientes',
    icono: Icons.people_alt_rounded,
    gradiente: [Color(0xFF6366F1), Color(0xFF818CF8)],
    ruta: '/clientes',
    textura: 'assets/images/aguayo_morado.png',
  ),
  _Modulo(
    titulo: 'Ventas',
    icono: Icons.shopping_bag_rounded,
    gradiente: [Color(0xFF10B981), Color(0xFF34D399)],
    ruta: '/ventas',
    textura: 'assets/images/aguayo_verde.png',
  ),
  _Modulo(
    titulo: 'Cobranzas',
    icono: Icons.account_balance_wallet_rounded,
    gradiente: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ruta: '/cobranzas',
    textura: 'assets/images/aguayo_naranja.png',
  ),
  _Modulo(
    titulo: 'Inventario',
    icono: Icons.inventory_2_rounded,
    gradiente: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ruta: '/inventario',
    textura: 'assets/images/aguayo_azul.png',
  ),
  _Modulo(
    titulo: 'Compras',
    icono: Icons.local_shipping_rounded,
    gradiente: [Color(0xFFEC4899), Color(0xFFF472B6)],
    ruta: '/compras',
    textura: 'assets/images/aguayo_rojo.png',
  ),
  _Modulo(
    titulo: 'Producción',
    icono: Icons.precision_manufacturing_rounded,
    gradiente: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ruta: '/produccion',
    textura: 'assets/images/aguayo_morado.png',
  ),
  _Modulo(
    titulo: 'Pagos',
    icono: Icons.payments_rounded,
    gradiente: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
    ruta: '/pagos',
    textura: 'assets/images/aguayo_verde.png',
  ),
  _Modulo(
    titulo: 'Urdido',
    icono: Icons.grid_on_rounded,
    gradiente: [Color(0xFFF97316), Color(0xFFFB923C)],
    ruta: '/urdido',
    textura: 'assets/images/aguayo_naranja.png',
  ),
  _Modulo(
    titulo: 'Dashboard',
    icono: Icons.bar_chart_rounded,
    gradiente: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    ruta: '/dashboard',
    textura: 'assets/images/aguayo_azul.png',
  ),
  _Modulo(
    titulo: 'Analítica',
    icono: Icons.auto_graph_rounded,
    gradiente: [Color(0xFFD946EF), Color(0xFFE879F9)],
    ruta: '/analitica',
    textura: 'assets/images/aguayo_morado.png',
  ),
  _Modulo(
    titulo: 'IA Matices',
    icono: Icons.auto_awesome_rounded,
    gradiente: [Color(0xFFEF4444), Color(0xFFF87171)],
    ruta: '/ia-matices',
    textura: 'assets/images/aguayo_rojo.png',
  ),
];

// ─────────────────────────────────────────────
//  Home Page con aguayo animado de fondo
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    // Scroll lento infinito: 60 seg por ciclo completo
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Aguayo de fondo animado ───────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              // La imagen se desplaza verticalmente de 0 a -1x su tamaño (loop)
              final offset = _bgCtrl.value * size.height * 1.2;
              return Stack(
                children: [
                  // Tile superior
                  Positioned(
                    left: 0,
                    top: -offset,
                    right: 0,
                    child: Image.asset(
                      'assets/images/aguayo_fondo.png',
                      width: size.width,
                      height: size.height * 2.4,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Tile inferior (para que no haya corte al reiniciarse)
                  Positioned(
                    left: 0,
                    top: size.height * 2.4 - offset,
                    right: 0,
                    child: Image.asset(
                      'assets/images/aguayo_fondo.png',
                      width: size.width,
                      height: size.height * 2.4,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Overlay oscuro semitransparente para legibilidad ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0D0018), // más oscuro arriba
                  Color(0xAA0D0018), // un poco más claro abajo
                ],
              ),
            ),
          ),

          // ── Brillo decorativo central ──────────────
          Positioned(
            top: size.height * 0.1,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: Container(
              height: size.height * 0.35,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6D28D9).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido ────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _ModuloCard(modulo: _modulos[index]),
                      childCount: _modulos.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner superior con glassmorphism ──────────
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.55),
                const Color(0xFF1A0035).withValues(alpha: 0.70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo animado con gradiente
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.60),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.hub_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              // Nombre + subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE0C3FC), Color(0xFFFFB6C1)],
                      ).createShader(bounds),
                      child: const Text(
                        'Arte en Hilos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      'Sistema de Gestión',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Campana de notificaciones
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: Colors.white.withValues(alpha: 0.80), size: 20),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Sección de bienvenida ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👋 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'Bienvenido de nuevo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFD8B4FE)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: const Text(
                  'Panel de Control',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Barra de búsqueda ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded,
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.70),
                    size: 19),
                const SizedBox(width: 10),
                Text(
                  'Buscar módulo...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    'Ctrl + K',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Etiqueta de módulos ────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MÓDULOS DEL SISTEMA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Tarjeta de módulo — con hover animado
// ─────────────────────────────────────────────
class _ModuloCard extends StatefulWidget {
  final _Modulo modulo;
  const _ModuloCard({required this.modulo});

  @override
  State<_ModuloCard> createState() => _ModuloCardState();
}

class _ModuloCardState extends State<_ModuloCard>
    with TickerProviderStateMixin {
  // Animación de tap (presionar)
  late AnimationController _tapCtrl;
  // Animación de hover (pasar el mouse)
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverScale;
  late Animation<double> _hoverGlow;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );

    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _hoverScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
    _hoverGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverCtrl.forward();
    } else {
      _hoverCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.modulo;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _tapCtrl.reverse(),
        onTapUp: (_) {
          _tapCtrl.forward();
          Navigator.pushNamed(context, m.ruta);
        },
        onTapCancel: () => _tapCtrl.forward(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_tapCtrl, _hoverCtrl]),
          builder: (_, child) {
            final scale = _tapCtrl.value * _hoverScale.value;
            final glow = _hoverGlow.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                // Sombra exterior con glow de color
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: m.gradiente[0].withValues(
                          alpha: 0.55 + 0.45 * glow),
                      blurRadius: 18 + 22 * glow,
                      spreadRadius: -2 + 4 * glow,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Textura aguayo única por módulo ──
                      Image.asset(
                        m.textura,
                        fit: BoxFit.cover,
                      ),
                      // ── Overlay muy sutil de color ────────
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              m.gradiente[0].withValues(
                                  alpha: 0.25 - 0.10 * glow),
                              m.gradiente[1].withValues(
                                  alpha: 0.35 - 0.15 * glow),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // ── Borde grueso brillante interior ───
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: m.gradiente[0].withValues(
                                alpha: 0.90 + 0.10 * glow),
                            width: 2.5 + 1.0 * glow,
                          ),
                        ),
                      ),
                      // ── Gradiente oscuro en la base ────────
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.70),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ── Ícono y texto centrados ───────────
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Círculo oscuro definido con ícono
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  m.gradiente[0].withValues(alpha: 0.45),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: m.gradiente[0].withValues(
                                      alpha: 0.70 + 0.30 * glow),
                                  blurRadius: 16 + 12 * glow,
                                  spreadRadius: 0 + 2 * glow,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.40),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child:
                                Icon(m.icono, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              m.titulo,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                      color: Colors.black,
                                      blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hub de Cobranza — 3 sub-módulos
// ─────────────────────────────────────────────
class CobranzaHubPage extends StatelessWidget {
  const CobranzaHubPage({super.key});

  static const _kAzul       = Color(0xFF1565C0);
  static const _kAzulClaro  = Color(0xFF42A5F5);
  static const _kVerde      = Color(0xFF00C853);
  static const _kVerdeClaro = Color(0xFF69F0AE);
  static const _kFondo      = Color(0xFF0A1628);
  static const _kFondo2     = Color(0xFF0D2145);

  @override
  Widget build(BuildContext context) {
    final opciones = [
      _HubOpcion(
        titulo: 'Pagos Parciales',
        subtitulo: 'Control de cuentas por cobrar',
        icono: Icons.account_balance_wallet_rounded,
        colores: const [_kAzul, _kAzulClaro],
        destino: const PagosParciales(),
      ),
      _HubOpcion(
        titulo: 'Clientes con Deuda',
        subtitulo: 'Lista y fechas de pago',
        icono: Icons.people_alt_rounded,
        colores: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        destino: const ListaDeudores(),
      ),
      _HubOpcion(
        titulo: 'Historial de Pagos',
        subtitulo: 'Línea de tiempo por cliente',
        icono: Icons.receipt_long_rounded,
        colores: const [_kVerde, _kVerdeClaro],
        destino: const HistorialPagos(),
      ),
    ];

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
              // ── AppBar ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_kAzulClaro, _kVerdeClaro],
                        ).createShader(b),
                        child: const Text('COBRANZA',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5)),
                      ),
                      Text('Gestión de cobros y pagos',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10,
                              letterSpacing: 1)),
                    ],
                  ),
                ]),
              ),
              // Franja decorativa
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAzul, _kAzulClaro, _kVerde, _kVerdeClaro]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 28),

              // ── Tarjetas de sub-módulos ───
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: opciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _TarjetaHub(opcion: opciones[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubOpcion {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<Color> colores;
  final Widget destino;
  const _HubOpcion({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colores,
    required this.destino,
  });
}

class _TarjetaHub extends StatelessWidget {
  final _HubOpcion opcion;
  const _TarjetaHub({required this.opcion});

  @override
  Widget build(BuildContext context) {
    final c1 = opcion.colores[0];
    final c2 = opcion.colores[1];

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => opcion.destino)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2145),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c1.withValues(alpha: 0.50), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: c1.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [c1, c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: c1.withValues(alpha: 0.50),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(opcion.icono, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opcion.titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(opcion.subtitulo,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c1.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c1.withValues(alpha: 0.40)),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, color: c1, size: 14),
          ),
        ]),
      ),
    );
  }
}
