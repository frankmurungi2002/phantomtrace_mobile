import 'package:flutter/material.dart';
import 'features/devices/device_details_screen.dart';

void main() {
  runApp(const PhantomTraceApp());
}

class PhantomTraceApp extends StatelessWidget {
  const PhantomTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DeviceDetailsScreen(),
    );
  }
}
