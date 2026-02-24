import 'package:pcos_app/widgets/app_scaffold.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────── DATA MODELS ──────────────────────────────────

class CycleData {
  final String id;
  final DateTime startDate;
  final DateTime endDate;

  CycleData({required this.id, required this.startDate, required this.endDate});

  int get periodLength => endDate.difference(startDate).inDays + 1;

  factory CycleData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleData(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
    );
  }
}

class CycleAnalysisResult {
  final double avgCycleLength;
  final double avgPeriodLength;
  final int variation;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? nextPeriodDate;
  final String cycleStatus;
  final String periodStatus;
  final String variationStatus;

  const CycleAnalysisResult({
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.variation,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.nextPeriodDate,
    required this.cycleStatus,
    required this.periodStatus,
    required this.variationStatus,
  });
}

// ─────────────────────────────── THEME CONSTANTS ──────────────────────────────

class CycleTheme {
  static const Color primary = Color(0xFFB5477A);
  static const Color primaryLight = Color(0xFFE07FAF);
  static const Color primaryDeep = Color(0xFF7A1F52);
  static const Color accent = Color(0xFFFF8FAB);
  static const Color accentWarm = Color(0xFFFFC2D1);
  static const Color nightStart = Color(0xFF1A0A2E);
  static const Color nightEnd = Color(0xFF3D1060);
  static const Color surface = Color(0xFFFFF0F6);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1C0B26);
  static const Color textSecondary = Color(0xFF7B5C7A);
  static const Color divider = Color(0xFFEDD5E8);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get nightGradient => const LinearGradient(
        colors: [nightStart, nightEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: primary.withValues(alpha: 0.12),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      );

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );
}

// ─────────────────────────────── MAIN PAGE ────────────────────────────────────

class CycleLoggingPage extends StatefulWidget {
  const CycleLoggingPage({super.key});

  @override
  State<CycleLoggingPage> createState() => _CycleLoggingPageState();
}

