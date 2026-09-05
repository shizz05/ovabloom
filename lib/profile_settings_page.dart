import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pcos_app/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:pcos_app/logo_page.dart';
import 'avatar_creation_page.dart';
import 'lifestyle_settings_page.dart';
import 'account_details_page.dart';
import 'general_settings_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage>
    with SingleTickerProviderStateMixin {
  String _avatarUrl = 'assets/avatars/1.png';
  String _userName = 'kiooooo';
  String _userEmail = 'cat2@gmail.com';

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));
    _animationController!.forward();
    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final data = await supabase
            .from('users')
            .select('avatar_url, name') // ✅ snake_case
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _avatarUrl = data['avatar_url'] ?? _avatarUrl; // ✅ snake_case
            _userName = data['name'] ?? _userName;
            _userEmail = user.email ?? _userEmail;
          });
        }
      } catch (e) {
        debugPrint('Fetch user data failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return AppScaffold(
      currentIndex: 3,
      body: FadeTransition(
        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position:
              _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero header with gradient ──────────────────────────────
                _ProfileHeader(
                  avatarUrl: _avatarUrl,
                  userName: _userName,
                  userEmail: _userEmail,
                  colorScheme: colorScheme,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AvatarCreationPage(),
                      ),
                    );
                    _fetchUserData();
                  },
                ),

                // ── Settings list ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'My Profile', theme: theme),
                      const SizedBox(height: 10),
                      _SettingsTile(
                        icon: Icons.person_rounded,
                        title: 'Account Details',
                        subtitle: 'Edit your personal info',
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            _fadeRoute(const AccountDetailsPage()),
                          ).then((_) => _fetchUserData());
                        },
                      ),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.favorite_rounded,
                        title: 'Lifestyle Settings',
                        subtitle: 'Health & activity preferences',
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            _fadeRoute(const LifestyleSettingsPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'App', theme: theme),
                      const SizedBox(height: 10),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'General Settings',
                        subtitle: 'Notifications, theme & more',
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            _fadeRoute(const GeneralSettingsPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      _LogOutButton(
                        colorScheme: colorScheme,
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LogoPage()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Profile header with gradient card
// ────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String avatarUrl;
  final String userName;
  final String userEmail;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.avatarUrl,
    required this.userName,
    required this.userEmail,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          bottom: 36,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: CircleAvatar(
                    radius: size.width * 0.13,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: size.width * 0.125,
                      backgroundImage: AssetImage(avatarUrl),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap to change avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section label
// ────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: theme.colorScheme.primary.withOpacity(0.75),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Settings tile
// ────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.10),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: widget.theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Log Out button
// ────────────────────────────────────────────────────────────────────────────
class _LogOutButton extends StatefulWidget {
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _LogOutButton({required this.colorScheme, required this.onTap});

  @override
  State<_LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<_LogOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
