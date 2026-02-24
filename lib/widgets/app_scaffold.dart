import 'package:flutter/material.dart';
import 'package:pcos_app/widgets/custom_bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;

  const AppScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: currentIndex,
      ),
    );
  }
}
