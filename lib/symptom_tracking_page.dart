import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

// ── Pastel symptom palette ──────────────────────────────────────
// Background   : warm cream   #FDF8F4
// Cycle        : soft rose    #F9B8C0
// Energy       : lavender     #C9B8E8
// Mood         : sky blue     #A8D8EA
// Hormonal     : peach        #FFDAB9
// Metabolic    : mint         #A8E6CF
// Digestive    : butter       #FFF3B0
// Text dark    : #3C2F2F
// Text muted   : #9E8E8E
// ───────────────────────────────────────────────────────────────

class SymptomTrackingPage extends StatefulWidget {
  const SymptomTrackingPage({super.key});

  @override
  State<SymptomTrackingPage> createState() => _SymptomTrackingPageState();
}

class _SymptomTrackingPageState extends State<SymptomTrackingPage>
    with TickerProviderStateMixin {
  // ── Supabase ─────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;

  // ── Palette ──────────────────────────────────────────────────
  static const Color _bg = Color(0xFFFDF8F4);
  static const Color _textDark = Color(0xFF3C2F2F);
  static const Color _textMute = Color(0xFF9E8E8E);
  static const Color _rose = Color(0xFFF28B9F);
  static const Color _lavender = Color(0xFFB39DDB);
  static const Color _sky = Color(0xFF81C7E8);
  static const Color _peach = Color(0xFFF4A261);
  static const Color _mint = Color(0xFF80CBB0);
  static const Color _butter = Color(0xFFE8C94F);

  // ── SYMPTOM STATE ─────────────────────────────────────────────

  // 1 · Ovulation Indicators
  String _ovulationPain = 'None'; // None / Mild / Moderate / Severe
  String _cervicalDischarge = 'Dry'; // Dry / Sticky / Creamy / Egg-white

  // 2 · Pain Symptoms
  String _lowerAbdominalPain = 'None'; // None / Mild / Moderate / Severe
  String _lowerBackPain = 'None'; // None / Mild / Moderate / Severe

  // 3 · Mood & Energy
  String _mood = 'Stable'; // Very Low / Low / Stable / Good / Elevated
  String _energyLevel = 'Moderate'; // Very Low / Low / Moderate / High

  // 4 · Digestive Symptoms
  String _bloating = 'None'; // None / Mild / Moderate / Severe
  String _digestiveIssue = 'No issue'; // No issue / Constipation / Loose motion

  bool _isLoading = false;
  bool _isSaving = false;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  //  SAVE — Supabase upsert
  // ════════════════════════════════════════════════════════════

  Future<void> _saveLog() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final logData = {
        'user_id': user.id,
        'date': dateKey,

        // 1 · Ovulation Indicators
        'ovulation_pain': _ovulationPain,
        'cervical_discharge': _cervicalDischarge,

        // 2 · Pain Symptoms
        'lower_abdominal_pain': _lowerAbdominalPain,
        'lower_back_pain': _lowerBackPain,

        // 3 · Mood & Energy
        'mood': _mood,
        'energy_level': _energyLevel,

        // 4 · Digestive Symptoms
        'bloating': _bloating,
        'digestive_issue': _digestiveIssue,

        'created_at': now.toUtc().toIso8601String(),
      };

      await _supabase
          .from('daily_logs')
          .upsert(logData, onConflict: 'user_id,date');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.favorite, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Daily log saved! 🌸'),
            ]),
            backgroundColor: _rose,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
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
          'Daily Check-in',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Animated hero banner ──────────────────
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _buildHeroBanner(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1 · Ovulation Indicators
                  _buildSection(
                    color: _rose,
                    icon: Icons.water_drop_rounded,
                    emoji: '🌡️',
                    title: 'Ovulation Indicators',
                    subtitle: 'Track ovulation pain and cervical changes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeveritySelector(
                          label: 'Ovulation Pain',
                          options: const ['None', 'Mild', 'Moderate', 'Severe'],
                          selected: _ovulationPain,
                          color: _rose,
                          onChanged: (val) =>
                              setState(() => _ovulationPain = val),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionSelector(
                          label: 'Cervical Discharge Type',
                          options: const [
                            'Dry',
                            'Sticky',
                            'Creamy',
                            'Egg-white'
                          ],
                          selected: _cervicalDischarge,
                          color: _rose,
                          onChanged: (val) =>
                              setState(() => _cervicalDischarge = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2 · Pain Symptoms
                  _buildSection(
                    color: _lavender,
                    icon: Icons.nights_stay_rounded,
                    emoji: '🩻',
                    title: 'Pain Symptoms',
                    subtitle: 'Lower abdominal and back discomfort',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeveritySelector(
                          label: 'Lower Abdominal Pain',
                          options: const ['None', 'Mild', 'Moderate', 'Severe'],
                          selected: _lowerAbdominalPain,
                          color: _lavender,
                          onChanged: (val) =>
                              setState(() => _lowerAbdominalPain = val),
                        ),
                        const SizedBox(height: 16),
                        _buildSeveritySelector(
                          label: 'Lower Back Pain',
                          options: const ['None', 'Mild', 'Moderate', 'Severe'],
                          selected: _lowerBackPain,
                          color: _lavender,
                          onChanged: (val) =>
                              setState(() => _lowerBackPain = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3 · Mood & Energy
                  _buildSection(
                    color: _sky,
                    icon: Icons.psychology_rounded,
                    emoji: '🧠',
                    title: 'Mood & Energy',
                    subtitle: 'Your emotional and energy state today',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOptionSelector(
                          label: 'Mood',
                          options: const [
                            'Very Low',
                            'Low',
                            'Stable',
                            'Good',
                            'Elevated'
                          ],
                          selected: _mood,
                          color: _sky,
                          onChanged: (val) => setState(() => _mood = val),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionSelector(
                          label: 'Energy Level',
                          options: const [
                            'Very Low',
                            'Low',
                            'Moderate',
                            'High'
                          ],
                          selected: _energyLevel,
                          color: _sky,
                          onChanged: (val) =>
                              setState(() => _energyLevel = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 · Digestive Symptoms
                  _buildSection(
                    color: _butter,
                    icon: Icons.self_improvement_rounded,
                    emoji: '🧘',
                    title: 'Digestive Symptoms',
                    subtitle: 'Bloating and digestive health',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeveritySelector(
                          label: 'Bloating',
                          options: const ['None', 'Mild', 'Moderate', 'Severe'],
                          selected: _bloating,
                          color: _butter,
                          onChanged: (val) => setState(() => _bloating = val),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionSelector(
                          label: 'Digestive Issue',
                          options: const [
                            'No issue',
                            'Constipation',
                            'Loose motion'
                          ],
                          selected: _digestiveIssue,
                          color: _butter,
                          onChanged: (val) =>
                              setState(() => _digestiveIssue = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Save button ───────────────────────────
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  WIDGETS
  // ════════════════════════════════════════════════════════════

  // ── Hero banner ───────────────────────────────────────────────
  Widget _buildHeroBanner() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = days[now.weekday - 1];
    final dateStr = '${now.day} ${months[now.month - 1]}, ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E8), Color(0xFFFFF0F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _rose.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good day! 🌸',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dayName, $dateStr',
                  style: const TextStyle(color: _textMute, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _rose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '📋 Tap to log your symptoms',
                    style: TextStyle(
                      color: _rose,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _rose.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌺', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ───────────────────────────────────────────────
  Widget _buildSection({
    required Color color,
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style:
                              const TextStyle(color: _textMute, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Severity selector (None / Mild / Moderate / Severe) ────────
  // Uses the existing chip-group visual style, single-select.
  Widget _buildSeveritySelector({
    required String label,
    required List<String> options,
    required String selected,
    required Color color,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(opt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : const Color(0xFFF8F4F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_circle_rounded, size: 14, color: color),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? color.withOpacity(0.85) : _textMute,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Option selector (generic descriptive options) ──────────────
  // Same visual as severity selector — reused for discharge, mood, etc.
  Widget _buildOptionSelector({
    required String label,
    required List<String> options,
    required String selected,
    required Color color,
    required ValueChanged<String> onChanged,
  }) {
    return _buildSeveritySelector(
      label: label,
      options: options,
      selected: selected,
      color: color,
      onChanged: onChanged,
    );
  }

  // ── Save button ────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveLog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF28B9F), Color(0xFFB39DDB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _rose.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Save Today's Log",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
