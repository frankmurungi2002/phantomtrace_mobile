import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';
import '../auth/login_screen.dart';
import '../devices/device_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Device> _devices = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadDevices());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final token = await TokenService().getToken();
      if (token == null) { _logout(); return; }
      final devices = await DeviceService().getDevices(token);
      if (mounted) setState(() { _devices = devices; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not connect to server.'; _loading = false; });
    }
  }

  void _logout() async {
    await TokenService().clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null ? _buildError()
          : _devices.isEmpty ? _buildEmpty()
          : _buildDashboard(),
    );
  }

  Widget _buildError() {
    return SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off, color: Colors.red, size: 64),
        const SizedBox(height: 24),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () { setState(() { _loading = true; _error = null; }); _loadDevices(); },
          icon: const Icon(Icons.refresh), label: const Text('Retry'),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: _logout, child: const Text('Log Out', style: TextStyle(color: Colors.white38))),
      ]),
    )));
  }

  Widget _buildEmpty() {
    return SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.devices_other, color: Colors.white24, size: 64),
        const SizedBox(height: 24),
        const Text('No Devices Found', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () { setState(() => _loading = true); _loadDevices(); },
          icon: const Icon(Icons.refresh), label: const Text('Refresh'),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: _logout, child: const Text('Log Out', style: TextStyle(color: Colors.white38))),
      ]),
    )));
  }

  Widget _buildDashboard() {
    final onlineCount = _devices.where((d) => d.online).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PHANTOMTRACE',
                    style: TextStyle(fontSize: 13, letterSpacing: 4, color: Colors.white70)),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white38),
                  tooltip: 'Log Out',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF111827),
                      title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () { Navigator.pop(context); _logout(); },
                          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Security Operations',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                Expanded(child: _stat('Devices', '${_devices.length}')),
                Expanded(child: _stat('Online', '$onlineCount', center: true)),
                Expanded(child: _stat('Offline', '${_devices.length - onlineCount}', end: true)),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('ENDPOINTS',
                style: TextStyle(fontSize: 13, letterSpacing: 3, color: Colors.white54)),
            const SizedBox(height: 16),
            ..._devices.map((device) => _deviceCard(device)),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(Device device) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: device.online ? Colors.green.withAlpha(60) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: device.online ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  device.online ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: device.online ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(device.deviceName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Last Seen: ${device.lastSeen}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeviceDetailsScreen(deviceId: device.id)),
                ).then((_) => _loadDevices()),
                child: const Text('Open Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {bool center = false, bool end = false}) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
