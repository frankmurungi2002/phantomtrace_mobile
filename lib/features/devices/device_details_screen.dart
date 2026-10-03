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
      if (mounted) setState(() {
        _overview = overview;
        // IMPORTANT: sync _status from the server too. Otherwise if the
        // user marks the device stolen, backs out, re-enters, our _status
        // is reset from widget.initialStatus (which was passed in as 'SAFE')
        // and the button stubbornly shows "Mark as Stolen" even though the
        // backend knows it's STOLEN.
        if (overview.status.isNotEmpty) _status = overview.status;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renameDevice() async {
    final ctrl = TextEditingController(text: _overview?.hostname ?? '');
    final newName = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Rename device', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New device name',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      final token = await TokenService().getToken();
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/rename',
        data: {'name': newName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (r.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Renamed.')));
        _loadOverview();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            r.data is Map ? (r.data['error'] ?? 'Rename failed') : 'Rename failed')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network error')));
      }
    }
  }

  Future<void> _generateReport() async {
    // Three choices — the user explicitly picks whether to capture fresh
    // evidence (slow, needs device online) or use what's already stored
    // (fast, might be stale). Cancel exits cleanly.
    //   returns: null (cancel) | true (capture fresh) | false (use existing)
    final choice = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Recovery Report',
            style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The report shows the latest 2 webcam shots and 2 screenshots. '
              'Choose how to prepare the evidence:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Text(
              '• Capture fresh: the agent takes a brand-new photo + '
              'screenshot right now (needs the device online — takes ~30s).',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              '• Use existing: builds the report immediately from the latest '
              'images already stored for this device.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        // Two-row button layout: Cancel + Use existing on top (secondary
        // options), then the primary call-to-action "Capture fresh" as its
        // own full-width button below, so the primary action is both the
        // most visually prominent AND never has its label clipped by narrow
        // phones.
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Use existing'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text(
                  'Capture fresh',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
    if (choice == null) return;

    final captureFresh = choice;
    setState(() => _generatingReport = true);
    if (mounted && captureFresh) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 4),
        content: Text(
          'Capturing fresh evidence from the device — this takes about 30 seconds…',
        ),
      ));
    }
    try {
      await ReportService().downloadAndShare(
        widget.deviceId,
        _overview?.hostname ?? 'device',
        captureFresh: captureFresh,
      );
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
                      // ── Device identity card ────────────────────────────
                      // Hostname sits on its own line so it NEVER truncates,
                      // with a small status pill underneath. Icon on the
                      // left, rename pencil docked to the right of the
                      // hostname. Compact but readable.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: isStolen
                              ? Border.all(
                                  color: Colors.red.withOpacity(0.5), width: 1.3)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: (isStolen
                                        ? Colors.red
                                        : _overview!.online
                                            ? AppColors.success
                                            : AppColors.warning)
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isStolen ? Icons.gpp_bad_rounded : Icons.laptop_mac,
                                color: isStolen
                                    ? Colors.red
                                    : _overview!.online
                                        ? AppColors.success
                                        : AppColors.warning,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Hostname row + status pill underneath.
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        _overview!.hostname,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                    // Pencil kept inline so it's always next
                                    // to the name it edits.
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                      tooltip: 'Rename this device',
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.white54, size: 18),
                                      onPressed: _renameDevice,
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  _statusPill(isStolen: isStolen,
                                      online: _overview!.online),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mark Stolen / Mark Found — single tap, high stakes.
                      // Lower padding, matched height with the other primary
                      // buttons on the page for a consistent rhythm.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStolen
                                ? Colors.green.shade800
                                : Colors.red.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _updatingStatus ? null : _toggleStolenStatus,
                          icon: _updatingStatus
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(isStolen
                                  ? Icons.check_circle_outline
                                  : Icons.report_problem_outlined, size: 20),
                          label: Text(
                            _updatingStatus
                                ? 'Updating...'
                                : isStolen
                                    ? 'Mark as Found'
                                    : 'Mark as Stolen',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // (Lock Device moved to Command Center — kept in one place only)
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

  /// Small pill showing ONLINE / OFFLINE / STOLEN with a dot. Used in the
  /// compact Device Intelligence header.
  Widget _statusPill({required bool isStolen, required bool online}) {
    final color = isStolen
        ? Colors.red
        : online ? AppColors.success : AppColors.warning;
    final label = isStolen ? 'STOLEN' : online ? 'ONLINE' : 'OFFLINE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.1,
        )),
      ]),
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
