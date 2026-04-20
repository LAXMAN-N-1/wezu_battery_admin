import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_scaffold_keys.dart';

class ApiErrorHandler {
  static String getReadableMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final detail = _extractDetail(error.response?.data);

    switch (statusCode) {
      case 400:
        return detail ?? 'Invalid credentials or inactive account.';
      case 401:
        if (detail == 'token_expired') {
          return 'Your session has expired. Please log in again.';
        }
        if (detail == 'token_invalid') {
          return 'Invalid session. Please log in again.';
        }
        return 'Authentication required. Please log in.';
      case 403:
        return 'You don\'t have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 307:
      case 308:
        return 'API redirect detected. Check trailing slash and base URL settings.';
      case 422:
        return 'Invalid request. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please retry in a moment.';
      case null:
        if (error.type == DioExceptionType.cancel) {
          if (_isSessionExpiredCancellation(error)) {
            return 'Your session has expired. Please log in again.';
          }
          return 'Request was cancelled. Please try again.';
        }
        if (error.type == DioExceptionType.connectionError) {
          final signal = '${error.message ?? ''} ${error.error ?? ''}'
              .toLowerCase()
              .trim();
          if (kIsWeb && signal.contains('xmlhttprequest')) {
            return 'Cannot reach API from browser. '
                'Verify API_BASE_URL, backend status, and CORS settings.';
          }
          return 'Connection error. The service may be temporarily unavailable.';
        }
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          return 'Request timed out. Please try again.';
        }
        return 'Network error. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static void showErrorSnackbar(BuildContext context, DioException error) {
    final statusCode = error.response?.statusCode;
    final message = getReadableMessage(error);
    final isAuthError =
        statusCode == 401 ||
        statusCode == 403 ||
        _isSessionExpiredCancellation(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isAuthError ? Colors.orange : Colors.red,
        action: isAuthError
            ? SnackBarAction(
                label: 'Log In',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                ),
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showGlobalError(DioException error) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    final statusCode = error.response?.statusCode;
    final message = getReadableMessage(error);
    final isAuthError =
        statusCode == 401 ||
        statusCode == 403 ||
        _isSessionExpiredCancellation(error);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isAuthError ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String getMessageFromError(Object error) {
    if (error is DioException) {
      return getReadableMessage(error);
    }
    return 'Something went wrong. Please try again.';
  }

  static String? _extractDetail(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['detail']?.toString() ??
          responseData['message']?.toString() ??
          responseData['error']?.toString();
    }

    if (responseData is Map) {
      return responseData['detail']?.toString() ??
          responseData['message']?.toString() ??
          responseData['error']?.toString();
    }

    return null;
  }

  static bool _isSessionExpiredCancellation(DioException error) {
    if (error.type != DioExceptionType.cancel) {
      return false;
    }

    final signal = '${error.error ?? ''} ${error.message ?? ''}'
        .toLowerCase()
        .trim();

    return signal.contains('session expired') ||
        signal.contains('awaiting re-login');
  }
}
