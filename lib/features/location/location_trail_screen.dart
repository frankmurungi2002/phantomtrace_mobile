import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sighting.dart';
import '../../services/sighting_service.dart';
import '../../services/token_service.dart';

/// Shows where a laptop has been: its reported locations on a map, joined
/// into a path, plus a newest-first timeline. Tapping a timeline entry
/// flies the map to that spot.
class LocationTrailScreen extends StatefulWidget {
  final String deviceId;
  final SightingService? service;

  const LocationTrailScreen({super.key, required this.deviceId, this.service});

  @override
  State<LocationTrailScreen> createState() => _LocationTrailScreenState();
}

class _LocationTrailScreenState extends State<LocationTrailScreen> {
  final _map = MapController();
  bool _mapReady = false;

  /// Newest first, as the backend returns them.
  List<Sighting> _points = [];
  bool _loading = true;
  String? _error;
  int _selected = 0;

  static final _timeFmt = DateFormat('d MMM, HH:mm');
  static final _dayFmt  = DateFormat('EEE d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = _points.isEmpty; _error = null; });
    try {
      final token = await TokenService().getToken();
      final all = await (widget.service ?? SightingService()).getSightings(token!, widget.deviceId);
      final valid = all
          .where((s) => !(s.latitude == 0 && s.longitude == 0))
          .toList();
      if (!mounted) return;
      setState(() { _points = valid; _selected = 0; _loading = false; });
      _fitAll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the location trail. Check your internet and try again.';
      });
    }
  }

  LatLng _ll(Sighting s) => LatLng(s.latitude, s.longitude);

  void _fitAll() {
    if (!_mapReady || _points.isEmpty) return;
    if (_points.length == 1) {
      _map.move(_ll(_points.first), 15);
      return;
    }
    _map.fitCamera(CameraFit.coordinates(
      coordinates: _points.map(_ll).toList(),
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      maxZoom: 16,
    ));
  }

  void _select(int i) {
    setState(() => _selected = i);
    if (_mapReady) {
      _map.move(_ll(_points[i]), _map.camera.zoom < 14 ? 15 : _map.camera.zoom);
    }
  }

  /// Total path length in metres, walking oldest → newest.
  double get _distanceMetres {
    const d = Distance();
    var total = 0.0;
    for (var i = 0; i < _points.length - 1; i++) {
      total += d.as(LengthUnit.Meter, _ll(_points[i]), _ll(_points[i + 1]));
    }
    return total;
  }

  String _formatDistance(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km';

  String _ago(DateTime? t) {
    if (t == null) return 'Unknown time';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return _timeFmt.format(t);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Location Trail'),
        actions: [
          if (_points.length > 1)
            IconButton(
              tooltip: 'Show whole trail',
              icon: const Icon(Icons.zoom_out_map_rounded),
              onPressed: _fitAll,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _points.isEmpty) {
      return _message(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        text: _error!,
        action: 'Try again',
      );
    }
    if (_points.isEmpty) {
      return _message(
        icon: Icons.location_searching_rounded,
        title: 'No locations yet',
        text: 'Once the PhantomTrace agent on this laptop reports its '
            'location, every place it goes will show up here.',
        action: 'Refresh',
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final mapHeight = (c.maxHeight * 0.45).clamp(220.0, 440.0);
      return Column(children: [
        SizedBox(height: mapHeight, child: _mapView()),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _stats(),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text('TIMELINE',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                for (var i = 0; i < _points.length; i++) _timelineTile(i),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  Widget _mapView() {
    // Oldest → newest for drawing the path.
    final path = _points.reversed.map(_ll).toList();
    final latest = _points.first;
    final oldest = _points.last;
    final sel = _points[_selected];

    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _ll(latest),
          initialZoom: 14,
          backgroundColor: const Color(0xFF0E1320),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onMapReady: () {
            _mapReady = true;
            _fitAll();
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: 'com.phantomtrace.app',
          ),
          if (path.length > 1)
            PolylineLayer(polylines: [
              Polyline(
                points: path,
                strokeWidth: 4,
                color: AppColors.primary.withValues(alpha: 0.85),
                borderStrokeWidth: 2,
                borderColor: Colors.black.withValues(alpha: 0.4),
              ),
            ]),
          MarkerLayer(markers: [
            for (var i = 1; i < _points.length - 1; i++)
              Marker(
                point: _ll(_points[i]),
                width: 12, height: 12,
                child: _dot(AppColors.primary, 12),
              ),
            if (_points.length > 1)
              Marker(
                point: _ll(oldest),
                width: 18, height: 18,
                child: _dot(AppColors.success, 18),
              ),
            if (_selected != 0)
              Marker(
                point: _ll(sel),
                width: 26, height: 26,
                child: _dot(AppColors.warning, 26, ring: true),
              ),
            Marker(
              point: _ll(latest),
              width: 44, height: 44,
              child: const _PulseMarker(),
            ),
          ]),
          const RichAttributionWidget(
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
              TextSourceAttribution('CARTO'),
            ],
          ),
        ],
      ),
      Positioned(
        left: 12, top: 12,
        child: _legend(),
      ),
    ]);
  }

  Widget _dot(Color c, double size, {bool ring = false}) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: ring ? c.withValues(alpha: 0.25) : c,
          shape: BoxShape.circle,
          border: Border.all(color: ring ? c : Colors.white, width: ring ? 3 : 2),
        ),
      );

  Widget _legend() {
    Widget item(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        item(AppColors.danger, 'Latest'),
        if (_points.length > 1) ...[
          const SizedBox(height: 4),
          item(AppColors.success, 'Start'),
        ],
      ]),
    );
  }

  Widget _stats() {
    final latest = _points.first;
    final oldest = _points.last;
    final span = (latest.timestamp != null && oldest.timestamp != null)
        ? latest.timestamp!.difference(oldest.timestamp!)
        : null;
    String spanText() {
      if (span == null) return '—';
      if (span.inDays >= 1) return '${span.inDays} d';
      if (span.inHours >= 1) return '${span.inHours} h';
      return '${span.inMinutes} min';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location_rounded, color: AppColors.danger),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LAST SEEN',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(latest.placeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                latest.timestamp == null
                    ? _ago(null)
                    : '${_ago(latest.timestamp)} · ${_dayFmt.format(latest.timestamp!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statTile('Places', '${_points.length}', Icons.place_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('Distance', _formatDistance(_distanceMetres), Icons.route_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('Over', spanText(), Icons.schedule_rounded)),
      ]),
    ]);
  }

  Widget _statTile(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      );

  Widget _timelineTile(int i) {
    final s = _points[i];
    final isLatest = i == 0;
    final isFirst = i == _points.length - 1;
    final selected = i == _selected;
    final dotColor = isLatest
        ? AppColors.danger
        : (isFirst ? AppColors.success : AppColors.primary);

    return InkWell(
      onTap: () => _select(i),
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Rail: dot with a connecting line to the next entry.
          SizedBox(
            width: 28,
            child: Column(children: [
              Container(
                width: 2, height: 16,
                color: isLatest ? Colors.transparent : AppColors.surfaceElevated,
              ),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst ? Colors.transparent : AppColors.surfaceElevated,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.surfaceElevated : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(s.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                  if (isLatest || isFirst) ...[
                    const SizedBox(width: 8),
                    _chip(isLatest ? 'Latest' : 'Start', dotColor),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(
                  s.timestamp == null ? 'Unknown time' : _timeFmt.format(s.timestamp!),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}'
                  '${s.isp != 'Unknown' ? ' · ${s.isp}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _message({
    required IconData icon,
    required String title,
    required String text,
    required String action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(action),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Red dot with an expanding ring, marking the laptop's latest position.
class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(alignment: Alignment.center, children: [
        Container(
          width: 16 + 28 * _c.value,
          height: 16 + 28 * _c.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.35 * (1 - _c.value)),
          ),
        ),
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ]),
    );
  }
}
