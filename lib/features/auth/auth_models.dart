import 'package:flutter/foundation.dart';

import '../../core/network/json_parse.dart';

/// The signed-in service provider, as returned by `ServiceProviderLogin`.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.appToken,
    this.profileImage,
  });

  final int id;
  final String fullName;
  final String appToken;
  final String? profileImage;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: asString(json['FullName']),
    appToken: asString(json['AppToken']),
    profileImage: json['ProfileImage'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'FullName': fullName,
    'AppToken': appToken,
    'ProfileImage': profileImage,
  };
}

/// The `{ isSuccess, responseMsg, data }` envelope the auth endpoints use.
@immutable
class ApiResult<T> {
  const ApiResult({required this.isSuccess, required this.message, this.data});

  final bool isSuccess;
  final String message;
  final T? data;
}

/// Response of `isValidToken`, which also tells us whether onboarding
/// (service selection) is still pending.
@immutable
class TokenStatus {
  const TokenStatus({required this.isValid, required this.isServiceSelected});

  final bool isValid;
  final bool isServiceSelected;

  factory TokenStatus.fromJson(Map<String, dynamic> json) => TokenStatus(
    isValid: asBool(json['IsValidToken']),
    isServiceSelected: asBool(json['IsServiceSelected']),
  );
}
