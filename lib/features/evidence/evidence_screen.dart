import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/evidence_photo.dart';
import '../../services/evidence_service.dart';
import '../../services/token_service.dart';
import 'photo_viewer_screen.dart';

class EvidenceScreen extends StatefulWidget {
  final String deviceId;
  const EvidenceScreen({super.key, required this.deviceId});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late TabController _tabController;
  List<EvidencePhoto> _allPhotos = [];
  bool _loading = true;
  Timer? _refreshTimer;
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadEvidence();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadEvidence());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(this.context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Called when user navigates BACK to this screen
    _loadEvidence();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEvidence();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    try {
      final token = await TokenService().getToken();
      final photos = await EvidenceService().getPhotos(token!, widget.deviceId);
      if (mounted) {
        setState(() {
          _allPhotos = photos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final webcamPhotos = _allPhotos.where((p) => p.photoType == 'WEBCAM').toList();
    final screenshots = _allPhotos.where((p) => p.photoType == 'SCREENSHOT').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('Evidence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvidence,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              icon: const Icon(Icons.face_retouching_natural),
              text: 'Webcam (${webcamPhotos.length})',
            ),
            Tab(
              icon: const Icon(Icons.screenshot_monitor),
              text: 'Screenshots (${screenshots.length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPhotoList(webcamPhotos, 'Webcam Photo',
                    Icons.face_retouching_natural, Colors.red),
                _buildPhotoList(screenshots, 'Screenshot',
                    Icons.screenshot_monitor, Colors.blue),
              ],
            ),
    );
  }

  Widget _buildPhotoList(
      List<EvidencePhoto> photos, String label, IconData icon, Color color) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No $label evidence yet',
                style: const TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Send a command from the control panel',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvidence,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PhotoViewerScreen(photoId: photo.id, label: label),
              ),
            ).then((_) => _loadEvidence()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: index == 0
                    ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          'http://192.168.1.76:5000/api/evidence/photo/${photo.id}',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: const Color(0xFF1F2937),
                        child: Center(
                            child: Icon(icon, color: Colors.white24, size: 48)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('LATEST',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM • HH:mm')
                              .format(DateTime.parse(photo.timestamp)),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
