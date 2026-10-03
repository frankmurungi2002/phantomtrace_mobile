import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';
import '../auth/login_screen.dart';
import '../devices/device_details_screen.dart';
import '../devices/pair_device_screen.dart';
import '../help/help_screen.dart';
import '../settings/settings_screen.dart';

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

  void _goToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
    );
    if (result == true) {
      setState(() => _loading = true);
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToRegister,
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Device',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
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
        const Text('No Devices Yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Tap "Add Device" to protect your first laptop',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _goToRegister,
          icon: const Icon(Icons.add),
          label: const Text('Add Device'),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: _logout, child: const Text('Log Out', style: TextStyle(color: Colors.white38))),
      ]),
    )));
  }

  Widget _buildDashboard() {
    final onlineCount = _devices.where((d) => d.online).length;
    final stolenCount = _devices.where((d) => d.status == 'STOLEN').length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PHANTOMTRACE',
                    style: TextStyle(fontSize: 13, letterSpacing: 4, color: Colors.white70)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white54),
                  tooltip: 'Help & FAQ',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white54),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
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
                ]),
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
                Expanded(child: _stat(
                  stolenCount > 0 ? 'STOLEN' : 'Offline',
                  stolenCount > 0 ? '$stolenCount' : '${_devices.length - onlineCount}',
                  end: true,
                  color: stolenCount > 0 ? Colors.red : null,
                )),
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
    final isStolen = device.status == 'STOLEN';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isStolen
                ? Colors.red.withOpacity(0.5)
                : device.online
                    ? Colors.green.withAlpha(60)
                    : Colors.transparent,
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
                    color: isStolen ? Colors.red : device.online ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isStolen ? 'STOLEN' : device.online ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: isStolen ? Colors.red : device.online ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                // BIOS protection warning — tap-through handled by the whole
                // card's Open Device button; here we just signal the status.
                if (!device.biosProtected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.amberAccent.withOpacity(0.7)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amberAccent, size: 12),
                      SizedBox(width: 4),
                      Text('BIOS',
                          style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(device.deviceName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Last seen: ${_humanizeLastSeen(device.lastSeen)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeviceDetailsScreen(deviceId: device.id)),
                ).then((_) => _loadDevices()),
                style: isStolen
                    ? ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800)
                    : null,
                child: Text(isStolen ? 'Track Device' : 'Open Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Turn a raw ISO timestamp like "2026-10-03T16:54:09.973067" into
  /// something a human reads at a glance: "just now", "5 min ago",
  /// "2 hours ago", "3 days ago". Falls back to the original string if
  /// parsing fails so we never crash the card over a bad timestamp.
  String _humanizeLastSeen(String s) {
    if (s.isEmpty) return 'unknown';
    try {
      final t = DateTime.tryParse(s)?.toUtc();
      if (t == null) return s;
      final now = DateTime.now().toUtc();
      final diff = now.difference(t);
      if (diff.inSeconds < 10)   return 'just now';
      if (diff.inSeconds < 60)   return '${diff.inSeconds} sec ago';
      if (diff.inMinutes < 60)   return '${diff.inMinutes} min ago';
      if (diff.inHours   < 24)   return '${diff.inHours} h ago';
      if (diff.inDays    < 7)    return '${diff.inDays} d ago';
      return '${(diff.inDays / 7).floor()} w ago';
    } catch (_) {
      return s;
    }
  }

  Widget _stat(String label, String value, {bool center = false, bool end = false, Color? color}) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color ?? Colors.white70)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
