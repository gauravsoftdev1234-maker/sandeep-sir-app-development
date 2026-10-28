import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/json_parse.dart';
import 'service_category.dart';

/// Wraps `/api/ServiceProviderCategory/*`.
///
/// These endpoints use a `{ status, data }` envelope rather than the
/// `{ isSuccess, responseMsg, data }` one the auth endpoints return.
class ServiceApi {
  const ServiceApi(this._client);

  final ApiClient _client;

  /// Links the chosen categories to the signed-in partner. The API replies
  /// `{ status, message }` with no data payload.
  Future<String> addCategories({
    required String appToken,
    required List<int> categoryIds,
  }) async {
    final json = await _client.post(
      '/api/ServiceProviderCategory/addserviceManCategory',
      {'appToken': appToken, 'categoryId': categoryIds},
    );

    final message = asString(json['message']);
    if (asString(json['status']).toLowerCase() != 'success') {
      throw ApiException(
        message.isEmpty ? 'Could not save your services.' : message,
      );
    }
    return message;
  }

  Future<List<ServiceCategory>> getCategories(String appToken) async {
    final json = await _client.get(
      '/api/ServiceProviderCategory/getServiceCategory',
      query: {'appToken': appToken},
    );

    final status = asString(json['status']).toLowerCase();
    final data = json['data'];

    if (status != 'success' || data is! List) {
      throw ApiException(
        asString(json['message']).isEmpty
            ? 'Could not load the service list.'
            : asString(json['message']),
      );
    }

    return [
      for (final row in data)
        if (row is Map<String, dynamic>) ServiceCategory.fromJson(row),
    ]..removeWhere((category) => category.name.isEmpty);
  }
}

final serviceApiProvider = Provider<ServiceApi>(
  (ref) => ServiceApi(ref.watch(apiClientProvider)),
);
