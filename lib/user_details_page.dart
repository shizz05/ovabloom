import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _supabase = Supabase.instance.client;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // ── FETCH USER PROFILE ─────────────────────────────────────────────────────

  Future<void> _fetchUserProfile() async {
    _currentUser = _supabase.auth.currentUser;

    if (_currentUser != null) {
      try {
        final data = await _supabase
            .from('users')
            .select('name, email')
            .eq('id', _currentUser!.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() => _userData = data);
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ── LOG OUT ────────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error signing out: $e', isError: true);
      }
    }
  }

  // ── DELETE ALL USER DATA ───────────────────────────────────────────────────
  //
  // Deletes rows from all public tables for the given userId.
  // Child tables are deleted first; the parent users row is deleted last.
  // auth.users is intentionally NOT touched (temporary method).
  //
  // Tables:
  //   cycles           → user_id
  //   daily_logs       → user_id
  //   sleep_logs       → user_id
  //   glucose_readings → user_id
  //   pcos_scorecard   → user_id
  //   users            → id  (parent — deleted last)

  Future<void> _deleteAllUserData(String userId) async {
    await _supabase.from('cycles').delete().eq('user_id', userId);
    await _supabase.from('daily_logs').delete().eq('user_id', userId);
    await _supabase.from('sleep_logs').delete().eq('user_id', userId);
    await _supabase.from('glucose_readings').delete().eq('user_id', userId);
    await _supabase.from('pcos_scorecard').delete().eq('user_id', userId);
    // Parent row — deleted last
    await _supabase.from('users').delete().eq('id', userId);
  }

  // ── DELETE ACCOUNT ─────────────────────────────────────────────────────────

  Future<void> _handleDeleteAccount() async {
    if (_currentUser == null) return;

    // Step 1 — Confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Account?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This action is permanent. All your data will be wiped and cannot be recovered.\n\n'
          'The following data will be deleted:\n'
          '  • Cycle logs\n'
          '  • Daily logs\n'
          '  • Sleep logs\n'
          '  • Glucose readings\n'
          '  • PCOS scorecard\n\n'
          'Are you sure?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete Forever',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Step 2 — Delete data and sign out
    setState(() => _isLoading = true);

    try {
      // Delete all user data from public tables
      await _deleteAllUserData(_currentUser!.id);

      // Sign out (auth.users record is NOT removed — temporary method)
      await _supabase.auth.signOut();

      // Step 3 — Navigate to LoginPage, clearing the stack
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error deleting account: $e', isError: true);
      }
    }
  }

  // ── HELPER ─────────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF679f9e),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Avatar ────────────────────────────────────────────────
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // ── User Name ─────────────────────────────────────────────
                  Text(
                    _userData?['name'] as String? ??
                        _currentUser?.userMetadata?['display_name']
                            as String? ??
                        'User',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // ── Email ─────────────────────────────────────────────────
                  Text(
                    _userData?['email'] as String? ??
                        _currentUser?.email ??
                        'No Email',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),

                  // ── Log Out ───────────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.teal),
                    title:
                        const Text('Log Out', style: TextStyle(fontSize: 18)),
                    onTap: _handleLogout,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Delete Account ────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                    ),
                    onTap: _handleDeleteAccount,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                    tileColor: Colors.red.shade50,
                  ),
                ],
              ),
            ),
    );
  }
}
