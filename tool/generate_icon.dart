// Run: dart run tool/generate_icon.dart
// Generates a simple saffron app icon with "SD" text

import 'dart:io';
import 'dart:math';

// Minimal PNG generator - creates a saffron square with embedded bitmap text
void main() {
  const size = 1024;

  // Saffron color: #F4811F → R=244, G=129, B=31
  const r = 244, g = 129, b = 31;

  // Create raw RGBA pixel data
  final pixels = List<int>.filled(size * size * 4, 0);

  // Fill with saffron background
  for (var i = 0; i < size * size; i++) {
    pixels[i * 4 + 0] = r;
    pixels[i * 4 + 1] = g;
    pixels[i * 4 + 2] = b;
    pixels[i * 4 + 3] = 255;
  }

  // Draw a white rounded rectangle in center (stamp shape)
  for (var y = 280; y < 744; y++) {
    for (var x = 200; x < 824; x++) {
      // Check if inside rounded rect (radius 40)
      final inRect = _inRoundedRect(x, y, 200, 280, 824, 744, 40);
      if (inRect) {
        final idx = (y * size + x) * 4;
        pixels[idx + 0] = 255;
        pixels[idx + 1] = 255;
        pixels[idx + 2] = 255;
        pixels[idx + 3] = 60; // Semi-transparent white
      }
    }
  }

  // Draw "S" and "D" as simple block letters (white)
  _drawS(pixels, size, 260, 340, 180, 340);
  _drawD(pixels, size, 560, 340, 180, 340);

  // Encode as PNG
  final png = _encodePng(size, size, pixels);

  File('assets/icon/icon.png').writeAsBytesSync(png);
  print('Generated assets/icon/icon.png (${png.length} bytes)');

  // Foreground (same but transparent background)
  final fgPixels = List<int>.filled(size * size * 4, 0);
  _drawS(fgPixels, size, 260, 340, 180, 340);
  _drawD(fgPixels, size, 560, 340, 180, 340);
  final fgPng = _encodePng(size, size, fgPixels);
  File('assets/icon/icon_foreground.png').writeAsBytesSync(fgPng);
  print('Generated assets/icon/icon_foreground.png');
}

bool _inRoundedRect(int x, int y, int left, int top, int right, int bottom, int radius) {
  if (x < left || x >= right || y < top || y >= bottom) return false;
  // Check corners
  if (x < left + radius && y < top + radius) {
    return (x - left - radius) * (x - left - radius) + (y - top - radius) * (y - top - radius) <= radius * radius;
  }
  if (x >= right - radius && y < top + radius) {
    return (x - right + radius) * (x - right + radius) + (y - top - radius) * (y - top - radius) <= radius * radius;
  }
  if (x < left + radius && y >= bottom - radius) {
    return (x - left - radius) * (x - left - radius) + (y - bottom + radius) * (y - bottom + radius) <= radius * radius;
  }
  if (x >= right - radius && y >= bottom - radius) {
    return (x - right + radius) * (x - right + radius) + (y - bottom + radius) * (y - bottom + radius) <= radius * radius;
  }
  return true;
}

void _setPixel(List<int> pixels, int stride, int x, int y, int r, int g, int b, [int a = 255]) {
  if (x < 0 || y < 0 || x >= stride || y >= stride) return;
  final idx = (y * stride + x) * 4;
  pixels[idx + 0] = r;
  pixels[idx + 1] = g;
  pixels[idx + 2] = b;
  pixels[idx + 3] = a;
}

void _fillRect(List<int> pixels, int stride, int x1, int y1, int w, int h, int r, int g, int b) {
  for (var y = y1; y < y1 + h; y++) {
    for (var x = x1; x < x1 + w; x++) {
      _setPixel(pixels, stride, x, y, r, g, b);
    }
  }
}

void _drawS(List<int> pixels, int stride, int x, int y, int w, int h) {
  final t = (w * 0.22).round(); // thickness
  // Top bar
  _fillRect(pixels, stride, x, y, w, t, 255, 255, 255);
  // Left side upper
  _fillRect(pixels, stride, x, y, t, h ~/ 2, 255, 255, 255);
  // Middle bar
  _fillRect(pixels, stride, x, y + h ~/ 2 - t ~/ 2, w, t, 255, 255, 255);
  // Right side lower
  _fillRect(pixels, stride, x + w - t, y + h ~/ 2, t, h ~/ 2, 255, 255, 255);
  // Bottom bar
  _fillRect(pixels, stride, x, y + h - t, w, t, 255, 255, 255);
}

void _drawD(List<int> pixels, int stride, int x, int y, int w, int h) {
  final t = (w * 0.22).round();
  // Left vertical bar
  _fillRect(pixels, stride, x, y, t, h, 255, 255, 255);
  // Top bar
  _fillRect(pixels, stride, x, y, (w * 0.7).round(), t, 255, 255, 255);
  // Bottom bar
  _fillRect(pixels, stride, x, y + h - t, (w * 0.7).round(), t, 255, 255, 255);
  // Right curved part (approximated as vertical bar offset)
  _fillRect(pixels, stride, x + w - t, y + t, t, h - 2 * t, 255, 255, 255);
  // Connect top-right
  _fillRect(pixels, stride, x + (w * 0.7).round() - t, y, w - (w * 0.7).round() + t, t, 255, 255, 255);
  // Connect bottom-right
  _fillRect(pixels, stride, x + (w * 0.7).round() - t, y + h - t, w - (w * 0.7).round() + t, t, 255, 255, 255);
}

// Minimal PNG encoder
List<int> _encodePng(int width, int height, List<int> rgba) {
  final rawData = <int>[];
  for (var y = 0; y < height; y++) {
    rawData.add(0); // filter: none
    for (var x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      rawData.addAll([rgba[idx], rgba[idx + 1], rgba[idx + 2], rgba[idx + 3]]);
    }
  }

  final compressed = zlib.encode(rawData);

  final png = <int>[];

  // PNG signature
  png.addAll([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  final ihdr = <int>[];
  ihdr.addAll(_int32(width));
  ihdr.addAll(_int32(height));
  ihdr.addAll([8, 6, 0, 0, 0]); // 8-bit RGBA
  _writeChunk(png, 'IHDR', ihdr);

  // IDAT
  _writeChunk(png, 'IDAT', compressed);

  // IEND
  _writeChunk(png, 'IEND', []);

  return png;
}

List<int> _int32(int value) {
  return [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}

void _writeChunk(List<int> png, String type, List<int> data) {
  png.addAll(_int32(data.length));
  final typeBytes = type.codeUnits;
  png.addAll(typeBytes);
  png.addAll(data);
  // CRC
  final crcData = [...typeBytes, ...data];
  png.addAll(_int32(_crc32(crcData)));
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      if (crc & 1 != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
