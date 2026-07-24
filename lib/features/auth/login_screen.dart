import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController(
    text:
        'frankmurungi2002@gmail.com',
  );

  final passwordController =
      TextEditingController(
    text: 'Uttorent@24',
  );

  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    try {
      final token =
          await AuthService().login(
        emailController.text,
        passwordController.text,
      );

      if (token != null) {
        await TokenService()
            .saveToken(token);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              AppColors.surface,
          content: Text(
            'Login failed',
            style: const TextStyle(
              color:
                  AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 420,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    28,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      28,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'PHANTOMTRACE',
                        style:
                            Theme.of(context)
                                .textTheme
                                .headlineMedium,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'Enterprise Endpoint Security',
                        style:
                            TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 40,
                      ),

                      const Text(
                        'Email Address',
                        style:
                            TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextField(
                        controller:
                            emailController,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Text(
                        'Password',
                        style:
                            TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextField(
                        controller:
                            passwordController,
                        obscureText: true,
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton(
                          onPressed:
                              loading
                                  ? null
                                  : login,
                          child: Text(
                            loading
                                ? 'Signing In...'
                                : 'Sign In',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      const Center(
                        child: Text(
                          'Secure Access Portal',
                          style:
                              TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize: 12,
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
}
