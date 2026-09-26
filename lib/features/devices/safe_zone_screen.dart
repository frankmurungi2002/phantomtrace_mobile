import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/token_service.dart';

/// Lets the owner define a "safe zone" (geofence). If the laptop leaves this
/// circle, the agent pushes an alert. Center defaults to the device's last
/// known location; radius is chosen with a slider.
class SafeZoneScreen extends StatefulWidget {
  final String deviceId;
  final double? currentLat;
  final double? currentLng;

  const SafeZoneScreen({
    super.key,
    required this.deviceId,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  double _radius = 300; // metres
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final token = await TokenService().getToken();
      final r = await _dio.get(
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/geofence',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (r.statusCode == 200 && r.data != null) {
        final lat = (r.data['home_lat'] as num?)?.toDouble();
        final lng = (r.data['home_lng'] as num?)?.toDouble();
        final rad = (r.data['geofence_radius'] as num?)?.toDouble();
        if (lat != null) _latCtrl.text = lat.toStringAsFixed(6);
        if (lng != null) _lngCtrl.text = lng.toStringAsFixed(6);
        if (rad != null) _radius = rad.clamp(100, 5000);
      }
    } catch (_) {}
    // fall back to the device's current location if nothing saved yet
    if (_latCtrl.text.isEmpty && widget.currentLat != null) {
      _latCtrl.text = widget.currentLat!.toStringAsFixed(6);
    }
    if (_lngCtrl.text.isEmpty && widget.currentLng != null) {
      _lngCtrl.text = widget.currentLng!.toStringAsFixed(6);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _useDeviceLocation() {
    if (widget.currentLat != null && widget.currentLng != null) {
      setState(() {
        _latCtrl.text = widget.currentLat!.toStringAsFixed(6);
        _lngCtrl.text = widget.currentLng!.toStringAsFixed(6);
      });
    } else {
      _snack('No recent device location available yet.');
    }
  }

  Future<void> _save({bool clear = false}) async {
    double? lat, lng, rad;
    if (!clear) {
      lat = double.tryParse(_latCtrl.text.trim());
      lng = double.tryParse(_lngCtrl.text.trim());
      rad = _radius;
      if (lat == null || lng == null) {
        _snack('Enter a valid latitude and longitude.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final token = await TokenService().getToken();
      final r = await _dio.post(
        '${ApiConstants.baseUrl}/api/device/${widget.deviceId}/geofence',
        data: {'home_lat': lat, 'home_lng': lng, 'geofence_radius': rad},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (r.statusCode == 200) {
        _snack(clear ? 'Safe zone cleared.' : 'Safe zone saved.');
        if (mounted) Navigator.pop(context);
      } else {
        _snack('Save failed (${r.statusCode}).');
      }
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safe Zone'),
        backgroundColor: AppColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If your device leaves this zone, you will get an alert.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  _label('Center latitude'),
                  _field(_latCtrl, 'e.g. -0.6167'),
                  const SizedBox(height: 16),
                  _label('Center longitude'),
                  _field(_lngCtrl, 'e.g. 30.6586'),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _useDeviceLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text("Use device's current location"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label('Radius: ${_radius.round()} m'),
                  Slider(
                    value: _radius,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    label: '${_radius.round()} m',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _saving ? null : () => _save(),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.shield_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Safe Zone'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _saving ? null : () => _save(clear: true),
                      child: const Text('Clear Safe Zone',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: true),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );
}
