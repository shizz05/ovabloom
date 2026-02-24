import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pcos_app/widgets/app_scaffold.dart';
import 'analytics_page.dart';
import 'profile_settings_page.dart';
import 'cycle_logging_page.dart';
import 'symptom_tracking_page.dart';
import 'package:pcos_app/screens/sleep_tracker_screen.dart';

// ─────────────────────────────── THEME ────────────────────────────────────────

class HomeTheme {
  static const Color roseDeep = Color(0xFFB5477A);
  static const Color roseMid = Color(0xFFE07FAF);
  static const Color roseLight = Color(0xFFFFC2D1);
  static const Color teal = Color(0xFF00BFA5);
  static const Color purple = Color(0xFF7E57C2);
  static const Color red = Color(0xFFFF5252);
  static const Color surface = Color(0xFFFFF0F6);
  static const Color textPrimary = Color(0xFF1C0B26);
  static const Color textMuted = Color(0xFF9B7A9B);
  static const Color sleepPurple = Color(0xFF6A5AE0);
  static const Color glucoseBlue = Color(0xFF1976D2);

  static BoxShadow get softShadow => BoxShadow(
        color: roseDeep.withValues(alpha: 0.10),
        blurRadius: 18,
        offset: const Offset(0, 6),
      );
}

// ─────────────────────────────── FLOATING PETAL ──────────────────────────────

class _FloatingPetal {
  double x, y, size, speed, opacity, angle, drift;
  _FloatingPetal(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 6 + rng.nextDouble() * 10,
        speed = 0.0004 + rng.nextDouble() * 0.0006,
        opacity = 0.08 + rng.nextDouble() * 0.18,
        angle = rng.nextDouble() * 2 * pi,
        drift = (rng.nextDouble() - 0.5) * 0.0003;
}

class _PetalPainter extends CustomPainter {
  final List<_FloatingPetal> petals;
  final Color color;
  _PetalPainter(this.petals, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.angle);
      final path = Path()
        ..moveTo(0, -p.size)
        ..cubicTo(
            p.size * 0.6, -p.size * 0.6, p.size * 0.6, p.size * 0.6, 0, p.size)
        ..cubicTo(-p.size * 0.6, p.size * 0.6, -p.size * 0.6, -p.size * 0.6, 0,
            -p.size)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => true;
}

class _FloatingPetalsWidget extends StatefulWidget {
  final Color color;
  const _FloatingPetalsWidget({required this.color});

  @override
  State<_FloatingPetalsWidget> createState() => _FloatingPetalsWidgetState();
}

class _FloatingPetalsWidgetState extends State<_FloatingPetalsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_FloatingPetal> _petals =
      List.generate(14, (_) => _FloatingPetal(Random()));

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            for (final p in _petals) {
              p.y -= p.speed;
              p.x += p.drift;
              p.angle += 0.005;
              if (p.y < -0.05) {
                p.y = 1.05;
                p.x = Random().nextDouble();
              }
            }
            setState(() {});
          })
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PetalPainter(_petals, widget.color),
      size: Size.infinite,
    );
  }
}

// ─────────────────────────────── PULSE RING ──────────────────────────────────

class _PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseRing({required this.color, required this.size});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _scale = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: _opacity.value),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── SPARKLE DOT ─────────────────────────────────

class _SparkleWidget extends StatefulWidget {
  final Color color;
  const _SparkleWidget({required this.color});

  @override
  State<_SparkleWidget> createState() => _SparkleWidgetState();
}

class _SparkleWidgetState extends State<_SparkleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200 + Random().nextInt(600)),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Icon(Icons.star, color: widget.color, size: 8),
    );
  }
}

