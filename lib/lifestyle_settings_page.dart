import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

// ── Pastel lifestyle palette ────────────────────────────────────
// Background  : warm cream  #FDF8F4
// Card        : white with soft shadow
// Sleep       : pastel lavender  #C9B8E8
// Water       : pastel sky       #A8D8EA
// Steps       : pastel mint      #A8E6CF
// Weight      : pastel peach     #FFDAB9
// Height      : pastel rose      #F9B8C0
// Calories    : pastel coral     #F4A78A
// Text dark   : #3C2F2F
// Text muted  : #9E8E8E
// ───────────────────────────────────────────────────────────────

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
  bool _isLoading = true;
  bool _isSaving = false;

  // Palette
  static const Color _bg = Color(0xFFFDF8F4);
  static const Color _textDark = Color(0xFF3C2F2F);
  static const Color _textMute = Color(0xFF9E8E8E);

  static const Color _sleep = Color(0xFFB39DDB); // lavender
  static const Color _water = Color(0xFF81C7E8); // sky blue
  static const Color _steps = Color(0xFF80CBB0); // mint
  static const Color _weight = Color(0xFFF4A261); // peach/warm orange
  static const Color _heightC = Color(0xFFF28B9F); // rose
  static const Color _cals = Color(0xFFE07B55); // coral

  @override
  void initState() {
    super.initState();
    _loadLifestyleData();
  }

  Future<void> _loadLifestyleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        setState(() {
          _sleepDuration = (d['sleepDuration'] ?? 8.0).toDouble();
          _waterIntake = (d['waterIntake'] ?? 2.25).toDouble();
          _dailyStepTarget = (d['dailyStepTarget'] ?? 5000.0).toDouble();
          _targetWeight = (d['targetWeight'] ?? 60.0).toDouble();
          _height = (d['height'] ?? 152.0).toDouble();
          _dailyCalorieIntake = (d['dailyCalorieIntake'] ?? 2200.0).toDouble();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLifestyleSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sleepDuration': _sleepDuration,
        'waterIntake': _waterIntake,
        'dailyStepTarget': _dailyStepTarget,
        'targetWeight': _targetWeight,
        'height': _height,
        'dailyCalorieIntake': _dailyCalorieIntake,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Settings saved successfully!'),
            ]),
            backgroundColor: _steps,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: _heightC,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _sleep))
          : Stack(
              children: [
                // ── Scrollable sliders ──────────────────────
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                  children: [
                    // Header hint
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Adjust your daily wellness targets below.',
                        style: TextStyle(
                          color: _textMute,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),

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
                      onChanged: (v) => setState(() => _dailyCalorieIntake = v),
                    ),
                  ],
                ),

                // ── Floating save button ────────────────────
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: GestureDetector(
                        onTap: _isSaving ? null : _saveLifestyleSettings,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Save Changes',
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
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            // ── Header row ──────────────────────────────
            Row(
              children: [
                // Icon bubble
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Value badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
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

            // ── Slider ──────────────────────────────────
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

            // ── Min / max labels ─────────────────────────
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
