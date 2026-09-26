import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final phoneController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  String? errorMessage;

  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));

  Future<void> signup() async {
    final name  = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final pass  = passwordController.text;
    final conf  = confirmController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
      setState(() => errorMessage = 'Please fill in every field.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => errorMessage = 'That email address looks wrong.');
      return;
    }
    if (pass.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != conf) {
      setState(() => errorMessage = 'The two passwords don’t match.');
      return;
    }

    setState(() { loading = true; errorMessage = null; });

    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/register',
        data: {'name': name, 'email': email, 'phone': phone, 'password': pass},
      );
      if (r.statusCode == 201) {
        final token = r.data['token'] as String?;
        if (token != null) {
          await TokenService().saveToken(token);
          await NotificationService.init();
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        final msg = r.data is Map
            ? (r.data['error'] ?? r.data['message'] ?? 'Sign up failed.')
            : 'Sign up failed.';
        setState(() { errorMessage = msg.toString(); loading = false; });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Could not reach the server. Check your internet and try again.';
        loading = false;
      });
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
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create your account',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      const Text(
                        'One account protects all your laptops.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      if (errorMessage != null) ...[
                        _errorBox(errorMessage!),
                        const SizedBox(height: 18),
                      ],

                      _label('Full name'),
                      TextField(
                        controller: nameController,
                        decoration: _dec('e.g. Frank Murungi', Icons.person_outline),
                      ),
                      const SizedBox(height: 16),

                      _label('Email address'),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _dec('you@example.com', Icons.mail_outline),
                      ),
                      const SizedBox(height: 16),

                      _label('Phone number'),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _dec('0712345678 or +256712345678', Icons.phone_iphone),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Used for quick-lock recovery if your laptop is stolen.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 16),

                      _label('Password'),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure1,
                        decoration: _dec('At least 6 characters', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure1 ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38, size: 20,
                            ),
                            onPressed: () => setState(() => obscure1 = !obscure1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Confirm password'),
                      TextField(
                        controller: confirmController,
                        obscureText: obscure2,
                        decoration: _dec('Type it again', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure2 ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38, size: 20,
                            ),
                            onPressed: () => setState(() => obscure2 = !obscure2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : signup,
                          child: Text(loading ? 'Creating account…' : 'Create account'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: loading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Already have an account?  Sign in',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      );

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ]),
      );
}
