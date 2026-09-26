import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/device.dart';
import '../../models/device_overview.dart';
import '../../services/command_service.dart';
import '../../services/device_overview_service.dart';
import '../../services/report_service.dart';
import '../../services/token_service.dart';
import '../commands/command_center_screen.dart';
import '../evidence/evidence_screen.dart';
import '../location/location_trail_screen.dart';
import 'safe_zone_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceId;
  final String initialStatus; // 'SAFE' or 'STOLEN'

  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
    this.initialStatus = 'SAFE',
  });

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen>
    with WidgetsBindingObserver {
  DeviceOverview? _overview;
  bool _loading = true;
  bool _locking = false;
  bool _updatingStatus = false;
  bool _generatingReport = false;
  late String _status;
  Timer? _refreshTimer;

  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
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
      final overview =
          await DeviceOverviewService().getOverview(token!, widget.deviceId);
      if (mounted) setState(() { _overview = overview; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _generatingReport = true);
    try {
      await ReportService().downloadAndShare(
          widget.deviceId, _overview?.hostname ?? 'device');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingReport = false);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lock command sent — device will lock within seconds'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send lock command')));
      }
    }
    if (mounted) setState(() => _locking = false);
  }

  Future<void> _toggleStolenStatus() async {
    final isStolen = _status == 'STOLEN';
    final action = isStolen ? 'Mark as Found' : 'Mark as Stolen';
    final confirmText = isStolen
        ? 'This will mark the device as recovered and stop theft tracking.'
        : 'This will mark the device as stolen and begin active tracking.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(action, style: const TextStyle(color: Colors.white)),
        content: Text(confirmText, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action,
                style: TextStyle(color: isStolen ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _updatingStatus = true);
    try {
      final token = await TokenService().getToken();
      final endpoint = isStolen ? 'mark-found' : 'mark-stolen';
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/$endpoint',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => _status = isStolen ? 'SAFE' : 'STOLEN');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor:
                isStolen ? Colors.green.shade800 : Colors.red.shade800,
            content: Text(isStolen
                ? 'Device marked as found. Tracking stopped.'
                : 'Device marked as stolen. Tracking active.'),
          ));
        }
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update device status')));
      }
    }
    if (mounted) setState(() => _updatingStatus = false);
  }

  @override
  Widget build(BuildContext context) {
    final isStolen = _status == 'STOLEN';

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
              ? const Center(
                  child: Text('Failed to load',
                      style: TextStyle(color: Colors.white)))
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
                          border: isStolen
                              ? Border.all(
                                  color: Colors.red.withOpacity(0.5), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DEVICE INTELLIGENCE',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Text(_overview!.hostname,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isStolen
                                      ? Colors.red
                                      : _overview!.online
                                          ? AppColors.success
                                          : AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isStolen
                                    ? 'STOLEN'
                                    : _overview!.online ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: isStolen
                                      ? Colors.red
                                      : _overview!.online
                                          ? AppColors.success
                                          : AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mark Stolen / Mark Found
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStolen
                                ? Colors.green.shade800
                                : Colors.red.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _updatingStatus ? null : _toggleStolenStatus,
                          icon: _updatingStatus
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(isStolen
                                  ? Icons.check_circle_outline
                                  : Icons.report_problem_outlined),
                          label: Text(_updatingStatus
                              ? 'Updating...'
                              : isStolen
                                  ? 'Mark as Found'
                                  : 'Mark as Stolen'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lock button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _locking ? null : _lockDevice,
                          icon: _locking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.lock),
                          label:
                              Text(_locking ? 'Sending Lock...' : 'Lock Device'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Evidence + Commands
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EvidenceScreen(
                                      deviceId: widget.deviceId)),
                            ).then((_) => _loadOverview()),
                            child: const Text('Evidence'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CommandCenterScreen(
                                      deviceId: widget.deviceId)),
                            ).then((_) => _loadOverview()),
                            child: const Text('Commands'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Location Trail
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LocationTrailScreen(
                                    deviceId: widget.deviceId)),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Location Trail'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Safe Zone (geofence)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SafeZoneScreen(
                                      deviceId: widget.deviceId,
                                      currentLat: _overview?.latitude,
                                      currentLng: _overview?.longitude,
                                    )),
                          ),
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text('Set Safe Zone'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Recovery Report (police PDF)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _generatingReport ? null : _generateReport,
                          icon: _generatingReport
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white70))
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(_generatingReport
                              ? 'Generating...'
                              : 'Recovery Report (PDF)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Metrics
                      Row(children: [
                        Expanded(child: _metricCard(
                            'Processes', _overview!.processCount.toString())),
                        const SizedBox(width: 12),
                        Expanded(child: _metricCard(
                            'Commands', _overview!.commandCount.toString())),
                      ]),
                      const SizedBox(height: 20),

                      _section('SYSTEM', [
                        _row('Hostname', _overview!.hostname),
                        _row('Username', _overview!.username),
                        _row('Operating System', _overview!.osName),
                        _row('Version', _overview!.osVersion),
                      ]),
                      const SizedBox(height: 16),

                      _section('NETWORK', [
                        _row('IP Address', _overview!.ipAddress),
                        _row('MAC Address', _overview!.macAddress),
                      ]),
                      const SizedBox(height: 16),

                      _section('STORAGE', [
                        _row('Free Disk', '${_overview!.freeGb} GB'),
                        _row('Used Disk', '${_overview!.usedGb} GB'),
                        _row('Total Disk', '${_overview!.totalGb} GB'),
                      ]),
                      const SizedBox(height: 16),

                      _section('LOCATION', [
                        if (_overview!.area.isNotEmpty)
                          _row('Area', _overview!.area),
                        _row('City', _overview!.city),
                        _row('Country', _overview!.country),
                        _row('ISP', _overview!.isp),
                        _row('Public IP', _overview!.locationIp),
                        if (_overview!.latitude != null)
                          _row('Coordinates',
                              '${_overview!.latitude!.toStringAsFixed(4)}, ${_overview!.longitude!.toStringAsFixed(4)}'),
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
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800)),
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
        SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
