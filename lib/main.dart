import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const PhantomTraceApp());
}

class PhantomTraceApp extends StatelessWidget {
  const PhantomTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhantomTrace',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
