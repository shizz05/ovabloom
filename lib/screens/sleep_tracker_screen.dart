import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ════════════════════════════════════════════════════════════════════
//  SLEEP TRACKER SCREEN
//  Firestore path : users/{uid}/sleep_hours/{auto-id}
//  Fields saved   : hours (int), minutes (int),
//                   date (String "yyyy-MM-dd"), timestamp (Timestamp)
// ════════════════════════════════════════════════════════════════════

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with TickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF0F0FA);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFFA0B4F0);
  static const Color _accent = Color(0xFFA8E6CF);
  static const Color _textDark = Color(0xFF3D3A5C);
  static const Color _textMuted = Color(0xFF9591B0);
  static const Color _pieRest = Color(0xFFE4E2F5);

  // ── Form ─────────────────────────────────────────────────────────
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _minsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── State ────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _saved = false;
  double _weeklyAvg = 0;
  bool _loadingAvg = true;
  String? _errorMsg;

  // ── Animations ───────────────────────────────────────────────────
  late final AnimationController _donutAnim;
  late final AnimationController _successAnim;
  late final Animation<double> _successScale;

  // ── Firestore refs ───────────────────────────────────────────────
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _sleepCol => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('sleep_hours');

  // ── Lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _donutAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successAnim,
      curve: Curves.elasticOut,
    );

    _loadWeeklyAvg();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    _donutAnim.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  FIRESTORE: fetch last 7 days & compute average
  // ════════════════════════════════════════════════════════════════
  Future<void> _loadWeeklyAvg() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snap = await _sleepCol
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _loadingAvg = false);
        return;
      }

      double total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final h = (data['hours'] as num?)?.toDouble() ?? 0;
        final m = (data['minutes'] as num?)?.toDouble() ?? 0;
        total += h + m / 60;
      }

      if (mounted) {
        setState(() {
          _weeklyAvg = total / snap.docs.length;
          _loadingAvg = false;
        });
        _donutAnim.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAvg = false;
          _errorMsg = 'Could not load data. Check Firestore rules.';
        });
        debugPrint('Sleep fetch error: $e');
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  FIRESTORE: save new entry
  // ════════════════════════════════════════════════════════════════
  Future<void> _saveSleep() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();

    final h = int.tryParse(_hoursCtrl.text) ?? 0;
    final m = int.tryParse(_minsCtrl.text) ?? 0;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    setState(() {
      _isSaving = true;
      _saved = false;
      _errorMsg = null;
    });

    try {
      // ── Write to Firestore ──────────────────────────────────────
      await _sleepCol.add({
        'hours': h,
        'minutes': m,
        'date': dateStr, // "2026-02-24"
        'timestamp': FieldValue.serverTimestamp(), // for ordering / queries
      });

      // Refresh weekly average
      await _loadWeeklyAvg();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saved = true;
        });
        _successAnim.forward(from: 0);
        HapticFeedback.mediumImpact();
        _hoursCtrl.clear();
        _minsCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMsg = 'Save failed. Check Firestore rules.\n$e';
        });
        debugPrint('Sleep save error: $e');
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String get _avgLabel {
    if (_weeklyAvg == 0) return '--h --m';
    final h = _weeklyAvg.floor();
    final m = ((_weeklyAvg - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  double get _donutFraction => (_weeklyAvg / 8.0).clamp(0.0, 1.0);

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _buildDonut(),
                    const SizedBox(height: 36),
                    _buildLogCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textDark, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Sleep Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textDark, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Donut chart ───────────────────────────────────────────────────
  Widget _buildDonut() {
    return AnimatedBuilder(
      animation: _donutAnim,
      builder: (_, __) {
        final progress = Curves.easeOutCubic.transform(_donutAnim.value);
        final filled = (_donutFraction * progress * 100).clamp(0.001, 99.999);
        final rest = (100 - filled).clamp(0.001, 99.999);

        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: _card,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.28),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                        color: _primary, value: filled, title: '', radius: 30),
                    PieChartSectionData(
                        color: _pieRest, value: rest, title: '', radius: 30),
                  ],
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 74,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Average Weekly',
                      style: TextStyle(color: _textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  _loadingAvg
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _primary),
                        )
                      : Text(
                          _avgLabel,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Log card ──────────────────────────────────────────────────────
  Widget _buildLogCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.nights_stay_rounded,
                        color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Log Hours',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  'How much did you sleep last night?',
                  style: TextStyle(color: _textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      controller: _hoursCtrl,
                      label: 'Hours',
                      hint: '0–12',
                      suffix: 'h',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 12) return 'Enter 0–12';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _InputField(
                      controller: _minsCtrl,
                      label: 'Minutes',
                      hint: '0–59',
                      suffix: 'm',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 59) return 'Enter 0–59';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSleep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? _accent : _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : _saved
                          ? ScaleTransition(
                              scale: _successScale,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text('Saved!',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: 20),
                                SizedBox(width: 8),
                                Text('Save Sleep',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ],
                            ),
                ),
              ),

              // ── Success banner ──────────────────────────────────
              if (_saved) ...[
                const SizedBox(height: 14),
                ScaleTransition(
                  scale: _successScale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF4CAF50), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Sleep logged & saved to Firestore!',
                          style: TextStyle(
                            color: _textDark.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Error banner ────────────────────────────────────
              if (_errorMsg != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A80).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFE53935), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(
                              color: Color(0xFFE53935), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  INPUT FIELD WIDGET
// ════════════════════════════════════════════════════════════════════
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    this.validator,
  });

  static const Color _primary = Color(0xFFA0B4F0);
  static const Color _textDark = Color(0xFF3D3A5C);
  static const Color _textMuted = Color(0xFF9591B0);
  static const Color _bg = Color(0xFFF0F0FA);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: validator,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textMuted.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
