import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../models/cooler.dart';

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.photos, this.initialIndex = 0});

  final List<CoolerPhoto> photos;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: Image.network(
              AppConfig.absoluteUrl(photos[i].url),
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
