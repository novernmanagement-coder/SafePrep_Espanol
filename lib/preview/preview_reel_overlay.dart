import 'package:flutter/material.dart';
import '../constants.dart';
import '../app_state.dart';
import '../readiness_engine.dart';
import 'preview_cinematic_splash.dart';

class PreviewReelOverlay extends StatefulWidget {
  final VoidCallback onBuy;
  final bool isPurchasing;
  final String unlockPrice;
  final VoidCallback? onBuySevenDay;
  final VoidCallback? onBuyFourteenDay;

  const PreviewReelOverlay({
    super.key,
    required this.onBuy,
    required this.isPurchasing,
    required this.unlockPrice,
    this.onBuySevenDay,
    this.onBuyFourteenDay,
  });

  @override
  State<PreviewReelOverlay> createState() => _PreviewReelOverlayState();
}

class _PreviewReelOverlayState extends State<PreviewReelOverlay>
    with TickerProviderStateMixin {
  int _reelIndex = 0;
  bool _reelShowingBlurb = false;
  bool _running = true;

  late AnimationController _itemController;
  late Animation<double> _itemFade;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _softWhite = Color(0xFFF0EDE8);
  static const Color _mutedWhite = Color(0x99F0EDE8);

  static const List<Map<String, String>> _featureSlides = [
    {
      'asset': 'Assets/reel_dashboard.png',
      'label': 'Panel',
      'blurb':
          'Tu plan de estudio personalizado — construido a partir de tus resultados, no una lista interminable de preguntas sin sentido.',
    },
    {
      'asset': 'Assets/reel_study.png',
      'label': 'Estudiar',
      'blurb':
          'Cada categoría de estudio, adaptada a tu nivel. Cada tema explicado claramente — con puntos clave que lo hacen memorable.',
    },
    {
      'asset': 'Assets/reel_flashcards.png',
      'label': 'Tarjetas de Estudio',
      'blurb':
          '82 tarjetas, codificadas por color según categoría. Toca para revelar — un método clásico de estudio integrado en tu mazo personalizado.',
    },
    {
      'asset': 'Assets/reel_scenario.png',
      'label': 'Simulacros de Escenario',
      'blurb':
          'Escenarios reales del examen. Dirigidos por instructor, con participación del estudiante.',
    },
    {
      'asset': 'Assets/reel_rapidfire.png',
      'label': 'Fuego Rápido',
      'blurb':
          'Entrenamiento de reacción rápida — porque el examen real no espera.',
    },
    {
      'asset': 'Assets/reel_mnemonics.png',
      'label': 'Nemotécnicas',
      'blurb':
          'Para los temas difíciles de recordar, asociación de palabras en su máxima expresión.',
    },
  ];

  late final List<Map<String, String>> _reelItems;

  @override
  void initState() {
    super.initState();

    _reelItems = [
      {
        'asset': '',
        'label': 'Tus Resultados',
        'blurb': _buildPersonalizedMessage(),
      },
      ..._featureSlides,
      {
        'asset': '',
        'label': 'Tu Preparación',
        'blurb': _buildReadinessTimeline(),
      },
    ];

    _itemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _itemFade = CurvedAnimation(
      parent: _itemController,
      curve: Curves.easeIn,
    ).drive(Tween(begin: 0.0, end: 1.0));

    _itemController.forward();
    _runLoop();
  }

  @override
  void dispose() {
    _running = false;
    _itemController.dispose();
    super.dispose();
  }

  String _buildPersonalizedMessage() {
    final state = AppState();
    final overall = state.getOverallScore();

    if (overall >= 95) {
      return 'Tus resultados son excepcionales — tu currículo está listo para mantenerte en forma. Tu plan de estudio personalizado te espera.';
    }

    final scored =
        AppState.allCategories
            .where((c) => state.hasScoreForCategory(c))
            .toList()
          ..sort(
            (a, b) =>
                state.getCategoryScore(a).compareTo(state.getCategoryScore(b)),
          );

    final count = overall >= AppState.masteryThreshold ? 2 : 3;
    final focus = scored.take(count).toList();

    if (focus.isEmpty) {
      return 'Tu currículo personalizado está construido y listo — pongámonos a trabajar.';
    }

    final categoryList = focus.length == 1
        ? focus[0]
        : focus.length == 2
        ? '${focus[0]} y ${focus[1]}'
        : '${focus[0]}, ${focus[1]} y ${focus[2]}';

    return 'Tus resultados indican que necesitas más estudio en $categoryList — tu currículo personalizado está listo y te espera.';
  }

  String _buildReadinessTimeline() {
    final state = AppState();
    final score = ReadinessEngine.calculate(state);

    if (score >= 85) {
      return 'Alta aptitud detectada. Se necesita poco estudio — ajusta con las herramientas de Tranquilidad Total y módulos de 60 Segundos y estarás listo.';
    }
    if (score >= 66) {
      return 'Has demostrado verdadera aptitud — una ventana enfocada de 2 a 3 días debería dejarte 100% listo para el examen.';
    }
    if (score >= 41) {
      return 'Con tu plan de estudio y herramientas de Tranquilidad Total, la mayoría de estudiantes en tu rango están 100% listos en 3 a 4 días.';
    }
    return 'El estudio diario enfocado te lleva ahí rápido. En promedio, los estudiantes en tu nivel están listos en 5 días o menos.';
  }

  Future<void> _runLoop() async {
    while (_running && mounted) {
      if (_reelIndex == 0) {
        await Future.delayed(const Duration(seconds: 8));
        if (!_running || !mounted) return;
        await _itemController.reverse();
        if (!mounted) return;
        setState(() {
          _reelShowingBlurb = true;
          _reelIndex = 1;
        });
        await _itemController.forward();
        continue;
      }

      if (_reelIndex == _reelItems.length - 1) {
        await Future.delayed(const Duration(seconds: 8));
        if (!_running || !mounted) return;
        await _itemController.reverse();
        if (!mounted) return;
        setState(() {
          _reelShowingBlurb = false;
          _reelIndex = 0;
        });
        await _itemController.forward();
        continue;
      }

      if (_reelShowingBlurb) {
        await Future.delayed(const Duration(milliseconds: 3500));
        if (!_running || !mounted) return;
        await _itemController.reverse();
        if (!mounted) return;
        setState(() => _reelShowingBlurb = false);
        await _itemController.forward();
      } else {
        await Future.delayed(const Duration(milliseconds: 3500));
        if (!_running || !mounted) return;
        await _itemController.reverse();
        if (!mounted) return;
        final nextIndex = _reelIndex + 1;
        if (nextIndex == _reelItems.length - 1) {
          setState(() {
            _reelShowingBlurb = false;
            _reelIndex = nextIndex;
          });
        } else {
          setState(() {
            _reelShowingBlurb = true;
            _reelIndex = nextIndex;
          });
        }
        await _itemController.forward();
      }
    }
  }

  Widget _buildPersonalizedCard(String message, double screenWidth) {
    return Container(
      width: screenWidth * 0.78,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TUS RESULTADOS',
            style: TextStyle(
              color: _gold.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _softWhite,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(String message, double screenWidth) {
    return Container(
      width: screenWidth * 0.78,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TU PREPARACIÓN',
            style: TextStyle(
              color: _gold.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _softWhite,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotFrame(
    String asset,
    String label,
    double screenWidth,
    double screenHeight,
  ) {
    final frameWidth = screenWidth * 0.55;
    final frameHeight = screenHeight * 0.42;

    return Column(
      children: [
        Container(
          width: frameWidth,
          height: frameHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: asset.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(asset, fit: BoxFit.contain),
                )
              : Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _gold.withValues(alpha: 0.3),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: _gold.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBlurbCard(String blurb, double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.75,
      child: Text(
        blurb,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _softWhite,
          fontSize: 18,
          fontWeight: FontWeight.w300,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPurchaseButtons() {
    if (widget.isPurchasing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    return Column(
      children: [
        _buildTierButton(
          label: '\$4.99  —  7 Días de Acceso',
          sublabel: 'Pruébalo',
          isHighlighted: false,
          onTap: widget.onBuySevenDay ?? widget.onBuy,
        ),
        const SizedBox(height: 8),
        _buildTierButton(
          label: '\$8.99  —  14 Días de Acceso',
          sublabel: 'Estudia a fondo',
          isHighlighted: false,
          onTap: widget.onBuyFourteenDay ?? widget.onBuy,
        ),
        const SizedBox(height: 8),
        _buildTierButton(
          label: '\$9.99  —  Acceso Vitalicio',
          sublabel: 'Mejor valor  •  Tuyo para siempre  ★',
          isHighlighted: true,
          onTap: widget.onBuy,
        ),
      ],
    );
  }

  Widget _buildTierButton({
    required String label,
    required String sublabel,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isHighlighted ? _gold : const Color(0xFF1A1A14),
          foregroundColor: isHighlighted ? const Color(0xFF0A0A0F) : _softWhite,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonCornerRadius),
            side: BorderSide(
              color: isHighlighted ? _gold : _gold.withValues(alpha: 0.4),
              width: isHighlighted ? 0 : 1,
            ),
          ),
          elevation: isHighlighted ? 6 : 2,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? const Color(0xFF0A0A0F) : _softWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isHighlighted
                    ? const Color(0xFF0A0A0F).withValues(alpha: 0.7)
                    : _mutedWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final item = _reelItems[_reelIndex];
    final isPersonalizedSlide = _reelIndex == 0;
    final isReadinessSlide = _reelIndex == _reelItems.length - 1;

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _itemFade,
              child: isPersonalizedSlide
                  ? _buildPersonalizedCard(item['blurb']!, screenWidth)
                  : isReadinessSlide
                  ? _buildReadinessCard(item['blurb']!, screenWidth)
                  : _reelShowingBlurb
                  ? _buildBlurbCard(item['blurb']!, screenWidth)
                  : _buildScreenshotFrame(
                      item['asset']!,
                      item['label']!,
                      screenWidth,
                      screenHeight,
                    ),
            ),

            const SizedBox(height: 24),

            // Puntos de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_reelItems.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _reelIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _reelIndex
                        ? _gold
                        : _gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildPurchaseButtons(),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
