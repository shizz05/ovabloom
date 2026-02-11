import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CycleLoggingPage extends StatefulWidget {
  const CycleLoggingPage({super.key});

  @override
  State<CycleLoggingPage> createState() => _CycleLoggingPageState();
}

class _CycleLoggingPageState extends State<CycleLoggingPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _lastPeriodDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCycleData();
  }

  Future<void> _fetchCycleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('lastPeriodDate')) {
        setState(() {
          _lastPeriodDate = (doc['lastPeriodDate'] as Timestamp).toDate();
        });
      }
    } catch (e) {
      print("Error fetching cycle data: $e");
    }
  }

  Future<void> _logPeriodStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastPeriodDate': Timestamp.fromDate(_selectedDate),
      }, SetOptions(merge: true));

      setState(() {
        _lastPeriodDate = _selectedDate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Period start date logged!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging date: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cycle Logging"),
        backgroundColor: const Color(0xFF679f9e),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 ACTUAL CALENDAR WIDGET
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.pinkAccent, // Pink selection color
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 SELECTED DATE INFO
            Text(
              "Selected Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            if (_lastPeriodDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Current Cycle Start: ${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 🔹 LOG PERIOD BUTTON
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _logPeriodStart,
              icon: const Icon(Icons.water_drop, color: Colors.white),
              label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Log Period Start Here"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 LOGGING OPTIONS (Placeholder for future functionality)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(Icons.water_drop, "Flow", Colors.redAccent),
                  _buildOptionButton(Icons.mood, "Mood", Colors.amber),
                  _buildOptionButton(Icons.healing, "Pain", Colors.purpleAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
