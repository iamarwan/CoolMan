// lib/screens/map/add_cooler_dialog.dart
//
// The "Add Public Cooler Point" form. It only collects what the person typed
// and picked; it does not talk to the server. It returns a NewCoolerRequest
// (or null if cancelled) and the caller sends it.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import 'map_widgets.dart';

/// A photo chosen in the form, with what it shows ('Cooler' or 'Cups').
class PhotoDraft {
  final XFile file;
  final String category;
  PhotoDraft(this.file, this.category);
}

/// Everything the add-cooler form collects.
class NewCoolerRequest {
  final String name;
  final List<PhotoDraft> photos;
  NewCoolerRequest({
    required this.name,
    required this.photos,
  });
}

Future<NewCoolerRequest?> showAddCoolerDialog(BuildContext context) async {
  final picker = ImagePicker();
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<PhotoDraft> pickedPhotos = [];
  String pickedCategory = 'Cooler';
  return showDialog<NewCoolerRequest>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Add Public Cooler Point', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Label Name / Landmark',
                      hintText: 'e.g. Next to El-Tawheed Mosque',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (value.trim().length > 255) return 'Length limited to 255 chars';
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Attach verification photos (Recommended)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PhotoCategoryChip(
                          label: 'Cooler Unit',
                          icon: Icons.water_drop_outlined,
                          selected: pickedCategory == 'Cooler',
                          onTap: () => setDialog(() => pickedCategory = 'Cooler'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PhotoCategoryChip(
                          label: 'Cups Rack',
                          icon: Icons.coffee_outlined,
                          selected: pickedCategory == 'Cups',
                          onTap: () => setDialog(() => pickedCategory = 'Cups'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final x = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              imageQuality: 85,
                              requestFullMetadata: false,
                            );
                            if (x != null) setDialog(() => pickedPhotos.add(PhotoDraft(x, pickedCategory)));
                          },
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galleries'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final x = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1920,
                              imageQuality: 85,
                              requestFullMetadata: false,
                            );
                            if (x != null) setDialog(() => pickedPhotos.add(PhotoDraft(x, pickedCategory)));
                          },
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  if (pickedPhotos.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedPhotos.length,
                        itemBuilder: (ctx, i) {
                          final p = pickedPhotos[i];
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(p.file.path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 14,
                                child: GestureDetector(
                                  onTap: () => setDialog(() => pickedPhotos.removeAt(i)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.danger,
                                    child: Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.category,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(NewCoolerRequest(
                  name: controller.text.trim(),
                  photos: List<PhotoDraft>.from(pickedPhotos),
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Propose Location'),
          ),
        ],
      ),
    ),
  );
}
