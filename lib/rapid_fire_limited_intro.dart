import 'package:flutter/material.dart';
import 'constants.dart';
import 'mixpanel_service.dart';
import 'fsme_popup.dart';
import 'rapid_fire_limited_page.dart';

/// Intro screen for the limited Fuego Rápido — positioned between the
/// paywall decline and the actual tool. Its job is to make a free
/// offering feel like a gift rather than a consolation prize.
///
/// The copy frames the tool as special (category-specific, not random)
/// and useful (60 seconds, focused) — but honest about the limit: 2
/// free rounds, not unlimited access. The category selection reinforces
/// the "not just random questions" promise — they pick what to study,
/// which is the personalization hook in miniature.
///
/// Ported from SafePrep Manager, translated to Spanish. Manager's
/// version hand-rolls its own FSME eye/typing widget with a longer,
/// lore-heavy script (the Boss, Byte-Me trophy, etc.) — that deeper
/// character system is still Manager-only (see the onboarding paywall
/// port's own note on this same scope call). Here FSME's "psst" aside
/// uses the shared [FsmePopup] widget already ported to Español, with
/// a shorter one-line touch instead of the full multi-beat script.
class RapidFireLimitedIntro extends StatelessWidget {
  const RapidFireLimitedIntro({super.key});

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _darkBg = Color(0xFF0A0A0F);
  static const Color _softWhite = Color(0xFFF0EDE8);
  static const Color _cardBg = Color(0xFF13130F);

  /// Top 3 categories by real exam weight (matches the Trust page's
  /// weighted breakdown). No diagnostic exists to personalize this,
  /// and this screen is a one-time taste, not somewhere users return
  /// to repeatedly — a fixed, meaningfully-chosen set is fine.
  static const List<String> _weakCategories = [
    'Time & Temperature',
    'Receiving & Storage',
    'Cross-Contamination',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // Icon
              Icon(Icons.bolt_rounded, size: 40, color: _gold),

              const SizedBox(height: 14),

              // Eyebrow
              Text(
                'FUEGO RÁPIDO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                  color: _gold,
                ),
              ),

              const SizedBox(height: 14),

              // Headline
              Text(
                '2 rondas gratis de nuestra herramienta\nde retención más '
                'poderosa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _softWhite,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 16),

              // Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Esta es una versión limitada de Fuego Rápido — diseñada '
                  'para mantener el material fresco en tu mente en 60 '
                  'segundos o menos. Tienes 2 rondas — úsalas cuando '
                  'estés listo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _softWhite.withValues(alpha: 0.55),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Feature callout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tune_rounded, size: 20, color: _gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No son solo preguntas al azar. Tú eliges la '
                        'categoría que quieres repasar — cada sesión está '
                        'enfocada en lo que necesitas.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _softWhite.withValues(alpha: 0.6),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Pre-selected categories
              Text(
                'Seleccionamos 3 de las categorías con mayor peso en el '
                'examen:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _softWhite.withValues(alpha: 0.4),
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _weakCategories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _gold,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Start button — sits directly below the category chips.
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    MixpanelService.instance.track(
                      'SpOn_RefLtd_IntroStart',
                      properties: {'app_name': 'ES'},
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RapidFireLimitedPage(),
                      ),
                    );
                  },
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
                  child: const Text(
                    'Comenzar Fuego Rápido  →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FSME's "psst" aside — appears below the Start button.
              FsmePopup(
                lines: const [
                  FsmeLine(
                    'Psst... hice 6 de estos entrenadores de 60 segundos '
                    '— este es mi favorito.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
