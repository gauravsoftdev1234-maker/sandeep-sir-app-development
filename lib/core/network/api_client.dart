import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin JSON wrapper around [http.Client]. Every failure surfaces as an
/// [ApiException] so callers never have to handle raw socket errors.
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 20)})
    : _client = client ?? http.Client();

  static const String baseUrl = 'https://appadmin.atharvaservices.com';

  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send(
      () => _client.post(
        _uri(path),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send(
      () => _client.get(
        _uri(path, query),
        headers: const {'Accept': 'application/json'},
      ),
    );
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException catch (error) {
      throw ApiException(error.message);
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _errorMessage(decoded) ?? 'Request failed (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  /// Pulls a message out of either the API's own envelope or the ASP.NET
  /// `ProblemDetails` body it returns for validation failures.
  String? _errorMessage(Map<String, dynamic> body) {
    for (final key in const ['responseMsg', 'message']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }

    final errors = body['errors'];
    if (errors is Map) {
      final messages = errors.values
          .expand((value) => value is List ? value : [value])
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final title = body['title'];
    return title is String && title.isNotEmpty ? title : null;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      throw ApiException(
        'Unexpected response from the server.',
        statusCode: response.statusCode,
      );
    }
  }

  void close() => _client.close();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});
