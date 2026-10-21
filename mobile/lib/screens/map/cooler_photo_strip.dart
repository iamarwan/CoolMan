// lib/screens/map/cooler_photo_strip.dart
//
// The photos at the top of the cooler sheet: loads the cooler's approved photos,
// shows them as a swipeable strip, and opens one full screen when tapped.
// With no photos it shows a friendly placeholder and an "add photo" button.

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/cooler_photo.dart';
import '../../services/api_client.dart';

class CoolerPhotoStrip extends StatefulWidget {
  final Future<List<CoolerPhoto>> Function() load;
  final VoidCallback onAddPhoto;

  const CoolerPhotoStrip({super.key, required this.load, required this.onAddPhoto});

  @override
  State<CoolerPhotoStrip> createState() => _CoolerPhotoStripState();
}

class _CoolerPhotoStripState extends State<CoolerPhotoStrip> {
  static const double _height = 190;

  late Future<List<CoolerPhoto>> _future;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _retry() => setState(() => _future = widget.load());

  String _url(CoolerPhoto p) => '${ApiConfig.baseUrl}${p.filePath}';

  void _openFullscreen(List<CoolerPhoto> photos, int start) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenPhotos(
        urls: photos.map(_url).toList(),
        start: start,
      ),
    ));
  }

  Widget _box({required Widget child}) => Container(
        height: _height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoolerPhoto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _box(child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return _box(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.slate400, size: 32),
                const SizedBox(height: 8),
                Text(friendlyError(snapshot.error!, 'Could not load photos.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                TextButton(onPressed: _retry, child: const Text('Try again')),
              ],
            ),
          );
        }
        final photos = snapshot.data ?? const <CoolerPhoto>[];
        if (photos.isEmpty) {
          return _box(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_outlined, color: AppColors.slate400, size: 36),
                const SizedBox(height: 8),
                const Text('No photos of this cooler yet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate600)),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: widget.onAddPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Add the first photo'),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: _height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _openFullscreen(photos, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        _url(photos[i]),
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppColors.slate100,
                                child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.slate100,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.slate400, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (photos.length > 1)
                Positioned(
                  right: 14,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_page + 1} / ${photos.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen, swipeable, zoomable view of the cooler's photos.
class _FullscreenPhotos extends StatelessWidget {
  final List<String> urls;
  final int start;

  const _FullscreenPhotos({required this.urls, required this.start});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: start),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
