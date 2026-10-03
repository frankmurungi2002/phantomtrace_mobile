import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';
import '../auth/emergency_contacts_screen.dart';
import '../auth/legal_webview_screen.dart';
import '../auth/login_screen.dart';
import '../help/help_screen.dart';

/// User settings: profile, security, legal, danger zone (delete account).
///
/// Follows the "danger zone" principle: destructive actions live under a
/// red collapsed card at the bottom, require a typed email to confirm,
/// and are visually separated from everyday settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));
  bool _loading = true;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Options> _auth() async {
    final t = await TokenService().getToken();
    return Options(headers: {'Authorization': 'Bearer $t'});
  }

  Future<void> _load() async {
    try {
      final r = await _dio.get(
        '${ApiConstants.baseUrl}/api/user/me',
        options: await _auth(),
      );
      if (r.statusCode == 200 && r.data is Map) {
        _me = Map<String, dynamic>.from(r.data as Map);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── Edit profile dialog ────────────────────────────────────────────────
  Future<void> _editProfile() async {
    final nameC  = TextEditingController(text: (_me?['name']  ?? '') as String);
    final phoneC = TextEditingController(text: (_me?['phone'] ?? '') as String);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit profile', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameC, 'Full name'),
          const SizedBox(height: 10),
          _field(phoneC, 'Phone (+256…)'),
          const SizedBox(height: 10),
          const Text(
            'Email cannot be changed from here. Contact support if you need to.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [_twinActions(
          ctx,
          onCancel: () => Navigator.pop(ctx, false),
          onSave:   () => Navigator.pop(ctx, true),
        )],
      ),
    );
    if (ok != true) return;
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/user/update-profile',
        data: {'name': nameC.text.trim(), 'phone': phoneC.text.trim()},
        options: await _auth(),
      );
      if (r.statusCode == 200 && mounted) {
        _snack('Profile updated.');
        _load();
      } else {
        _snack(r.data is Map ? (r.data['error'] ?? 'Could not update') : 'Could not update');
      }
    } catch (_) {
      _snack('Network error');
    }
  }

  // ── Change password dialog ────────────────────────────────────────────
  Future<void> _changePassword() async {
    final currentC = TextEditingController();
    final newC     = TextEditingController();
    final confirmC = TextEditingController();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Change password',
              style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(currentC, 'Current password', obscure: obscure),
            const SizedBox(height: 10),
            _field(newC, 'New password (min 8)', obscure: obscure),
            const SizedBox(height: 10),
            _field(confirmC, 'Confirm new password', obscure: obscure),
            Row(children: [
              Checkbox(
                value: !obscure,
                onChanged: (v) => setState(() => obscure = !(v ?? false)),
                activeColor: AppColors.primary,
              ),
              const Text('Show passwords', style: TextStyle(color: Colors.white70)),
            ]),
          ]),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [_twinActions(
            ctx,
            onCancel: () => Navigator.pop(ctx, false),
            onSave:   () => Navigator.pop(ctx, true),
          )],
        );
      }),
    );
    if (ok != true) return;
    if (newC.text != confirmC.text) {
      _snack('New password and confirmation do not match');
      return;
    }
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/user/change-password',
        data: {
          'current_password': currentC.text,
          'new_password': newC.text,
        },
        options: await _auth(),
      );
      if (r.statusCode == 200) {
        _snack('Password changed.');
      } else {
        _snack(r.data is Map ? (r.data['error'] ?? 'Could not change') : 'Could not change');
      }
    } catch (_) {
      _snack('Network error');
    }
  }

  // ── Delete account flow ────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final email = (_me?['email'] ?? '') as String;
    final confirmC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final matches = confirmC.text.trim().toLowerCase() == email.toLowerCase();
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Row(children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(child: Text('Delete account',
                style: TextStyle(color: Colors.redAccent))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'This permanently deletes your account, all of your devices, '
              'all captured evidence, and all emergency contacts. The agents '
              'on your paired laptops will be told to uninstall themselves '
              'the next time they come online.\n\n'
              'This cannot be undone.',
              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('To confirm, type your email:  $email',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            TextField(
              controller: confirmC,
              autofocus: true,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                hintText: 'Type your email',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: matches ? () => Navigator.pop(ctx, true) : null,
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete my account'),
            ),
          ],
        );
      }),
    );
    if (ok != true) return;

    try {
      final r = await _dio.delete(
        '${ApiConstants.baseUrl}/api/user/account',
        data: {'confirm_email': confirmC.text.trim()},
        options: await _auth(),
      );
      if (r.statusCode == 200) {
        await TokenService().clearToken();
        await TokenService().disableBiometric();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        _snack(r.data is Map ? (r.data['error'] ?? 'Deletion failed') : 'Deletion failed');
      }
    } catch (_) {
      _snack('Network error');
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────
  Widget _field(TextEditingController c, String hint, {bool obscure = false}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );

  /// Two matched dialog action buttons: Cancel (outlined, white) +
  /// Save (filled, brand red). Same height, same width via Expanded.
  /// Replaces the Material default where TextButton+ElevatedButton render
  /// at different sizes and visually imbalanced.
  Widget _twinActions(BuildContext ctx,
      {required VoidCallback onCancel, required VoidCallback onSave,
       String saveLabel = 'Save'}) {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(saveLabel,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                children: [
                  _profileHeader(),
                  const SizedBox(height: 24),
                  _sectionHeader('ACCOUNT'),
                  _row(Icons.person_outline, 'Edit profile',
                      subtitle: 'Change your name or phone number',
                      onTap: _editProfile),
                  _row(Icons.lock_outline, 'Change password',
                      subtitle: 'Set a new password', onTap: _changePassword),
                  _row(Icons.contacts_outlined, 'Emergency contacts',
                      subtitle: 'People to notify when a device is stolen',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EmergencyContactsScreen()),
                          )),
                  const SizedBox(height: 20),
                  _sectionHeader('APP'),
                  _row(Icons.help_outline, 'Help & FAQ',
                      subtitle: 'How things work; privacy; recovery',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()))),
                  _row(Icons.article_outlined, 'Terms of Service',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LegalWebviewScreen(
                                  title: 'Terms of Service', path: '/terms')))),
                  _row(Icons.privacy_tip_outlined, 'Privacy Policy',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LegalWebviewScreen(
                                  title: 'Privacy Policy', path: '/privacy')))),
                  const SizedBox(height: 28),
                  _dangerZone(),
                ],
              ),
            ),
    );
  }

  Widget _profileHeader() {
    final name = (_me?['name']  ?? '-') as String;
    final email = (_me?['email'] ?? '-') as String;
    final phone = (_me?['phone'] ?? '-') as String;
    final devices = (_me?['device_count'] ?? 0) as int;
    final tfa = (_me?['totp_enabled'] == true);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.22),
          child: Text(
            name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 22),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Text(phone, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _chip('$devices device${devices == 1 ? "" : "s"}'),
                const SizedBox(width: 8),
                _chip(tfa ? '2FA on' : '2FA off',
                    color: tfa ? Colors.greenAccent : Colors.white54),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (color ?? Colors.white54).withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (color ?? Colors.white54).withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color ?? Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 11)),
      );

  Widget _sectionHeader(String s) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(s,
            style: const TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      );

  Widget _row(IconData icon, String title,
      {String? subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ]),
        ),
      ),
    );
  }

  Widget _dangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text('Danger zone',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          const Text(
            'Deleting your account removes all your data from our servers '
            'and tells the agents on your laptops to uninstall themselves. '
            'This cannot be undone.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              label: const Text('Delete my account',
                  style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
