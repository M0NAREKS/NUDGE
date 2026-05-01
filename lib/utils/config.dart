const String _nudgeFunctionsBaseUrl = String.fromEnvironment(
  'NUDGE_FUNCTIONS_BASE_URL',
  defaultValue: '',
);

const String _legacyFunctionsBaseUrl = String.fromEnvironment(
  'FITCOACH_FUNCTIONS_BASE_URL',
  defaultValue: '',
);

final String cloudFunctionsBaseUrl = _nudgeFunctionsBaseUrl.isNotEmpty
    ? _nudgeFunctionsBaseUrl
    : _legacyFunctionsBaseUrl.isNotEmpty
    ? _legacyFunctionsBaseUrl
    : 'https://us-central1-fitcoach-13e40.cloudfunctions.net';

Uri buildCloudFunctionUri(
  String functionName, {
  Map<String, String>? queryParameters,
}) {
  return Uri.parse(
    '$cloudFunctionsBaseUrl/$functionName',
  ).replace(queryParameters: queryParameters);
}
