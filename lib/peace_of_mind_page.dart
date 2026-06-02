import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_page.dart';
import 'flash_cards_page.dart';
import 'instructor_tips_page.dart';
import 'mnemonics_page.dart';
import 'rapid_fire_page.dart';
import 'scenario_drills_page.dart';

class PeaceOfMindPage extends StatelessWidget {
  const PeaceOfMindPage({super.key});

  void _go(BuildContext context, Widget page) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => page),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.pageMargin,
          child: Column(
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        'Prep\u2122',
                        style: TextStyle(
                          fontSize: AppFonts.header,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '\ud83d\udd13 Tranquilidad Total',
                style: TextStyle(
                  fontSize: AppFonts.header,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bodyText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                'Herramientas de estudio exclusivas de SafePrep\u2122 \u2014 ese impulso extra de confianza',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.subtleText,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              _buildToolButton(
                context,
                '\ud83c\udccf Tarjetas de Estudio',
                () => _go(context, const FlashCardsPage()),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                '\ud83c\udfad Simulacros de Escenario',
                () => _go(context, const ScenarioDrillsPage()),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                '\u26a1 Fuego Rápido',
                () => _go(context, const RapidFirePage()),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                '\ud83e\udde0 Nemotécnicas',
                () => _go(context, const MnemonicsPage()),
              ),
              const SizedBox(height: 8),
              _buildToolButton(
                context,
                '\ud83d\udccc Proctor Tips',
                () => _go(context, const InstructorTipsPage()),
              ),

              const SizedBox(height: 32),

              // Pie de página
              Column(
                children: [
                  Text(
                    AppStrings.footerLine1,
                    style: TextStyle(
                      fontSize: AppFonts.footer,
                      color: AppColors.footerText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.footerLine2,
                    style: TextStyle(
                      fontSize: AppFonts.footer,
                      color: AppColors.footerText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
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

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.primaryButtonHeight,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonCornerRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppFonts.button,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
