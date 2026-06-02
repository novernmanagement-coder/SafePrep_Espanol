import 'app_state.dart';

class ReadinessEngine {
  static const Map<String, double> _examWeights = {
    'Time & Temperature': 0.23,
    'Cross-Contamination': 0.15,
    'Receiving & Storage': 0.15,
    'Personal Hygiene': 0.14,
    'Cleaning & Sanitizing': 0.12,
    'Food Preparation': 0.12,
    'Food Safety Management': 0.05,
    'Facility & Equipment': 0.02,
  };

  static const double _ecFlashCards = 1.0;
  static const double _ecRapidFire = 1.0;
  static const double _ecScenario = 1.0;
  static const double _ec60Second = 1.0;
  static const double _ecMnemonics = 1.0;
  static const double _ecCurriculum = 1.0;
  static const double _ecMaxTotal = 10.0;

  static double _categoryPoints(String category, int score) {
    final weight = _examWeights[category] ?? 0.02;
    final maxPts = weight * 100.0;
    if (score >= 85) return maxPts;
    if (score >= 75) return maxPts * 0.6;
    if (score >= 51) return maxPts * 0.3;
    return 0.0;
  }

  static int calculate(AppState state) {
    double score = 0.0;

    for (final category in AppState.allCategories) {
      if (state.hasScoreForCategory(category)) {
        final catScore = state.getCategoryScore(category);
        score += _categoryPoints(category, catScore);
      }
    }

    final ec = state.extraCreditPoints.clamp(0.0, _ecMaxTotal);

    double finalScore;
    if (state.extraCreditPoints == 0.0) {
      // Solo evaluación — límite de 88
      finalScore = (score + ec).clamp(0.0, 88.0);
    } else if (score < 85.0) {
      finalScore = (score + ec).clamp(0.0, 80.0);
    } else {
      finalScore = (score + ec).clamp(0.0, 100.0);
    }

    if (state.finalExamScore != null) {
      final examScore = state.finalExamScore!;
      if (examScore >= 85) {
        finalScore = 100.0;
      } else {
        finalScore = finalScore < examScore.toDouble()
            ? finalScore
            : examScore.toDouble();
      }
    }

    // Todos los que han tomado la evaluación obtienen al menos 5%
    final raw = finalScore.round().clamp(0, 100);
    if (state.hasTakenAssessment && raw < 5) return 5;
    return raw;
  }

  static double improvementDelta(
    String category,
    int previousScore,
    int newScore,
  ) {
    final previousPts = _categoryPoints(category, previousScore);
    final newPts = _categoryPoints(category, newScore);
    return newPts - previousPts;
  }

  static double extraCreditForAction(ExtraCreditAction action) {
    switch (action) {
      case ExtraCreditAction.flashCards:
        return _ecFlashCards;
      case ExtraCreditAction.rapidFire:
        return _ecRapidFire;
      case ExtraCreditAction.scenarioDrills:
        return _ecScenario;
      case ExtraCreditAction.sixtySecond:
        return _ec60Second;
      case ExtraCreditAction.mnemonics:
        return _ecMnemonics;
      case ExtraCreditAction.curriculum:
        return _ecCurriculum;
    }
  }

  static String coachMessage(AppState state, int readinessScore) {
    if (state.finalExamScore != null && state.finalExamScore! < 85) {
      final focus = _focusCategory(state);
      if (focus != null) {
        return '$focus es tu mayor oportunidad — enfócate ahí antes de volver a intentarlo.';
      }
      return 'Tu puntaje del examen es tu punto de referencia — estudia tus categorías prioritarias para recuperarte.';
    }

    if (!state.hasTakenAssessment) {
      return 'Toma la evaluación diagnóstica para comenzar a construir tu puntuación de preparación.';
    }

    final masteredWithoutCurriculum = state.masteredCategories
        .where((c) => !state.hasStudiedCategory(c))
        .toList();
    if (masteredWithoutCurriculum.isNotEmpty) {
      final cat = masteredWithoutCurriculum.first;
      return 'Has dominado $cat — ve al Panel y selecciona Estudiar para repasar el currículo.';
    }

    final unmastered =
        AppState.allCategories
            .where(
              (c) =>
                  state.hasScoreForCategory(c) &&
                  state.getCategoryScore(c) < AppState.masteryThreshold,
            )
            .toList()
          ..sort(
            (a, b) =>
                state.getCategoryScore(a).compareTo(state.getCategoryScore(b)),
          );

    if (unmastered.isNotEmpty) {
      final cat = unmastered.first;
      final weight = (_examWeights[cat] ?? 0.02) * 100;
      final score = state.getCategoryScore(cat);
      return '$cat necesita trabajo — estás en $score% y representa el ${weight.round()}% del examen.';
    }

    final unstudied = AppState.allCategories
        .where((c) => !state.hasScoreForCategory(c))
        .toList();
    if (unstudied.isNotEmpty) {
      return 'Aún no has estudiado ${unstudied.first} — empieza por ahí.';
    }

    if (readinessScore >= 100) {
      return 'Buena suerte en tu examen final — definitivamente hiciste el trabajo. Estás listo.';
    }

    if (state.finalExamScore == null && readinessScore >= 85) {
      return 'Estás listo — toma el Examen Final de SafePrep para completar tu puntuación de preparación.';
    }

    if (readinessScore >= 80 && readinessScore < 100) {
      return 'Usa Tarjetas de Estudio y Fuego Rápido para llevar tu preparación al 100%.';
    }

    if (readinessScore < 50) {
      return 'Enfócate en los quizzes de categoría — son la forma más rápida de mover el marcador.';
    }

    return 'Sigue estudiando — cada quiz mueve tu puntuación de preparación.';
  }

  static String cheerleaderMessage(AppState state, int readinessScore) {
    if (readinessScore >= 100) {
      return 'Luz verde. Hiciste el trabajo. Ve a pasar ese examen.';
    }
    if (readinessScore >= 85) {
      return 'Estás en la zona — las personas que llegan a este punto aprueban. Sigue adelante.';
    }
    if (readinessScore >= 65) {
      return 'Estás construyendo algo real. Cada categoría dominada es un obstáculo menos entre tú y esa certificación.';
    }
    if (readinessScore >= 40) {
      return 'Ya superaste la línea de salida — el impulso lo es todo ahora. No te detengas.';
    }
    if (state.hasTakenAssessment) {
      return 'Apareciste y tomaste la evaluación. Así es como comienza toda historia de éxito.';
    }
    return 'SafePrep fue creado con un solo propósito — prepararte. Comencemos.';
  }

  static String? _focusCategory(AppState state) {
    final scored =
        AppState.allCategories
            .where((c) => state.hasScoreForCategory(c))
            .toList()
          ..sort(
            (a, b) =>
                state.getCategoryScore(a).compareTo(state.getCategoryScore(b)),
          );
    return scored.isEmpty ? null : scored.first;
  }
}

enum ExtraCreditAction {
  flashCards,
  rapidFire,
  scenarioDrills,
  sixtySecond,
  mnemonics,
  curriculum,
}
