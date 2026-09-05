import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _HealthRecommendation {
  final String category;
  final String emoji;
  final Color color;
  final String headline;
  final String detail;
  final String tip;

  const _HealthRecommendation({
    required this.category,
    required this.emoji,
    required this.color,
    required this.headline,
    required this.detail,
    required this.tip,
  });
}

class _HealthEngine {
  static double recommendedWater(double weightKg) =>
      (weightKg * 0.035).clamp(1.5, 4.0);

  static _HealthRecommendation? waterCheck(
      double intake, double weightKg, Color color) {
    final rec = recommendedWater(weightKg);
    if (intake >= rec) return null;
    final deficit = rec - intake;
    return _HealthRecommendation(
      category: 'Water Intake',
      emoji: '💧',
      color: color,
      headline: 'You need more water!',
      detail:
          'For your body weight of ${weightKg.round()} kg, you should drink '
          '${rec.toStringAsFixed(1)} L per day.\n\n'
          'Your current target of ${intake.toStringAsFixed(1)} L is '
          '${deficit.toStringAsFixed(1)} L below the recommendation.',
      tip: 'Try keeping a water bottle nearby. Set a reminder every 2 hours '
          'to take a few sips — small habits add up fast! 🚰',
    );
  }

  static _HealthRecommendation? sleepCheck(double hours, Color color) {
    if (hours >= 7) return null;
    final deficit = 7 - hours;
    return _HealthRecommendation(
      category: 'Sleep Duration',
      emoji: '🌙',
      color: color,
      headline: 'You\'re not sleeping enough!',
      detail: 'Adults need 7–9 hours of sleep per night for optimal health.\n\n'
          'Your target of ${hours.toStringAsFixed(1)} hrs is '
          '${deficit.toStringAsFixed(1)} hrs below the minimum recommendation.',
      tip: 'Try going to bed 30 minutes earlier each night this week. '
          'Avoid screens 1 hour before sleep and keep your room cool & dark. 😴',
    );
  }

  static double minCalories(double weightKg, double heightCm) {
    final bmr = 10 * weightKg + 6.25 * heightCm - 5 * 25 - 161;
    return (bmr * 1.2).clamp(1200, 3000);
  }

  static _HealthRecommendation? calorieCheck(
      double intake, double weightKg, double heightCm, Color color) {
    final min = minCalories(weightKg, heightCm);
    if (intake >= min) return null;
    return _HealthRecommendation(
      category: 'Daily Calories',
      emoji: '🔥',
      color: color,
      headline: 'Calorie intake is too low!',
      detail: 'Based on your height (${heightCm.round()} cm) and weight '
          '(${weightKg.round()} kg), your estimated minimum daily need is '
          '${min.round()} kcal.\n\n'
          'Your current target of ${intake.round()} kcal may leave your body '
          'under-fuelled.',
      tip: 'Add nutrient-dense snacks like nuts, yoghurt, or avocado to '
          'reach your daily target without feeling overly full. 🥑',
    );
  }

  static _HealthRecommendation? stepsCheck(double steps, Color color) {
    if (steps >= 8000) return null;
    final deficit = (8000 - steps).round();
    return _HealthRecommendation(
      category: 'Daily Steps',
      emoji: '👟',
      color: color,
      headline: 'Step target is below recommended!',
      detail:
          'The WHO recommends at least 8 000 steps per day for general health.\n\n'
          'Your current target of ${steps.round()} steps is '
          '$deficit steps below the minimum.',
      tip: 'Try short 10-minute walks after each meal. Parking further away '
          'or taking stairs can add 1 000–2 000 extra steps effortlessly! 🚶‍♀️',
    );
  }

  static _HealthRecommendation? weightCheck(
      double targetKg, double heightCm, Color color) {
    final heightM = heightCm / 100;
    final bmi = targetKg / (heightM * heightM);
    if (bmi >= 18.5) return null;
    final minHealthyKg = 18.5 * heightM * heightM;
    return _HealthRecommendation(
      category: 'Target Weight',
      emoji: '⚖️',
      color: color,
      headline: 'Target weight may be too low!',
      detail:
          'For your height of ${heightCm.round()} cm, a healthy weight range '
          'starts at ${minHealthyKg.toStringAsFixed(1)} kg (BMI 18.5).\n\n'
          'Your target of ${targetKg.round()} kg gives a BMI of '
          '${bmi.toStringAsFixed(1)}, which is below the healthy range.',
      tip: 'Consult a healthcare professional before setting a weight goal '
          'below the healthy BMI range. Your wellbeing always comes first! 💕',
    );
  }

