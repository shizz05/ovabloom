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

  // ── Symptom state ─────────────────────────────────────────────
  final Map<String, bool> _cycleSymptoms = {
    'Bleeding': false,
    'Spotting': false,
    'Cramps': false,
    'Pelvic Discomfort': false,
  };
  final Map<String, bool> _energySymptoms = {
    'Fatigue': false,
    'Low Energy': false,
    'Poor Sleep': false,
    'Daytime Sleepiness': false,
  };
  double _energyLevel = 3.0;

  final Map<String, bool> _moodSymptoms = {
    'Mood Swings': false,
    'Anxiety': false,
    'Irritability': false,
    'Low Mood': false,
    'Brain Fog': false,
  };
  String _moodRating = 'Neutral';

  final Map<String, bool> _hormonalSymptoms = {
    'Acne Flare-up': false,
    'Oily Skin': false,
    'Hair Fall': false,
    'Excess Sweating': false,
  };
  final Map<String, bool> _metabolicSymptoms = {
    'Sugar Cravings': false,
    'Extreme Hunger': false,
    'Bloating': false,
    'Energy Crash': false,
  };
  String _cravingIntensity = 'None';

  final Map<String, bool> _digestiveSymptoms = {
    'Constipation': false,
    'Indigestion': false,
    'Headache': false,
    'Breast Tenderness': false,
  };

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
  //
  //  Table   : daily_logs
  //  Columns : id, user_id (uuid), date (text "yyyy-MM-dd"),
  //            cycle_pain (jsonb), energy_sleep (jsonb),
  //            energy_level (float4), mood_mental (jsonb),
  //            mood_rating (text), hormonal_skin (jsonb),
  //            metabolic_appetite (jsonb), craving_intensity (text),
  //            digestive_physical (jsonb),
  //            created_at (timestamptz)
  //
  //  Upsert on (user_id, date) — one log per user per day.
  //  Requires: UNIQUE constraint on (user_id, date).
  // ════════════════════════════════════════════════════════════

  Future<void> _saveLog() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      // "yyyy-MM-dd" key used as the upsert discriminator
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final logData = {
        'user_id': user.id,
        'date': dateKey, // replaces Firestore doc id + Timestamp
        'cycle_pain': _selectedKeys(_cycleSymptoms),
        'energy_sleep': _selectedKeys(_energySymptoms),
        'energy_level': _energyLevel,
        'mood_mental': _selectedKeys(_moodSymptoms),
        'mood_rating': _moodRating,
        'hormonal_skin': _selectedKeys(_hormonalSymptoms),
        'metabolic_appetite': _selectedKeys(_metabolicSymptoms),
        'craving_intensity': _cravingIntensity,
        'digestive_physical': _selectedKeys(_digestiveSymptoms),
        'created_at': now
            .toUtc()
            .toIso8601String(), // replaces FieldValue.serverTimestamp()
      };

      // Upsert: inserts today's log or updates it if it already exists.
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

  // ── Extracts selected chip keys into a plain List<String> ──────
  List<String> _selectedKeys(Map<String, bool> map) =>
      map.entries.where((e) => e.value).map((e) => e.key).toList();

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

                  // 1 · Cycle & Body Pain
                  _buildSection(
                    color: _rose,
                    icon: Icons.water_drop_rounded,
                    emoji: '🩸',
                    title: 'Cycle & Body Pain',
                    subtitle: 'Track your flow and physical discomfort',
                    child: _buildChipGroup(_cycleSymptoms, _rose),
                  ),
                  const SizedBox(height: 16),

                  // 2 · Energy & Sleep
                  _buildSection(
                    color: _lavender,
                    icon: Icons.nights_stay_rounded,
                    emoji: '💤',
                    title: 'Energy & Sleep',
                    subtitle: 'How rested and energised do you feel?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChipGroup(_energySymptoms, _lavender),
                        const SizedBox(height: 16),
                        _buildEnergySlider(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3 · Mood & Mental State
                  _buildSection(
                    color: _sky,
                    icon: Icons.psychology_rounded,
                    emoji: '🧠',
                    title: 'Mood & Mental State',
                    subtitle: 'Your emotional and cognitive wellbeing',
                    child: Column(
                      children: [
                        _buildChipGroup(_moodSymptoms, _sky),
                        const SizedBox(height: 16),
                        _buildMoodSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 · Hormonal & Skin
                  _buildSection(
                    color: _peach,
                    icon: Icons.auto_awesome_rounded,
                    emoji: '✨',
                    title: 'Hormonal & Skin',
                    subtitle: 'Skin, hair and hormonal changes',
                    child: _buildChipGroup(_hormonalSymptoms, _peach),
                  ),
                  const SizedBox(height: 16),

                  // 5 · Metabolic & Appetite
                  _buildSection(
                    color: _mint,
                    icon: Icons.restaurant_rounded,
                    emoji: '🍽️',
                    title: 'Metabolic & Appetite',
                    subtitle: 'Hunger, cravings and digestion',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChipGroup(_metabolicSymptoms, _mint),
                        const SizedBox(height: 16),
                        _buildCravingPicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6 · Digestive & Physical
                  _buildSection(
                    color: _butter,
                    icon: Icons.self_improvement_rounded,
                    emoji: '🧘',
                    title: 'Digestive & Physical',
                    subtitle: 'Body discomfort and digestive health',
                    child: _buildChipGroup(_digestiveSymptoms, _butter),
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
  //  WIDGETS  (all identical to original — zero UI changes)
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

  // ── Chip group ─────────────────────────────────────────────────
  Widget _buildChipGroup(Map<String, bool> symptoms, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.keys.map((key) {
        final isSelected = symptoms[key]!;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => symptoms[key] = !symptoms[key]!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? color.withOpacity(0.2) : const Color(0xFFF8F4F4),
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
                  key,
                  style: TextStyle(
                    color: isSelected ? color.withOpacity(0.85) : _textMute,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Energy slider ──────────────────────────────────────────────
  Widget _buildEnergySlider() {
    const labels = ['', '😴', '😪', '😐', '😊', '⚡'];
    final level = _energyLevel.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Energy Level',
                style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _lavender.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(labels[level], style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _lavender,
            inactiveTrackColor: _lavender.withOpacity(0.2),
            thumbColor: _lavender,
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayColor: _lavender.withOpacity(0.2),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: _energyLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _energyLevel = val);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Low', style: TextStyle(color: _textMute, fontSize: 11)),
              Text('High', style: TextStyle(color: _textMute, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mood selector ──────────────────────────────────────────────
  Widget _buildMoodSelector() {
    final moods = [
      {'label': 'Sad', 'emoji': '😢', 'value': 'Sad'},
      {'label': 'Neutral', 'emoji': '😐', 'value': 'Neutral'},
      {'label': 'Happy', 'emoji': '😊', 'value': 'Happy'},
    ];
    return Row(
      children: moods.map((m) {
        final isSelected = _moodRating == m['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _moodRating = m['value']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: m['value'] != 'Happy' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _sky.withOpacity(0.22)
                    : const Color(0xFFF8F4F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _sky : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(m['emoji']!, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    m['label']!,
                    style: TextStyle(
                      color: isSelected ? _sky : _textMute,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Craving picker ─────────────────────────────────────────────
  Widget _buildCravingPicker() {
    final options = [
      {'label': 'None', 'emoji': '🙅', 'value': 'None'},
      {'label': 'Mild', 'emoji': '🤏', 'value': 'Mild'},
      {'label': 'Strong', 'emoji': '🔥', 'value': 'Strong'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Craving Intensity',
            style: TextStyle(
                color: _textDark, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: options.map((o) {
            final isSelected = _cravingIntensity == o['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cravingIntensity = o['value']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      EdgeInsets.only(right: o['value'] != 'Strong' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _mint.withOpacity(0.22)
                        : const Color(0xFFF8F4F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _mint : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(o['emoji']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        o['label']!,
                        style: TextStyle(
                          color: isSelected ? _mint : _textMute,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
