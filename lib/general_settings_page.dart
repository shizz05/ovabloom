import 'package:flutter/material.dart';
import 'package:pcos_app/view/chat/app_lock_settings_page.dart';
import 'package:pcos_app/view/chat/help_desk.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('General Settings', style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ──────────────────────────────
              Text(
                'System Theme',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a color palette for the app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),

              // ── Theme palettes ──────────────────────────────
              _buildThemePalette(context, 'Sakura Kiss', AppThemes.sakuraKiss),
              _buildThemePalette(
                  context, 'Violet Breeze', AppThemes.violetBreeze),
              _buildThemePalette(context, 'Blush Petal', AppThemes.blushPetal),
              _buildThemePalette(
                  context, 'Sunset Petal', AppThemes.sunsetPetal),

              const SizedBox(height: 32),

              // ── Section header ──────────────────────────────
              Text(
                'More Options',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),

              // ── Settings tiles ──────────────────────────────
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQs, contact & resources',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpDesk()),
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline_rounded,
                title: 'App Lock',
                subtitle: 'PIN, biometric & security',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppLockSettingsPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePalette(
      BuildContext context, String name, ThemeData themeData) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentTheme = Theme.of(context);
    final isSelected = currentTheme.primaryColor == themeData.primaryColor;

    return GestureDetector(
      onTap: () => themeProvider.setTheme(themeData),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: currentTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeData.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Color swatches
              Row(
                children: [
                  _buildColorSwatch(themeData.primaryColor),
                  _buildColorSwatch(themeData.colorScheme.secondary),
                  _buildColorSwatch(themeData.colorScheme.surface),
                  _buildColorSwatch(themeData.scaffoldBackgroundColor),
                ],
              ),
              const SizedBox(width: 16),
              // Theme name
              Expanded(
                child: Text(
                  name,
                  style: currentTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              // Selected checkmark
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: themeData.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
