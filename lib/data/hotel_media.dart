import 'package:flutter/material.dart';
import 'package:nse_mobile/theme/app_theme.dart';

/// Hotel inspection photos are bundled inside the app (offline-first).
/// JSON paths look like `/hotels/<id>/preview/001.webp`; on disk they live
/// under `assets/hotels/<id>/preview/001.webp`.
class HotelMedia {
  const HotelMedia._();

  static String resolve(String path) {
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    return 'assets$clean';
  }
}

/// Renders a bundled hotel photo with a graceful fallback.
class HotelPhoto extends StatelessWidget {
  const HotelPhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      HotelMedia.resolve(path),
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => Container(
        width: width,
        height: height,
        color: AppColors.navySoft,
        child: const Center(
          child: Icon(Icons.hotel_rounded, color: AppColors.navy, size: 40),
        ),
      ),
    );
  }
}
