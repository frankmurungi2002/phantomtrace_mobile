import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

/// Two-step 2FA setup:
///   1. Backend generates a TOTP secret + provisioning URL. We show a QR
///      code for the user to scan with Google Authenticator / Authy.
///   2. User types the current 6-digit code back in. Server verifies →
///      2FA turns on → server returns 10 recovery codes to keep safe.
class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _codeCtrl = TextEditingController();
  final _dio = Dio(BaseOptions(validateStatus: (s) => true));

  bool _loadingSetup = true;
  bool _loadingVerify = false;
  String? _otpauthUrl;
  String? _secret;
  String? _msg;
  bool _msgIsError = true;
  List<String>? _recoveryCodes;   // shown after successful verify

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  Future<Options> _auth() async {
    final t = await TokenService().getToken();
    return Options(headers: {'Authorization': 'Bearer $t'});
  }

  Future<void> _startSetup() async {
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/2fa/setup',
        options: await _auth(),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _otpauthUrl = r.data['otpauth_url'] as String?;
          _secret = r.data['secret'] as String?;
          _loadingSetup = false;
        });
      } else {
        setState(() { _msg = 'Could not start 2FA setup'; _loadingSetup = false; });
      }
    } catch (_) {
      setState(() { _msg = 'Could not reach server'; _loadingSetup = false; });
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() { _msg = 'Enter the 6-digit code from your authenticator app'; _msgIsError = true; });
      return;
    }
    setState(() { _loadingVerify = true; _msg = null; });
    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/2fa/verify-setup',
        data: {'code': code},
        options: await _auth(),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final codes = (r.data['recovery_codes'] as List?)?.cast<String>() ?? [];
        setState(() { _recoveryCodes = codes; _msg = null; });
      } else {
        final err = r.data is Map ? (r.data['error'] ?? 'Verification failed') : 'Verification failed';
        setState(() { _msg = err.toString(); _msgIsError = true; });
      }
    } catch (_) {
      setState(() => _msg = 'Could not reach server');
    } finally {
      setState(() => _loadingVerify = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Set up two-factor authentication'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _recoveryCodes != null
              ? _recoveryCodesView()
              : _loadingSetup
                  ? const Center(child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(),
                    ))
                  : _qrSetupView(),
        ),
      ),
    );
  }

  Widget _qrSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Install an authenticator app',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'Google Authenticator, Authy, or Microsoft Authenticator all work.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        const Text('2. Scan this QR with the app',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _otpauthUrl ?? '',
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _secret ?? ''));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret copied — paste it into your app manually'),
                    duration: Duration(seconds: 2)));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Can\'t scan? Copy the secret'),
          ),
        ),
        const SizedBox(height: 22),
        const Text('3. Enter the 6-digit code from the app',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_msg != null) ...[_msgBox(), const SizedBox(height: 12)],
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 6),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(color: Colors.white24, letterSpacing: 6),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loadingVerify ? null : _verify,
            child: Text(_loadingVerify ? 'Verifying…' : 'Turn on 2FA'),
          ),
        ),
      ],
    );
  }

  Widget _recoveryCodesView() {
    final codes = _recoveryCodes ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 32),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('2FA is now ON',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 20),
        const Text('Save these recovery codes',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'If you lose access to your authenticator app, each code below can '
          'be used ONCE to sign in. Screenshot or write them down and keep them safe.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: codes.map((c) => Text(c,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 15,
                    letterSpacing: 1))).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: codes.join('\n')));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recovery codes copied')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy all'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I saved my codes — done'),
          ),
        ),
      ],
    );
  }

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
