import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'csv_loader.dart';
import 'mixpanel_service.dart';
import 'iap_service.dart';
import 'category_study_page.dart';
import 'fsme_popup.dart';

/// Limited Fuego Rápido — the $4.99 decline path's free taste.
///
/// This is a SELLING PAGE that happens to be a working tool. It runs a
/// capped version of Fuego Rápido (3 weakest categories × 5 questions
/// each = 15 total) with a persistent "limited version" banner and a
/// re-ask at every category's 5-question ceiling. Each re-ask names the
/// category, states how many more questions are available, and offers
/// the unlock — turning one paywall into several conversion moments
/// that fire while the user is engaged.
///
/// VISUAL FIDELITY: mirrors the real RapidFirePage — the speech-bubble
/// question card ([_BubblePainter]), category color map, slide in/out,
/// and the ✓/✗/— score boxes — so the taste looks like the actual tool.
/// The interaction stays instant-answer (both choices shown at once, tap
/// reveals green/red) rather than the full tool's timed reveal, because
/// this is a funnel stage and snappier converts better.
///
/// Separate file from rapid_fire_page.dart intentionally. The full
/// trainer is a tool; this is a funnel stage that uses the tool's
/// mechanics. Mixing the two would compromise both.
///
/// Ported from SafePrep Manager, translated to Spanish. Manager's
/// version hand-rolls its own FSME eye/typing widget with two longer,
/// lore-heavy scripts (a robot gag involving "the Boss" and a rival
/// named Goggles). That deeper character system is still Manager-only
/// (same scope call already made on the onboarding paywall port) — here
/// both FSME moments use the shared [FsmePopup] widget already ported
/// to Español, with a single short line each instead of the full
/// multi-beat scripts. The actual decline-path mechanics (capped quiz,
/// category re-ask upsell, completion upsell, purchase flow) are ported
/// in full.
///
/// Reuses Español's own established proctor-finder link
/// (servsafe.com/Instructors-Proctors, per about_proctors_page.dart)
/// rather than Manager's foodsafetymadeeasy.com one.
class RapidFireLimitedPage extends StatefulWidget {
  const RapidFireLimitedPage({super.key});

  @override
  State<RapidFireLimitedPage> createState() => _RapidFireLimitedPageState();
}

