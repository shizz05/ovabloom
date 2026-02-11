import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_details_page.dart';
import 'cycle_logging_page.dart';
import 'symptom_tracking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  
  // 🔹 STATE
  DateTime _selectedDate = DateTime.now(); // The date selected in the horizontal strip
  DateTime? _lastPeriodDate;
  String? _userName;
  User? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    
    // Scroll to the middle of the calendar strip to show "today"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(58.0 * 13); // Adjust based on item width + margin
      }
    });
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;
    
    // 1. Reload Auth User to get latest displayName
    await _currentUser?.reload();
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });

    try {
      // 2. Fetch from Firestore
      print("Fetching user data for uid: ${_currentUser!.uid}");
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      
      if (doc.exists) {
        print("User document found: ${doc.data()}");
        final data = doc.data()!;
        setState(() {
          if (data.containsKey('lastPeriodDate')) {
            _lastPeriodDate = (data['lastPeriodDate'] as Timestamp).toDate();
          }
          if (data.containsKey('name')) {
            _userName = data['name'];
          }
        });
      } else {
        print("User document does not exist in Firestore.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Helper: Month Name
  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  // Helper: Weekday Name
  String _getWeekday(int weekday) {
    const days = ["M", "T", "W", "T", "F", "S", "S"];
    return days[weekday - 1];
  }

  // 🔹 CYCLE CALCULATION LOGIC
  int _calculateCycleDay() {
    if (_lastPeriodDate == null) return 0;
    final sDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final pDate = DateTime(_lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);
    return sDate.difference(pDate).inDays + 1;
  }

  Map<String, dynamic> _getCycleDisplayData(int cycleDay) {
    if (cycleDay == 0) {
      return {
        "title": "Log your period",
        "mainText": "?",
        "subtitle": "to track ovulation",
        "color": Colors.grey.shade300,
        "progress": 0.0,
      };
    }

    if (cycleDay < 1) {
       return {
        "title": "Days until period",
        "mainText": "${cycleDay.abs()}",
        "subtitle": "Predicted start",
        "color": Colors.purple.shade200,
        "progress": 0.9,
      };
    } else if (cycleDay >= 1 && cycleDay <= 5) {
      return {
        "title": "Period Day",
        "mainText": "$cycleDay",
        "subtitle": "Low chance of pregnancy",
        "color": const Color(0xFFFF5252), // Red/Pink
        "progress": cycleDay / 5.0 * 0.25, // First quarter
      };
    } else if (cycleDay >= 10 && cycleDay <= 16) {
      // Fertile window
      int daysToOvulation = 14 - cycleDay;
      String title = "Fertile Window";
      String mainText = "Day $cycleDay";
      
      if (daysToOvulation == 0) {
        title = "Ovulation Day";
        mainText = "Today";
      } else if (daysToOvulation > 0) {
        title = "Ovulation in";
        mainText = "$daysToOvulation days";
      }

      return {
        "title": title,
        "mainText": mainText,
        "subtitle": "High chance of getting pregnant",
        "color": const Color(0xFF00BFA5), // Teal
        "progress": 0.35 + ((cycleDay - 10) / 6.0 * 0.15), // Middle section
      };
    } else {
      // Luteal / Follicular
      return {
        "title": "Cycle Day",
        "mainText": "$cycleDay",
        "subtitle": "Low chance of pregnancy",
        "color": const Color(0xFF7E57C2), // Purple
        "progress": cycleDay / 28.0, // General progress
      };
    }
  }

  // 🔹 SHOW SYMPTOM SHEET (Now navigates to full page)
  void _showSymptomLoggingSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SymptomTrackingPage()),
    );
  }

  // Old helper for chips removed as they are now in the full page

  // 🔹 SHOW GLUCOSE DIALOG
  void _showGlucoseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Glucose"),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "mg/dL",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: "mg/dL",
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Glucose reading saved!")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycleDay = _calculateCycleDay();
    final displayData = _getCycleDisplayData(cycleDay);
    final primaryColor = displayData["color"] as Color;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 TOP SECTION WITH GRADIENT
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2F1), // Light Teal
                    Colors.white, // Fade to white
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 🔸 HEADER (Avatar - Date - Calendar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // User Profile Icon
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UserDetailsPage()),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orangeAccent,
                              child: Icon(Icons.face, color: Colors.white), 
                            ),
                          ),
                          
                          // Date (Selected Date)
                          Text(
                            "${_getMonthName(_selectedDate.month)} ${_selectedDate.day}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          // Calendar Icon
                          IconButton(
                            icon: const Icon(Icons.calendar_month, color: Colors.black87),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CycleLoggingPage()),
                              ).then((_) => _fetchUserData()); // Refresh on return
                            },
                          ),
                        ],
                      ),
                    ),

                    // 🔸 HELLO USER
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Hello, ${_userName ?? _currentUser?.displayName ?? 'User'} 👋",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // 🔸 CONTINUOUS CALENDAR STRIP
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        // Create a large number of items to simulate infinite scroll
                        itemCount: 365 * 2, 
                        itemBuilder: (context, index) {
                          // Let index 0 be some days in the past (e.g. 15 days ago)
                          // But to center "Today", let's say index 15 is today.
                          final now = DateTime.now();
                          final initialDate = now.subtract(const Duration(days: 15));
                          final date = initialDate.add(Duration(days: index));
                          
                          final isSelected = date.day == _selectedDate.day && 
                                             date.month == _selectedDate.month && 
                                             date.year == _selectedDate.year;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: Container(
                              width: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getWeekday(date.weekday),
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${date.day}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔸 MAIN CIRCULAR INDICATOR (Flo Style)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Circle
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 25,
                            ),
                          ),
                        ),
                        // Progress Indicator
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: displayData["progress"],
                            strokeWidth: 25,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withValues(alpha: 0.6)),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Inner Dashed/Decorative Circle (Optional, simple for now)
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          ),
                        ),
                        // Text Content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayData["title"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              displayData["mainText"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              displayData["subtitle"],
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 12),
                            // Log Period Button (Small pill)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CycleLoggingPage()),
                                ).then((_) => _fetchUserData());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Log Period",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 🔹 INSIGHTS SECTION
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My daily insights · Today",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Horizontal Cards
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildInsightCard(
                          title: "Log your\nsymptoms",
                          icon: Icons.add,
                          iconColor: Colors.pinkAccent,
                          bgColor: Colors.white,
                          borderColor: Colors.grey.shade200,
                          onTap: _showSymptomLoggingSheet,
                        ),
                        _buildInsightCard(
                          title: "Glucose\nreadings",
                          icon: Icons.water_drop,
                          iconColor: Colors.blueAccent,
                          bgColor: const Color(0xFFE3F2FD), // Light Blue
                          borderColor: Colors.blue.shade100,
                          onTap: _showGlucoseDialog,
                        ),
                        _buildInsightCard(
                          title: "Analytics",
                          icon: Icons.bar_chart,
                          iconColor: Colors.deepPurpleAccent,
                          bgColor: const Color(0xFFEDE7F6), // Light Purple
                          borderColor: Colors.deepPurple.shade100,
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Analytics feature coming soon!")),
                             );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 BOTTOM BANNER (Sleep/Reports)
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF311B92), // Deep Purple
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.nightlight_round, size: 16, color: Colors.purple),
                                  SizedBox(width: 4),
                                  Text("Sleep", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.insert_chart, size: 16, color: Colors.black87),
                                  SizedBox(width: 4),
                                  Text("Reports", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            label: 'Secret Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Partner',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    required Color bgColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (icon != null && subtitle == null)
               Align(
                alignment: Alignment.bottomCenter,
                 child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.pinkAccent,
                  child: Icon(icon, color: Colors.white, size: 20),
                 ),
               ),
            if (subtitle != null)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (icon != null) Icon(icon, color: iconColor, size: 30),
                   if (icon != null) const SizedBox(height: 4),
                   Text(
                     subtitle,
                     style: const TextStyle(
                       color: Colors.black54,
                       fontSize: 13,
                     ),
                   ),
                 ],
               ),
          ],
        ),
      ),
    );
  }
}
