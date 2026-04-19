import 'package:dio/dio.dart';
import '../widgets/api_error_handler.dart';

class ReadableDioException extends DioException {
  final String readableMessage;

  ReadableDioException({
    required super.requestOptions,
    super.response,
    super.type,
    super.error,
    super.stackTrace,
    super.message,
    required this.readableMessage,
  });

  @override
  String toString() => readableMessage;
}

class ErrorFormattingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err is! ReadableDioException) {
      final readableMessage = ApiErrorHandler.getReadableMessage(err);
      final customException = ReadableDioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: err.error,
        stackTrace: err.stackTrace,
        message: err.message,
        readableMessage: readableMessage,
      );
      return handler.next(customException);
    }
    return handler.next(err);
  }
}
