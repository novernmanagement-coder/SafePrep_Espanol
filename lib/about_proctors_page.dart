import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'home_page.dart';

class AboutProctorsPage extends StatelessWidget {
  const AboutProctorsPage({super.key});

  static const String _proctorUrl =
      'https://www.servsafe.com/Instructors-Proctors';

  Future<void> _launchUrl() async {
    final uri = Uri.parse(_proctorUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCard(String title, List<String> items) {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.cardCornerRadius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.strongText,
            ),
          ),
          ...items.map(
            (item) => Text(
              item,
              style: TextStyle(fontSize: 13, color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.pageMargin,
          child: Column(
            spacing: 12,
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      ),
                      child: Row(
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
                          Image.asset(
                            'Assets/splash.png',
                            width: 36,
                            height: 36,
                          ),
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
                    ),
                  ],
                ),
              ),

              Text(
                'Sobre los Proctors',
                style: TextStyle(
                  fontSize: AppFonts.header,
                  fontWeight: FontWeight.bold,
                  color: AppColors.strongText,
                ),
                textAlign: TextAlign.center,
              ),

              _buildCard('¿Qué es un Proctor?', [
                'Un proctor es una persona certificada por ServSafe® autorizada para administrar el examen de certificación ServSafe® Manager.',
              ]),

              _buildCard('Responsabilidades del Proctor', [
                '• Verificar la identidad del candidato al examen',
                '• Administrar el examen bajo condiciones controladas',
                '• Supervisar la sesión del examen para garantizar su integridad',
                '• Enviar los resultados a ServSafe® al finalizar',
              ]),

              _buildCard('Lo que un Proctor No Es', [
                'Un proctor no es un instructor. Un proctor no proporciona orientación, responde preguntas, ofrece consejos ni asiste con el contenido del examen de ninguna manera. La única función de un proctor es administrar y supervisar el examen y verificar que la persona que lo toma es quien dice ser.',
              ]),

              _buildCard('Proveedores de Servicios Independientes', [
                'Los proctors son profesionales independientes y autónomos. No son empleados ni agentes de ServSafe®, la National Restaurant Association® ni SafePrep™. Las tarifas de proctoring son establecidas de forma independiente por cada proctor y pueden variar. SafePrep™ no hace ninguna declaración sobre la disponibilidad, precios o programación de los proctors.',
              ]),

              _buildCard('Para Programar Tu Examen', [
                'Usa el localizador de proctors de ServSafe® para encontrar un proctor certificado en tu área.',
              ]),

              SizedBox(
                width: double.infinity,
                height: AppSizes.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: _launchUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonCornerRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'www.ServSafe.com',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
