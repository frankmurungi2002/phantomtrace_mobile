import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

/// Lets the owner list people who should be notified when a device is marked
/// stolen — spouse, flatmate, campus security, driver. Each gets an email
/// with the recovery PDF attached the moment the owner taps "Mark as Stolen".
///
/// Backend endpoints:
///   GET    /api/user/emergency-contacts
///   POST   /api/user/emergency-contacts  { name, email?, phone?, relationship? }
///   DELETE /api/user/emergency-contacts/<id>
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));
  bool _loading = true;
  List<Map<String, dynamic>> _contacts = [];

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
    setState(() => _loading = true);
    try {
      final r = await _dio.get(
        '${ApiConstants.baseUrl}/api/user/emergency-contacts',
        options: await _auth(),
      );
      if (r.statusCode == 200 && r.data is Map) {
        final raw = (r.data['contacts'] as List?) ?? const [];
        _contacts = raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addDialog() async {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final relC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add emergency contact',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _f(nameC, 'Full name *'),
            const SizedBox(height: 10),
            _f(emailC, 'Email'),
            const SizedBox(height: 10),
            _f(phoneC, 'Phone (+256…)'),
            const SizedBox(height: 10),
            _f(relC, 'Relationship (e.g. spouse, security)'),
            const SizedBox(height: 6),
            const Text(
              'At least email OR phone is required.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final name = nameC.text.trim();
    if (name.isEmpty) {
      _snack('Name is required'); return;
    }
    if (emailC.text.trim().isEmpty && phoneC.text.trim().isEmpty) {
      _snack('Email or phone must be provided'); return;
    }
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/user/emergency-contacts',
        data: {
          'name': name,
          if (emailC.text.trim().isNotEmpty) 'email': emailC.text.trim(),
          if (phoneC.text.trim().isNotEmpty) 'phone': phoneC.text.trim(),
          if (relC.text.trim().isNotEmpty) 'relationship': relC.text.trim(),
        },
        options: await _auth(),
      );
      if (r.statusCode == 201) {
        _snack('Added.');
        _load();
      } else {
        _snack(r.data is Map ? (r.data['error'] ?? 'Could not add contact') : 'Could not add contact');
      }
    } catch (_) {
      _snack('Network error');
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove ${c['name']}?',
            style: const TextStyle(color: Colors.white)),
        content: const Text(
          'They will no longer receive the recovery report if this device is '
          'marked stolen.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await _dio.delete(
        '${ApiConstants.baseUrl}/api/user/emergency-contacts/${c['id']}',
        options: await _auth(),
      );
      if (r.statusCode == 200) {
        _snack('Removed.');
        _load();
      } else {
        _snack('Could not remove');
      }
    } catch (_) {
      _snack('Network error');
    }
  }

  Widget _f(TextEditingController c, String hint) => TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );

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
        title: const Text('Emergency contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add contact'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  const Text('WHO ELSE TO NOTIFY',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'When you mark a device stolen, these people also receive '
                    "the recovery report by email. Add anyone who could help "
                    "recover the laptop — a spouse, flatmate, campus security.",
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (_contacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(children: [
                        Icon(Icons.person_search,
                            color: AppColors.textSecondary, size: 48),
                        SizedBox(height: 10),
                        Text(
                          'No emergency contacts yet.\nTap "Add contact" to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ]),
                    )
                  else
                    ..._contacts.map(_tile),
                ],
              ),
            ),
    );
  }

  Widget _tile(Map<String, dynamic> c) {
    final name = (c['name'] ?? '') as String;
    final email = (c['email'] ?? '') as String?;
    final phone = (c['phone'] ?? '') as String?;
    final rel = (c['relationship'] ?? '') as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.18),
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                if (rel != null && rel.isNotEmpty)
                  Text(rel,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                if (email != null && email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                if (phone != null && phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _delete(c),
          ),
        ]),
      ),
    );
  }
}
