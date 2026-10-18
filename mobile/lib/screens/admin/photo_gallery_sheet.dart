// lib/screens/admin/photo_gallery_sheet.dart
//
// Bottom sheet showing a cooler's photos with approve / delete / add buttons.

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../models/cooler_photo.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';

class AdminPhotoGallerySheet extends StatefulWidget {
  final WaterCooler cooler;
  final ApiService api;

  const AdminPhotoGallerySheet({super.key, required this.cooler, required this.api});

  @override
  State<AdminPhotoGallerySheet> createState() => _AdminPhotoGallerySheetState();
}

class _AdminPhotoGallerySheetState extends State<AdminPhotoGallerySheet> {
  List<CoolerPhoto> _photos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await widget.api.fetchCoolerPhotosAdmin(widget.cooler.id);
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load photos.';
        _loading = false;
      });
    }
  }

  Future<void> _approvePhoto(CoolerPhoto photo) async {
    try {
      await widget.api.approvePhoto(photo.id);
      setState(() {
        final idx = _photos.indexWhere((p) => p.id == photo.id);
        if (idx != -1) {
          _photos[idx] = CoolerPhoto(
            id: photo.id,
            coolerId: photo.coolerId,
            filePath: photo.filePath,
            uploadedAt: photo.uploadedAt,
            isApproved: true,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e, 'Approval failed.')),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _deletePhoto(CoolerPhoto photo) async {
    try {
      await widget.api.deletePhoto(photo.id);
      setState(() => _photos.removeWhere((p) => p.id == photo.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e, 'Delete failed.')),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              headers: ApiService.adminImageHeaders,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.cooler.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_loading && _photos.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_photos.length} item${_photos.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      )
                    : _photos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(60),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No user submitted photos.',
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                            itemCount: _photos.length,
                            itemBuilder: (_, i) {
                              final photo = _photos[i];
                              final url = '${ApiConfig.baseUrl}${photo.filePath}';
                              return GestureDetector(
                                onTap: () => _openFullscreen(context, url),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        url,
                                        headers: ApiService.adminImageHeaders,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey.shade400,
                                              size: 36),
                                        ),
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                                ? child
                                                : Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey.shade500,
                                                        borderRadius:
                                                            BorderRadius.circular(14)),
                                                    child: const Center(
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2, color: Colors.white)),
                                                  ),
                                      ),
                                    ),
                                    if (photo.isApproved)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              color: AppColors.success,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5)),
                                          child: const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 10),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  bottom: Radius.circular(14)),
                                          color: Colors.black.withValues(alpha: 0.65),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            if (!photo.isApproved)
                                              GestureDetector(
                                                onTap: () =>
                                                    _approvePhoto(photo),
                                                child: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Color(0xFF34D399),
                                                    size: 22),
                                              ),
                                            GestureDetector(
                                              onTap: () => _deletePhoto(photo),
                                              child: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.dangerLight,
                                                  size: 22),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
