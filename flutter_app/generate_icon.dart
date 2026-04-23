/// Generates assets/icons/launcher_icon.png
/// Run from flutter_app/: dart run generate_icon.dart
/// Then: dart run flutter_launcher_icons
///
/// Design: blue (#0077B6) background, white medical cross (rounded ends),
///         green (#00B37E) pulse dot — SalamaRecover brand colours.
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  const cx = size ~/ 2;
  const cy = size ~/ 2;

  // Brand colours
  final blue  = img.ColorRgba8(0, 119, 182, 255);   // #0077B6
  final white = img.ColorRgba8(255, 255, 255, 255);
  final green = img.ColorRgba8(0, 179, 126, 255);    // #00B37E

  final image = img.Image(width: size, height: size);

  // ── 1. Solid blue background ────────────────────────────────
  img.fill(image, color: blue);

  // ── 2. White medical cross (rounded-end bars) ───────────────
  //  Bar dimensions: arm width = 13 %, arm length = 46 % of icon
  final arm  = (size * 0.46).round(); // half-length of each arm
  final half = (size * 0.065).round(); // half-width of bar

  // Vertical bar
  img.fillRect(image,
      x1: cx - half, y1: cy - arm, x2: cx + half, y2: cy + arm,
      color: white);
  // Round the top and bottom ends
  img.fillCircle(image, x: cx, y: cy - arm, radius: half, color: white);
  img.fillCircle(image, x: cx, y: cy + arm, radius: half, color: white);

  // Horizontal bar
  img.fillRect(image,
      x1: cx - arm, y1: cy - half, x2: cx + arm, y2: cy + half,
      color: white);
  // Round the left and right ends
  img.fillCircle(image, x: cx - arm, y: cy, radius: half, color: white);
  img.fillCircle(image, x: cx + arm, y: cy, radius: half, color: white);

  // ── 3. Green pulse dot (top-right of centre cross) ──────────
  //  Placed where the right arm meets the top arm — like a heartbeat indicator
  final dotR   = (size * 0.075).round();
  final dotOff = (size * 0.30).round();
  img.fillCircle(image,
      x: cx + dotOff, y: cy - dotOff, radius: dotR, color: green);

  // ── 4. Save ─────────────────────────────────────────────────
  final outFile = File('assets/icons/launcher_icon.png');
  outFile.writeAsBytesSync(img.encodePng(image));

  print('✓  Icon saved → ${outFile.path}  ($size × $size px)');
  print('   Now run:  dart run flutter_launcher_icons');
}
