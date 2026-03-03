import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_scaffold.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFFF6F4FF);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF7C6CF8);
  static const Color _rose = Color(0xFFFF7EB3);
  static const Color _teal = Color(0xFF3DD6C0);
  static const Color _amber = Color(0xFFFFB347);
  static const Color _red = Color(0xFFFF6B6B);
  static const Color _textDark = Color(0xFF2A2550);
  static const Color _textMuted = Color(0xFF9B96C0);
  static const Color _divider = Color(0xFFEEEBFF);

  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _twin;
  bool _loading = true;
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchDigitalTwin();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDigitalTwin() async {
    if (mounted) setState(() => _loading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('digital_twin')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _twin = data;
          _loading = false;
          _errorMsg = null;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _errorMsg = e.toString();
        });
    }
  }

  String _fmt(dynamic v, {String fallback = '—'}) =>
      (v?.toString().isNotEmpty == true) ? v.toString() : fallback;

  String _fmtTs(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  double _toDouble(dynamic v, double fb) => v is num ? v.toDouble() : fb;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 2,
      body: Container(
        color: _bg,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _twin == null
                ? _buildEmpty()
                : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.hub_outlined,
                  size: 48, color: _primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text('No AI data yet',
                style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'Your Raspberry Pi will populate this\nonce the edge ML server is running.',
                style: TextStyle(color: _textMuted, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center),
            if (_errorMsg != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_errorMsg!,
                    style: TextStyle(color: _red, fontSize: 11),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchDigitalTwin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(16)),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final t = _twin!;

    final hrBaseline = _toDouble(t['hr_baseline'], 0);
    final hrvBaseline = _toDouble(t['hrv_baseline'], 0);
    final sleepBaseline = _toDouble(t['sleep_baseline'], 0);
    final moveBaseline = _toDouble(t['movement_baseline'], 0);
    final glucoseBaseline = _toDouble(t['glucose_baseline'], 0);
    final avgCycleLen = _toDouble(t['avg_cycle_length'], 28);
    final cycleVariation = _toDouble(t['cycle_variation'], 3);
    final stressHigh = t['stress_high'] == true;
    final glucoseHigh = t['glucose_high'] == true;
    final flareType = _fmt(t['flare_type'], fallback: 'None');
    final ovulationDay = _toDouble(t['predicted_ovulation_day'], 0);
    final daysUntilPeriod = _toDouble(t['predicted_days_until_period'], 0);
    final lastInference = _fmtTs(t['last_inference_at']?.toString());
    final modelVersion = _fmt(t['model_version'], fallback: 'v1.0');
    final glucoseState = _fmt(t['glucose_state'], fallback: 'Unknown');
    final flags = (t['insight_flags'] is List)
        ? List<String>.from(t['insight_flags'])
        : <String>[];

    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hp = isTablet ? sw * 0.08 : 20.0;

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetchDigitalTwin,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(hp, 24, hp, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────
            _buildPageHeader(lastInference, modelVersion),
            const SizedBox(height: 28),

            // ── Wearable Baselines ────────────────────────────────
            _sectionLabel('WEARABLE BASELINES'),
            const SizedBox(height: 12),
            _buildBaselineGrid(
                hrBaseline, hrvBaseline, sleepBaseline, moveBaseline,
                isTablet: isTablet),
            const SizedBox(height: 28),

            // ── Cycle Intelligence ────────────────────────────────
            _sectionLabel('CYCLE INTELLIGENCE'),
            const SizedBox(height: 12),
            _buildCycleSection(
                ovulationDay, daysUntilPeriod, avgCycleLen, cycleVariation),
            const SizedBox(height: 28),

            // ── Metabolic Panel ───────────────────────────────────
            _sectionLabel('METABOLIC PANEL'),
            const SizedBox(height: 12),
            _buildMetabolicCard(glucoseBaseline, glucoseState, glucoseHigh),
            const SizedBox(height: 28),

            // ── Risk Signals ──────────────────────────────────────
            _sectionLabel('RISK SIGNALS'),
            const SizedBox(height: 12),
            _buildRiskRow(stressHigh, flareType),

            // ── Active Flags ──────────────────────────────────────
            if (flags.isNotEmpty) ...[
              const SizedBox(height: 28),
              _sectionLabel('ACTIVE AI FLAGS'),
              const SizedBox(height: 12),
              _buildFlagsCard(flags),
            ],

            const SizedBox(height: 28),
            _buildFooter(lastInference, modelVersion),
          ],
        ),
      ),
    );
  }

  // ══ Page Header ───────────────────────────────────────────────────
  Widget _buildPageHeader(String last, String ver) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: 'Health ',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.8)),
                TextSpan(
                    text: 'Intelligence',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        letterSpacing: -0.8)),
              ])),
              const SizedBox(height: 5),
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      const BoxDecoration(color: _teal, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Live · Raspberry Pi · $ver',
                    style: TextStyle(
                        fontSize: 12, color: _textMuted, letterSpacing: 0.2)),
              ]),
            ],
          ),
        ),
        GestureDetector(
          onTap: _fetchDigitalTwin,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.refresh_rounded, color: _primary, size: 22),
          ),
        ),
      ],
    );
  }

  // ══ Baseline Grid ─────────────────────────────────────────────────
  Widget _buildBaselineGrid(double hr, double hrv, double sleep, double move,
      {required bool isTablet}) {
    final items = [
      _TileData('Heart Rate', '${hr.toStringAsFixed(1)}', 'bpm',
          Icons.favorite_rounded, _rose, (hr / 120).clamp(0, 1)),
      _TileData('HRV', '${hrv.toStringAsFixed(1)}', 'ms',
          Icons.timeline_rounded, _teal, (hrv / 80).clamp(0, 1)),
      _TileData('Sleep Score', '${(sleep * 100).toStringAsFixed(0)}', '%',
          Icons.bedtime_rounded, _primary, sleep.clamp(0, 1)),
      _TileData('Movement', move.toStringAsFixed(2), 'idx',
          Icons.directions_walk_rounded, _amber, (move / 2).clamp(0, 1)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isTablet ? 1.1 : 1.05,
      ),
      itemBuilder: (_, i) {
        final d = items[i];
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: d.color.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: d.color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(d.icon, color: d.color, size: 18),
            ),
            const Spacer(),
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: d.value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.5)),
              TextSpan(
                  text: ' ${d.unit}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted)),
            ])),
            const SizedBox(height: 3),
            Text(d.label,
                style: TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: d.fraction,
                minHeight: 5,
                backgroundColor: d.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(d.color),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ══ Cycle Section ─────────────────────────────────────────────────
  Widget _buildCycleSection(
      double ovDay, double daysLeft, double avgLen, double variation) {
    final progress = ((avgLen - daysLeft) / avgLen).clamp(0.0, 1.0);
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: _rose.withOpacity(0.13),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: _rose, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Text('Cycle Progress',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _rose.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Avg ${avgLen.toInt()} ± ${variation.toInt()} days',
                  style: TextStyle(
                      fontSize: 11, color: _rose, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 18),
          Stack(children: [
            Container(
                height: 10,
                decoration: BoxDecoration(
                    color: _rose.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: [_rose, Color(0xFFFF9CC8)]),
                      borderRadius: BorderRadius.circular(6))),
            ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(progress * 100).toStringAsFixed(0)}% complete',
                style: TextStyle(fontSize: 11, color: _textMuted)),
            Text('${daysLeft.toInt()} days to period',
                style: TextStyle(
                    fontSize: 12, color: _rose, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
            child: _miniCard(
                icon: Icons.egg_outlined,
                color: _amber,
                label: 'Predicted Ovulation',
                value: 'Day ${ovDay.toInt()}',
                sub: 'Model-based estimate')),
        const SizedBox(width: 14),
        Expanded(
            child: _miniCard(
                icon: Icons.water_drop_outlined,
                color: _rose,
                label: 'Days to Period',
                value: '${daysLeft.toInt()} days',
                sub: 'Period model forecast')),
      ]),
    ]);
  }

  // ══ Metabolic Card ────────────────────────────────────────────────
  Widget _buildMetabolicCard(
      double glucoseBase, String glucoseState, bool glucoseHigh) {
    final c = glucoseHigh ? _red : _teal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: glucoseHigh
            ? Border.all(color: _red.withOpacity(0.35), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.13),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bloodtype_rounded, color: _teal, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Glucose Intelligence',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
            ]),
            const SizedBox(height: 16),
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: glucoseBase.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -1.0)),
              TextSpan(
                  text: ' mg/dL',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textMuted)),
            ])),
            const SizedBox(height: 8),
            Row(children: [
              _statusPill(glucoseHigh ? 'Elevated' : 'Normal', c),
              const SizedBox(width: 8),
              Text(glucoseState,
                  style: TextStyle(
                      fontSize: 13, color: c, fontWeight: FontWeight.w600)),
            ]),
          ],
        )),
        const SizedBox(width: 16),
        _GlucoseArc(fraction: (glucoseBase / 200).clamp(0, 1), color: c),
      ]),
    );
  }

  // ══ Risk Row ──────────────────────────────────────────────────────
  Widget _buildRiskRow(bool stressHigh, String flareType) {
    final noFlare = flareType == 'None' || flareType == '—';
    return Row(children: [
      Expanded(
          child: _riskCard(
              icon: Icons.psychology_rounded,
              color: stressHigh ? _red : _teal,
              label: 'Stress Detection',
              value: stressHigh ? 'Elevated' : 'Normal',
              sub: 'HR · HRV model',
              isAlert: stressHigh)),
      const SizedBox(width: 14),
      Expanded(
          child: _riskCard(
              icon: Icons.local_fire_department_rounded,
              color: noFlare ? _teal : _amber,
              label: 'Flare Prediction',
              value: flareType,
              sub: 'Inflammatory model',
              isAlert: !noFlare)),
    ]);
  }

  Widget _riskCard(
      {required IconData icon,
      required Color color,
      required String label,
      required String value,
      required String sub,
      required bool isAlert}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: isAlert
            ? Border.all(color: color.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          if (isAlert) ...[
            const SizedBox(width: 8),
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ]),
        const SizedBox(height: 14),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isAlert ? color : _textDark,
                letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(sub,
            style: TextStyle(fontSize: 11, color: _textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ══ Flags Card ────────────────────────────────────────────────────
  Widget _buildFlagsCard(List<String> flags) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_rounded, color: _primary, size: 18),
          const SizedBox(width: 8),
          Text('${flags.length} flag${flags.length > 1 ? 's' : ''} active',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: flags
              .map((f) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary)),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  // ══ Footer ───────────────────────────────────────────────────────
  Widget _buildFooter(String last, String ver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _divider, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.memory_rounded, size: 15, color: _textMuted),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Last inference: $last · Model $ver',
                style: TextStyle(fontSize: 11, color: _textMuted),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Reusable ─────────────────────────────────────────────────────
  Widget _miniCard(
      {required IconData icon,
      required Color color,
      required String label,
      required String value,
      required String sub}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.11),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 14),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.4)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(fontSize: 11, color: _textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: _primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textMuted,
                letterSpacing: 1.4)),
      ]);

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  DATA CLASS  (now with unit field)
// ════════════════════════════════════════════════════════════════════
class _TileData {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  final double fraction;
  const _TileData(
      this.label, this.value, this.unit, this.icon, this.color, this.fraction);
}

// ════════════════════════════════════════════════════════════════════
//  GLUCOSE ARC
// ════════════════════════════════════════════════════════════════════
class _GlucoseArc extends StatelessWidget {
  final double fraction;
  final Color color;
  const _GlucoseArc({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(painter: _ArcPainter(fraction, color)));
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _ArcPainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 7;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final base = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -2.35, 4.71, false, base);
    canvas.drawArc(rect, -2.35, 4.71 * fraction, false, fill);
  }

  @override
  bool shouldRepaint(_ArcPainter o) =>
      o.fraction != fraction || o.color != color;
}

// ════════════════════════════════════════════════════════════════════
//  PULSING ORB  (kept — not used in UI anymore, retained for reuse)
// ════════════════════════════════════════════════════════════════════
class _PulsingOrb extends StatefulWidget {
  final Color color;
  const _PulsingOrb({required this.color});
  @override
  State<_PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<_PulsingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final s = 52.0 + _anim.value * 12;
        return Container(
          width: s,
          height: s,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: widget.color),
          child: Center(
              child: Container(
            width: s * 0.48,
            height: s * 0.48,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white.withOpacity(0.38)),
          )),
        );
      },
    );
  }
}
