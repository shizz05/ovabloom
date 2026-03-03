import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ════════════════════════════════════════════════════════════════════
//  SLEEP TRACKER SCREEN
//  Supabase table : sleep_logs
//  Columns        : id, user_id, hours (int), minutes (int),
//                   date (text "yyyy-MM-dd"), created_at (timestamptz)
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

  // ── Supabase ─────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  String get _uid => _supabase.auth.currentUser!.id;

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
  //  SUPABASE: fetch last 7 days & compute average
  // ════════════════════════════════════════════════════════════════
  Future<void> _loadWeeklyAvg() async {
    try {
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .toUtc()
          .toIso8601String();

      final rows = await _supabase
          .from('sleep_logs')
          .select('hours, minutes')
          .eq('user_id', _uid)
          .gte('created_at', sevenDaysAgo)
          .order('created_at', ascending: false);

      final list = rows as List;

      if (list.isEmpty) {
        if (mounted) setState(() => _loadingAvg = false);
        return;
      }

      double total = 0;
      for (final row in list) {
        final h = (row['hours'] as num?)?.toDouble() ?? 0;
        final m = (row['minutes'] as num?)?.toDouble() ?? 0;
        total += h + m / 60;
      }

      if (mounted) {
        setState(() {
          _weeklyAvg = total / list.length;
          _loadingAvg = false;
        });
        _donutAnim.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAvg = false;
          _errorMsg = 'Could not load data. Check Supabase RLS policies.';
        });
        debugPrint('Sleep fetch error: $e');
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  SUPABASE: save new entry
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
      await _supabase.from('sleep_logs').insert({
        'user_id': _uid,
        'hours': h,
        'minutes': m,
        'date': dateStr,
        'created_at': now.toUtc().toIso8601String(),
      });

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
          _errorMsg = 'Save failed. Check Supabase RLS policies.\n$e';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    // Responsive sizing
    final donutSize = isTablet
        ? 260.0
        : isSmall
            ? 170.0
            : (screenWidth * 0.52).clamp(170.0, 220.0);

    final horizontalPadding = isTablet
        ? screenWidth * 0.12
        : isSmall
            ? 16.0
            : 24.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isTablet: isTablet),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    SizedBox(height: isSmall ? 18 : 28),
                    _buildDonut(donutSize: donutSize, isSmall: isSmall),
                    SizedBox(height: isSmall ? 24 : 36),
                    _buildLogCard(isSmall: isSmall, isTablet: isTablet),
                    SizedBox(height: isSmall ? 20 : 32),
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
  Widget _buildHeader(BuildContext context, {required bool isTablet}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isTablet ? 16 : 8, 12, isTablet ? 16 : 8, 0),
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
  Widget _buildDonut({required double donutSize, required bool isSmall}) {
    final centerSpaceRadius = donutSize * 0.336;
    final sectionRadius = donutSize * 0.136;
    final avgFontSize = isSmall ? 22.0 : 28.0;
    final labelFontSize = isSmall ? 11.0 : 12.0;

    return AnimatedBuilder(
      animation: _donutAnim,
      builder: (_, __) {
        final progress = Curves.easeOutCubic.transform(_donutAnim.value);
        final filled = (_donutFraction * progress * 100).clamp(0.001, 99.999);
        final rest = (100 - filled).clamp(0.001, 99.999);

        return Container(
          width: donutSize,
          height: donutSize,
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
                        color: _primary,
                        value: filled,
                        title: '',
                        radius: sectionRadius),
                    PieChartSectionData(
                        color: _pieRest,
                        value: rest,
                        title: '',
                        radius: sectionRadius),
                  ],
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: centerSpaceRadius,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Average Weekly',
                    style:
                        TextStyle(color: _textMuted, fontSize: labelFontSize),
                  ),
                  const SizedBox(height: 6),
                  _loadingAvg
                      ? SizedBox(
                          width: isSmall ? 18 : 22,
                          height: isSmall ? 18 : 22,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: _primary),
                        )
                      : Text(
                          _avgLabel,
                          style: TextStyle(
                            color: _textDark,
                            fontSize: avgFontSize,
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
  Widget _buildLogCard({required bool isSmall, required bool isTablet}) {
    final cardPadding = isSmall ? 16.0 : (isTablet ? 32.0 : 24.0);
    final titleFontSize = isSmall ? 16.0 : 18.0;
    final subtitleFontSize = isSmall ? 12.0 : 13.0;
    final buttonHeight = isSmall ? 48.0 : 54.0;
    final buttonFontSize = isSmall ? 14.0 : 16.0;
    final iconSize = isSmall ? 18.0 : 20.0;
    final iconContainerSize = isSmall ? 34.0 : 40.0;
    final iconInnerSize = isSmall ? 16.0 : 20.0;
    final spacingAfterTitle = isSmall ? 16.0 : 24.0;
    final spacingBeforeButton = isSmall ? 16.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(isTablet ? 32 : 28),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                    ),
                    child: Center(
                      child: Icon(Icons.nights_stay_rounded,
                          color: _primary, size: iconInnerSize),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Log Hours',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(left: iconContainerSize + 12),
                child: Text(
                  'How much did you sleep last night?',
                  style:
                      TextStyle(color: _textMuted, fontSize: subtitleFontSize),
                ),
              ),
              SizedBox(height: spacingAfterTitle),

              // Inputs
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      controller: _hoursCtrl,
                      label: 'Hours',
                      hint: '0–12',
                      suffix: 'h',
                      isSmall: isSmall,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 12) return 'Enter 0–12';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 14),
                  Expanded(
                    child: _InputField(
                      controller: _minsCtrl,
                      label: 'Minutes',
                      hint: '0–59',
                      suffix: 'm',
                      isSmall: isSmall,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 59) return 'Enter 0–59';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: spacingBeforeButton),

              // Save button
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSleep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? _accent : _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: isSmall ? 18 : 22,
                          height: isSmall ? 18 : 22,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : _saved
                          ? ScaleTransition(
                              scale: _successScale,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: iconSize),
                                  const SizedBox(width: 8),
                                  Text('Saved!',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: buttonFontSize)),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: iconSize),
                                const SizedBox(width: 8),
                                Text('Save Sleep',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: buttonFontSize)),
                              ],
                            ),
                ),
              ),

              // ── Success banner ──────────────────────────────────
              if (_saved) ...[
                SizedBox(height: isSmall ? 10 : 14),
                ScaleTransition(
                  scale: _successScale,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isSmall ? 10 : 12,
                        horizontal: isSmall ? 12 : 16),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: const Color(0xFF4CAF50),
                            size: isSmall ? 16 : 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sleep logged & saved to Supabase!',
                            style: TextStyle(
                              color: _textDark.withOpacity(0.75),
                              fontSize: isSmall ? 11 : 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Error banner ────────────────────────────────────
              if (_errorMsg != null) ...[
                SizedBox(height: isSmall ? 10 : 14),
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: isSmall ? 10 : 12,
                      horizontal: isSmall ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A80).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: const Color(0xFFE53935),
                          size: isSmall ? 16 : 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                              color: const Color(0xFFE53935),
                              fontSize: isSmall ? 11 : 12),
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
  final bool isSmall;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    this.validator,
    this.isSmall = false,
  });

  static const Color _primary = Color(0xFFA0B4F0);
  static const Color _textDark = Color(0xFF3D3A5C);
  static const Color _textMuted = Color(0xFF9591B0);
  static const Color _bg = Color(0xFFF0F0FA);

  @override
  Widget build(BuildContext context) {
    final labelFontSize = isSmall ? 11.0 : 12.0;
    final valueFontSize = isSmall ? 18.0 : 22.0;
    final hintFontSize = isSmall ? 14.0 : 16.0;
    final suffixFontSize = isSmall ? 14.0 : 16.0;
    final verticalPadding = isSmall ? 12.0 : 16.0;
    final borderRadius = isSmall ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textMuted,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
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
          style: TextStyle(
            color: _textDark,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textMuted.withOpacity(0.5),
              fontSize: hintFontSize,
              fontWeight: FontWeight.w400,
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: _primary,
              fontSize: suffixFontSize,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide:
                  const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide:
                  const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPadding,
            ),
          ),
        ),
      ],
    );
  }
}
