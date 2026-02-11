import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SymptomTrackingPage extends StatefulWidget {
  const SymptomTrackingPage({super.key});

  @override
  State<SymptomTrackingPage> createState() => _SymptomTrackingPageState();
}

class _SymptomTrackingPageState extends State<SymptomTrackingPage> {
  // 🔹 STATE VARIABLES
  
  // Cycle & Body Pain
  final Map<String, bool> _cycleSymptoms = {
    "Bleeding": false,
    "Spotting": false,
    "Cramps": false,
    "Pelvic Discomfort": false,
  };

  // Energy & Sleep
  final Map<String, bool> _energySymptoms = {
    "Fatigue": false,
    "Low Energy": false,
    "Poor Sleep": false,
    "Daytime Sleepiness": false,
  };
  double _energyLevel = 3.0; // 1 to 5

  // Mood & Mental State
  final Map<String, bool> _moodSymptoms = {
    "Mood Swings": false,
    "Anxiety": false,
    "Irritability": false,
    "Low Mood": false,
    "Brain Fog": false,
  };
  String _moodRating = "Neutral"; // Sad, Neutral, Happy

  // Hormonal & Skin
  final Map<String, bool> _hormonalSymptoms = {
    "Acne Flare-up": false,
    "Oily Skin": false,
    "Hair Fall": false,
    "Excess Sweating": false,
  };

  // Metabolic & Appetite
  final Map<String, bool> _metabolicSymptoms = {
    "Sugar Cravings": false,
    "Extreme Hunger": false,
    "Bloating": false,
    "Energy Crash": false,
  };
  String _cravingIntensity = "None"; // None, Mild, Strong

  // Digestive & Physical
  final Map<String, bool> _digestiveSymptoms = {
    "Constipation": false,
    "Indigestion": false,
    "Headache": false,
    "Breast Tenderness": false,
  };

  bool _isLoading = false;

  // 🔹 COLORS (Pastel Palette)
  final Color _lavender = const Color(0xFFE6E6FA);
  final Color _blush = const Color(0xFFFFE4E1);
  final Color _mint = const Color(0xFFF0FFF0);
  final Color _offWhite = const Color(0xFFFAFAFA);
  final Color _textDark = const Color(0xFF424242);
  final Color _primaryColor = const Color(0xFF9FA8DA); // Soft Indigo/Lavender

  // 🔹 SAVE FUNCTION
  Future<void> _saveLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final logData = {
        "date": Timestamp.now(),
        "cycle_pain": _cycleSymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
        "energy_sleep": _energySymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
        "energy_level": _energyLevel,
        "mood_mental": _moodSymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
        "mood_rating": _moodRating,
        "hormonal_skin": _hormonalSymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
        "metabolic_appetite": _metabolicSymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
        "craving_intensity": _cravingIntensity,
        "digestive_physical": _digestiveSymptoms.entries.where((e) => e.value).map((e) => e.key).toList(),
      };

      // Save to subcollection 'daily_logs'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_logs')
          .doc(dateKey)
          .set(logData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Daily log saved successfully! 🌸")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving log: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        title: Text("Daily Check-in", style: TextStyle(color: _textDark, fontWeight: FontWeight.w600)),
        backgroundColor: _lavender,
        elevation: 0,
        iconTheme: IconThemeData(color: _textDark),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌸 Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _mint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.spa, color: Colors.teal, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Symptoms vary daily. Tracking helps identify patterns over time.",
                            style: TextStyle(color: Colors.teal.shade700, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Cycle & Body Pain
                  _buildSectionTitle("🩸 Cycle & Body Pain"),
                  _buildChipGroup(_cycleSymptoms, _blush),

                  const SizedBox(height: 24),

                  // 2. Energy & Sleep
                  _buildSectionTitle("💤 Energy & Sleep"),
                  _buildChipGroup(_energySymptoms, Colors.blue.shade50),
                  const SizedBox(height: 12),
                  const Text("Energy Level", style: TextStyle(fontWeight: FontWeight.w500)),
                  Slider(
                    value: _energyLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _energyLevel.round().toString(),
                    activeColor: _primaryColor,
                    onChanged: (val) => setState(() => _energyLevel = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Low", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("High", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Mood & Mental State
                  _buildSectionTitle("🧠 Mood & Mental State"),
                  _buildChipGroup(_moodSymptoms, Colors.purple.shade50),
                  const SizedBox(height: 16),
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: "Sad", icon: Icon(Icons.sentiment_dissatisfied)),
                        ButtonSegment(value: "Neutral", icon: Icon(Icons.sentiment_neutral)),
                        ButtonSegment(value: "Happy", icon: Icon(Icons.sentiment_satisfied)),
                      ],
                      selected: {_moodRating},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _moodRating = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _primaryColor.withOpacity(0.3);
                          }
                          return Colors.white;
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Hormonal & Skin
                  _buildSectionTitle("✨ Hormonal & Skin"),
                  _buildChipGroup(_hormonalSymptoms, Colors.orange.shade50),

                  const SizedBox(height: 24),

                  // 5. Metabolic & Appetite
                  _buildSectionTitle("🍽️ Metabolic & Appetite"),
                  _buildChipGroup(_metabolicSymptoms, Colors.green.shade50),
                  const SizedBox(height: 12),
                  const Text("Craving Intensity", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: ["None", "Mild", "Strong"].map((intensity) {
                      final isSelected = _cravingIntensity == intensity;
                      return ChoiceChip(
                        label: Text(intensity),
                        selected: isSelected,
                        selectedColor: Colors.pinkAccent.withOpacity(0.2),
                        onSelected: (val) => setState(() => _cravingIntensity = intensity),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 6. Digestive & Physical
                  _buildSectionTitle("🧘 Digestive & Physical"),
                  _buildChipGroup(_digestiveSymptoms, Colors.brown.shade50),

                  const SizedBox(height: 40),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Save Today’s Log",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _buildChipGroup(Map<String, bool> symptoms, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: symptoms.keys.map((key) {
          final isSelected = symptoms[key]!;
          return FilterChip(
            label: Text(key),
            selected: isSelected,
            onSelected: (bool value) {
              setState(() {
                symptoms[key] = value;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: _primaryColor.withOpacity(0.3),
            checkmarkColor: _primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black87 : Colors.black54,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
