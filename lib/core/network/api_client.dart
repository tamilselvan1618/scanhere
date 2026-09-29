import 'package:dio/dio.dart';
import '../errors/failures.dart';

/// Network client wrapper based on Dio with timeout and error handling.
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

  /// Performs a POST request and handles network failures gracefully.
  Future<Response<dynamic>> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.message ??
          'An unexpected network error occurred.';
      throw ApiFailure(message.toString(), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiFailure(e.toString());
    }
  }
}
