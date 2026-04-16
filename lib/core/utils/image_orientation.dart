import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Normalises an image picked by `image_picker` so that:
///   * the pixels are in their visually-correct orientation, and
///   * the resulting JPEG file has NO EXIF orientation tag.
///
/// Background (why this exists):
/// `image_picker` on iOS (≥ iOS 13, including 18.x) can return a JPEG whose
/// pixels have already been physically rotated to the display orientation but
/// whose EXIF `Orientation` tag is still `6` (or similar). Our S3 backend
/// runs `sharp(...).rotate()` which honours that stale tag and rotates the
/// image a second time — portrait photos end up 90° CCW.
///
/// Strategy: decode with `package:image`. For JPEGs this decoder already
/// applies the EXIF orientation to the pixel buffer AND nulls out the
/// orientation tag on the resulting `Image`. We then run `bakeOrientation`
/// as a defensive no-op for any non-JPEG format that might still carry a
/// tag, and re-encode as JPEG. The new file has correctly oriented pixels
/// and no orientation tag, so no one downstream will rotate it again.
Future<File> bakeImageOrientation(File input) async {
  try {
    final bytes = await input.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return input;

    final exif = decoded.exif;
    final orientation =
        exif.imageIfd.hasOrientation ? exif.imageIfd.orientation : 1;

    // Defensive: strip any residual orientation (JPEG decoder already did this,
    // but other formats might not).
    final baked = (orientation != null && orientation != 1)
        ? img.bakeOrientation(decoded)
        : decoded;

    final jpg = img.encodeJpg(baked, quality: 90);

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/picked_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(jpg, flush: true);

    debugPrint(
      '[orient] in=${decoded.width}x${decoded.height} '
      'exif=${orientation ?? "none"} '
      'out=${baked.width}x${baked.height} '
      'bytes=${bytes.length}->${jpg.length}',
    );

    return out;
  } catch (e) {
    debugPrint('[orient] bakeImageOrientation failed: $e');
    return input;
  }
}
