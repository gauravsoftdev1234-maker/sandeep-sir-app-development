import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/json_parse.dart';
import 'auth_models.dart';

/// Wraps the `/api/Auth/*` endpoints.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  /// The API rejects an empty `fcmToken` with a 400, so send a placeholder
  /// until push notifications are wired up.
  static const String _fcmPlaceholder = 'pending';

  Future<ApiResult<AuthUser>> login({
    required String mobileNumber,
    required String password,
    String fcmToken = '',
  }) async {
    final json = await _client.post('/api/Auth/ServiceProviderLogin', {
      'mobileNumber': mobileNumber,
      'password': password,
      'fcmToken': fcmToken.isEmpty ? _fcmPlaceholder : fcmToken,
    });

    final data = json['data'];
    return ApiResult(
      isSuccess: asBool(json['isSuccess']),
      message: asString(json['responseMsg']),
      data: data is Map<String, dynamic> ? AuthUser.fromJson(data) : null,
    );
  }

  Future<ApiResult<void>> register({
    required String userName,
    required String mobileNumber,
    required String emailId,
    required String password,
    required String confirmPassword,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final json = await _client.post('/api/Auth/register', {
      'userName': userName,
      'mobileNumber': mobileNumber,
      'emailId': emailId,
      'password': password,
      'confirmpassword': confirmPassword,
      'latitude': latitude,
      'longitude': longitude,
    });

    return ApiResult(
      isSuccess: asBool(json['isSuccess']),
      message: asString(json['responseMsg']),
    );
  }

  Future<TokenStatus> validateToken(String appToken) async {
    final json = await _client.get(
      '/api/Auth/isValidToken',
      query: {'appToken': appToken},
    );
    return TokenStatus.fromJson(json);
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);
