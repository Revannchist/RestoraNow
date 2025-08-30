import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:restoranow_desktop/core/api_exception.dart';

enum AppMessageType { error, success, info, warning }

// ---------- colors/icons (unchanged) ----------
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

Color _overlayBgFor(AppMessageType t) {
  switch (t) {
    case AppMessageType.error:
      return const Color(0xFFB71C1C);
    case AppMessageType.success:
      return const Color(0xFF2E7D32);
    case AppMessageType.info:
      return const Color(0xFF1565C0);
    case AppMessageType.warning:
      return const Color(0xFFF57C00);
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

// ---------- SnackBar (unchanged) ----------
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

// ---------- Compact top overlay (unchanged UI) ----------
void showOverlayMessage(
  BuildContext context,
  String message, {
  AppMessageType type = AppMessageType.error,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _overlayBgFor(type),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black26),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(type), color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    try {
      entry.remove();
    } catch (_) {}
  });
}

void showApiErrorOverlay(
  BuildContext context,
  ApiException e, {
  String? overrideMessage,
}) {
  showOverlayMessage(
    context,
    (overrideMessage?.trim().isNotEmpty == true) ? overrideMessage! : e.message,
    type: AppMessageType.error,
  );
}

// ---------- JSON tolerant helpers ----------
Map<String, dynamic>? _decodeToMap(dynamic body) {
  // Unwrap ApiException to its message string
  if (body is ApiException) body = body.message;

  if (body is Map<String, dynamic>) {
    return body;
  }

  if (body is String) {
    final s = body.trim();

    // Fast path: already JSON object/array
    if (s.startsWith('{') || s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    // Try to locate a JSON object *inside* a wrapped string like:
    // "Response: 400\n{...}" or "ApiException(400): {...}"
    final start = s.indexOf('{');
    if (start != -1) {
      // Try to find the matching closing brace with a simple depth counter
      int depth = 0;
      for (int i = start; i < s.length; i++) {
        final ch = s[i];
        if (ch == '{') depth++;
        if (ch == '}') {
          depth--;
          if (depth == 0) {
            final candidate = s.substring(start, i + 1);
            try {
              final decoded = jsonDecode(candidate);
              if (decoded is Map<String, dynamic>) return decoded;
            } catch (_) {
              // ignore and fall through
            }
            break;
          }
        }
      }
    }
  }

  return null;
}

/// Extract a single “best” message from common API shapes.
/// Handles:
/// - plain strings
/// - ApiException(message)
/// - {"message":"..."}
/// - {"errors":{"email":["..."], "phone":[]}}
String extractServerMessage(
  dynamic body, {
  List<String> preferredKeys = const [
    'message',
    'general',
    'email',
    'phone',
    'username',
  ],
}) {
  // 1) Try structured JSON maps (even if wrapped with prefixes)
  final map = _decodeToMap(body);
  if (map != null) {
    // top-level message
    final topMsg = map['message'];
    if (topMsg is String && topMsg.trim().isNotEmpty) {
      return topMsg.trim();
    }

    // field errors block
    final errors = map['errors'];
    if (errors is Map) {
      // priority keys first
      for (final key in preferredKeys) {
        final v = errors[key];
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      // otherwise first non-empty entry
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
  }

  // 2) If body is ApiException, prefer its message text
  if (body is ApiException && body.message.trim().isNotEmpty) {
    return body.message.trim();
  }

  // 3) If body is a non-JSON string, show it directly (better than generic)
  if (body is String && body.trim().isNotEmpty) {
    return body.trim();
  }

  // 4) Fallback
  return 'Something went wrong. Please try again.';
}

/// Extract a per-field message (e.g., highlight input errors)
String? extractFieldMessage(dynamic body, String fieldKey) {
  final map = _decodeToMap(body);
  if (map == null) return null;
  final errors = map['errors'];
  if (errors is Map) {
    final v = errors[fieldKey];
    if (v is List && v.isNotEmpty) return v.first.toString();
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// One-call convenience to show *any* error nicely on top.
void showAnyErrorOnTop(BuildContext context, Object error, {String? fallback}) {
  if (error is ApiException) {
    showOverlayMessage(
      context,
      error.message.isNotEmpty
          ? error.message
          : (fallback ?? 'Something went wrong.'),
      type: AppMessageType.error,
    );
    return;
  }

  if (error is String || error is Map) {
    showOverlayMessage(
      context,
      extractServerMessage(error),
      type: AppMessageType.error,
    );
    return;
  }

  showOverlayMessage(
    context,
    fallback ?? 'Something went wrong.',
    type: AppMessageType.error,
  );
}