class _CycleLoggingPageState extends State<CycleLoggingPage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime? _lastPeriodDate;
  bool _isLoading = true;
  List<CycleData> _cycleHistory = [];
  CycleAnalysisResult? _analysisResult;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchCycleData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── DATA FETCHING ──────────────────────────────────────────────────────────

  Future<void> _fetchCycleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      DateTime? currentCycleStart;
      if (userDoc.exists && userDoc.data()!.containsKey('lastPeriodDate')) {
        currentCycleStart = (userDoc['lastPeriodDate'] as Timestamp).toDate();
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles')
          .orderBy('startDate', descending: true)
          .limit(4)
          .get();

      final history = querySnapshot.docs
          .map((doc) => CycleData.fromFirestore(doc))
          .toList();

      if (!mounted) return;
      setState(() {
        _lastPeriodDate = currentCycleStart;
        _cycleHistory = history;
        _analysisResult = _analyzeCycles(history, currentCycleStart);
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error fetching data: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logPeriodStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'lastPeriodDate': Timestamp.fromDate(_selectedDate)},
          SetOptions(merge: true));
      await _fetchCycleData();
      if (!mounted) return;
      _showSnack("Period start date logged! 🌸");
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error logging date: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : CycleTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── ANALYSIS ──────────────────────────────────────────────────────────────

  CycleAnalysisResult? _analyzeCycles(
      List<CycleData> completedCycles, DateTime? currentCycleStartDate) {
    if (completedCycles.length < 2) return null;

    List<int> cycleLengths = [];
    for (int i = 0; i < completedCycles.length - 1; i++) {
      cycleLengths.add(completedCycles[i]
          .startDate
          .difference(completedCycles[i + 1].startDate)
          .inDays);
    }
    if (cycleLengths.isEmpty) return null;

    final periodLengths = completedCycles.map((c) => c.periodLength).toList();
    double avgCycleLength =
        cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    double avgPeriodLength =
        periodLengths.reduce((a, b) => a + b) / periodLengths.length;
    int variation = cycleLengths.reduce(max) - cycleLengths.reduce(min);

    if (variation > 10 && cycleLengths.length >= 3) {
      avgCycleLength =
          (cycleLengths[0] * 3 + cycleLengths[1] * 2 + cycleLengths[2] * 1) /
              6.0;
    }

    final String cycleStatus =
        (avgCycleLength >= 21 && avgCycleLength <= 35) ? "Healthy" : "Poor";
    final String periodStatus = (avgPeriodLength >= 3 && avgPeriodLength <= 8)
        ? "Regular"
        : "Irregular";
    final String variationStatus = variation <= 7
        ? "Healthy"
        : variation <= 10
            ? "Slightly Irregular"
            : "Irregular";

    final DateTime? lastValidStartDate = currentCycleStartDate ??
        (completedCycles.isNotEmpty ? completedCycles.first.startDate : null);

    DateTime? nextPeriodDate, ovulationDate, fertileStart, fertileEnd;
    if (lastValidStartDate != null) {
      nextPeriodDate =
          lastValidStartDate.add(Duration(days: avgCycleLength.round()));
      ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
      fertileStart = ovulationDate.subtract(const Duration(days: 5));
      fertileEnd = ovulationDate.add(const Duration(days: 1));
    }

    return CycleAnalysisResult(
      avgCycleLength: avgCycleLength,
      avgPeriodLength: avgPeriodLength,
      variation: variation,
      nextPeriodDate: nextPeriodDate,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      cycleStatus: cycleStatus,
      periodStatus: periodStatus,
      variationStatus: variationStatus,
    );
  }

  // ── EDIT HISTORY DIALOG ───────────────────────────────────────────────────

  Future<void> _showEditHistoryDialog() async {
    List<CycleData> dialogHistory = List.from(_cycleHistory);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: CycleTheme.surface,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: CycleTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_calendar,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Edit Cycle History",
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CycleTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogHistory.length + 1,
                        itemBuilder: (context, index) {
                          if (index == dialogHistory.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    dialogHistory.insert(
                                      0,
                                      CycleData(
                                        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                                        startDate: DateTime.now(),
                                        endDate: DateTime.now(),
                                      ),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.add,
                                    color: CycleTheme.primary),
                                label: const Text(
                                  "Add a Past Cycle",
                                  style: TextStyle(color: CycleTheme.primary),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: CycleTheme.primaryLight),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            );
                          }

                          final cycle = dialogHistory[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: CycleTheme.divider, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Cycle ${dialogHistory.length - index}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: CycleTheme.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: Colors.red.shade300,
                                            size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => setDialogState(() =>
                                            dialogHistory.removeAt(index)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _dialogDateRow(
                                    label: "Start",
                                    date: cycle.startDate,
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: cycle.startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (d != null) {
                                        setDialogState(() {
                                          dialogHistory[index] = CycleData(
                                            id: cycle.id,
                                            startDate: d,
                                            endDate: cycle.endDate,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  _dialogDateRow(
                                    label: "End  ",
                                    date: cycle.endDate,
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: cycle.endDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (d != null) {
                                        setDialogState(() {
                                          dialogHistory[index] = CycleData(
                                            id: cycle.id,
                                            startDate: cycle.startDate,
                                            endDate: d,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _saveCycleHistory(dialogHistory);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CycleTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogDateRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: CycleTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label:  ${DateFormat.yMMMd().format(date)}",
              style: const TextStyle(
                  fontSize: 13, color: CycleTheme.textSecondary),
            ),
            const Icon(Icons.edit_outlined,
                size: 16, color: CycleTheme.primaryLight),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCycleHistory(List<CycleData> history) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cycles');

      final existingDocs = await collectionRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var cycle in history) {
        if (cycle.endDate.isBefore(cycle.startDate)) {
          if (!mounted) return;
          _showSnack("Error: End date cannot be before start date.",
              isError: true);
          continue;
        }
        batch.set(collectionRef.doc(), {
          'startDate': Timestamp.fromDate(cycle.startDate),
          'endDate': Timestamp.fromDate(cycle.endDate),
        });
      }

      await batch.commit();
      await _fetchCycleData();
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error saving history: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 2,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildCalendarCard(),
                    const SizedBox(height: 20),
                    _buildLogButton(),
                    const SizedBox(height: 24),
                    if (_isLoading) _buildLoadingIndicator(),
                    if (!_isLoading && _analysisResult != null) ...[
                      _buildCurrentCycleCard(),
                      const SizedBox(height: 16),
                      _buildPredictionsCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildCycleSummaryCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: CycleTheme.primary.withValues(alpha: 0.2),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: CycleTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "My Cycle",
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CycleTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _fetchCycleData,
          icon: const Icon(Icons.refresh_rounded, color: CycleTheme.primary),
          tooltip: "Refresh",
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: CycleTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [CycleTheme.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Calendar header strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: CycleTheme.primaryGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Select Date",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            // Calendar picker
            Theme(
              data: ThemeData(
                colorScheme: const ColorScheme.light(
                  primary: CycleTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: CycleTheme.textPrimary,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (newDate) =>
                    setState(() => _selectedDate = newDate),
              ),
            ),
            // Selected date chip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Selected:",
                    style: TextStyle(
                        fontSize: 13, color: CycleTheme.textSecondary),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: CycleTheme.accentWarm,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d yyyy').format(_selectedDate),
                      style: const TextStyle(
                        color: CycleTheme.primaryDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _logPeriodStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: CycleTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              CycleTheme.primaryLight.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 6,
          shadowColor: CycleTheme.primary.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Log Period Start",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: CircularProgressIndicator(color: CycleTheme.primary),
      ),
    );
  }

  // ── CURRENT CYCLE COUNTER CARD ─────────────────────────────────────────────

  Widget _buildCurrentCycleCard() {
    final cycleDays = _lastPeriodDate != null
        ? DateTime.now().difference(_lastPeriodDate!).inDays
        : 0;
    final avgLength = _analysisResult?.avgCycleLength.round() ?? 28;
    final progress = (cycleDays / avgLength).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: CycleTheme.nightGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CycleTheme.nightEnd.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Cycle",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$cycleDays",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 6),
                        child: Text(
                          "days",
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (_lastPeriodDate != null)
                    Text(
                      "Since ${DateFormat('MMM d').format(_lastPeriodDate!)}",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          CycleTheme.accentWarm),
                    ),
                    Text(
                      "${(progress * 100).round()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(CycleTheme.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Day 1",
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text("Day $avgLength",
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── PREDICTIONS CARD ───────────────────────────────────────────────────────

  Widget _buildPredictionsCard() {
    final r = _analysisResult;
    if (r == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CycleTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [CycleTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Predictions",
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CycleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (r.fertileWindowStart != null && r.fertileWindowEnd != null)
            _buildPredictionTile(
              icon: Icons.spa_rounded,
              iconBg: const Color(0xFFFFF0F0),
              iconColor: const Color(0xFFE57373),
              label: "Fertile Window",
              value:
                  "${DateFormat.MMMd().format(r.fertileWindowStart!)} – ${DateFormat.MMMd().format(r.fertileWindowEnd!)}",
            ),
          if (r.ovulationDate != null) ...[
            _buildDividerLine(),
            _buildPredictionTile(
              icon: Icons.brightness_3_rounded,
              iconBg: const Color(0xFFF3E5FF),
              iconColor: const Color(0xFFAB47BC),
              label: "Ovulation",
              value: DateFormat.yMMMd().format(r.ovulationDate!),
            ),
          ],
          if (r.nextPeriodDate != null) ...[
            _buildDividerLine(),
            _buildPredictionTile(
              icon: Icons.water_drop_rounded,
              iconBg: const Color(0xFFFFE8F0),
              iconColor: CycleTheme.primary,
              label: "Next Period",
              value: DateFormat.yMMMd().format(r.nextPeriodDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDividerLine() =>
      const Divider(height: 20, color: CycleTheme.divider, thickness: 1);

  Widget _buildPredictionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: CycleTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CycleTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CYCLE SUMMARY CARD ────────────────────────────────────────────────────

  Widget _buildCycleSummaryCard() {
    final r = _analysisResult;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CycleTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [CycleTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cycle Summary",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CycleTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _showEditHistoryDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CycleTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CycleTheme.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_calendar_outlined,
                          size: 14, color: CycleTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 12,
                          color: CycleTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (r == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CycleTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: CycleTheme.primaryLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Log at least 3 past cycles via 'Edit' to see your summary and predictions.",
                      style: TextStyle(
                          fontSize: 13,
                          color: CycleTheme.textSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          if (r != null) ...[
            _buildSummaryMetric(
              label: "Average cycle",
              value: "${r.avgCycleLength.toStringAsFixed(1)} days",
              status: r.cycleStatus,
              icon: Icons.loop_rounded,
            ),
            Divider(height: 24, color: CycleTheme.divider),
            _buildSummaryMetric(
              label: "Average period",
              value: "${r.avgPeriodLength.toStringAsFixed(1)} days",
              status: r.periodStatus,
              icon: Icons.calendar_today_rounded,
            ),
            Divider(height: 24, color: CycleTheme.divider),
            _buildSummaryMetric(
              label: "Variation",
              value: "±${r.variation} days",
              status: r.variationStatus,
              icon: Icons.show_chart_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required String status,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: CycleTheme.primaryLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style:
                const TextStyle(fontSize: 14, color: CycleTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CycleTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        _buildStatusChip(status),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'healthy':
      case 'regular':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF388E3C);
        break;
      case 'slightly irregular':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFF57C00);
        break;
      case 'irregular':
      case 'poor':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFD32F2F);
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
