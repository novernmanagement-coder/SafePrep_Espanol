import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../mixpanel_service.dart';
import '../iap_service.dart';
import '../fsme_popup.dart';
import '../dashboard_page.dart';
import '../rapid_fire_limited_intro.dart';
import 'onboard_answers.dart';
import 'onboard_knowledge_level.dart';

/// Onboarding paywall — redesigned for the self-report funnel.
///
/// One product ($4.99, 7 days full access — reuses the existing
/// `kProductSevenDay` / 'SafePrepEspanolUnlock1Week' product, no new
/// App Store Connect product needed). The subline and FSME's one-line
/// reaction both key off the knowledge level the user self-reported
/// earlier in the funnel — copy only, never a different product or
/// different curriculum.
///
/// FSME's role here is deliberately minimal — one reactive line via
/// the shared [FsmePopup] widget, no authored multi-beat script.
///
/// "¿Aún no estás listo?" routes to the Fuego Rápido preview (now
/// ported — see RapidFireLimitedIntro) as a taste of the tool before a
/// second ask, rather than a hard decline exit.
///
/// Still DIVERGES from Manager on one point, a deliberate scope call:
/// on purchase success, routes straight to [DashboardPage] instead of
/// the FSME cluster-tour post-purchase landing — that landing page
/// (and the rest of the FSME character system beyond the popup lines
/// used here and in the Rapid Fire decline path) is not yet ported to
/// Español.
///
/// Ported from SafePrep Manager, translated to Spanish.
class OnboardPaywall extends StatefulWidget {
  const OnboardPaywall({super.key});

  @override
  State<OnboardPaywall> createState() => _OnboardPaywallState();
}

class _OnboardPaywallState extends State<OnboardPaywall> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _darkBg = Color(0xFF0A0A0F);
  static const Color _softWhite = Color(0xFFF0EDE8);

  static const String _price = '\$4.99';

  bool _purchasing = false;

  /// FSME's one-line reaction, keyed to the self-reported knowledge
  /// level.
  String _fsmeLineFor(KnowledgeLevel? level) {
    switch (level) {
      case KnowledgeLevel.confident:
        return 'Dijiste que tienes confianza — bien. Esto te mantendrá '
            'al día, no te va a atrasar. Así está diseñado.';
      case KnowledgeLevel.prepared:
        return 'Estar preparado es un buen lugar. Esto ajusta lo que '
            'falte antes de que entres al examen.';
      case KnowledgeLevel.almostReady:
        return 'Casi listo — esto cierra los vacíos rápido, no '
            'empieza desde cero.';
      case KnowledgeLevel.newToServSafe:
        return '¿Empezando desde cero? Esto está diseñado para '
            'llevarte hasta el final, paso a paso.';
      case null:
        return 'Esto está diseñado para dejarte listo para el '
            'examen, sin importar desde dónde empieces.';
    }
  }

  @override
  void initState() {
    super.initState();
    MixpanelService.instance.track(
      'SpOn_Pay_Viewed',
      properties: {
        'app_name': 'ES',
        'knowledge_level':
            OnboardingAnswers.instance.knowledgeLevel?.tag ?? 'unknown',
      },
    );
    _recordOnboardingRun();
  }

  /// Reaching the paywall counts as one completed onboarding run — the
  /// splash uses the tally to cap free runs before requiring the access
  /// code. See kOnboardingRunsKey.
  Future<void> _recordOnboardingRun() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(kOnboardingRunsKey) ?? 0;
    await prefs.setInt(kOnboardingRunsKey, current + 1);
  }

  Future<void> _purchase() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

    MixpanelService.instance.track(
      'SpOn_Purchase',
      properties: {
        'app_name': 'ES',
        'source': 'paywall',
        'price': _price,
        'knowledge_level':
            OnboardingAnswers.instance.knowledgeLevel?.tag ?? 'unknown',
      },
    );

    final result = await IAPService.instance.buySevenDay();

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result == IAPResult.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (_) => false,
      );
    } else if (result != IAPResult.canceled) {
      final message = result.userMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showMeMore() {
    MixpanelService.instance.track(
      'SpOn_Pay_ShowMeMore',
      properties: {'app_name': 'ES'},
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RapidFireLimitedIntro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = OnboardingAnswers.instance.knowledgeLevel;

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TU PLAN ESTÁ LISTO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w500,
                  color: _gold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Un plan.\nTodo incluido.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  color: _softWhite,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Creado con base en lo que nos dijiste.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _gold.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Cuestionarios ilimitados, más de 500 preguntas,\n'
                'un examen completo de 90 preguntas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _softWhite.withValues(alpha: 0.45),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              FsmePopup(lines: [FsmeLine(_fsmeLineFor(level))]),

              const SizedBox(height: 20),

              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: _purchasing ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _darkBg,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonCornerRadius,
                      ),
                    ),
                  ),
                  child: _purchasing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _darkBg,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Desbloquea SafePrep — $_price',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Acceso completo por 7 días. Sin límites.',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: _darkBg.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _showMeMore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '¿Aún no estás listo para decidir? Prueba esto primero  →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
