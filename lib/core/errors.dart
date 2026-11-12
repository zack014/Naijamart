
import 'package:dio/dio.dart';

/// A user-presentable API failure.
///
/// Screens can safely display [message] directly.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;

  /// Converts errors from the data layer into user-friendly API exceptions.
  static ApiException from(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      return _fromDioException(error);
    }

    if (error is FormatException) {
      return const ApiException(
        'The server returned an invalid response. Please try again.',
      );
    }

    return const ApiException(
      'Something went wrong. Please try again.',
    );
  }

  static ApiException _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          'Connection timed out. Check your internet connection.',
          isNetwork: true,
        );

      case DioExceptionType.sendTimeout:
        return const ApiException(
          'Sending your request took too long. Please try again.',
          isNetwork: true,
        );

      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
          isNetwork: true,
        );

      case DioExceptionType.transformTimeout:
        return const ApiException(
          'Processing the server response took too long. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to NaijaMart. Check your internet connection or try again later.',
          isNetwork: true,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          'Your request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          'A secure connection could not be established.',
        );

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final status = error.response?.statusCode;

    if (status == null) {
      return const ApiException(
        'Unable to complete your request. Please try again.',
        isNetwork: true,
      );
    }

    final serverMessage = _extractMessage(
      error.response?.data,
    );

    return ApiException(
      serverMessage ?? _fallbackForStatus(status),
      statusCode: status,
    );
  }

  /// Default messages for HTTP status codes.
  static String _fallbackForStatus(int status) {
    switch (status) {
      case 400:
        return 'Your request is invalid. Please check your details.';

      case 401:
        return 'Your session has expired. Please sign in again.';

      case 403:
        return 'You do not have permission to perform this action.';

      case 404:
        return 'The requested information could not be found.';

      case 405:
        return 'This action is not supported.';

      case 408:
        return 'The request timed out. Please try again.';

      case 409:
        return 'This action conflicts with the current state.';

      case 413:
        return 'The uploaded file is too large.';

      case 415:
        return 'This file format is not supported.';

      case 422:
        return 'Some of the details you entered are invalid.';

      case 429:
        return 'Too many attempts. Please wait and try again.';

      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        return 'NaijaMart servers are temporarily unavailable. Please try again shortly.';

      default:
        if (status >= 500) {
          return 'A server error occurred. Please try again later.';
        }

        return 'Something went wrong. Please try again.';
    }
  }

  /// Extracts useful messages from FastAPI and common JSON responses.
  static String? _extractMessage(Object? data) {
    if (data is String) {
      final message = data.trim();
      return message.isEmpty ? null : message;
    }

    if (data is! Map) return null;

    final candidates = [
      data['detail'],
      data['message'],
      data['error'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }

      if (candidate is List && candidate.isNotEmpty) {
        final messages = <String>[];

        for (final item in candidate) {
          if (item is Map && item['msg'] is String) {
            final value = (item['msg'] as String).trim();

            if (value.isNotEmpty) {
              messages.add(value);
            }
          } else if (item is String && item.trim().isNotEmpty) {
            messages.add(item.trim());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      if (candidate is Map) {
        final nestedMessage = candidate['message'] ?? candidate['msg'];

        if (nestedMessage is String &&
            nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }
    }

    return null;
  }
}
