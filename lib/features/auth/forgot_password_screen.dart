import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';

/// Two-step password reset:
///   1. User enters email → server SMSes a 6-digit OTP to the PHONE
///      registered against that email. (Two-channel proof: hijacker
///      needs both the email AND the phone to complete the reset.)
///   2. User enters OTP + new password → server updates it, invalidates
///      other sessions, sends the owner a push saying "password reset from
///      IP X" so a hijacker gets caught.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  int _step = 1;          // 1 = enter email, 2 = enter code + new password
  bool _loading = false;
  String? _msg;
  bool _msgIsError = true;

  final _dio = Dio(BaseOptions(validateStatus: (s) => true));

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() { _msg = 'Enter a valid email address'; _msgIsError = true; });
      return;
    }
    setState(() { _loading = true; _msg = null; });
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/forgot-password/request',
        data: {'email': email},
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _step = 2;
          _msg = 'Check your SMS for a 6-digit code. It expires in 10 minutes.';
          _msgIsError = false;
        });
      } else {
        setState(() => _msg = 'Could not start password reset. Try again.');
      }
    } catch (_) {
      setState(() => _msg = 'Could not reach the server');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndReset() async {
    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;
    final conf = _confirmCtrl.text;
    if (code.length != 6) {
      setState(() { _msg = 'Enter the 6-digit code from SMS'; _msgIsError = true; });
      return;
    }
    if (pass.length < 6) {
      setState(() { _msg = 'New password must be at least 6 characters'; _msgIsError = true; });
      return;
    }
    if (pass != conf) {
      setState(() { _msg = 'Passwords don\'t match'; _msgIsError = true; });
      return;
    }
    setState(() { _loading = true; _msg = null; });
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/forgot-password/verify',
        data: {
          'email':        _emailCtrl.text.trim(),
          'code':         code,
          'new_password': pass,
        },
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
        final err = r.data is Map ? (r.data['error'] ?? 'Reset failed') : 'Reset failed';
        setState(() { _msg = err.toString(); _msgIsError = true; });
      }
    } catch (_) {
      setState(() => _msg = 'Could not reach the server');
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
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Reset your password'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _step == 1 ? _emailStep() : _codeStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Forgot your password?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text(
        'Enter your email. We\'ll SMS a 6-digit code to the phone number '
        'registered on the account. You\'ll need both to reset.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      if (_msg != null) ...[_msgBox(), const SizedBox(height: 14)],
      _label('Email address'),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _dec('you@example.com', Icons.mail_outline),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _sendCode,
          child: Text(_loading ? 'Sending…' : 'Send code'),
        ),
      ),
    ],
  );

  Widget _codeStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Set a new password',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(
        'We sent a 6-digit code to the phone on file for ${_emailCtrl.text.trim()}.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      if (_msg != null) ...[_msgBox(), const SizedBox(height: 14)],
      _label('Code from SMS'),
      TextField(
        controller: _codeCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: _dec('••••••', Icons.pin_outlined),
      ),
      const SizedBox(height: 8),
      _label('New password'),
      TextField(
        controller: _passCtrl,
        obscureText: true,
        decoration: _dec('At least 6 characters', Icons.lock_outline),
      ),
      const SizedBox(height: 14),
      _label('Confirm new password'),
      TextField(
        controller: _confirmCtrl,
        obscureText: true,
        decoration: _dec('Type it again', Icons.lock_outline),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _verifyAndReset,
          child: Text(_loading ? 'Resetting…' : 'Reset password'),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: _loading ? null : () => setState(() { _step = 1; _msg = null; }),
          child: const Text('Use a different email'),
        ),
      ),
    ],
  );

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(s, style: const TextStyle(
        color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
  );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    counterText: '',
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
    prefixIcon: Icon(icon, color: Colors.white38, size: 20),
  );

  Widget _msgBox() {
    final color = _msgIsError ? Colors.red : Colors.greenAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(_msgIsError ? Icons.error_outline : Icons.info_outline,
            color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_msg ?? '',
              style: TextStyle(color: color, fontSize: 13)),
        ),
      ]),
    );
  }
}
