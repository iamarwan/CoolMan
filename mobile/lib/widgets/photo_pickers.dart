// lib/widgets/photo_pickers.dart
//
// The two bottom sheets shown when adding a photo to a cooler:
//   1) pickPhotoCategory: "what is the photo of?"  -> 'Cooler' or 'Cups' (null if dismissed)
//   2) pickImageSource:   "camera or gallery?"     -> ImageSource (null if dismissed)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

/// The small grey bar at the top of a bottom sheet.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

Future<String?> pickPhotoCategory(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: _sheetShape,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Categorize Photo Attachment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.slate800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined, color: AppColors.primary),
              title: const Text('Entire Cooler Unit'),
              subtitle: const Text('Verify physical address and condition'),
              onTap: () => Navigator.pop(ctx, 'Cooler'),
            ),
            ListTile(
              leading: const Icon(Icons.coffee_outlined, color: AppColors.primary),
              title: const Text('Cups Rack Stock'),
              subtitle: const Text('Refill status of disposable stock'),
              onTap: () => Navigator.pop(ctx, 'Cups'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<ImageSource?> pickImageSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    shape: _sheetShape,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Capture with Device Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Import from Photo Stream'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
