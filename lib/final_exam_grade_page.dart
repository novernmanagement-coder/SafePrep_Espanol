import 'package:flutter/material.dart';
import 'constants.dart';
import 'app_state.dart';
import 'dashboard_page.dart';
import 'exam_ready_page.dart';

class FinalExamGradePage extends StatelessWidget {
  final TestResult result;

  const FinalExamGradePage({super.key, required this.result});

  Color _scoreColor(int score) {
    if (score <= 50) return AppColors.scoreBand1;
    if (score <= 65) return AppColors.scoreBand2;
    if (score <= 84) return AppColors.scoreBand3;
    return AppColors.scoreBand4;
  }

  String _scoreBandMessage(int score) {
    if (score <= 50) {
      return 'Hemos ajustado tu plan de estudio y lo hemos hecho más intuitivo. Pongámonos a trabajar.';
    }
    if (score <= 65) {
      return 'Tus resultados son muy alentadores. Tienes las bases — hemos creado un plan de estudio personalizado solo para ti.';
    }
    if (score <= 84) {
      return 'Dominaste lo básico. Ahora vamos a afinar tu conocimiento — tu plan de estudio personalizado y compacto está listo.';
    }
    if (score <= 99) {
      return 'Estás listo. Regresa a repasar cuando quieras — hemos agregado esa opción en el Repaso de 60 Segundos.';
    }
    return 'Estás listo para el examen ServSafe®. El Repaso de 60 Segundos te estará esperando cuando lo necesites.';
  }

  String _primaryButtonLabel(int score) {
    if (score <= 50) return 'Construir mi base';
    if (score <= 65) return 'Iniciar mi plan de estudio';
    if (score <= 84) return 'Afinar mi conocimiento';
    if (score <= 99) return 'Perfeccionar mi conocimiento';
    return 'Estás listo →';
  }

  Widget _buildCategoryRow(String category, int score) {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.cardCornerRadius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: TextStyle(
                fontSize: AppFonts.body,
                fontWeight: FontWeight.w600,
                color: AppColors.strongText,
              ),
            ),
          ),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: AppFonts.body,
              fontWeight: FontWeight.bold,
              color: _scoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore;
    final scoreColor = _scoreColor(score);
    final state = AppState();

    final categories = [
      'Time & Temperature',
      'Cross-Contamination',
      'Food Preparation',
      'Receiving & Storage',
      'Personal Hygiene',
      'Cleaning & Sanitizing',
      'Facility & Equipment',
      'Food Safety Management',
    ];

    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.pageMargin,
          child: Column(
            spacing: 10,
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Safe',
                          style: TextStyle(
                            fontSize: AppFonts.header,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset('Assets/splash.png', width: 36, height: 36),
                        const SizedBox(width: 6),
                        Text(
                          'Prep™',
                          style: TextStyle(
                            fontSize: AppFonts.header,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Text(
                'Tus Resultados',
                style: TextStyle(
                  fontSize: AppFonts.header,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bodyText,
                ),
                textAlign: TextAlign.center,
              ),

              // Tarjeta de puntaje general
              Container(
                padding: AppSizes.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardCornerRadius,
                  ),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  spacing: 4,
                  children: [
                    Text(
                      'Puntaje General',
                      style: TextStyle(
                        fontSize: AppFonts.caption,
                        color: AppColors.subtleText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Mensaje de banda de puntaje
              Text(
                _scoreBandMessage(score),
                style: TextStyle(
                  fontSize: AppFonts.body,
                  color: AppColors.bodyText,
                ),
                textAlign: TextAlign.center,
              ),

              // Encabezado de desglose por categoría
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Desglose por Categoría',
                    style: TextStyle(
                      fontSize: AppFonts.subheader,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
              ),

              // Filas de categorías
              ...categories.map((cat) {
                final catScore =
                    result.categoryScores[cat] ?? state.getCategoryScore(cat);
                return _buildCategoryRow(cat, catScore);
              }),

              const SizedBox(height: 8),

              // Botón de acción principal
              SizedBox(
                width: double.infinity,
                height: AppSizes.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.masteredCategories.length ==
                        AppState.allCategories.length) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExamReadyPage(overallScore: score),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonCornerRadius,
                      ),
                    ),
                  ),
                  child: Text(_primaryButtonLabel(score)),
                ),
              ),

              // Pie de página
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  spacing: AppSizes.footerSpacing,
                  children: [
                    Text(
                      AppStrings.footerLine1,
                      style: TextStyle(
                        fontSize: AppFonts.footer,
                        color: AppColors.footerText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      AppStrings.footerLine2,
                      style: TextStyle(
                        fontSize: AppFonts.footer,
                        color: AppColors.footerText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      AppStrings.footerLine3,
                      style: TextStyle(
                        fontSize: AppFonts.footer,
                        color: AppColors.starMotifBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
