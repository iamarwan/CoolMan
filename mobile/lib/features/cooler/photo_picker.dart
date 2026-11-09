import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/cooler.dart';
import '../../shared/ui.dart';

typedef PickedPhoto = ({String path, PhotoCategory category});

final _picker = ImagePicker();

/// One sheet: choose what the photo shows, then camera or gallery.
/// Images are downscaled on the phone before upload (faster, less data).
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
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
              const Text('What does the photo show?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              SegmentedButton<PhotoCategory>(
                segments: const [
                  ButtonSegment(
                      value: PhotoCategory.cooler,
                      icon: Icon(Icons.water_drop_outlined),
                      label: Text('The cooler')),
                  ButtonSegment(
                      value: PhotoCategory.cups,
                      icon: Icon(Icons.coffee_outlined),
                      label: Text('The cups')),
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
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
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
    if (context.mounted) showSnack(context, 'Could not open the camera or gallery.', error: true);
    return null;
  }
}
