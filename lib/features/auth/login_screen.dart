import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'two_factor_verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool rememberMe = false;
  bool obscurePassword = true;
  String? errorMessage;
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;
  bool _biometricPromptedThisLaunch = false;

  final _bio = BiometricService();
  final _tokens = TokenService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final avail = await _bio.isAvailable();
    final enabled = await _tokens.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = avail;
      _biometricEnrolled = enabled;
    });
    // If the user has fingerprint sign-in enabled, prompt for it right away
    // so they never have to touch the password screen at all.
    if (avail && enabled && !_biometricPromptedThisLaunch) {
      _biometricPromptedThisLaunch = true;
      Future.delayed(const Duration(milliseconds: 300), _tryBiometricLogin);
    }
  }

  Future<void> _tryBiometricLogin() async {
    final ok = await _bio.authenticate(
      reason: 'Sign in to PhantomTrace with your fingerprint');
    if (!ok || !mounted) return;
    final token = await _tokens.getBiometricToken();
    if (token == null) return;
    await _tokens.saveToken(token);
    await AuthService().refreshFcmForToken(token);
    await NotificationService.init();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final saved = prefs.getBool('remember_me') ?? false;
    if (saved) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe = true;
      });
    } else if (savedEmail.isNotEmpty) {
      setState(() { emailController.text = savedEmail; });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', emailController.text.trim());
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe) {
      await prefs.setString('saved_password', passwordController.text);
    } else {
      await prefs.remove('saved_password');
    }
  }

  Future<void> login() async {
    setState(() { loading = true; errorMessage = null; });
    final email = emailController.text.trim();
    final result = await AuthService().login(email, passwordController.text);
    if (!mounted) return;

    if (result.requiresTwoFactor && result.preAuthToken != null) {
      setState(() => loading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorVerifyScreen(
            preAuthToken: result.preAuthToken!,
            email: email,
          ),
        ),
      );
      return;
    }

    if (result.token != null) {
      final token = result.token!;
      await _saveCredentials();
      await _tokens.saveToken(token);
      await NotificationService.init();

      // Offer to turn on biometric sign-in the FIRST time we get a token,
      // if the phone supports it and the user hasn't already opted in.
      if (_biometricAvailable && !(await _tokens.isBiometricEnabled())) {
        await _maybeOfferBiometric(token, email);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      return;
    }

    setState(() {
      errorMessage = result.error ?? 'Login failed';
      loading = false;
    });
  }

  Future<void> _maybeOfferBiometric(String token, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign in with fingerprint next time?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You can skip typing your password every time by using your '
          'fingerprint. Your credentials stay in the phone\'s secure enclave.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (ok == true) {
      // Verify once so we know biometrics really work on this device
      final auth = await _bio.authenticate(reason: 'Confirm fingerprint to enable sign-in');
      if (auth) {
        await _tokens.enableBiometric(token: token, email: email);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      Text('PHANTOMTRACE',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      const Text('Enterprise Endpoint Security',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 40),

                      if (errorMessage != null) ...[
                        Container(
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
                            Expanded(child: Text(errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Text('Email Address',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Password',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38, size: 20,
                            ),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            SizedBox(
                              width: 20, height: 20,
                              child: Checkbox(
                                value: rememberMe,
                                onChanged: (val) => setState(() => rememberMe = val ?? false),
                                activeColor: AppColors.primary,
                                side: const BorderSide(color: Colors.white38),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Remember me',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ]),
                          TextButton(
                            onPressed: loading ? null : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: const Text('Forgot password?',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          child: Text(loading ? 'Signing In...' : 'Sign In'),
                        ),
                      ),

                      if (_biometricAvailable && _biometricEnrolled) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : _tryBiometricLogin,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Sign in with fingerprint'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: loading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'New to PhantomTrace?  ',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Create an account',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Secure Access Portal',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
}
