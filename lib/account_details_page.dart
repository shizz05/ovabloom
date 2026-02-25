import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pcos_app/logo_page.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditingName = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── LOAD USER DATA ─────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final userData = await _supabase
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _nameController.text = userData?['name'] as String? ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load user data: $e', isError: true);
      }
    }
  }

  // ── UPDATE NAME ────────────────────────────────────────────────────────────

  Future<void> _updateUserName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('users')
          .update({'name': _nameController.text}).eq('id', user.id);

      if (mounted) {
        _showSnack('Name updated successfully!');
        setState(() => _isEditingName = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to update name: $e', isError: true);
      }
    }
  }

  // ── DELETE ALL USER DATA ───────────────────────────────────────────────────
  //
  // Deletes all rows belonging to the current user from every public table,
  // then signs the user out. The auth.users record is intentionally kept
  // (temporary method). RLS is assumed to be enabled on all tables.
  //
  // Deletion order — child tables first, parent (users) last:
  //   cycles           → user_id
  //   daily_logs       → user_id
  //   sleep_logs       → user_id
  //   glucose_readings → user_id
  //   pcos_scorecard   → user_id
  //   users            → id

  Future<void> _deleteAllUserData(String userId) async {
    await _supabase.from('cycles').delete().eq('user_id', userId);
    await _supabase.from('daily_logs').delete().eq('user_id', userId);
    await _supabase.from('sleep_logs').delete().eq('user_id', userId);
    await _supabase.from('glucose_readings').delete().eq('user_id', userId);
    await _supabase.from('pcos_scorecard').delete().eq('user_id', userId);
    // Delete parent row last
    await _supabase.from('users').delete().eq('id', userId);
  }

  // ── DELETE ACCOUNT FLOW ────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Step 1 — Confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'This will permanently remove all your data including:\n'
          '  • Cycle logs\n'
          '  • Daily logs\n'
          '  • Sleep logs\n'
          '  • Glucose readings\n'
          '  • PCOS scorecard\n\n'
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Yes, Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 2 — Show progress, delete data, sign out
    setState(() => _isDeletingAccount = true);

    try {
      // Delete all user data from public tables
      await _deleteAllUserData(user.id);

      // Sign the user out (auth.users record is NOT removed — temporary method)
      await _supabase.auth.signOut();

      // Step 3 — Navigate to LogoPage, clearing the entire navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LogoPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        _showSnack('Failed to delete account: $e', isError: true);
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
    // Show a full-screen loading state while deletion is in progress
    if (_isDeletingAccount) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8EAF6),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 24),
              Text(
                'Deleting your account...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait, this may take a moment.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Name & Email card ─────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Name row
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.blue),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name',
                                  style: TextStyle(color: Colors.black54)),
                              TextField(
                                controller: _nameController,
                                readOnly: !_isEditingName,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditingName
                                ? Icons.save_outlined
                                : Icons.edit_outlined,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            if (_isEditingName) {
                              _updateUserName();
                            } else {
                              setState(() => _isEditingName = true);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    // Email row
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.orange),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email',
                                  style: TextStyle(color: Colors.black54)),
                              TextField(
                                controller: _emailController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Delete Account card ───────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Permanently removes all your data',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.red),
                onTap: _deleteAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