  static List<_HealthRecommendation> analyse({
    required double sleep,
    required double water,
    required double steps,
    required double targetWeight,
    required double height,
    required double calories,
  }) {
    const sleepColor = Color(0xFFB39DDB);
    const waterColor = Color(0xFF81C7E8);
    const stepsColor = Color(0xFF80CBB0);
    const weightColor = Color(0xFFF4A261);
    const calColor = Color(0xFFE07B55);

    return [
      sleepCheck(sleep, sleepColor),
      waterCheck(water, targetWeight, waterColor),
      stepsCheck(steps, stepsColor),
      weightCheck(targetWeight, height, weightColor),
      calorieCheck(calories, targetWeight, height, calColor),
    ].whereType<_HealthRecommendation>().toList();
  }
}

// ════════════════════════════════════════════════════════════════
//  RECOMMENDATION BOTTOM SHEET — fully responsive & scrollable
// ════════════════════════════════════════════════════════════════

class _RecommendationsSheet extends StatefulWidget {
  final List<_HealthRecommendation> recommendations;
  const _RecommendationsSheet({required this.recommendations});

  @override
  State<_RecommendationsSheet> createState() => _RecommendationsSheetState();
}

class _RecommendationsSheetState extends State<_RecommendationsSheet> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendations[_page];
    final total = widget.recommendations.length;

    // ── Use 90% of screen height so nothing is cut off ──────────
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Progress dots ──────────────────────────────────────
          if (total > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? rec.color : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // ── Scrollable content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Icon circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: rec.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          Text(rec.emoji, style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Headline
                  Text(
                    rec.headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: rec.color,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Category label
                  Text(
                    rec.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E8E8E),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: rec.color.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: rec.color.withOpacity(0.2)),
                    ),
                    child: Text(
                      rec.detail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3C2F2F),
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tip box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFB39DDB).withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rec.tip,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5C4A8A),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Navigation buttons ─────────────────────────
                  Row(
                    children: [
                      if (_page > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _page--),
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: rec.color.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '← Back',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_page < total - 1) {
                              setState(() => _page++);
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rec.color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _page < total - 1 ? 'Next →' : 'Got it! 👍',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  LIFESTYLE SETTINGS PAGE
// ════════════════════════════════════════════════════════════════

class LifestyleSettingsPage extends StatefulWidget {
  const LifestyleSettingsPage({super.key});

  @override
  State<LifestyleSettingsPage> createState() => _LifestyleSettingsPageState();
}

class _LifestyleSettingsPageState extends State<LifestyleSettingsPage> {
  double _sleepDuration = 8;
  double _waterIntake = 2.25;
  double _dailyStepTarget = 5000;
  double _targetWeight = 60;
  double _height = 152;
  double _dailyCalorieIntake = 2200;

  static const Color _bg = Color(0xFFFDF8F4);
  static const Color _textDark = Color(0xFF3C2F2F);
  static const Color _textMute = Color(0xFF9E8E8E);
  static const Color _sleep = Color(0xFFB39DDB);
  static const Color _water = Color(0xFF81C7E8);
  static const Color _steps = Color(0xFF80CBB0);
  static const Color _weight = Color(0xFFF4A261);
  static const Color _heightC = Color(0xFFF28B9F);
  static const Color _cals = Color(0xFFE07B55);

  void _showRecommendationsIfNeeded() {
    final recs = _HealthEngine.analyse(
      sleep: _sleepDuration,
      water: _waterIntake,
      steps: _dailyStepTarget,
      targetWeight: _targetWeight,
      height: _height,
      calories: _dailyCalorieIntake,
    );

    if (recs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Text('🌟', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'All your targets look great! Keep it up!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF80CBB0),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) Navigator.of(context).pop(true);
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ── Prevent sheet from being dismissed by tapping outside ──
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _RecommendationsSheet(recommendations: recs),
    ).then((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.05;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textDark),
        title: const Text(
          'Lifestyle Settings',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 130),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Adjust your daily wellness targets below.',
                  style: TextStyle(color: _textMute, fontSize: 14, height: 1.4),
                ),
              ),
              _buildInfoBanner(),
              const SizedBox(height: 20),
              _buildSliderCard(
                color: _sleep,
                icon: Icons.nights_stay_outlined,
                title: 'Sleep Duration',
                emoji: '🌙',
                value: _sleepDuration,
                min: 4,
                max: 12,
                divisions: 16,
                displayLabel: '${_sleepDuration.toStringAsFixed(1)} hrs',
                recommendation: '7–9 hrs recommended',
                isLow: _sleepDuration < 7,
                onChanged: (v) => setState(() => _sleepDuration = v),
              ),
              _buildSliderCard(
                color: _water,
                icon: Icons.water_drop_outlined,
                title: 'Water Intake',
                emoji: '💧',
                value: _waterIntake,
                min: 1,
                max: 5,
                divisions: 16,
                displayLabel: '${_waterIntake.toStringAsFixed(1)} L',
                recommendation:
                    '${_HealthEngine.recommendedWater(_targetWeight).toStringAsFixed(1)} L for your weight',
                isLow: _waterIntake <
                    _HealthEngine.recommendedWater(_targetWeight),
                onChanged: (v) => setState(() => _waterIntake = v),
              ),
              _buildSliderCard(
                color: _steps,
                icon: Icons.directions_walk_outlined,
                title: 'Daily Steps',
                emoji: '👟',
                value: _dailyStepTarget,
                min: 1000,
                max: 20000,
                divisions: 19,
                displayLabel: '${_dailyStepTarget.round()} steps',
                recommendation: '8 000+ steps recommended',
                isLow: _dailyStepTarget < 8000,
                onChanged: (v) => setState(() => _dailyStepTarget = v),
              ),
              _buildSliderCard(
                color: _weight,
                icon: Icons.monitor_weight_outlined,
                title: 'Target Weight',
                emoji: '⚖️',
                value: _targetWeight,
                min: 40,
                max: 150,
                divisions: 110,
                displayLabel: '${_targetWeight.round()} kg',
                recommendation:
                    'Healthy BMI: ${((_height / 100) * (_height / 100) * 18.5).toStringAsFixed(0)}–${((_height / 100) * (_height / 100) * 24.9).toStringAsFixed(0)} kg',
                isLow: (_targetWeight / ((_height / 100) * (_height / 100))) <
                    18.5,
                onChanged: (v) => setState(() => _targetWeight = v),
              ),
              _buildSliderCard(
                color: _heightC,
                icon: Icons.height_outlined,
                title: 'Height',
                emoji: '📏',
                value: _height,
                min: 120,
                max: 220,
                divisions: 100,
                displayLabel: '${_height.round()} cm',
                recommendation: 'Used to calculate your health targets',
                isLow: false,
                onChanged: (v) => setState(() => _height = v),
              ),
              _buildSliderCard(
                color: _cals,
                icon: Icons.local_fire_department_outlined,
                title: 'Daily Calories',
                emoji: '🔥',
                value: _dailyCalorieIntake,
                min: 1200,
                max: 4000,
                divisions: 28,
                displayLabel: '${_dailyCalorieIntake.round()} kcal',
                recommendation:
                    '${_HealthEngine.minCalories(_targetWeight, _height).round()} kcal minimum for you',
                isLow: _dailyCalorieIntake <
                    _HealthEngine.minCalories(_targetWeight, _height),
                onChanged: (v) => setState(() => _dailyCalorieIntake = v),
              ),
            ],
          ),

          // ── Floating save button ────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: GestureDetector(
                  onTap: _showRecommendationsIfNeeded,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB39DDB), Color(0xFF80CBB0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _sleep.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Save & Check My Health',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final recs = _HealthEngine.analyse(
      sleep: _sleepDuration,
      water: _waterIntake,
      steps: _dailyStepTarget,
      targetWeight: _targetWeight,
      height: _height,
      calories: _dailyCalorieIntake,
    );

    if (recs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF80CBB0).withOpacity(0.4)),
        ),
        child: const Row(
          children: [
            Text('🌟', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All targets are within healthy ranges!',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4A261).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${recs.length} target${recs.length > 1 ? 's are' : ' is'} below healthy recommendations. '
              'We\'ll show you personalised tips after saving.',
              style: const TextStyle(
                color: Color(0xFF7B4700),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required Color color,
    required IconData icon,
    required String title,
    required String emoji,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayLabel,
    required String recommendation,
    required bool isLow,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isLow
            ? Border.all(color: color.withOpacity(0.45), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isLow)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text('⚠️', style: TextStyle(fontSize: 10)),
                            ),
                          Flexible(
                            child: Text(
                              recommendation,
                              style: TextStyle(
                                fontSize: 11,
                                color: isLow ? color : _textMute,
                                fontWeight:
                                    isLow ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLow
                        ? color.withOpacity(0.18)
                        : color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.18),
                trackShape: const RoundedRectSliderTrackShape(),
                trackHeight: 5.0,
                thumbColor: color,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayColor: color.withOpacity(0.18),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                activeTickMarkColor: Colors.transparent,
                inactiveTickMarkColor: Colors.transparent,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  onChanged(val);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMinMax(min, title),
                    style: TextStyle(color: _textMute, fontSize: 11),
                  ),
                  Text(
                    _formatMinMax(max, title),
                    style: TextStyle(color: _textMute, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinMax(double val, String title) {
    if (title == 'Water Intake') return '${val.toStringAsFixed(0)} L';
    if (title == 'Daily Steps') return '${val.round()}';
    if (title == 'Daily Calories') return '${val.round()} kcal';
    if (title == 'Sleep Duration') return '${val.toStringAsFixed(0)} hrs';
    return '${val.round()}';
  }
}
