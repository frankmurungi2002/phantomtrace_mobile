import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';
import 'pair_device_screen.dart';
import 'bios_setup_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  Future<List<Device>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDevices();
  }

  Future<List<Device>> _loadDevices() async {
    final token = await TokenService().getToken();
    if (token == null) return [];
    return DeviceService().getDevices(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadDevices());
    await _future;
  }

  Future<void> _openPairFlow() async {
    final paired = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
    );
    if (paired == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPairFlow,
        icon: const Icon(Icons.add),
        label: const Text('Add device'),
        backgroundColor: const Color(0xFFE11D48),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Devices',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Monitor every protected endpoint.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFFE11D48),
                  child: FutureBuilder<List<Device>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final devices = snapshot.data ?? [];
                      if (devices.isEmpty) return _emptyState();
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: devices.length,
                        itemBuilder: (context, i) => _deviceTile(devices[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.laptop_outlined,
                size: 48, color: Color(0xFFE11D48)),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('No devices yet',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pair your first laptop to start protecting it. '
            'It only takes 30 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: _openPairFlow,
              icon: const Icon(Icons.add),
              label: const Text('Pair a device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteDevice(Device d) async {
    // Two options: Graceful (tell agent to self-uninstall first; recommended
    // if the laptop is still online) vs Force (just wipe the DB row;
    // leaves a zombie agent on the laptop until the owner removes it
    // manually, used when the laptop is gone or offline forever).
    final choice = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Remove this device?',
            style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '"${d.deviceName}" will be removed from your account.\n',
            style: const TextStyle(color: Colors.white70),
          ),
          const Text(
            'Clean uninstall tells the agent on the laptop to tear itself '
            'down — removes autostart, deletes device.json, deletes the '
            'PhantomTraceAgent.exe. Use this when the laptop is still '
            'with you.\n',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const Text(
            'Force remove deletes the record immediately. Use this only if '
            'the laptop is lost, offline forever, or already handled '
            'manually. Any still-running agent becomes orphaned.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'force'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Force remove'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'graceful'),
            child: const Text('Clean uninstall'),
          ),
        ],
      ),
    );
    if (choice == null) return;

    try {
      final token = await TokenService().getToken();
      final dio = Dio(BaseOptions(validateStatus: (s) => true));
      final r = await dio.delete(
        '${ApiConstants.baseUrl}/api/device/${d.id}?mode=$choice',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 202) {
        final msg = r.statusCode == 202
            ? 'Uninstall sent to ${d.deviceName}. The laptop will clean up as soon as it checks in.'
            : '${d.deviceName} removed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg),
              backgroundColor: Colors.green.shade800),
        );
        await _refresh();
      } else {
        final msg = r.data is Map
            ? (r.data['error'] ?? 'Delete failed')
            : 'Delete failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()),
              backgroundColor: Colors.red.shade800),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _deviceTile(Device d) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: d.online
                ? const Color(0x3322C55E)
                : const Color(0x33F59E0B),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.laptop,
              color: d.online ? const Color(0xFF22C55E) : Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: device name (left) + delete icon (extreme right,
              // on the SAME line as the ONLINE/OFFLINE label just below).
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d.deviceName,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _deleteDevice(d),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(d.status, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Row(children: [
                Text(
                  d.online ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: d.online ? const Color(0xFF22C55E) : Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                // Yellow BIOS warning badge — the device isn't protected
                // against USB boot yet. Tap to open the setup wizard.
                if (!d.biosProtected)
                  GestureDetector(
                    onTap: () => _openBiosSetup(d),
                    child: Container(
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
                  ),
              ]),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white70),
      ],
    ),
  );

  /// Opens the BIOS setup wizard for this device. Called from the yellow
  /// warning badge in the tile.
  void _openBiosSetup(Device d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiosSetupScreen(deviceId: d.id, deviceName: d.deviceName),
      ),
    ).then((_) => _refresh());
  }
}
