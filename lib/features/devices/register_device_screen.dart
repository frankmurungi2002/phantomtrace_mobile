import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

class RegisterDeviceScreen extends StatefulWidget {
  const RegisterDeviceScreen({super.key});

  @override
  State<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> {
  final _nameController = TextEditingController();
  final _gsmController = TextEditingController();
  bool _loading = false;
  String? _error;

  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));

  @override
  void dispose() {
    _nameController.dispose();
    _gsmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a device name.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final token = await TokenService().getToken();
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/register',
        data: {
          'device_name': name,
          if (_gsmController.text.trim().isNotEmpty)
            'gsm_number': _gsmController.text.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('$name registered successfully!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
        Navigator.pop(context, true); // true = refresh dashboard
      } else {
        final msg = response.data['message'] ?? 'Registration failed.';
        setState(() { _error = msg.toString(); _loading = false; });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Register Device'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROTECT A NEW LAPTOP',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a device to monitor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                Container(
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
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device Name *',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. My HP Pavilion, Black ThinkPad',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.25)),
                        prefixIcon: const Icon(Icons.laptop,
                            color: Colors.white38, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('GSM Phone Number (optional)',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'If you have the GSM hardware module installed',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _gsmController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. 0700123456',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.25)),
                        prefixIcon: const Icon(Icons.sim_card,
                            color: Colors.white38, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('After registering',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.w700)),
                    ]),
                    SizedBox(height: 10),
                    Text(
                      '1. Download PhantomTraceAgent.exe from your dashboard\n'
                      '2. Copy it to C:\\PhantomTrace\\ on the laptop\n'
                      '3. Run it — the laptop will appear Online',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _register,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_loading ? 'Registering...' : 'Register Device'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
