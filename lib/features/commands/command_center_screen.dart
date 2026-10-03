import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/command_service.dart';
import '../../services/token_service.dart';
import 'command_history_screen.dart';

class CommandCenterScreen extends StatefulWidget {
  final String deviceId;
  const CommandCenterScreen({super.key, required this.deviceId});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  String? _loadingCommand;

  Future<void> sendCommand(String command) async {
    setState(() => _loadingCommand = command);
    try {
      final token = await TokenService().getToken();
      await CommandService().sendCommand(token!, widget.deviceId, command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('$command sent successfully',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Failed to send $command',
                  style: const TextStyle(color: Colors.white)),
            ]),
          ),
        );
      }
    }
    if (mounted) setState(() => _loadingCommand = null);
  }

  Widget commandCard(
    String title,
    String subtitle,
    IconData icon, {
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primary;
    final isLoading = _loadingCommand == title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isLoading || _loadingCommand != null ? null : () => sendCommand(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLoading ? color.withAlpha(30) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLoading ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(isLoading ? 60 : 30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLoading ? color : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading ? 'Sending...' : subtitle,
                    style: TextStyle(
                      color: isLoading ? color.withAlpha(180) : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(width: 14)
                : const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary, size: 14),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Command Center')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REMOTE OPERATIONS',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text('Execute commands on the endpoint.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    // ─── EVERYDAY ACTIONS ─────────────────────────────
                    // Safe, reversible, no-data-loss commands.
                    commandCard('PHOTO', 'Capture thief face via webcam',
                        Icons.face_retouching_natural, accentColor: Colors.red),
                    commandCard('SCREENSHOT', 'Capture screen evidence',
                        Icons.screenshot_monitor, accentColor: Colors.blue),
                    commandCard('LOCK', 'Lock device immediately',
                        Icons.lock, accentColor: Colors.orange),
                    commandCard('ALARM', 'Trigger loud alarm at max volume',
                        Icons.volume_up, accentColor: Colors.red),
                    commandCard('STOP_ALARM', 'Stop the alarm',
                        Icons.volume_off, accentColor: Colors.green),
                    commandCard('GET_LOCATION',
                        'Force a fresh location fix (useful if the device moved)',
                        Icons.location_on, accentColor: Colors.cyan),

                    const SizedBox(height: 24),

                    // ─── DANGER ZONE ──────────────────────────────────
                    // Collapsible section with destructive commands. Hidden
                    // behind an expand gesture + typed confirmation so the
                    // owner cannot press them by mistake. GitHub-style.
                    _DangerZone(onSend: sendCommand, loadingCommand: _loadingCommand),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommandHistoryScreen(deviceId: widget.deviceId)),
                      ),
                      icon: const Icon(Icons.history),
                      label: const Text('Command History'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Danger-zone section: SECURE_DATA / RESTORE_DATA / WIPE / INSTANT_WIPE /
/// DETERRENT_LOCK / ENABLE_BITLOCKER.
///
/// GitHub-style containment:
///   • Starts collapsed with a red warning banner
///   • Expanding requires a tap
///   • Each individual action requires a TYPED confirmation (e.g. the user
///     must type "WIPE" to run WIPE) — stops muscle-memory accidents
class _DangerZone extends StatefulWidget {
  final Future<void> Function(String) onSend;
  final String? loadingCommand;
  const _DangerZone({required this.onSend, required this.loadingCommand});

  @override
  State<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends State<_DangerZone> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.2),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger zone',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    SizedBox(height: 2),
                    Text(
                      'Destructive and semi-destructive actions. Tap to expand.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.redAccent),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          _dangerItem(
            label: 'SECURE_DATA',
            icon: Icons.enhanced_encryption,
            desc: 'Encrypt your vault folder (~/PhantomTrace_Vault).\n'
                  'Reversible with RESTORE_DATA. Only touches the vault folder.',
            confirmPhrase: 'SECURE',
          ),
          _dangerItem(
            label: 'RESTORE_DATA',
            icon: Icons.lock_open,
            desc: 'Decrypt the vault folder. Only works if a secure_data '
                  'operation was run on this device.',
            confirmPhrase: 'RESTORE',
          ),
          _dangerItem(
            label: 'ENABLE_BITLOCKER',
            icon: Icons.shield,
            desc: 'Enable Windows BitLocker full-disk encryption on C:. '
                  'IRREVERSIBLE from here (owner must disable from Windows). '
                  'Recovery key is escrowed to the backend.',
            confirmPhrase: 'ENABLE',
          ),
          _dangerItem(
            label: 'WIPE',
            icon: Icons.delete_forever,
            desc: 'Permanently delete the user folders (Documents, Desktop, '
                  'Downloads, Pictures, Videos). CANNOT be undone. Only use '
                  'after you have given up on recovering the laptop.',
            confirmPhrase: 'WIPE',
          ),
          _dangerItem(
            label: 'INSTANT_WIPE',
            icon: Icons.flash_on,
            desc: 'Crypto-erase: destroys BitLocker key protectors so the '
                  'entire drive becomes mathematically unreadable. '
                  'CANNOT be undone. Only use as a last resort.',
            confirmPhrase: 'INSTANT',
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }

  Widget _dangerItem({
    required String label,
    required IconData icon,
    required String desc,
    required String confirmPhrase,
  }) {
    final isLoading = widget.loadingCommand == label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: InkWell(
        onTap: isLoading ? null : () => _confirm(label, desc, confirmPhrase),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.redAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.redAccent))
                : const Icon(Icons.chevron_right,
                    color: Colors.white24, size: 18),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirm(String command, String desc, String phrase) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Confirm $command',
                style: const TextStyle(color: Colors.redAccent)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(desc,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Text(
                'Type the word  "$phrase"  below to confirm:',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.redAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                hintText: 'Type to enable',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: ctrl.text.trim().toUpperCase() == phrase
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Run $command'),
            ),
          ],
        );
      }),
    );
    if (ok == true) {
      await widget.onSend(command);
    }
  }
}
