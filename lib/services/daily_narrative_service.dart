import 'functions_gateway.dart';
import 'models/daily_insight.dart';

class DailyNarrativeService {
  DailyNarrativeService({FunctionsGateway? gateway})
    : _gateway = gateway ?? FirebaseFunctionsGateway();

  final FunctionsGateway _gateway;

  Future<String> polishNarrative({
    required DailyInsight insight,
    required String localeCode,
  }) async {
    final data = await _gateway.postJson(
      'dailyNarrative',
      body: {'locale': localeCode, 'insight': insight.toMap()},
    );
    final narrative = data['narrative'] as String?;
    if (narrative == null || narrative.trim().isEmpty) {
      throw const FunctionGatewayException('Daily narrative empty.');
    }
    return narrative.trim();
  }
}
