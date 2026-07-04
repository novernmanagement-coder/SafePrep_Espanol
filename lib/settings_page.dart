import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'home_page.dart';
import 'splash_page.dart';
import 'tips_page.dart';
import 'safe_prep_nav_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppState _state = AppState();
  final TextEditingController _nameController = TextEditingController();
  bool _nameSaved = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _state.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      _state.userName = name;
      AppStatePersistence.save();
      setState(() => _nameSaved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _nameSaved = false);
      });
    }
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Restablecer todo el progreso?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _state.reset();
      AppStatePersistence.delete();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashPage()),
        );
      }
    }
  }

  // TODO: confirm actual Español refund redirect URL — placeholder below
  // mirrors Manager's URL structure on the assumption it lives under the
  // same domain. Update if Español has a distinct refund page.
  Future<void> _openRefundPage() async {
    final uri = Uri.parse(
      'https://foodsafetymadeeasy.com/refund-redirect-page/',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppFonts.subheader,
              fontWeight: FontWeight.w600,
              color: AppColors.strongText,
            ),
          ),
          Divider(color: AppColors.cardBorder),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppFonts.body,
            fontWeight: FontWeight.w600,
            color: AppColors.strongText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: AppFonts.caption,
            color: AppColors.bodyText,
          ),
        ),
        Divider(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppFonts.body,
                color: AppColors.subtleText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFonts.body,
              color: AppColors.strongText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTrial = !_state.hasUnlockedApp;

    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: SafeArea(
        child: Column(
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
                  ),
                ],
              ),
            ),

            // Cuerpo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  spacing: 10,
                  children: [
                    // Acerca de
                    _buildSectionCard(
                      title: 'Acerca de SafePrep™',
                      children: [
                        _buildInfoRow('Versión', '1.2.0'),
                        _buildInfoRow('Build', 'Mayo 2026'),
                        _buildInfoRow('Plataforma', 'Flutter'),
                        const SizedBox(height: 4),
                        Text(
                          'SafePrep™ es un sistema de aprendizaje psicológicamente adaptativo para la preparación del examen ServSafe® Manager.',
                          style: TextStyle(
                            fontSize: AppFonts.caption,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),

                    // Opciones de restablecimiento
                    _buildSectionCard(
                      title: 'Opciones de Restablecimiento',
                      children: [
                        Text(
                          'Tu nombre',
                          style: TextStyle(
                            fontSize: AppFonts.caption,
                            color: AppColors.subtleText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                maxLength: 20,
                                decoration: InputDecoration(
                                  hintText: 'Escribe tu nombre…',
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              width: 70,
                              child: ElevatedButton(
                                onPressed: _saveName,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryButton,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Guardar',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_nameSaved)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '✓  Nombre guardado',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.scoreBand4,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          'Borra todos los puntajes de quiz, líneas base y progreso del currículo. Esta acción no se puede deshacer.',
                          style: TextStyle(
                            fontSize: AppFonts.caption,
                            color: AppColors.subtleText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _resetProgress,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Restablecer Progreso'),
                          ),
                        ),
                      ],
                    ),

                    // Consejos
                    _buildSectionCard(
                      title: 'Consejos e Información',
                      children: [
                        Text(
                          'Consejos para el día del examen, estrategias de estudio e información sobre ServSafe®.',
                          style: TextStyle(
                            fontSize: AppFonts.caption,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TipsPage(),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryButton,
                              side: BorderSide(color: AppColors.primaryButton),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Abrir Consejos e Información'),
                          ),
                        ),
                      ],
                    ),

                    // Contacto
                    _buildSectionCard(
                      title: 'Contacto y Soporte',
                      children: [
                        Text(
                          'Para preguntas, soporte o consultas legales:',
                          style: TextStyle(
                            fontSize: AppFonts.body,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.servSafeBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NovernManagement@gmail.com',
                            style: TextStyle(
                              fontSize: AppFonts.body,
                              fontWeight: FontWeight.w600,
                              color: AppColors.strongText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    // Legal — updated to match Manager's guarantee model.
                    // Removed the old "no guarantees" disclaimer since it
                    // directly contradicted the pass-or-refund promise.
                    _buildSectionCard(
                      title: 'Legal y Cumplimiento',
                      children: [
                        _buildLegalSection(
                          'Aviso de Marca Registrada',
                          'ServSafe® es una marca registrada de la National Restaurant Association Educational Foundation. SafePrep™ no está afiliado, respaldado ni conectado oficialmente con la National Restaurant Association ni con ServSafe®. Todas las referencias a ServSafe® son únicamente con fines descriptivos.',
                        ),
                        _buildLegalSection(
                          'Descargo de Responsabilidad',
                          'SafePrep™ es un recurso educativo independiente y no está afiliado con ServSafe® ni con la National Restaurant Association. Para conocer nuestra política de garantía, consulta a continuación.',
                        ),
                        _buildLegalSection(
                          'Términos de Uso',
                          'Al usar esta aplicación, acepta estos Términos. La aplicación es solo para uso educativo. No puede modificar, distribuir ni realizar ingeniería inversa de la aplicación ni de su contenido. El desarrollador puede actualizar o discontinuar la aplicación en cualquier momento. La aplicación se proporciona "tal cual" sin garantías de ningún tipo.',
                        ),
                        _buildLegalSection(
                          'Privacidad y Manejo de Datos',
                          'La aplicación puede recopilar datos técnicos o de uso limitados para funcionalidad y análisis. No se recopila información de identificación personal a menos que se proporcione voluntariamente. Los datos recopilados nunca se venden ni se comparten con terceros, excepto cuando lo exija la ley. Al usar la aplicación, usted consiente esta política.',
                        ),
                        _buildLegalSection(
                          'Nuestra Garantía',
                          'Garantizamos que aprobarás el examen en tu primer intento, o te devolvemos tu dinero, sin hacer preguntas.',
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isTrial ? null : _openRefundPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primaryButton
                                  .withValues(alpha: 0.35),
                              disabledForegroundColor: Colors.white.withValues(
                                alpha: 0.7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Reembolso'),
                          ),
                        ),
                        if (isTrial)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Los reembolsos aplican solo a compras — disponible una vez que hayas desbloqueado el acceso completo.',
                              style: TextStyle(
                                fontSize: AppFonts.caption,
                                color: AppColors.subtleText,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 4),

                        Divider(
                          color: AppColors.cardBorder.withValues(alpha: 0.4),
                        ),
                        Text(
                          'Documentos Legales Completos',
                          style: TextStyle(
                            fontSize: AppFonts.body,
                            fontWeight: FontWeight.w600,
                            color: AppColors.strongText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'La Política de Privacidad y los Términos de Servicio completos están disponibles en:',
                          style: TextStyle(
                            fontSize: AppFonts.caption,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.servSafeBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            spacing: 4,
                            children: [
                              Text(
                                'sites.google.com/view/safeprep/privacy-policy',
                                style: TextStyle(
                                  fontSize: AppFonts.caption,
                                  color: AppColors.strongText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'sites.google.com/view/safeprep/terms-of-service',
                                style: TextStyle(
                                  fontSize: AppFonts.caption,
                                  color: AppColors.strongText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SafePrepNavBar(),
          ],
        ),
      ),
    );
  }
}