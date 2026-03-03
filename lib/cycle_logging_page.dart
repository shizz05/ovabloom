import 'package:pcos_app/widgets/app_scaffold.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────── DATA MODELS ──────────────────────────────────

class CycleData {
  final String id;
  final DateTime startDate;
  final int
      cycleLength; // stored integer — derived from consecutive start_dates
  final int periodLength; // stored integer — optional, defaults to 5

  CycleData({
    required this.id,
    required this.startDate,
    this.cycleLength = 28,
    this.periodLength = 5,
  });

  /// Construct from a Supabase row (Map<String, dynamic>)
  factory CycleData.fromSupabase(Map<String, dynamic> row) {
    return CycleData(
      id: row['id'].toString(),
      startDate: DateTime.parse(row['start_date'] as String),
      cycleLength: (row['cycle_length'] as num?)?.toInt() ?? 28,
      periodLength: (row['period_length'] as num?)?.toInt() ?? 5,
    );
  }

  /// Predicted next period start for this cycle
  DateTime get predictedNextStart => startDate.add(Duration(days: cycleLength));
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
  final _supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();
  DateTime? _lastPeriodDate;
  bool _isLoading = true;
  List<CycleData> _cycleHistory = [];
  CycleAnalysisResult? _analysisResult;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Flo-style constants ───────────────────────────────────────
  static const int _minCycleLength = 15;
  static const int _maxCycleLength = 60;

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

  // ── DATA FETCHING ─────────────────────────────────────────────────────────

  /// Fetches all cycles from the 'cycles' table ordered by start_date DESC.
  /// Derives rolling cycle lengths dynamically from consecutive start_date
  /// differences — exactly as Flo does.
  Future<void> _fetchCycleData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final rows = await _supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .order('start_date', ascending: false);

      final allCycles = (rows as List)
          .map((row) => CycleData.fromSupabase(row as Map<String, dynamic>))
          .toList();

      // Show most recent 4 in the edit dialog
      final recentHistory = allCycles.take(4).toList();

      if (!mounted) return;
      setState(() {
        _lastPeriodDate =
            allCycles.isNotEmpty ? allCycles.first.startDate : null;
        _cycleHistory = recentHistory;
        _analysisResult = _analyzeCycles(allCycles);
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error fetching data: $e", isError: true);
      setState(() => _isLoading = false);
    }
  }

  // ── HELPER: Derive valid cycle lengths from sorted cycle list ─────────────

  /// Given a list of cycles sorted by start_date DESC, derives realistic
  /// cycle lengths by computing differences between consecutive start_dates.
  /// Filters out values outside [_minCycleLength, _maxCycleLength].
  ///
  /// Returns lengths ordered from most recent to oldest.
  List<int> _deriveCycleLengths(List<CycleData> cycles) {
    if (cycles.length < 2) return [];

    final lengths = <int>[];
    for (int i = 0; i < cycles.length - 1; i++) {
      // cycles[i] is newer, cycles[i+1] is older
      final diff =
          cycles[i].startDate.difference(cycles[i + 1].startDate).inDays;
      if (diff >= _minCycleLength && diff <= _maxCycleLength) {
        lengths.add(diff);
      }
    }
    return lengths;
  }

  // ── HELPER: Weighted average (Flo-style) ─────────────────────────────────

  /// Applies Flo-style weighted smoothing to derived cycle lengths.
  /// Weights: most recent = 3, second = 2, third = 1.
  /// Falls back to simple average if fewer than 3 valid lengths.
  double _weightedAvgCycleLength(List<int> lengths) {
    if (lengths.isEmpty) return 28.0;
    if (lengths.length == 1) return lengths[0].toDouble();
    if (lengths.length == 2) {
      return (lengths[0] * 2 + lengths[1] * 1) / 3.0;
    }
    // Use only the 3 most recent for weighting
    return (lengths[0] * 3 + lengths[1] * 2 + lengths[2] * 1) / 6.0;
  }

  // ── LOG PERIOD START ──────────────────────────────────────────────────────

  /// Flo-style period logging:
  ///   1. Fetch the most recent existing cycle.
  ///   2. Derive the previous cycle length = new_start - last_start.
  ///   3. Only store if length is between 15 and 60 days.
  ///   4. Insert a new row — NEVER modify or delete previous rows.
  Future<void> _logPeriodStart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      // Step 1: Fetch most recent cycle
      final latestRow = await _supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      // Step 2: Derive cycle length from gap between start_dates
      int derivedCycleLength = 28; // fallback only used if no prior cycle
      int derivedPeriodLength = 5; // default period length

      if (latestRow != null) {
        final lastCycle =
            CycleData.fromSupabase(latestRow as Map<String, dynamic>);
        final gapDays = _selectedDate.difference(lastCycle.startDate).inDays;

        // Step 3: Only use realistic gaps
        if (gapDays >= _minCycleLength && gapDays <= _maxCycleLength) {
          derivedCycleLength = gapDays;
        } else if (gapDays > 0) {
          // Gap exists but outside realistic range — keep prior stored value
          // as the best available estimate rather than hardcoding 28
          derivedCycleLength = lastCycle.cycleLength;
        }
        // Carry forward period_length from most recent cycle
        derivedPeriodLength = lastCycle.periodLength;
      }

