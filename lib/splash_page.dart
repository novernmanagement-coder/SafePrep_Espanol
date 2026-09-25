import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';
import 'mixpanel_service.dart';
import 'dashboard_page.dart';
import 'splash_navigating_page.dart';
import 'onboard/onboard_intro.dart';
import 'onboard/onboard_answers.dart';

// UPDATED — matches SafePrep Manager's self-report-funnel splash
// routing (ported/translated), PLUS a debug backdoor (long-press the
// splash logo, enter the access code) — same code as Manager's
// ('Novern2026!'), routing to SplashNavigatingPage (a destination
// menu — Dashboard/force-unlocked, Home Page, or the onboarding
// funnel) same as Manager, so testing isn't limited to just an
// instant Dashboard unlock. English-only by design, same as
// Manager's — this is a developer tool, not user-facing content.
// DEBUG ONLY — consider removing before a public release build, same
// as Manager's own note on this.
//
// Two paths:
//   purchased & active  → DashboardPage
//   everyone else       → OnboardIntro (the new self-report funnel),
//                          every launch, no trial, no run cap
//
// This REPLACES the old trial-based flow (30-minute TrialTimerService
// countdown gating DashboardPage access via PreviewCinematicSplash).
// The new self-report funnel has no trial concept at all — onboarding
// leads straight to the $4.99/7-day paywall. kOnboardingRunsKey is
// still incremented in OnboardPaywall.initState purely as an
// analytics signal now, not a routing gate.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _seenSplashPrefKey = 'has_seen_splash_before';

  // Access code — same one used across the other SafePrep apps.
  // Correct entry → SplashNavigatingPage (debug destination menu:
  // Dashboard force-unlocked, Home Page, or the onboarding funnel).
  // Wrong, blank, or dismissed entry just closes the dialog — normal
  // timed navigation continues underneath if it hasn't already fired.
  static const String _accessCode = 'Novern2026!';

  static const int _firstLaunchHoldSeconds = 8;
  static const int _returningHoldSeconds = 5;
  static const int _orientationSeconds = 2;

  Timer? _displayTicker;
  int _secondsElapsed = 0;
  int? _totalHoldSeconds;

  // Guards against the auto-navigate firing after a long-press has
  // already taken the user down the debug path.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initHoldDuration();
  }

  Future<void> _initHoldDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenBefore = prefs.getBool(_seenSplashPrefKey) ?? false;
    final holdSeconds = hasSeenBefore
        ? _returningHoldSeconds
        : _firstLaunchHoldSeconds;

    if (!hasSeenBefore) {
      await prefs.setBool(_seenSplashPrefKey, true);
    }

    if (!mounted) return;
    setState(() => _totalHoldSeconds = holdSeconds);
    _startDisplayTicker();
  }

  // Ticker is the SINGLE source of truth for both the visible countdown
  // and the auto-navigate trigger — canceling it (e.g. while the debug
  // access-code dialog is open) genuinely pauses the hold, not just the
  // on-screen number. Resuming just restarts this same timer; it picks
  // up from whatever _secondsElapsed already reached, it doesn't reset.
  void _startDisplayTicker() {
    _displayTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final total = _totalHoldSeconds;
      if (total != null && _secondsElapsed + 1 >= total) {
        _displayTicker?.cancel();
        setState(() => _secondsElapsed = total);
        _navigate();
        return;
      }
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _displayTicker?.cancel();
    super.dispose();
  }

  int get _countdownRemaining {
    final total = _totalHoldSeconds ?? _returningHoldSeconds;
    final remaining = total - _secondsElapsed;
    return remaining.clamp(0, total - _orientationSeconds);
  }

  Future<void> _navigate() async {
    final state = AppState();

    if (!mounted || _navigated) return;

    // Clear stale debug/legacy state — a forced-unlock with no real
    // purchaseDate should never be treated as a real purchase.
    if (state.hasUnlockedApp && state.purchaseDate == null) {
      state.hasUnlockedApp = false;
      state.purchaseType = PurchaseType.none;
      await AppStatePersistence.save();
    }
    if (!mounted || _navigated) return;

    // ── Path 1: purchased and active → Dashboard ─────────────────────
    // Checked FIRST so a paying customer never sees the funnel again.
    if (state.hasUnlockedApp && !state.isExpired) {
      // One-time legacy safety net: an existing install that had trial
      // progress under the old (pre-self-report) flow gets it cleared
      // exactly once on first post-purchase launch. New self-report
      // purchasers never accumulate trial progress in the first place,
      // so this is a no-op for them.
      if (!state.hasSeenIntro) {
        state.clearCurriculumProgress();
        state.hasSeenIntro = true;
        AppStatePersistence.save();
      }
      _navigated = true;
      MixpanelService.instance.track(
        'SpOn_Splash_Route',
        properties: {'app_name': 'ES', 'path': 'purchased'},
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
      return;
    }

    if (state.hasUnlockedApp && state.isExpired) {
      state.hasUnlockedApp = false;
      AppStatePersistence.save();
    }
    if (!mounted || _navigated) return;

    // ── Path 2: everyone else → funnel, every time ────────────────────
    _navigated = true;
    OnboardingAnswers.instance.reset();
    final prefs = await SharedPreferences.getInstance();
    final runs = prefs.getInt(kOnboardingRunsKey) ?? 0;
    MixpanelService.instance.track(
      'SpOn_Splash_Route',
      properties: {'app_name': 'ES', 'path': 'free_attempt', 'runs': runs},
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardIntro()),
    );
  }

  /// Long-press on the splash logo — access-code backdoor. Correct
  /// entry routes to [SplashNavigatingPage], a debug destination menu
  /// (Dashboard force-unlocked, Home Page, or the onboarding funnel)
  /// so testing isn't limited to a single hardcoded destination.
  ///
  /// Stops the hold timer the instant the dialog opens (see
  /// _startDisplayTicker — canceling it pauses both the visible
  /// countdown and the auto-navigate trigger together) so a slow typer
  /// never gets yanked into the funnel mid-entry. If the code turns out
  /// wrong/blank/dismissed, the timer resumes from wherever it left
  /// off rather than restarting from zero.
  Future<void> _debugEntry() async {
    if (_navigated) return;
    _displayTicker?.cancel();

    final entered = await _promptAccessCode();
    if (!mounted || _navigated) return;

    if (entered == _accessCode) {
      _navigated = true;

      MixpanelService.instance.track(
        'SpOn_Splash_Route',
        properties: {'app_name': 'ES', 'path': 'debug_nav_longpress'},
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashNavigatingPage()),
      );
      return;
    }

    // Wrong/blank/dismissed: resume the paused timer from where it
    // left off — normal routing proceeds once it reaches the hold
    // duration, same as if the dialog had never opened.
    if (!_navigated) _startDisplayTicker();
  }

  /// Shows a modal asking for the access code. Returns the entered
  /// string, or null if dismissed. English-only, matching Manager —
  /// this dialog is a developer tool, not user-facing content, so it
  /// isn't part of the app's Spanish localization.
  Future<String?> _promptAccessCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF13130F),
          title: const Text(
            'Access code',
            style: TextStyle(color: Color(0xFFF0EDE8), fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            style: const TextStyle(color: Color(0xFFF0EDE8)),
            decoration: const InputDecoration(
              hintText: 'Enter code',
              hintStyle: TextStyle(color: Color(0x66F0EDE8)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x33D4AF37)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text(
                'Continue',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showCountdown =
        _totalHoldSeconds != null && _secondsElapsed >= _orientationSeconds;

    return Scaffold(
      backgroundColor: AppColors.servSafeBlue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: _debugEntry,
                child: Image.asset('Assets/splash.png', width: 80, height: 80),
              ),
              const SizedBox(height: 24),

              const Text(
                '100% Garantizado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aprueba el examen ServSafe® o te devolvemos tu dinero.\nTe tendremos listo en menos de 4 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.strongText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Dinos en qué nivel estás — construiremos tu plan '
                'a partir de eso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              AnimatedOpacity(
                opacity: showCountdown ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  showCountdown
                      ? 'Preparando tu experiencia $_countdownRemaining…'
                      : ' ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB8860B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.3,
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
