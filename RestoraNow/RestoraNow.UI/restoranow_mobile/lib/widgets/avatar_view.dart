import 'dart:typed_data';
import 'package:flutter/material.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    required this.initials,
    this.imageBytes,
    this.imageUrl,
    this.size = 72,
    this.isBusy = false,
    this.onTap,
    this.showCameraBadge = true,
  });

  final String initials;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final double size;
  final bool isBusy;
  final VoidCallback? onTap;
  final bool showCameraBadge;

  @override
  Widget build(BuildContext context) {
    // Identity string that changes when content changes (URL with ?v=..., or bytes)
    final String _id = _identity(imageUrl, imageBytes, isBusy);

    Widget avatar;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      avatar = Image.memory(
        imageBytes!,
        key: ValueKey('mem:$_id'),
        fit: BoxFit.cover,
        cacheWidth: (size * 3).floor(),
        cacheHeight: (size * 3).floor(),
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
    } else if (imageUrl != null &&
        imageUrl!.isNotEmpty &&
        !imageUrl!.startsWith('data:image/')) {
      avatar = Image.network(
        imageUrl!,
        key: ValueKey('net:$_id'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _Initial(initials: initials),
      );
    } else {
      avatar = _Initial(key: const ValueKey('initial'), initials: initials);
    }

    final content = SizedBox(
      key: ValueKey('slot:$_id:${isBusy ? 1 : 0}'),
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipOval(child: avatar),
          if (showCameraBadge && onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          if (isBusy)
            const Positioned.fill(child: ColoredBox(color: Color(0x55000000))),
          if (isBusy)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );

    return onTap == null
        ? content
        : GestureDetector(onTap: onTap, child: content);
  }

  static String _identity(String? url, Uint8List? bytes, bool isBusy) {
    if (bytes != null && bytes.isNotEmpty) {
      final len = bytes.length;
      final b0 = bytes[0];
      final bm = bytes[len >> 1];
      final bl = bytes[len - 1];
      return 'mem:$len,$b0,$bm,$bl:${isBusy ? 1 : 0}';
    }
    return '${url ?? 'none'}:${isBusy ? 1 : 0}';
  }
}

class _Initial extends StatelessWidget {
  const _Initial({super.key, required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Text(
          initials,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