      // Step 4: Insert new cycle row — never touch previous rows
      await _supabase.from('cycles').insert({
        'user_id': user.id,
        'start_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'cycle_length': derivedCycleLength,
        'period_length': derivedPeriodLength,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

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

  // ── ANALYSIS (Flo-style) ──────────────────────────────────────────────────

  /// Flo-style cycle analysis:
  ///
  ///   1. Derive actual cycle lengths from consecutive start_date differences.
  ///   2. Filter out unrealistic lengths (<15 or >60 days).
  ///   3. Apply weighted smoothing on the last 3 valid lengths.
  ///   4. Anchor all predictions to the most recent start_date.
  ///
  /// Predictions:
  ///   next_period  = anchor + weighted_avg
  ///   ovulation    = next_period - 14
  ///   fertile_start = ovulation - 5
  ///   fertile_end  = ovulation + 1
  CycleAnalysisResult? _analyzeCycles(List<CycleData> allCycles) {
    if (allCycles.isEmpty) return null;

    // Derive realistic cycle lengths from consecutive start_date differences
    final derivedLengths = _deriveCycleLengths(allCycles);

    // Need at least one derived length for meaningful analysis
    // If we only have one logged cycle (no gap to measure), show a
    // partial result anchored to that cycle's stored length as a seed.
    final double weightedAvg;
    final int variation;
    final double avgPeriodLength;

    if (derivedLengths.isEmpty) {
      // Only one entry exists — use its stored cycle_length as the seed
      weightedAvg = allCycles.first.cycleLength.toDouble();
      variation = 0;
    } else {
      weightedAvg = _weightedAvgCycleLength(derivedLengths);
      variation = derivedLengths.length > 1
          ? derivedLengths.reduce(max) - derivedLengths.reduce(min)
          : 0;
    }

    // Average period length from stored values (period_length is user-reported)
    final periodLengths = allCycles.map((c) => c.periodLength).toList();
    avgPeriodLength =
        periodLengths.reduce((a, b) => a + b) / periodLengths.length;

    // ── Status labels ──────────────────────────────────────────
    final String cycleStatus =
        (weightedAvg >= 21 && weightedAvg <= 35) ? "Healthy" : "Poor";
    final String periodStatus = (avgPeriodLength >= 3 && avgPeriodLength <= 8)
        ? "Regular"
        : "Irregular";
    final String variationStatus = variation <= 7
        ? "Healthy"
        : variation <= 10
            ? "Slightly Irregular"
            : "Irregular";

    // ── Predictions anchored to most recent start_date ─────────
    final DateTime anchor = allCycles.first.startDate;

    final nextPeriodDate = anchor.add(Duration(days: weightedAvg.round()));
    final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    return CycleAnalysisResult(
      avgCycleLength: weightedAvg,
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
                                        cycleLength: 28,
                                        periodLength: 5,
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
                                            cycleLength: cycle.cycleLength,
                                            periodLength: cycle.periodLength,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  _dialogInfoRow(
                                    label: "Cycle ",
                                    value: "${cycle.cycleLength} days",
                                  ),
                                  const SizedBox(height: 4),
                                  _dialogInfoRow(
                                    label: "Period",
                                    value: "${cycle.periodLength} days",
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

  Widget _dialogInfoRow({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CycleTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:  $value",
            style:
                const TextStyle(fontSize: 13, color: CycleTheme.textSecondary),
          ),
          const Icon(Icons.info_outline,
              size: 14, color: CycleTheme.primaryLight),
        ],
      ),
    );
  }

  /// Saves edited cycle history to the 'cycles' table.
  /// After re-inserting, re-derives and updates stored cycle_length values
  /// so the DB stays consistent with the Flo-style derivation approach.
  Future<void> _saveCycleHistory(List<CycleData> history) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _supabase.from('cycles').delete().eq('user_id', user.id);

      if (history.isNotEmpty) {
        // Sort ascending for insertion and derivation
        final sorted = List<CycleData>.from(history)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

        final rows = <Map<String, dynamic>>[];
        for (int i = 0; i < sorted.length; i++) {
          final cycle = sorted[i];
          int storedLength = cycle.cycleLength;

          // Re-derive cycle_length from the gap to the next start_date
          if (i < sorted.length - 1) {
            final gap =
                sorted[i + 1].startDate.difference(cycle.startDate).inDays;
            if (gap >= _minCycleLength && gap <= _maxCycleLength) {
              storedLength = gap;
            }
          }

          rows.add({
            'user_id': user.id,
            'start_date': DateFormat('yyyy-MM-dd').format(cycle.startDate),
            'cycle_length': storedLength,
            'period_length': cycle.periodLength,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        }

        await _supabase.from('cycles').insert(rows);
      }

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
