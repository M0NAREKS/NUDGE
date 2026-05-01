import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../utils/config.dart';

class FunctionGatewayException implements Exception {
  const FunctionGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class FunctionsGateway {
  Future<Map<String, dynamic>> getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  });

  Future<Map<String, dynamic>> postJson(
    String functionName, {
    Map<String, dynamic>? body,
  });
}

class FirebaseFunctionsGateway implements FunctionsGateway {
  FirebaseFunctionsGateway({
    FirebaseAuth? auth,
    http.Client? client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _client.get(
        buildCloudFunctionUri(
          functionName,
          queryParameters: queryParameters,
        ),
        headers: await _headers(),
      );
      return _decodeResponse(response);
    } on http.ClientException {
      throw const FunctionGatewayException(
        'Cloud Functions endpointine ulaşılamıyor. Deploy ve CORS ayarlarını kontrol edin.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.post(
        buildCloudFunctionUri(functionName),
        headers: await _headers(includeContentType: true),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
      return _decodeResponse(response);
    } on http.ClientException {
      throw const FunctionGatewayException(
        'Cloud Functions endpointine ulaşılamıyor. Deploy ve CORS ayarlarını kontrol edin.',
      );
    }
  }

  Future<Map<String, String>> _headers({bool includeContentType = false}) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const FunctionGatewayException('Bu islem icin oturum gerekli.');
    }

    return {
      'Authorization': 'Bearer $token',
      if (includeContentType) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();
    final data = body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw FunctionGatewayException(
      data['message'] as String? ??
          (data['error'] is Map<String, dynamic>
              ? data['error']['message'] as String? ?? 'Sunucu hatasi.'
              : 'Sunucu hatasi.'),
      statusCode: response.statusCode,
    );
  }
}
