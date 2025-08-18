import 'package:flutter/material.dart';
import 'package:restoranow_desktop/core/api_exception.dart';

enum AppMessageType { error, success, info, warning }

Color _bgFor(AppMessageType t) {
  switch (t) {
    case AppMessageType.success:
      return const Color(0xFF2E7D32);
    case AppMessageType.info:
      return const Color(0xFF1565C0);
    case AppMessageType.warning:
      return const Color(0xFFF57C00);
    case AppMessageType.error:
      return const Color(0xFF424242);
  }
}

IconData _iconFor(AppMessageType t) {
  switch (t) {
    case AppMessageType.success:
      return Icons.check_circle_outline;
    case AppMessageType.info:
      return Icons.info_outline;
    case AppMessageType.warning:
      return Icons.warning_amber_outlined;
    case AppMessageType.error:
      return Icons.error_outline;
  }
}

void showSnackMessage(
  BuildContext context,
  String message, {
  AppMessageType type = AppMessageType.error,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _bgFor(type),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration,
      content: Row(
        children: [
          Icon(_iconFor(type), color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Colors.white,
            )
          : null,
    ),
  );
}

/// Convenience for ApiException
void showApiErrorSnack(
  BuildContext context,
  ApiException e, {
  String? overrideMessage,
}) {
  showSnackMessage(
    context,
    overrideMessage ?? e.message,
    type: AppMessageType.error,
  );
}
