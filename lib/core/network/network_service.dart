import 'package:dio/dio.dart';

import '../error/failures.dart';
import '../utils/result.dart';

class NetworkService {
  late final Dio _dio;
  
  NetworkService() {
    _dio = Dio();
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add common headers
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          
          // Add authorization header if token exists
          // This will be implemented when we have auth token management
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          final failure = _handleError(error);
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: failure,
            type: error.type,
          ));
        },
      ),
    );
  }
  
  Failure _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error occurred';
        
        switch (statusCode) {
          case 400:
            return ValidationFailure(message);
          case 401:
            return const AuthFailure('Unauthorized. Please login again.');
          case 403:
            return const AuthFailure('Access forbidden.');
          case 404:
            return ServerFailure('Resource not found.', code: '404');
          case 500:
            return const ServerFailure('Internal server error.');
          default:
            return ServerFailure(message, code: statusCode?.toString());
        }
      
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled.');
      
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection. Please check your network.');
      
      default:
        return UnknownFailure('An unexpected error occurred: ${error.message}');
    }
  }
  
  // GET request
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      final data = fromJson != null ? fromJson(response.data) : response.data as T;
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.error is Failure ? (e.error as Failure).message : e.message ?? 'Unknown error');
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }
  
  // POST request
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      final responseData = fromJson != null ? fromJson(response.data) : response.data as T;
      return Success(responseData);
    } on DioException catch (e) {
      return Failure(e.error is Failure ? (e.error as Failure).message : e.message ?? 'Unknown error');
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }
  
  // PUT request
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      final responseData = fromJson != null ? fromJson(response.data) : response.data as T;
      return Success(responseData);
    } on DioException catch (e) {
      return Failure(e.error is Failure ? (e.error as Failure).message : e.message ?? 'Unknown error');
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }
  
  // DELETE request
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      final responseData = fromJson != null ? fromJson(response.data) : response.data as T;
      return Success(responseData);
    } on DioException catch (e) {
      return Failure(e.error is Failure ? (e.error as Failure).message : e.message ?? 'Unknown error');
    } catch (e) {
      return Failure('Unexpected error: $e');
    }
  }
}
