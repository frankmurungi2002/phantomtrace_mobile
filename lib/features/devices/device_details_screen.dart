import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/device_overview.dart';
import '../../services/command_service.dart';
import '../../services/device_overview_service.dart';
import '../../services/token_service.dart';
import '../commands/command_center_screen.dart';
import '../evidence/evidence_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceId;
  const DeviceDetailsScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen>
    with WidgetsBindingObserver {
  DeviceOverview? _overview;
  bool _loading = true;
  bool _locking = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOverview();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOverview());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final token = await TokenService().getToken();
      final overview = await DeviceOverviewService().getOverview(token!, widget.deviceId);
      if (mounted) setState(() { _overview = overview; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _lockDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Lock Device', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will immediately lock the screen on the remote device. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lock Now', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _locking = true);
    try {
      final token = await TokenService().getToken();
      await CommandService().sendCommand(token!, widget.deviceId, 'LOCK');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Lock command sent — device will lock within seconds'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send lock command')),
        );
      }
    }
    if (mounted) setState(() => _locking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Overview'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOverview),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _overview == null
              ? const Center(child: Text('Failed to load', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Status card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DEVICE INTELLIGENCE',
                                style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Text(_overview!.hostname,
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  color: _overview!.online ? AppColors.success : AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _overview!.online ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: _overview!.online ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lock button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _locking ? null : _lockDevice,
                          icon: _locking
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.lock),
                          label: Text(_locking ? 'Sending Lock...' : 'Lock Device'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Evidence + Commands buttons
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => EvidenceScreen(deviceId: widget.deviceId)),
                            ).then((_) => _loadOverview()),
                            child: const Text('Evidence'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => CommandCenterScreen(deviceId: widget.deviceId)),
                            ).then((_) => _loadOverview()),
                            child: const Text('Commands'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Metrics
                      Row(children: [
                        Expanded(child: _metricCard('Processes', _overview!.processCount.toString())),
                        const SizedBox(width: 12),
                        Expanded(child: _metricCard('Commands', _overview!.commandCount.toString())),
                      ]),
                      const SizedBox(height: 20),

                      // System
                      _section('SYSTEM', [
                        _row('Hostname', _overview!.hostname),
                        _row('Username', _overview!.username),
                        _row('Operating System', _overview!.osName),
                        _row('Version', _overview!.osVersion),
                      ]),
                      const SizedBox(height: 16),

                      // Network
                      _section('NETWORK', [
                        _row('IP Address', _overview!.ipAddress),
                        _row('MAC Address', _overview!.macAddress),
                      ]),
                      const SizedBox(height: 16),

                      // Storage
                      _section('STORAGE', [
                        _row('Free Disk', '${_overview!.freeGb} GB'),
                        _row('Used Disk', '${_overview!.usedGb} GB'),
                        _row('Total Disk', '${_overview!.totalGb} GB'),
                      ]),
                      const SizedBox(height: 16),

                      // Location
                      _section('LOCATION', [
                        if (_overview!.area.isNotEmpty)
                          _row('Area', _overview!.area),
                        _row('City', _overview!.city),
                        _row('Country', _overview!.country),
                        _row('ISP', _overview!.isp),
                        _row('Public IP', _overview!.locationIp),
                        if (_overview!.latitude != null)
                          _row('Coordinates', '${_overview!.latitude!.toStringAsFixed(4)}, ${_overview!.longitude!.toStringAsFixed(4)}'),
                        if (_overview!.latitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final lat = _overview!.latitude!;
                                  final lon = _overview!.longitude!;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Coordinates: $lat, $lon')),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('View Coordinates'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _metricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, letterSpacing: 1.5, color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
