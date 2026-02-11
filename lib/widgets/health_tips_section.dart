import 'package:flutter/material.dart';

class HealthTip {
  final IconData icon;
  final String title;
  final String content;
  final Gradient gradient;
  final Color iconBg;
  final Color iconColor;

  HealthTip({
    required this.icon,
    required this.title,
    required this.content,
    required this.gradient,
    required this.iconBg,
    required this.iconColor,
  });
}

final List<HealthTip> healthTips = [
  HealthTip(
    icon: Icons.apple,
    title: "Nutrition Tip",
    content:
        "Include colorful fruits and vegetables in every meal. They're packed with essential vitamins and antioxidants.",
    gradient: LinearGradient(colors: [Color(0xFFFFE4E6), Color(0xFFFFEDD5)]),
    iconBg: Color(0xFFFECACA),
    iconColor: Color(0xFFDC2626),
  ),
  HealthTip(
    icon: Icons.directions_run,
    title: "Movement Matters",
    content:
        "Aim for at least 30 minutes of moderate exercise daily. Even a brisk walk improves mood.",
    gradient: LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFCFFAFE)]),
    iconBg: Color(0xFFBFDBFE),
    iconColor: Color(0xFF2563EB),
  ),
  HealthTip(
    icon: Icons.nightlight_round,
    title: "Sleep Well",
    content:
        "Quality sleep supports hormone balance. Aim for 7–9 hours in a calm environment.",
    gradient: LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF3E8FF)]),
    iconBg: Color(0xFFC7D2FE),
    iconColor: Color(0xFF4F46E5),
  ),
  HealthTip(
    icon: Icons.water_drop,
    title: "Hydration",
    content:
        "Drink at least 8 glasses of water daily. Hydration supports metabolism and skin health.",
    gradient: LinearGradient(colors: [Color(0xFFECFEFF), Color(0xFFCCFBF1)]),
    iconBg: Color(0xFF99F6E4),
    iconColor: Color(0xFF0D9488),
  ),
  HealthTip(
    icon: Icons.favorite,
    title: "Stress Management",
    content:
        "Practice mindfulness daily. Reducing stress improves hormonal balance.",
    gradient: LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFFE4E6)]),
    iconBg: Color(0xFFFBCFE8),
    iconColor: Color(0xFFDB2777),
  ),
];

class HealthTipsSection extends StatefulWidget {
  const HealthTipsSection({super.key});

  @override
  State<HealthTipsSection> createState() => _HealthTipsSectionState();
}

class _HealthTipsSectionState extends State<HealthTipsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RotationTransition(
              turns: Tween(begin: -0.02, end: 0.02).animate(_controller),
              child:
                  const Icon(Icons.auto_awesome, size: 30, color: Colors.amber),
            ),
            const SizedBox(width: 8),
            const Text(
              "Daily Health Tips",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: healthTips.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            return _HealthTipCard(tip: healthTips[index]);
          },
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(168, 85, 247, 0.4),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: const Column(
            children: [
              Text("✨ Remember ✨",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 10),
              Text(
                "Your health journey is unique. Be patient and celebrate small wins.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthTipCard extends StatefulWidget {
  final HealthTip tip;

  const _HealthTipCard({required this.tip});

  @override
  State<_HealthTipCard> createState() => _HealthTipCardState();
}

class _HealthTipCardState extends State<_HealthTipCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: widget.tip.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(pressed ? 0.18 : 0.1),
              blurRadius: pressed ? 40 : 25,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.tip.iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(widget.tip.icon, color: widget.tip.iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(widget.tip.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.tip.content),
          ],
        ),
      ),
    );
  }
}
