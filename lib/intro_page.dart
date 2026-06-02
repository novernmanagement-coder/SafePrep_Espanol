import 'package:flutter/material.dart';
import 'home_page.dart';
import 'constants.dart';
import 'app_state.dart';

class IntroductoryPage extends StatefulWidget {
  const IntroductoryPage({super.key});

  @override
  State<IntroductoryPage> createState() => _IntroductoryPageState();
}

class _IntroductoryPageState extends State<IntroductoryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  bool _showTapHint = false;
  late AnimationController _bobbingController;
  late Animation<double> _bobbingAnimation;

  @override
  void initState() {
    super.initState();
    _bobbingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bobbingAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bobbingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bobbingController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      AppState().userName = name;
    }
  }

  void _showHint() {
    setState(() => _showTapHint = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTapHint = false);
    });
  }

  void _onIconTapped() {
    _saveName();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = AppState().hasTakenAssessment;

    final resultsMessage = hasResults
        ? 'Ya tenemos tus resultados de evaluación archivados — tu plan de estudio personalizado está listo.\n\nSi prefieres comenzar de nuevo, puedes repetir la evaluación en cualquier momento desde la página de inicio.'
        : 'Ve a la página de inicio para tomar tu evaluación diagnóstica gratuita — a partir de ahí crearemos tu plan de estudio personalizado.';

    return Scaffold(
      backgroundColor: AppColors.primaryButton,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSizes.pageMargin,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSizes.bodySpacing,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _onIconTapped,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'Assets/splash.png',
                            width: AppSizes.iconLarge,
                            height: AppSizes.iconLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _bobbingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bobbingAnimation.value),
                            child: const Text(
                              '▲',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toca el ícono para ir a la página de inicio',
                        style: TextStyle(
                          fontSize: AppFonts.caption,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Titular de felicitaciones
                  const Text(
                    'Felicitaciones.',
                    style: TextStyle(
                      fontSize: AppFonts.title,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Mensaje principal
                  const Text(
                    'Acabas de tomar la decisión más inteligente para aprobar tu examen ServSafe\u00ae.\n\nSafePrep\u2122 fue creado con un solo propósito — prepararte. No con preguntas genéricas y suposiciones, sino con un sistema que te conoce, se adapta a ti y construye un plan de estudio basado en tus resultados.\n\nNo solo estás estudiando. Te estás preparando.',
                    style: TextStyle(
                      fontSize: AppFonts.body,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Mensaje contextual de resultados
                  Text(
                    resultsMessage,
                    style: const TextStyle(
                      fontSize: AppFonts.body,
                      color: Colors.white70,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  Column(
                    spacing: AppSizes.headerSpacing,
                    children: [
                      const Text(
                        '¿Cómo te gusta que te llamen?',
                        style: TextStyle(
                          fontSize: AppFonts.body,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        width: AppSizes.primaryButtonWidth,
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu nombre',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          onSubmitted: (_) {
                            _saveName();
                            _showHint();
                          },
                          onEditingComplete: () {
                            if (_nameController.text.trim().isNotEmpty) {
                              _saveName();
                              _showHint();
                            }
                          },
                        ),
                      ),
                      const Text(
                        '(Opcional)',
                        style: TextStyle(
                          fontSize: AppFonts.caption,
                          color: Colors.white54,
                        ),
                      ),
                      if (_showTapHint)
                        const Text(
                          'Toca el ícono de arriba para continuar',
                          style: TextStyle(
                            fontSize: AppFonts.question,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),

                  Column(
                    spacing: AppSizes.footerSpacing,
                    children: [
                      Text(
                        AppStrings.footerLine1,
                        style: const TextStyle(
                          fontSize: AppFonts.footer,
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        AppStrings.footerLine2,
                        style: const TextStyle(
                          fontSize: AppFonts.footer,
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        AppStrings.footerLine3,
                        style: const TextStyle(
                          fontSize: AppFonts.footer,
                          color: AppColors.starMotifBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
