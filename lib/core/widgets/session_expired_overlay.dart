import 'package:flutter/material.dart';

/// Global navigator key used by [SessionExpiredOverlay] to show the modal
/// on top of all routes.  Must be wired into the GoRouter / MaterialApp.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// A full-screen modal overlay shown when the user's session has expired.
///
/// Blocks all interaction with the app until the user acknowledges and is
/// redirected to the login screen.  Uses [rootNavigatorKey] so it sits above
/// all routes, including dialogs.
class SessionExpiredOverlay {
  SessionExpiredOverlay._();

  static bool _showing = false;

  /// Show the session-expired modal.  No-ops if already visible.
  static Future<void> show({VoidCallback? onLogin}) async {
    if (_showing) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    _showing = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: _SessionExpiredDialog(onLogin: () {
          Navigator.of(ctx).pop();
          onLogin?.call();
        }),
      ),
    );

    _showing = false;
  }

  /// Dismiss the dialog programmatically (e.g. if the user logs in from
  /// another tab).
  static void dismiss() {
    if (!_showing) return;
    final nav = rootNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    _showing = false;
  }

  /// Whether the overlay is currently visible.
  static bool get isShowing => _showing;
}

class _SessionExpiredDialog extends StatelessWidget {
  const _SessionExpiredDialog({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Session Expired',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your authentication token has expired.\n'
                  'Please log in again to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Log In Again'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
