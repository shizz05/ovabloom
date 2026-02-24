import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Pastel-warm analytics palette ──────────────────────────────
// Background  : warm cream
// Card        : pure white with soft shadow
// Primary     : coral rose  #F28B82
// Secondary   : sky blue    #A8D8EA
// Accent mint : #A8E6CF
// Accent peach: #FFDAB9
// Text dark   : #3C2F2F
// Text muted  : #9E8E8E
// ───────────────────────────────────────────────────────────────

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  bool _isWeekly = true;
  Map<String, dynamic>? _scorecardData;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color _bg = Color(0xFFFDF8F4);
  static const Color _primary = Color(0xFFF28B82);
  static const Color _sky = Color(0xFFA8D8EA);
  static const Color _mint = Color(0xFFA8E6CF);
  static const Color _peach = Color(0xFFFFDAB9);
  static const Color _lilac = Color(0xFFD4B8E0);
  static const Color _textDark = Color(0xFF3C2F2F);
  static const Color _textMuted = Color(0xFF9E8E8E);
  static const Color _cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchScorecardData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchScorecardData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final docId = _isWeekly ? 'weekly' : 'monthly';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pcos_scorecard')
          .doc(docId)
          .get();

      if (doc.exists) {
        setState(() => _scorecardData = doc.data());
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSampleData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final weeklyData = {
        'wellness_score': 85,
        'metrics': {
          'sleep': {'score': 78},
          'basal_temp': {'score': 90},
          'stress': {'score': 75},
          'cycle': {'score': 95},
          'heart_rate': {'score': 88},
          'activity': {'score': 92},
          'glucose': {'score': 80},
          'symptoms': {'score': 85},
        },
        'insights': [
          "Your sleep consistency is great! Keep it up.",
          "Consider adding some light exercise on days you feel stressed.",
        ],
      };

      final monthlyData = {
        'wellness_score': 78,
        'metrics': {
          'sleep': {'score': 82},
          'basal_temp': {'score': 85},
          'stress': {'score': 65},
          'cycle': {'score': 92},
          'heart_rate': {'score': 85},
          'activity': {'score': 88},
          'glucose': {'score': 75},
          'symptoms': {'score': 80},
        },
        'insights': [
          "You've shown great consistency with your cycle tracking this month.",
          "Try to incorporate more relaxation techniques to manage stress levels.",
        ],
      };

      final batch = FirebaseFirestore.instance.batch();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.set(userRef.collection('pcos_scorecard').doc('weekly'), weeklyData);
      batch.set(
          userRef.collection('pcos_scorecard').doc('monthly'), monthlyData);
      await batch.commit();
      await _fetchScorecardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating sample data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'PCOS Scorecard',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggle(),
            const SizedBox(height: 28),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (_scorecardData == null)
              _buildEmptyState()
            else
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreHero(sw),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Health Metrics'),
                    const SizedBox(height: 14),
                    _buildMetricsGrid(sw),
                    const SizedBox(height: 28),
                    _buildSectionLabel('AI Insights'),
                    const SizedBox(height: 14),
                    _buildInsights(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Toggle ─────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn('Weekly', _isWeekly, () {
              if (!_isWeekly) {
                setState(() => _isWeekly = true);
                _fetchScorecardData();
              }
            }),
            _toggleBtn('Monthly', !_isWeekly, () {
              if (_isWeekly) {
                setState(() => _isWeekly = false);
                _fetchScorecardData();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Score hero ─────────────────────────────────────────────────
  Widget _buildScoreHero(double sw) {
    final score = _scorecardData?['wellness_score'] ?? 0;
    final circleSize = sw * 0.52;

    return Center(
      child: Column(
        children: [
          // Gradient card behind circle
          Container(
            width: sw * 0.88,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFECEA), Color(0xFFFFF4F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CustomPaint(
                        painter: ScoreCirclePainter(score: score),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'WELLNESS SCORE',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'out of 100',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Score label badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    score >= 90
                        ? '🌟 Excellent'
                        : score >= 75
                            ? '✨ Good Progress'
                            : score >= 60
                                ? '💪 Keep Going'
                                : '🌱 Just Starting',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textDark,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  // ── Metrics grid ───────────────────────────────────────────────
  Widget _buildMetricsGrid(double sw) {
    final metrics = _scorecardData?['metrics'] as Map<String, dynamic>? ?? {};

    final items = [
      _MetricItem(Icons.nights_stay_outlined, 'Sleep',
          metrics['sleep']?['score'], _sky),
      _MetricItem(Icons.thermostat_outlined, 'Basal Temp',
          metrics['basal_temp']?['score'], _peach),
      _MetricItem(
          Icons.cloud_outlined, 'Stress', metrics['stress']?['score'], _lilac),
      _MetricItem(Icons.calendar_today_outlined, 'Cycle',
          metrics['cycle']?['score'], _mint),
      _MetricItem(Icons.favorite_border, 'Heart Rate',
          metrics['heart_rate']?['score'], _primary),
      _MetricItem(Icons.directions_run, 'Activity',
          metrics['activity']?['score'], Color(0xFFFFD580)),
      _MetricItem(Icons.water_drop_outlined, 'Glucose',
          metrics['glucose']?['score'], _sky),
      _MetricItem(Icons.sync, 'Symptoms', metrics['symptoms']?['score'], _mint),
    ];

    // Responsive: 2 columns on narrow, 4 on wide
    final cols = sw < 400 ? 2 : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildMetricCard(items[i]),
    );
  }

  Widget _buildMetricCard(_MetricItem item) {
    final score = item.score ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.score ?? "N/A"}',
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 4,
              backgroundColor: item.color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Insights ───────────────────────────────────────────────────
  Widget _buildInsights() {
    final insights =
        List<String>.from(_scorecardData?['insights'] as List<dynamic>? ?? []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF6FF), Color(0xFFF0FFF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _sky.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _sky.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF5B9FBF), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Recommendations',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            const Text('No insights available yet.',
                style: TextStyle(color: _textMuted))
          else
            ...insights.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(right: 12, top: 1),
                      decoration: BoxDecoration(
                        color: _mint.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: Color(0xFF3A8C6E),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: _primary, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No data yet',
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate sample data to see your\nPCOS wellness scorecard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _generateSampleData,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Generate Sample Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────
class _MetricItem {
  final IconData icon;
  final String title;
  final dynamic score;
  final Color color;
  const _MetricItem(this.icon, this.title, this.score, this.color);
}

// ── Custom painter ─────────────────────────────────────────────
class ScoreCirclePainter extends CustomPainter {
  final int score;
  const ScoreCirclePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;
    const totalSegments = 60;
    const gap = 0.04;
    const anglePerSegment = (2 * pi - totalSegments * gap) / totalSegments;

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEEE8E8);

    for (int i = 0; i < totalSegments; i++) {
      final startAngle = -pi / 2 + i * (anglePerSegment + gap);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSegment,
        false,
        trackPaint,
      );
    }

    // Filled arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: const [
        Color(0xFFFFB3AE), // soft coral
        Color(0xFFF28B82), // rose
        Color(0xFFA8E6CF), // mint
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final filledPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    for (int i = 0; i < totalSegments; i++) {
      if (i / totalSegments <= score / 100.0) {
        final startAngle = -pi / 2 + i * (anglePerSegment + gap);
        canvas.drawArc(rect, startAngle, anglePerSegment, false, filledPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScoreCirclePainter old) => old.score != score;
}
