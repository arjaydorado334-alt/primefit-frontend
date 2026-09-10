import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// The single source of truth for the landing page's "Step inside the gym"
/// gallery.
///
/// Images live in **`assets/images/gallery/`** (registered as a directory
/// in `pubspec.yaml`, so anything dropped in is bundled). At runtime
/// [load] reads the asset manifest and returns every image found under
/// that folder, sorted by filename — so **adding a photo is just: drop the
/// file into `assets/images/gallery/`, run `flutter pub get`, hot-restart.
/// No code change.**
///
/// [fallback] is only used if the manifest can't be read (it never should
/// be in a normal build) — keep it roughly in sync with the folder.
class GalleryImages {
  GalleryImages._();

  static const String dir = 'assets/images/gallery/';

  static const List<String> fallback = [
    '${dir}gallery-1.jpg',
    '${dir}gallery-2.jpg',
    '${dir}gallery-3.jpg',
    '${dir}gallery-4.jpg',
    '${dir}gallery-5.jpg',
    '${dir}gallery-6.jpg',
  ];

  static bool _isImage(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  /// Every image under [dir], sorted. Falls back to [fallback] on error or
  /// if the folder is empty.
  static Future<List<String>> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final images = manifest
          .listAssets()
          .where((p) => p.startsWith(dir) && _isImage(p))
          .toList()
        ..sort();
      return images.isEmpty ? fallback : images;
    } catch (_) {
      return fallback;
    }
  }
}
