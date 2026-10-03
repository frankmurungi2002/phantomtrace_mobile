import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

/// Pair-device screen. Shows the pairing code from the backend and polls
/// for pairing status every 2 seconds. As soon as the user's agent posts
/// to /api/device/pair with this code, the screen flips to "Paired!" and
/// pops back to the caller (dashboard/devices list refreshes).
class PairDeviceScreen extends StatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  final _nameController = TextEditingController();
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));

  bool _generating = false;
  String? _code;
  DateTime? _expiresAt;
  bool _paired = false;
  String? _pairedDeviceId;
  String? _error;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<Options> _auth() async {
    final t = await TokenService().getToken();
    return Options(headers: {'Authorization': 'Bearer $t'});
  }

  Future<void> _generateCode() async {
    setState(() { _generating = true; _error = null; });
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/create-pair-code',
        data: {
          if (_nameController.text.trim().isNotEmpty)
            'device_name': _nameController.text.trim(),
        },
        options: await _auth(),
      );
      if (r.statusCode == 201) {
        setState(() {
          _code = r.data['code'] as String?;
          _expiresAt = DateTime.tryParse(r.data['expires_at'] ?? '');
          _paired = false;
        });
        _startPolling();
        _startCountdown();
      } else {
        setState(() {
          _error = r.data is Map
              ? (r.data['error'] ?? 'Could not generate pairing code.')
              : 'Could not generate pairing code.';
        });
      }
    } catch (_) {
      setState(() => _error = 'Could not reach the server.');
    } finally {
      setState(() => _generating = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_expiresAt == null) return;
      final left = _expiresAt!.difference(DateTime.now());
      if (mounted) setState(() => _timeLeft = left.isNegative ? Duration.zero : left);
      if (left.isNegative) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      }
    });
  }

  Future<void> _checkStatus() async {
    if (_code == null) return;
    try {
      // Public endpoint — no JWT needed. The pairing code IS the token.
      final r = await _dio.get(
        '${ApiConstants.baseUrl}/api/device/pair-status/$_code',
      );
      // ignore: avoid_print
      print('[pair-status] ${r.statusCode} ${r.data}');
      // Accept any truthy spelling the backend might return — true, "true", 1, "1"
      final raw = r.data is Map ? r.data['paired'] : null;
      final isPaired = raw == true || raw == 'true' || raw == 1 || raw == '1';
      if (r.statusCode == 200 && isPaired) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() {
          _paired = true;
          _pairedDeviceId = (r.data is Map ? r.data['device_id'] : null)?.toString();
        });
        // Small delay so the user sees the success state
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[pair-status] error: $e');
    }
  }

  /// Manual fallback the user can hit if auto-polling misses the flip.
  /// Immediately checks pair-status and, if paired, pops back; otherwise
  /// shows a short "still waiting" snackbar.
  Future<void> _checkNow() async {
    await _checkStatus();
    if (_paired) return; // _checkStatus already popped
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Not paired yet. If the laptop shows "Paired", '
            'tap "Done — I\'ve paired" below.'),
      ));
    }
  }

  /// Hard-exit the pairing screen. Useful when the user is sure the laptop
  /// is linked (the backend may have accepted it) but polling is stuck.
  /// Pops true so the devices list refreshes.
  void _doneManually() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    Navigator.pop(context, true);
  }

  String _fmtTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Add a device'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_paired)
                _successCard()
              else if (_code == null)
                _startCard()
              else
                _codeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _startCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAIR A NEW LAPTOP',
          style: TextStyle(
            color: AppColors.textSecondary, fontSize: 12,
            letterSpacing: 2, fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add a device to protect',
          style: TextStyle(
            color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'You will get a one-time code to type into PhantomTrace on your laptop. '
          'The code links that laptop to your account only.',
          style: TextStyle(color: Colors.white54, height: 1.5),
        ),
        const SizedBox(height: 28),

        if (_error != null) ...[
          _errorBox(_error!),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Device name (optional)',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. HP Pavilion, Black ThinkPad',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                  prefixIcon: const Icon(Icons.laptop, color: Colors.white38, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generating ? null : _generateCode,
            icon: _generating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.qr_code_2),
            label: Text(_generating ? 'Generating code…' : 'Get pairing code'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  Widget _codeCard() {
    final code = _code ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR PAIRING CODE',
          style: TextStyle(
            color: AppColors.textSecondary, fontSize: 12,
            letterSpacing: 2, fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Type this on your laptop',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),

        // The code itself, big
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              SelectableText(
                code,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
              const SizedBox(height: 8),
              Text(
                _timeLeft.inSeconds > 0
                    ? 'Expires in ${_fmtTime(_timeLeft)}'
                    : 'Expired — generate a new code',
                style: TextStyle(
                  color: _timeLeft.inSeconds > 60 ? Colors.white54 : Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _stepsCard(),
        const SizedBox(height: 24),

        // Waiting state
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for your laptop to connect…',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Manual re-check — polling can miss the first flip if the network
        // hiccups or the device-list refresh fires at the wrong moment.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _checkNow,
            icon: const Icon(Icons.sync),
            label: const Text("I've paired — check now"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Hard-exit if the user has already seen the laptop online elsewhere
        // in the app but this screen is stuck on "waiting".
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _doneManually,
            icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
            label: const Text(
              "Done — I've paired",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              _countdownTimer?.cancel();
              setState(() { _code = null; _timeLeft = Duration.zero; });
            },
            child: const Text('Generate a new code'),
          ),
        ),
      ],
    );
  }

  Widget _stepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Do this next on the laptop',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _step('1', 'Download PhantomTraceAgent.exe from your dashboard (or copy it from your existing setup).'),
          _step('2', 'Run PhantomTraceAgent.exe. A pairing dialog opens automatically.'),
          _step('3', 'Type the code above and press Pair. This screen updates as soon as the laptop is linked.'),
        ],
      ),
    );
  }

  Widget _step(String n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(n, style: const TextStyle(
            color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.5)),
        ),
      ],
    ),
  );

  Widget _successCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Paired!',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Your laptop is now protected by PhantomTrace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ]),
      );
}
