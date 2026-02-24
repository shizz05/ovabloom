import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/screens/insight_page.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.selectedIndex;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const InsightPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color selectedColor = Colors.black87;
    const Color unselectedColor = Color(0xFF757575);

    final logoStyle = GoogleFonts.greatVibes(
      textStyle: const TextStyle(
        fontSize: 28,
        color: Color(0xFF3D3D3D),
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6ED),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 HOME ICON
              GestureDetector(
                onTap: () => _onTabTapped(0),
                child: Icon(
                  Icons.home_outlined,
                  size: 26,
                  color: _currentIndex == 0 ? selectedColor : unselectedColor,
                ),
              ),

              // 🔹 CENTER LOGO TEXT
              Text(
                "OvaBloom",
                style: logoStyle,
              ),

              // 🔹 INSIGHTS ICON
              GestureDetector(
                onTap: () => _onTabTapped(1),
                child: Icon(
                  Icons.bar_chart_outlined,
                  size: 26,
                  color: _currentIndex == 1 ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
