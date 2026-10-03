import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

/// Shows the owner the exact steps to set a BIOS/UEFI password on THIS
/// specific laptop model (looked up by manufacturer+model that the agent
/// reports at startup). This is the one defence software cannot enforce
/// — the owner has to boot into BIOS physically. We make it as easy as
/// possible by giving the right key and the right menu path.
class BiosSetupScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const BiosSetupScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<BiosSetupScreen> createState() => _BiosSetupScreenState();
}

class _BiosSetupScreenState extends State<BiosSetupScreen> {
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _info;

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
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/bios-info',
        options: await _auth(),
      );
      if (r.statusCode == 200 && r.data is Map) {
        _info = Map<String, dynamic>.from(r.data as Map);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmProtected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("I've set the BIOS password",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Only tick this once you have ACTUALLY set a BIOS/UEFI password "
          "AND disabled USB boot in your firmware. We cannot verify this "
          "from here — you are confirming it on your word.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('Yes, confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/bios-protected',
        data: {'protected': true},
        options: await _auth(),
      );
      if (r.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('BIOS protection recorded. Thanks.'),
          ));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save status')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network error')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('BIOS Protection Setup'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(child: _content()),
    );
  }

  Widget _content() {
    final info = _info ?? {};
    final isProtected = info['protected'] == true;
    final mfg = (info['manufacturer'] ?? '') as String?;
    final mdl = (info['model'] ?? '') as String?;
    final enterKey = (info['enter_key'] ?? 'F2') as String? ?? 'F2';
    final fallback = (info['fallback_key'] ?? '') as String? ?? '';
    final rawSteps = (info['steps'] as List?) ?? const [];
    final steps = rawSteps.map((s) => s.toString()).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isProtected
                ? Colors.green.withOpacity(0.08)
                : Colors.amber.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isProtected ? Colors.greenAccent : Colors.amberAccent,
              width: 1.3,
            ),
          ),
          child: Row(children: [
            Icon(
              isProtected ? Icons.verified_user : Icons.warning_amber_rounded,
              color: isProtected ? Colors.greenAccent : Colors.amberAccent,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProtected ? 'BIOS protection confirmed'
                               : 'BIOS protection NOT confirmed',
                    style: TextStyle(
                      color: isProtected ? Colors.greenAccent : Colors.amberAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isProtected
                        ? 'This device is protected against USB-boot wipes.'
                        : 'A thief could still boot from USB and reinstall '
                          'Windows. Follow the steps below to close that gap.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        const Text('WHY THIS MATTERS',
            style: TextStyle(color: AppColors.textSecondary,
                letterSpacing: 2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          "Software running inside Windows cannot stop someone powering off "
          "your laptop and booting it from a USB drive. The only thing that "
          "can is a password set in the laptop's firmware (BIOS/UEFI). "
          "Setting it takes about 2 minutes and makes the laptop useless "
          "to anyone who steals it.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Model detected row
        if ((mfg?.isNotEmpty ?? false) || (mdl?.isNotEmpty ?? false))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.laptop_mac, color: Colors.white54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detected model',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('${mfg ?? ''} ${mdl ?? ''}'.trim(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('BIOS key: $enterKey'
                        '${fallback.isNotEmpty ? "   (fallback: $fallback)" : ""}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
        const SizedBox(height: 24),

        const Text('STEPS',
            style: TextStyle(color: AppColors.textSecondary,
                letterSpacing: 2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (steps.isEmpty)
          const Text(
            "No instructions were received from the agent yet. Start the "
            "agent on your laptop at least once, then come back here.",
            style: TextStyle(color: Colors.white60),
          )
        else
          ...steps.asMap().entries.map((e) => _stepTile(e.key + 1, e.value)),
        const SizedBox(height: 24),

        if (!isProtected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _confirmProtected,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_user),
              label: Text(_saving ? 'Saving...' : "I've done it — mark protected"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final r = await _dio.post(
                  '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/bios-protected',
                  data: {'protected': false},
                  options: await _auth(),
                );
                if (r.statusCode == 200 && mounted) {
                  setState(() => _info?['protected'] = false);
                }
              },
              icon: const Icon(Icons.undo, color: Colors.white54),
              label: const Text('Unmark (not actually protected)',
                  style: TextStyle(color: Colors.white54)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepTile(int n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Text('$n', style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: Colors.white, height: 1.5, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
}
