import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';

/// Shown after password login when the account has 2FA enabled.
/// Takes the pre-auth token (short-lived, 5 min) and swaps it for a real
/// JWT once the user enters a valid 6-digit code (or a one-use recovery
/// code).
class TwoFactorVerifyScreen extends StatefulWidget {
  final String preAuthToken;
  final String? email;    // shown for the biometric-opt-in flow
  const TwoFactorVerifyScreen({
    super.key,
    required this.preAuthToken,
    this.email,
  });

  @override
  State<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends State<TwoFactorVerifyScreen> {
  final _codeCtrl = TextEditingController();
  final _dio = Dio(BaseOptions(validateStatus: (s) => true));
  bool _loading = false;
  String? _err;

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim().replaceAll(' ', '');
    if (code.isEmpty) {
      setState(() => _err = 'Enter your 6-digit code');
      return;
    }
    setState(() { _loading = true; _err = null; });
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/2fa/verify-login',
        data: {'code': code},
        options: Options(headers: {'Authorization': 'Bearer ${widget.preAuthToken}'}),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final token = r.data['token'] as String?;
        if (token != null) {
          await TokenService().saveToken(token);
          await NotificationService.init();
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      } else {
        final err = r.data is Map ? (r.data['error'] ?? 'Verification failed') : 'Verification failed';
        setState(() => _err = err.toString());
      }
    } catch (_) {
      setState(() => _err = 'Could not reach server');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Two-factor verification'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 40),
                    const SizedBox(height: 12),
                    const Text('One more step',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                      'Open your authenticator app and type the current 6-digit code. '
                      'Lost your phone? Enter one of your recovery codes.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    if (_err != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 6),
                      decoration: const InputDecoration(
                        hintText: '••••••',
                        hintStyle: TextStyle(color: Colors.white24, letterSpacing: 6),
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        child: Text(_loading ? 'Verifying…' : 'Verify'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