// ─────────────────────────────── HOME PAGE ────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _lastPeriodDate;
  String? _userName;
  String? _avatarUrl;
  User? _currentUser;
  String _quote = '';
  String _quotePhase = 'default';
  Timer? _timer;

  AnimationController? _headerAnimCtrl;
  AnimationController? _circleAnimCtrl;
  AnimationController? _cardSlideCtrl;
  Animation<double>? _headerFade;
  Animation<double>? _circleScale;
  Animation<Offset>? _cardSlide;
  Animation<double>? _cardFade;

  final Map<String, List<Map<String, String>>> _quotes = {
    'period': [
      {'text': 'Be gentle with yourself today', 'icon': '🌸'},
      {'text': 'You are strong and beautiful', 'icon': '✨'},
      {'text': 'Listen to your body, it knows best', 'icon': '💕'},
    ],
    'fertile': [
      {'text': "You're glowing with energy!", 'icon': '🌟'},
      {'text': "Feel your power — you're in your prime", 'icon': '🌺'},
      {'text': 'Confidence looks gorgeous on you', 'icon': '💫'},
    ],
    'luteal': [
      {'text': "It's okay to slow down and recharge", 'icon': '🌙'},
      {'text': 'Nourish your body and soul', 'icon': '🍵'},
      {'text': 'Trust the process, your body is wise', 'icon': '🌿'},
    ],
    'default': [
      {'text': 'You are amazing, remember that!', 'icon': '💗'},
      {'text': 'Every day is a fresh start', 'icon': '🌅'},
      {'text': "You've got this!", 'icon': '⭐'},
    ],
  };

  String _quoteIcon = '💗';

  @override
  void initState() {
    super.initState();

    _headerAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _circleAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _cardSlideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _headerFade =
        CurvedAnimation(parent: _headerAnimCtrl!, curve: Curves.easeOut);
    _circleScale =
        CurvedAnimation(parent: _circleAnimCtrl!, curve: Curves.elasticOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _cardSlideCtrl!, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardSlideCtrl!, curve: Curves.easeOut);

    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _startQuoteTimer();

    _headerAnimCtrl!.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _circleAnimCtrl!.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _cardSlideCtrl!.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(58.0 * 13);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _headerAnimCtrl?.dispose();
    _circleAnimCtrl?.dispose();
    _cardSlideCtrl?.dispose();
    super.dispose();
  }

  // ── QUOTE TIMER ────────────────────────────────────────────────────────────

  void _startQuoteTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateQuote());
    _updateQuote();
  }

  void _updateQuote() {
    final day = _calculateCycleDay();
    String phase = 'default';
    if (day >= 1 && day <= 5) {
      phase = 'period';
    } else if (day >= 10 && day <= 16) {
      phase = 'fertile';
    } else if (day > 16 && day <= 28) {
      phase = 'luteal';
    }
    final list = _quotes[phase]!;
    final picked = list[Random().nextInt(list.length)];
    setState(() {
      _quote = picked['text']!;
      _quoteIcon = picked['icon']!;
      _quotePhase = phase;
    });
  }

  // ── DATA FETCH ─────────────────────────────────────────────────────────────

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    await _currentUser?.reload();
    if (!mounted) return;
    setState(() => _currentUser = FirebaseAuth.instance.currentUser);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          if (data.containsKey('lastPeriodDate')) {
            _lastPeriodDate = (data['lastPeriodDate'] as Timestamp).toDate();
          }
          if (data.containsKey('name')) {
            _userName = data['name'] as String?;
          }
          if (data.containsKey('avatarUrl')) {
            _avatarUrl = data['avatarUrl'] as String?;
          }
        });
      }
    } catch (_) {}
  }

  // ── CYCLE LOGIC ────────────────────────────────────────────────────────────

  int _calculateCycleDay() {
    if (_lastPeriodDate == null) return 0;
    final s =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final p = DateTime(
        _lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);
    return s.difference(p).inDays + 1;
  }

  Map<String, dynamic> _getCycleDisplayData(int cycleDay) {
    if (cycleDay == 0) {
      return {
        'title': 'Track your cycle',
        'mainText': '?',
        'subtitle': 'Log period to start',
        'color': HomeTheme.textMuted,
        'progress': 0.0,
        'phase': 'none',
      };
    }
    if (cycleDay < 1) {
      return {
        'title': 'Days until period',
        'mainText': '${cycleDay.abs()}',
        'subtitle': 'Predicted start',
        'color': HomeTheme.purple,
        'progress': 0.9,
        'phase': 'upcoming',
      };
    } else if (cycleDay >= 1 && cycleDay <= 5) {
      return {
        'title': 'Period Day',
        'mainText': '$cycleDay',
        'subtitle': 'Low chance of pregnancy',
        'color': HomeTheme.red,
        'progress': cycleDay / 5.0 * 0.25,
        'phase': 'period',
      };
    } else if (cycleDay >= 10 && cycleDay <= 16) {
      final daysToOv = 14 - cycleDay;
      return {
        'title': daysToOv == 0
            ? 'Ovulation Day'
            : daysToOv > 0
                ? 'Ovulation in'
                : 'Fertile Window',
        'mainText': daysToOv == 0
            ? 'Today'
            : daysToOv > 0
                ? '$daysToOv days'
                : 'Day $cycleDay',
        'subtitle': 'Higher chance of pregnancy',
        'color': HomeTheme.teal,
        'progress': 0.35 + ((cycleDay - 10) / 6.0 * 0.15),
        'phase': 'fertile',
      };
    } else {
      return {
        'title': 'Cycle Day',
        'mainText': '$cycleDay',
        'subtitle': 'Follicular / Luteal phase',
        'color': HomeTheme.purple,
        'progress': cycleDay / 28.0,
        'phase': 'luteal',
      };
    }
  }

  String _getWeekday(int weekday) =>
      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];

  String _getMonthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ── GLUCOSE HELPERS ────────────────────────────────────────────────────────

  Map<String, dynamic> _getGlucoseStatus(double value) {
    if (value < 70) {
      return {'color': const Color(0xFFFF5252), 'label': 'Low', 'icon': '⬇️'};
    } else if (value <= 99) {
      return {'color': const Color(0xFF43A047), 'label': 'Normal', 'icon': '✅'};
    } else if (value <= 125) {
      return {
        'color': const Color(0xFFFFA726),
        'label': 'Pre-diabetic',
        'icon': '⚠️',
      };
    } else {
      return {'color': const Color(0xFFFF5252), 'label': 'High', 'icon': '⬆️'};
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.day}/${local.month}/${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  // ── GLUCOSE BOTTOM SHEET ───────────────────────────────────────────────────
  // Opens a modal bottom sheet containing:
  //   • reference range legend
  //   • input + save button  →  writes to Firestore
  //   • live list of last 5 readings from Firestore

  void _showGlucoseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlucoseBottomSheet(
        currentUser: _currentUser,
        getGlucoseStatus: _getGlucoseStatus,
        formatDateTime: _formatDateTime,
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cycleDay = _calculateCycleDay();
    final displayData = _getCycleDisplayData(cycleDay);
    final primaryColor = displayData['color'] as Color;

    final headerFade = _headerFade ?? const AlwaysStoppedAnimation(1.0);
    final circleScale = _circleScale ?? const AlwaysStoppedAnimation(1.0);
    final cardFade = _cardFade ?? const AlwaysStoppedAnimation(1.0);
    final cardSlide = _cardSlide ?? const AlwaysStoppedAnimation(Offset.zero);

    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── HERO SECTION ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.12),
                    HomeTheme.surface.withValues(alpha: 0.6),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: _FloatingPetalsWidget(color: primaryColor)),
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        FadeTransition(
                            opacity: headerFade, child: _buildHeader()),
                        const SizedBox(height: 14),
                        FadeTransition(
                            opacity: headerFade,
                            child: _buildMonthAndQuote(primaryColor)),
                        const SizedBox(height: 16),
                        FadeTransition(
                            opacity: headerFade,
                            child: _buildDateStrip(primaryColor)),
                        const SizedBox(height: 36),
                        ScaleTransition(
                          scale: circleScale,
                          child: _buildMainCircle(
                              cycleDay, displayData, primaryColor),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── PHASE PILL ────────────────────────────────────────────────
            SlideTransition(
              position: cardSlide,
              child: FadeTransition(
                  opacity: cardFade, child: _buildPhasePill(displayData)),
            ),

            const SizedBox(height: 24),

            // ── INSIGHTS ──────────────────────────────────────────────────
            SlideTransition(
              position: cardSlide,
              child: FadeTransition(
                  opacity: cardFade, child: _buildInsightsSection()),
            ),

            const SizedBox(height: 20),

            // ── SLEEP BANNER ──────────────────────────────────────────────
            SlideTransition(
              position: cardSlide,
              child:
                  FadeTransition(opacity: cardFade, child: _buildSleepBanner()),
            ),

            // ── Standalone Glucose Log section removed ────────────────────

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final displayName = _userName ?? _currentUser?.displayName ?? 'Beautiful';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage()));
              _fetchUserData();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HomeTheme.textPrimary,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [HomeTheme.softShadow],
                    gradient: const LinearGradient(
                      colors: [HomeTheme.roseDeep, HomeTheme.roseMid],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _avatarUrl != null ? AssetImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person,
                            color: HomeTheme.roseDeep, size: 22)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _SparkleWidget(color: HomeTheme.roseMid),
              const SizedBox(width: 4),
              _SparkleWidget(color: HomeTheme.roseLight),
              const SizedBox(width: 4),
              _SparkleWidget(color: HomeTheme.roseMid),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CycleLoggingPage()))
                .then((_) => _fetchUserData()),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [HomeTheme.softShadow],
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: HomeTheme.roseDeep, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── MONTH + QUOTE SECTION ──────────────────────────────────────────────────

  Widget _buildMonthAndQuote(Color primaryColor) {
    final Map<String, List<Color>> phaseGradients = {
      'period': [const Color(0xFFFF8FAB), const Color(0xFFFF4D8D)],
      'fertile': [const Color(0xFF26C6DA), const Color(0xFF00897B)],
      'luteal': [const Color(0xFF9575CD), const Color(0xFF5E35B1)],
      'default': [HomeTheme.roseMid, HomeTheme.roseDeep],
    };

    final gradColors =
        phaseGradients[_quotePhase] ?? phaseGradients['default']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getMonthLabel(_selectedDate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                        .animate(anim),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(_quote),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradColors.last.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -10,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 6,
                      child: Text(
                        '\u201C',
                        style: TextStyle(
                          fontSize: 52,
                          color: Colors.white.withValues(alpha: 0.18),
                          fontFamily: 'Georgia',
                          height: 1,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(_quoteIcon,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Affirmation',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _quote.isEmpty ? 'You are amazing!' : _quote,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Georgia',
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DATE STRIP ─────────────────────────────────────────────────────────────

  Widget _buildDateStrip(Color primaryColor) {
    final now = DateTime.now();
    final initialDate = now.subtract(const Duration(days: 15));

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 365 * 2,
        itemBuilder: (context, index) {
          final date = initialDate.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : HomeTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isSelected ? Colors.white : HomeTheme.textPrimary,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── MAIN CIRCLE ────────────────────────────────────────────────────────────

  Widget _buildMainCircle(
      int cycleDay, Map<String, dynamic> displayData, Color primaryColor) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseRing(color: primaryColor, size: 280),
          _PulseRing(color: primaryColor.withValues(alpha: 0.5), size: 260),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.15),
                width: 20,
              ),
            ),
          ),
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: displayData['progress'] as double,
              strokeWidth: 20,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  primaryColor.withValues(alpha: 0.6)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.18),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          if (cycleDay == 0)
            GestureDetector(
              onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CycleLoggingPage()))
                  .then((_) => _fetchUserData()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HomeTheme.teal, Color(0xFF26C6DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: HomeTheme.teal.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Log Period',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayData['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: HomeTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayData['mainText'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'Georgia',
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayData['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── PHASE PILL ─────────────────────────────────────────────────────────────

  Widget _buildPhasePill(Map<String, dynamic> displayData) {
    final phase = displayData['phase'] as String;
    final color = displayData['color'] as Color;

    const phaseInfo = <String, Map<String, String>>{
      'period': {
        'emoji': '🌸',
        'label': 'Menstrual Phase',
        'tip': 'Rest & nourish'
      },
      'fertile': {
        'emoji': '🌺',
        'label': 'Fertile Window',
        'tip': 'Peak energy'
      },
      'luteal': {'emoji': '🌙', 'label': 'Luteal Phase', 'tip': 'Wind down'},
      'upcoming': {
        'emoji': '⏳',
        'label': 'Period Approaching',
        'tip': 'Prep time'
      },
      'none': {'emoji': '💫', 'label': 'Log your cycle', 'tip': 'Get started'},
    };

    final info = phaseInfo[phase] ?? phaseInfo['none']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [HomeTheme.softShadow],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Text(info['emoji']!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info['label']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: HomeTheme.textPrimary)),
              Text(info['tip']!,
                  style: const TextStyle(
                      fontSize: 12, color: HomeTheme.textMuted)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Today',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── INSIGHTS SECTION ───────────────────────────────────────────────────────

  Widget _buildInsightsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'let me know you',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HomeTheme.textPrimary,
                ),
              ),
              Spacer(),
              Text('Today',
                  style: TextStyle(fontSize: 13, color: HomeTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 172,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildInsightCard(
                  imagePath: 'assets/symptoms.png',
                  title: 'Symptoms',
                  subtitle: 'Log today',
                  bgColor: const Color(0xFFE8F5E9),
                  accentColor: const Color(0xFF388E3C),
                  shadowColor: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SymptomTrackingPage())),
                ),
                // Glucose card → opens full bottom sheet with readings + add
                _buildInsightCard(
                  imagePath: 'assets/glucose.png',
                  title: 'Glucose',
                  subtitle: 'Add reading',
                  bgColor: const Color(0xFFE3F2FD),
                  accentColor: const Color(0xFF1976D2),
                  shadowColor: const Color(0xFF2196F3),
                  onTap: _showGlucoseSheet,
                ),
                _buildInsightCard(
                  imagePath: 'assets/analytics.png',
                  title: 'Analytics',
                  subtitle: 'View trends',
                  bgColor: const Color(0xFFF3E5F5),
                  accentColor: HomeTheme.purple,
                  shadowColor: const Color(0xFF9C27B0),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AnalyticsPage())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color accentColor,
    required Color shadowColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 172,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: SizedBox(
                height: 118,
                width: double.infinity,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    color: bgColor,
                    child: Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: accentColor, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: accentColor)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor.withValues(alpha: 0.65)),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: accentColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SLEEP BANNER ───────────────────────────────────────────────────────────

  Widget _buildSleepBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SleepTrackerScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A2E), Color(0xFF3D1060)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: HomeTheme.sleepPurple.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('🌙', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Tracker',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Track your rest & recovery',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GLUCOSE BOTTOM SHEET
// All glucose functionality — readings list + add new reading.
// Saves to Firestore: users/{uid}/glucoseReadings
// ══════════════════════════════════════════════════════════════════════════════

class _GlucoseBottomSheet extends StatefulWidget {
  final User? currentUser;
  final Map<String, dynamic> Function(double) getGlucoseStatus;
  final String Function(DateTime) formatDateTime;

  const _GlucoseBottomSheet({
    required this.currentUser,
    required this.getGlucoseStatus,
    required this.formatDateTime,
  });

  @override
  State<_GlucoseBottomSheet> createState() => _GlucoseBottomSheetState();
}

class _GlucoseBottomSheetState extends State<_GlucoseBottomSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String? _errorText;
  bool _isSaving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveReading() async {
    final raw = _ctrl.text.trim();
    final parsed = double.tryParse(raw);

    if (raw.isEmpty || parsed == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }
    if (parsed <= 0 || parsed > 600) {
      setState(() => _errorText = 'Enter a value between 1–600');
      return;
    }
    if (widget.currentUser == null) {
      setState(() => _errorText = 'Not signed in');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser!.uid)
          .collection('glucoseReadings')
          .add({
        'userId': widget.currentUser!.uid,
        'value': parsed,
        'unit': 'mg/dL',
        'timestamp': FieldValue.serverTimestamp(),
        'loggedAt': DateTime.now().toIso8601String(),
      });

      _ctrl.clear();
      setState(() => _isSaving = false);

      final status = widget.getGlucoseStatus(parsed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(status['icon'] as String,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$parsed mg/dL saved — ${status['label']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: status['color'] as Color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorText = 'Failed to save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Max height shrinks when keyboard appears so nothing overflows
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.92,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: HomeTheme.glucoseBlue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('💧', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glucose Log',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HomeTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Track your blood sugar levels',
                      style:
                          TextStyle(fontSize: 12, color: HomeTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Reference ranges ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GlucoseRange(
                      label: 'Low', value: '<70', color: Color(0xFFFF5252)),
                  _GlucoseRange(
                      label: 'Normal',
                      value: '70–99',
                      color: Color(0xFF43A047)),
                  _GlucoseRange(
                      label: 'Pre-DM',
                      value: '100–125',
                      color: Color(0xFFFFA726)),
                  _GlucoseRange(
                      label: 'High', value: '>125', color: Color(0xFFFF5252)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Input + Save ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_errorText != null) setState(() => _errorText = null);
                    },
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HomeTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 95',
                      hintStyle: const TextStyle(
                          color: HomeTheme.textMuted, fontSize: 16),
                      suffixText: 'mg/dL',
                      suffixStyle: const TextStyle(
                          color: HomeTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFFBBDEFB), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFFBBDEFB), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: HomeTheme.glucoseBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5FAFE),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeTheme.glucoseBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 4),
                              Text('Save',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Readings header ───────────────────────────────────────────────
            const Row(
              children: [
                Text(
                  'Recent Readings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: HomeTheme.textPrimary,
                  ),
                ),
                Spacer(),
                Text('Last 5',
                    style: TextStyle(fontSize: 12, color: HomeTheme.textMuted)),
              ],
            ),

            const SizedBox(height: 10),

            // ── Readings list ─────────────────────────────────────────────────
            if (widget.currentUser == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Sign in to view readings.',
                      style: TextStyle(color: HomeTheme.textMuted)),
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUser!.uid)
                    .collection('glucoseReadings')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop_outlined,
                              color:
                                  HomeTheme.glucoseBlue.withValues(alpha: 0.3),
                              size: 40),
                          const SizedBox(height: 10),
                          const Text(
                            'No readings yet',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: HomeTheme.textPrimary,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter a value above to log your first reading',
                            style: TextStyle(
                                color: HomeTheme.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final readings = snapshot.data!.docs;
                  // NeverScrollableScrollPhysics because parent
                  // SingleChildScrollView handles scrolling
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: readings.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 0,
                      color: Color(0xFFF0F4F8),
                    ),
                    itemBuilder: (context, index) {
                      final data =
                          readings[index].data() as Map<String, dynamic>;
                      final value = (data['value'] as num?)?.toDouble() ?? 0.0;
                      final unit = data['unit'] as String? ?? 'mg/dL';
                      final ts = data['timestamp'];
                      DateTime? time;
                      if (ts is Timestamp) time = ts.toDate();

                      final status = widget.getGlucoseStatus(value);
                      final statusColor = status['color'] as Color;
                      final statusLabel = status['label'] as String;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(status['icon'] as String,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        title: Text(
                          '$value $unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: HomeTheme.textPrimary,
                          ),
                        ),
                        subtitle: time != null
                            ? Text(
                                widget.formatDateTime(time),
                                style: const TextStyle(
                                    color: HomeTheme.textMuted, fontSize: 12),
                              )
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── GLUCOSE RANGE BADGE ────────────────────────────────────────────────────

class _GlucoseRange extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GlucoseRange({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: HomeTheme.textMuted)),
      ],
    );
  }
}