class _RapidFireLimitedPageState extends State<RapidFireLimitedPage>
    with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _darkBg = Color(0xFF0A0A0F);
  static const Color _softWhite = Color(0xFFF0EDE8);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _red = Color(0xFFC62828);

  static const int _questionsPerCategory = 5;
  static const int _slideInMs = 320;
  static const int _slideOutMs = 260;

  /// Category color map — matched to the real RapidFirePage so the
  /// speech bubble reads the same per category.
  static const Map<String, Color> _categoryColors = {
    'Time & Temperature': Color(0xFFC0392B),
    'Cross-Contamination': Color(0xFFE67E22),
    'Food Preparation': Color(0xFF27AE60),
    'Receiving & Storage': Color(0xFF2980B9),
    'Personal Hygiene': Color(0xFF8E44AD),
    'Cleaning & Sanitizing': Color(0xFF16A085),
    'Facility & Equipment': Color(0xFF34495E),
    'Food Safety Management': Color(0xFFB7950B),
  };

  /// Español's own established Find-a-Proctor link (see
  /// about_proctors_page.dart) — offered on the completion screen as a
  /// neutral next step for someone who finished the free taste and
  /// didn't buy. Framed as "when you're ready," not a claim that they
  /// ARE ready.
  static const String _proctorUrl =
      'https://www.servsafe.com/Instructors-Proctors';

  /// Full question bank counts per category — used in the re-ask copy
  /// to show how many more are available. Approximate is fine; these
  /// come from the bank distribution noted in the diagnostic spec.
  static const Map<String, int> _bankCounts = {
    'Time & Temperature': 70,
    'Cross-Contamination': 42,
    'Cleaning & Sanitizing': 38,
    'Personal Hygiene': 36,
    'Food Preparation': 34,
    'Receiving & Storage': 44,
    'Facility & Equipment': 22,
    'Food Safety Management': 20,
    'Food Safety Foundations': 12,
    'Pathogens': 12,
    'Pest Management': 6,
  };

  List<String> _categories = [];
  Map<String, List<QuestionModel>> _categoryDecks = {};
  Map<String, int> _categoryProgress = {};

  int _currentCatIndex = 0;
  bool _loaded = false;

  // Question state
  String _questionText = '';
  String _answerAText = '';
  String _answerBText = '';
  int _correctSlot = 0;
  bool _answered = false;

  // Answer button colors (real tool uses slate-blue idle, green/red/grey
  // on reveal).
  Color _colorA = const Color(0xFF4A6FA5);
  Color _colorB = const Color(0xFF4A6FA5);

  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  int _totalAnswered = 0;

  // Category limit reached
  bool _showingLimit = false;

  // All done
  bool _allDone = false;

  // Slide animation for the question bubble.
  AnimationController? _slideController;
  Animation<Offset> _slideOffset = const AlwaysStoppedAnimation(Offset.zero);

  // One-time FSME touch on the first category-limit screen only —
  // checked before scheduling, so picking "Continue to next category"
  // never re-triggers it on the 2nd or 3rd category's limit screen.
  bool _limitFsmeShown = false;

  // FSME's completion-screen line finishes revealing → reveal the
  // proctor-finder button, matching Manager's "appears once the
  // readout finishes" pacing.
  bool _completionFsmeDone = false;

  /// Top 3 categories by real exam weight (matches the Trust page's
  /// weighted breakdown) — fixed for everyone now that there's no
  /// diagnostic to personalize against.
  static const List<String> _topCategories = [
    'Time & Temperature',
    'Receiving & Storage',
    'Cross-Contamination',
  ];

  Color get _currentColor {
    final cat = _currentCatIndex < _categories.length
        ? _categories[_currentCatIndex]
        : '';
    return _categoryColors[cat] ?? _gold;
  }

  @override
  void initState() {
    super.initState();
    MixpanelService.instance.track(
      'SpOn_RefLtd_Viewed',
      properties: {'app_name': 'ES'},
    );
    _loadDecks();
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _launchProctor() async {
    MixpanelService.instance.track(
      'SpOn_RefLtd_ProctorFinder',
      properties: {'app_name': 'ES'},
    );
    final uri = Uri.parse(_proctorUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadDecks() async {
    // No diagnostic exists anymore to personalize this — top 3 by real
    // exam weight (matches the Trust page's breakdown), fixed for
    // everyone. This screen is a one-time taste, not somewhere users
    // return to repeatedly, so a fixed set is fine.
    final weakest = List<String>.from(_topCategories);

    final all = await QuestionLoader.loadAll(shuffle: false);
    final decks = <String, List<QuestionModel>>{};
    final progress = <String, int>{};

    for (final cat in weakest) {
      final questions =
          all
              .where((q) => q.category.toLowerCase() == cat.toLowerCase())
              .toList()
            ..shuffle();
      decks[cat] = questions.take(_questionsPerCategory).toList();
      progress[cat] = 0;
    }

    if (!mounted) return;
    setState(() {
      _categories = weakest;
      _categoryDecks = decks;
      _categoryProgress = progress;
      _loaded = true;
    });

    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    if (_currentCatIndex >= _categories.length) {
      setState(() => _allDone = true);
      return;
    }

    final cat = _categories[_currentCatIndex];
    final deck = _categoryDecks[cat] ?? [];
    final progress = _categoryProgress[cat] ?? 0;

    if (progress >= deck.length || progress >= _questionsPerCategory) {
      setState(() => _showingLimit = true);
      return;
    }

    final q = deck[progress];
    final answers = [q.answer1, q.answer2, q.answer3, q.answer4];
    final correctText = answers[q.correctAnswer];
    final wrongs = <String>[];
    for (int i = 0; i < answers.length; i++) {
      if (i != q.correctAnswer) wrongs.add(answers[i]);
    }
    wrongs.shuffle();

    final slot = Random().nextInt(2);

    setState(() {
      _questionText = q.questionText;
      _correctSlot = slot;
      _answerAText = slot == 0 ? correctText : wrongs[0];
      _answerBText = slot == 1 ? correctText : wrongs[0];
      _answered = false;
      _showingLimit = false;
      _colorA = const Color(0xFF4A6FA5);
      _colorB = const Color(0xFF4A6FA5);
    });

    await _slideIn();
  }

  Future<void> _slideIn() async {
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideInMs),
    );
    _slideOffset = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController!,
            curve: Curves.easeOutCubic,
          ),
        );
    if (mounted) setState(() {});
    await _slideController!.forward();
  }

  Future<void> _slideOut() async {
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideOutMs),
    );
    _slideOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, 0))
        .animate(
          CurvedAnimation(parent: _slideController!, curve: Curves.easeInCubic),
        );
    if (mounted) setState(() {});
    await _slideController!.forward();
  }

  void _onAnswer(bool tappedA) {
    if (_answered) return;

    final isCorrect =
        (tappedA && _correctSlot == 0) || (!tappedA && _correctSlot == 1);

    final cat = _categories[_currentCatIndex];

    setState(() {
      _answered = true;
      _totalAnswered++;
      if (isCorrect) {
        _totalCorrect++;
      } else {
        _totalIncorrect++;
      }
      _categoryProgress[cat] = (_categoryProgress[cat] ?? 0) + 1;

      // Reveal colors, matching the real tool: correct slot green, the
      // tapped-wrong slot red, the other loser greyed.
      if (isCorrect) {
        if (tappedA) {
          _colorA = _green;
          _colorB = const Color(0xFF888888);
        } else {
          _colorB = _green;
          _colorA = const Color(0xFF888888);
        }
      } else {
        if (tappedA) {
          _colorA = _red;
          _colorB = _green;
        } else {
          _colorB = _red;
          _colorA = _green;
        }
      }
    });

    MixpanelService.instance.track(
      'SpOn_RefLtd_Answered',
      properties: {
        'app_name': 'ES',
        'category': cat,
        'correct': isCorrect,
        'question_in_category': _categoryProgress[cat],
      },
    );

    // Auto-advance after a beat: slide the current card out, then load
    // the next.
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      await _slideOut();
      if (!mounted) return;
      _loadQuestion();
    });
  }

  void _continueToNextCategory() {
    MixpanelService.instance.track(
      'SpOn_RefLtd_CatLimit',
      properties: {'app_name': 'ES', 'category': _categories[_currentCatIndex]},
    );

    setState(() {
      _currentCatIndex++;
      _showingLimit = false;
    });
    _loadQuestion();
  }

  /// Shared $4.99 unlock. Triggers the real IAP; only a VERIFIED success
  /// opens the app (straight to the user's weakest category, matching the
  /// post-purchase route). Cancel or failure returns to the paywall.
  bool _purchasing = false;

  Future<void> _unlock(String source) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

    MixpanelService.instance.track(
      'SpOn_Purchase',
      properties: {
        'app_name': 'ES',
        'source': source,
        'price': '\$4.99',
      },
    );

    final result = await IAPService.instance.buySevenDay();
    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result == IAPResult.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryStudyPage(category: _topCategories.first),
        ),
        (_) => false,
      );
    } else {
      // Cancel or fail → back to the paywall to decide again.
      if (Navigator.canPop(context)) Navigator.pop(context);
      final message = result.userMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── Build methods ───────────────────────────────────────────────

  Widget _limitedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: _gold.withValues(alpha: 0.12),
      child: Text(
        'VERSIÓN LIMITADA  •  $_totalAnswered de '
        '${_categories.length * _questionsPerCategory} preguntas gratis',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: _gold,
        ),
      ),
    );
  }

  Widget _questionView() {
    final cat = _currentCatIndex < _categories.length
        ? _categories[_currentCatIndex]
        : '';
    final progress = _categoryProgress[cat] ?? 0;
    final color = _currentColor;

    return Column(
      children: [
        // Category accent strip, matching the real tool.
        Container(height: 3, color: color.withValues(alpha: 0.4)),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '$progress de $_questionsPerCategory',
                style: TextStyle(
                  fontSize: 12,
                  color: _softWhite.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Speech-bubble question card + answer buttons, sliding as a unit.
        SlideTransition(
          position: _slideOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _questionBubble(color),
              const SizedBox(height: 16),
              _answerButtons(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _scoreCounters(),
      ],
    );
  }

  Widget _questionBubble(Color color) {
    return CustomPaint(
      painter: _BubblePainter(color: color),
      child: SizedBox(
        width: 320,
        height: 150,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: Text(
              _questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _answerButtons() {
    return SizedBox(
      width: 320,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _answerButton(
                'A',
                _answerAText,
                _colorA,
                () => _onAnswer(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _answerButton(
                'B',
                _answerBText,
                _colorB,
                () => _onAnswer(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(
    String label,
    String text,
    Color bg,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: _answered ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 72),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _scoreCounters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: _scoreBox(
              '✓ Correctas',
              '$_totalCorrect',
              const Color(0xFFE8F5E9),
              const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _scoreBox(
              '✗ Incorrectas',
              '$_totalIncorrect',
              const Color(0xFFFFEBEE),
              const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _scoreBox(
              '— Total',
              '$_totalAnswered',
              const Color(0xFFF5F5F5),
              const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  /// The re-ask screen — fires when a category hits its 5-question limit.
  /// Names the category, states how many more are in the full version,
  /// and offers the unlock. This is the conversion moment.
  Widget _categoryLimitView() {
    final cat = _categories[_currentCatIndex];
    final bankTotal = _bankCounts[cat] ?? 30;
    final remaining = bankTotal - _questionsPerCategory;
    final hasMoreCategories = _currentCatIndex < _categories.length - 1;

    // Only ever shown once, on the first category-limit screen the
    // user sees — picking "Continue to next category" never re-shows it.
    final showLimitFsme = _currentCatIndex == 0;
    if (showLimitFsme && !_limitFsmeShown) {
      _limitFsmeShown = true;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 40, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),

          Icon(Icons.lock_outline, size: 32, color: _gold),

          const SizedBox(height: 14),

          Text(
            'Esas fueron tus $_questionsPerCategory preguntas gratis\nen '
            '$cat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _softWhite,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Hay $remaining más — y el examen ServSafe® insiste mucho en '
            'esta categoría.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _softWhite.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),

          if (showLimitFsme) ...[
            const SizedBox(height: 18),
            FsmePopup(
              lines: const [
                FsmeLine(
                  'Ya te dije que esto estaba genial — lo diseñé para '
                  'máxima retención.',
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Unlock button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _purchasing ? null : () => _unlock('cat_limit'),
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
                'Desbloquea SafePrep  —  \$4.99',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (hasMoreCategories)
            GestureDetector(
              onTap: _continueToNextCategory,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Continuar a la siguiente categoría  →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _gold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Final screen after all 15 questions — one more conversion moment.
  Widget _completionView() {
    final pct = _totalAnswered > 0
        ? ((_totalCorrect / _totalAnswered) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 40, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),

          Text(
            'VERSIÓN LIMITADA COMPLETA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: _gold,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            '$_totalCorrect de $_totalAnswered correctas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _softWhite,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$pct% en tus 3 categorías más débiles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _softWhite.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Eso fueron 15 preguntas de más de 500.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _softWhite.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _purchasing ? null : () => _unlock('completion'),
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
                'Desbloquea SafePrep  —  \$4.99',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // FSME's sign-off + free proctor-finder exit, gated on the
          // popup finishing its (short) line.
          FsmePopup(
            lines: const [
              FsmeLine(
                'Ya probaste la experiencia SafePrep. Encuentra un '
                'proctor cerca de ti y hazlo oficial — esto es gratis.',
              ),
            ],
            onComplete: () {
              if (mounted) setState(() => _completionFsmeDone = true);
            },
          ),

          if (_completionFsmeDone) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _launchProctor,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.buttonCornerRadius,
                    ),
                  ),
                ),
                child: const Text(
                  'Encuentra un proctor cerca de mí  →',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: _darkBg,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _limitedBanner(),
            Expanded(
              child: SingleChildScrollView(
                child: _allDone
                    ? _completionView()
                    : _showingLimit
                    ? _categoryLimitView()
                    : _questionView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Speech-bubble painter — copied from the real RapidFirePage so the
/// limited version's question card reads identically.
class _BubblePainter extends CustomPainter {
  final Color color;
  const _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(20, 0)
      ..quadraticBezierTo(0, 0, 0, 20)
      ..lineTo(0, 100)
      ..quadraticBezierTo(0, 120, 20, 120)
      ..lineTo(30, 120)
      ..lineTo(20, 145)
      ..lineTo(60, 120)
      ..lineTo(300, 120)
      ..quadraticBezierTo(320, 120, 320, 100)
      ..lineTo(320, 20)
      ..quadraticBezierTo(320, 0, 300, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
