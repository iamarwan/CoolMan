import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/cooler.dart';
import '../../core/locale.dart';
import '../../shared/ui.dart';

typedef PickedPhoto = ({String path, PhotoCategory category});

final _picker = ImagePicker();

/// One sheet: choose what the photo shows, then camera or gallery.
/// Images are downscaled on the phone before upload (faster, less data).
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
  final l = context.l10n;
  var category = PhotoCategory.cooler;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              Text(l.photoWhat,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              SegmentedButton<PhotoCategory>(
                segments: [
                  ButtonSegment(
                      value: PhotoCategory.cooler,
                      icon: const Icon(Icons.water_drop_outlined),
                      label: Text(l.photoCooler)),
                  ButtonSegment(
                      value: PhotoCategory.cups,
                      icon: const Icon(Icons.coffee_outlined),
                      label: Text(l.photoCups)),
                ],
                selected: {category},
                onSelectionChanged: (s) => setSheet(() => category = s.first),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l.gallery),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
  if (source == null) return null;
  try {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    return file == null ? null : (path: file.path, category: category);
  } catch (_) {
    if (context.mounted) showSnack(context, l.errCameraGallery, error: true);
    return null;
  }
}
