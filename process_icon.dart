import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Read the original image which had the K on black background
  final file = File('/Users/tkp/.gemini/antigravity/brain/9a2236c7-18a6-43a6-9b21-f5d9d0b2dc26/geometric_growth_keep_noborder_1775234679145.png');
  final original = file.existsSync() ? img.decodePng(file.readAsBytesSync()) : null;
  if (original == null) {
    print('Original not found');
    return;
  }
  
  // Create a new image for transparency
  final out = img.Image(width: original.width, height: original.height);
  
  // The threshold for "black". Black background is usually around r=15, g=15, b=15
  for (int y = 0; y < original.height; y++) {
    for (int x = 0; x < original.width; x++) {
      var pixel = original.getPixel(x, y);
      if (pixel.r < 35 && pixel.g < 35 && pixel.b < 35) {
        // pure or near black -> transparent
        out.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      } else {
        out.setPixel(x, y, pixel);
      }
    }
  }

  // Crop tight to the K
  int minX = out.width, maxX = 0;
  int minY = out.height, maxY = 0;

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      if (out.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  // Add a little padding
  int padding = 50;
  minX = (minX - padding).clamp(0, out.width);
  maxX = (maxX + padding).clamp(0, out.width);
  minY = (minY - padding).clamp(0, out.height);
  maxY = (maxY + padding).clamp(0, out.height);

  var cropped = img.copyCrop(out, x: minX, y: minY, width: maxX - minX, height: maxY - minY);
  
  // Resize back to 1024x1024 to make it nice
  var resized = img.copyResize(cropped, width: 1024, height: 1024, interpolation: img.Interpolation.average);

  File('assets/logo_transparent.png').writeAsBytesSync(img.encodePng(resized));
  print('Done');
}
