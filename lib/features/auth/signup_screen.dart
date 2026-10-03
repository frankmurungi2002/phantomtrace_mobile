import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'legal_webview_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey           = GlobalKey<FormState>();
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final phoneController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool _submitted = false;
  bool _agreedToTerms = false;    // required to enable the "Create account" button
  String? errorMessage;

  // Public URLs of the hosted legal pages. The backend serves them from
  // ApiConstants.baseUrl/{terms,privacy}; we open them in the system browser
  // so users see the real, versioned text.
  static const _termsUrl   = '/terms';
  static const _privacyUrl = '/privacy';

  // Explicit timeouts so we can distinguish "server is waking up" from
  // "server rejected the request" from "no internet at all".
  final Dio _dio = Dio(BaseOptions(
    validateStatus: (s) => true,
    connectTimeout: const Duration(seconds: 60),   // Render cold boot ≈ 50s
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

  @override
  void initState() {
    super.initState();
    // Rebuild so the password strength meter follows what's typed.
    passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    FocusScope.of(context).unfocus();
    setState(() { _submitted = true; errorMessage = null; });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      setState(() => errorMessage =
          'Please read and accept the Terms of Service and Privacy Policy to continue.');
      return;
    }

    final name  = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final pass  = passwordController.text;

    setState(() => loading = true);

    try {
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/auth/register',
        data: {
          'name': name, 'email': email, 'phone': phone, 'password': pass,
          'accepted_terms': true,   // backend blocks the signup without this
        },
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
        if (!mounted) return;
        setState(() {
          errorMessage = _friendlyServerError(r);
          loading = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _friendlyNetworkError(e);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage =
            'Unexpected error while creating your account.\n($e)';
        loading = false;
      });
    }
  }

  /// Converts an HTTP error response into a message the user can act on.
  /// Covers: duplicate email, missing Terms, bad validation, Render cold
  /// starts, and bare 5xx errors — always with a concrete next step.
  String _friendlyServerError(Response r) {
    final code = r.statusCode ?? 0;
    // Try to pull the backend's error field; works for Flask's jsonify responses.
    String? backendMsg;
    if (r.data is Map) {
      final m = r.data as Map;
      backendMsg = (m['error'] ?? m['message'])?.toString();
    } else if (r.data is String) {
      final s = r.data as String;
      // If it's an HTML error page (e.g. Render maintenance), don't dump it.
      if (!s.startsWith('<')) backendMsg = s;
    }

    switch (code) {
      case 400:
        return backendMsg ??
            'Some details on the form are not valid. Please check your '
            'name, email, phone number, and password, then try again.';
      case 401:
      case 403:
        return backendMsg ??
            'The server refused the sign up ($code). Please try again.';
      case 409:
        return backendMsg ??
            'An account with this email already exists. Try signing in '
            'instead, or use "Forgot password?" if you cannot remember it.';
      case 429:
        return 'Too many attempts. Please wait a minute and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is having a problem right now (error $code). '
               'Please try again in a few seconds. '
               '${backendMsg != null ? "\nDetails: $backendMsg" : ""}';
      default:
        return backendMsg ??
            'Sign up failed (error $code). Please try again. '
            'If the problem persists, contact support.';
    }
  }

  /// Converts a Dio network error into a message that explains what the
  /// user can try. Distinguishes "server waking up", "no internet",
  /// "server blocked", etc.
  String _friendlyNetworkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'The server took too long to respond. If this is your first '
               'request after a long time, the server may be waking up — '
               'please try again in 30 seconds.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to answer. Please check your '
               'internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your Wi-Fi or mobile data '
               'and try again. If both are fine, the server may be down.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please update the PhantomTrace '
               'app from the Play Store.';
      case DioExceptionType.cancel:
        return 'Sign up was cancelled.';
      case DioExceptionType.unknown:
      default:
        final msg = e.message ?? '';
        return 'Could not reach the server. '
               '${msg.isNotEmpty ? "\nDetails: $msg" : "Please try again."}';
    }
  }

  /// Builds a tap-recognizer that opens the given legal page in an in-app
  /// WebView-free viewer (we fetch the HTML and show it). Keeps the user
  /// inside the app instead of bouncing to an external browser.
  TapGestureRecognizer _openUrlRecognizer(String path) {
    return TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalWebviewScreen(
              title: path == '/terms' ? 'Terms of Service' : 'Privacy Policy',
              path: path,
            ),
          ),
        );
      };
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter your name' : null;

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'That email address looks wrong';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Please enter your phone number';
    if (digits.length < 9) return 'That phone number looks too short';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please choose a password';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != passwordController.text) return 'The passwords don’t match';
    return null;
  }

  /// 0 = empty, 1 = weak, 2 = fair, 3 = good, 4 = strong
  int _strength(String p) {
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(1, 4);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Tighter gutters on small phones so fields keep a comfortable width.
    final hPad = width < 360 ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.2,
            colors: [Color(0xFF15254A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad - 8, 4, hPad, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: loading ? null : () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.textPrimary,
                    tooltip: 'Back',
                  ),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _form(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 24),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: errorMessage == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _errorBox(errorMessage!),
                    ),
            ),

            _field(
              label: 'Full name',
              controller: nameController,
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              validator: _validateName,
              capitalization: TextCapitalization.words,
              autofill: const [AutofillHints.name],
            ),
            _field(
              label: 'Email address',
              controller: emailController,
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              validator: _validateEmail,
              keyboard: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
            ),
            _field(
              label: 'Phone number',
              controller: phoneController,
              hint: '+256 712 345 678',
              icon: Icons.phone_iphone_rounded,
              validator: _validatePhone,
              keyboard: TextInputType.phone,
              autofill: const [AutofillHints.telephoneNumber],
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              helper: 'Used for quick-lock recovery if your laptop is stolen.',
            ),
            _field(
              label: 'Password',
              controller: passwordController,
              hint: 'At least 6 characters',
              icon: Icons.lock_outline_rounded,
              validator: _validatePassword,
              obscure: obscure1,
              onToggleObscure: () => setState(() => obscure1 = !obscure1),
              autofill: const [AutofillHints.newPassword],
              below: _strengthMeter(),
            ),
            _field(
              label: 'Confirm password',
              controller: confirmController,
              hint: 'Type it again',
              icon: Icons.lock_outline_rounded,
              validator: _validateConfirm,
              obscure: obscure2,
              onToggleObscure: () => setState(() => obscure2 = !obscure2),
              autofill: const [AutofillHints.newPassword],
              action: TextInputAction.done,
              onSubmitted: (_) => loading ? null : signup(),
            ),
            const SizedBox(height: 16),

            // ── Terms + Privacy acceptance ────────────────────────────────
            // Required by Play Store policy. The checkbox state is persisted
            // only for this signup attempt; the backend records the timestamp
            // when the account is actually created.
            InkWell(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.primary,
                        side: BorderSide(
                          color: (_submitted && !_agreedToTerms)
                              ? Colors.redAccent
                              : Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, height: 1.4),
                          children: [
                            const TextSpan(text: 'I have read and I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _openUrlRecognizer(_termsUrl),
                            ),
                            const TextSpan(text: '  and  '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _openUrlRecognizer(_privacyUrl),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_submitted && !_agreedToTerms)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 36),
                child: Text(
                  'Required to create an account.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : signup,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: loading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Creating account…'),
                        ],
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 18),

            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                TextButton(
                  onPressed: loading ? null : () => Navigator.maybePop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Sign in',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.28),
                blurRadius: 32,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/icon/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Create your account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'One account protects all your laptops.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    Iterable<String>? autofill,
    List<TextInputFormatter>? formatters,
    String? helper,
    bool? obscure,
    VoidCallback? onToggleObscure,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    Widget? below,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            enabled: !loading,
            keyboardType: keyboard,
            textCapitalization: capitalization,
            textInputAction: action,
            autofillHints: autofill,
            inputFormatters: formatters,
            obscureText: obscure ?? false,
            enableSuggestions: obscure == null,
            autocorrect: false,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: _dec(hint, icon).copyWith(
              helperText: helper,
              helperMaxLines: 2,
              helperStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              suffixIcon: obscure == null
                  ? null
                  : IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38, size: 20,
                      ),
                      tooltip: obscure ? 'Show password' : 'Hide password',
                      onPressed: onToggleObscure,
                    ),
            ),
          ),
          ?below,
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      errorMaxLines: 2,
      border: border(AppColors.surfaceElevated),
      enabledBorder: border(AppColors.surfaceElevated),
      disabledBorder: border(AppColors.surfaceElevated),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.danger.withValues(alpha: 0.7)),
      focusedErrorBorder: border(AppColors.danger, 1.5),
    );
  }

  Widget _strengthMeter() {
    final s = _strength(passwordController.text);
    if (s == 0) return const SizedBox.shrink();
    const labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      Colors.transparent,
      AppColors.danger,
      AppColors.warning,
      Color(0xFF84CC16),
      AppColors.success,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      child: Row(children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= s ? colors[s] : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 48,
          child: Text(labels[s],
              textAlign: TextAlign.right,
              style: TextStyle(color: colors[s], fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.35)),
          ),
        ]),
      );
}
