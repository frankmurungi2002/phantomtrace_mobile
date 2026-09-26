import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';
import 'pair_device_screen.dart';

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
              Text(d.deviceName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(d.status, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                d.online ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: d.online ? const Color(0xFF22C55E) : Colors.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white70),
      ],
    ),
  );
}
