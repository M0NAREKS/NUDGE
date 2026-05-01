import 'package:nudge/services/ai_calorie_estimator.dart';
import 'package:nudge/services/fatsecret_api_service.dart';
import 'package:nudge/services/functions_gateway.dart';
import 'package:nudge/services/groq_coach_service.dart';
import 'package:nudge/services/models/food_item.dart';
import 'package:nudge/services/models/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_doubles.dart';

void main() {
  group('FatSecretApiService', () {
    test('maps calories and macros from FatSecret payload', () async {
      final gateway = FakeFunctionsGateway(
        getHandler: (functionName, queryParameters) async {
          expect(functionName, 'fatsecretSearch');
          expect(queryParameters?['q'], 'apple');
          return <String, dynamic>{
            'foods': <String, dynamic>{
              'food': <String, dynamic>{
                'food_name': 'Apple',
                'food_description':
                    'Per 100g - Calories: 52, Protein: 0.3, Carbs: 14, Fat: 0.2',
              },
            },
          };
        },
      );

      final service = FatSecretApiService(gateway: gateway);
      final results = await service.performSearch('apple');

      expect(results, hasLength(1));
      expect(results.single.name, 'Apple');
      expect(results.single.calories, 52);
      expect(results.single.protein, 0.3);
      expect(results.single.carbs, 14);
      expect(results.single.fat, 0.2);
      expect(results.single.source, 'fatsecret');
      expect(results.single.servingLabel, 'Per 100g');
      expect(results.single.servingGrams, 100);
      expect(results.single.selectedGrams, 100);
      expect(results.single.isEstimated, isFalse);
    });

    test('scales FatSecret nutrition by selected grams', () {
      const item = FoodItem(
        name: 'Apple',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        source: 'fatsecret',
        baseCalories: 52,
        baseProtein: 0.3,
        baseCarbs: 14,
        baseFat: 0.2,
        servingLabel: 'Per 100g',
        servingGrams: 100,
        selectedGrams: 100,
      );

      final scaled = item.scaleToGrams(250);

      expect(scaled.calories, 130);
      expect(scaled.protein, closeTo(0.75, 0.01));
      expect(scaled.carbs, closeTo(35, 0.01));
      expect(scaled.fat, closeTo(0.5, 0.01));
      expect(scaled.selectedGrams, 250);
    });
  });

  group('AiCalorieEstimator', () {
    test('marks AI fallback results as estimated', () async {
      final gateway = FakeFunctionsGateway(
        postHandler: (functionName, body) async {
          expect(functionName, 'foodEstimate');
          return <String, dynamic>{
            'item': <String, dynamic>{
              'name': 'Custom Bowl',
              'calories': 420,
              'protein': 24,
              'carbs': 40,
              'fat': 16,
              'source': 'ai_estimate',
              'isEstimated': true,
              'confidence': 0.62,
            },
          };
        },
      );

      final estimator = AiCalorieEstimator(gateway: gateway);
      final result = await estimator.estimate('custom bowl');

      expect(result, isNotNull);
      expect(result!.source, 'ai_estimate');
      expect(result.isEstimated, isTrue);
      expect(result.confidence, 0.62);
    });
  });

  group('GroqCoachService', () {
    test('returns backend message on function error', () async {
      final gateway = FakeFunctionsGateway(
        postHandler: (functionName, body) async {
          throw const FunctionGatewayException(
            'AI koc su anda yanit veremiyor.',
          );
        },
      );

      final service = GroqCoachService(gateway: gateway);
      final reply = await service.sendMessage(
        uid: 'user-1',
        content: 'Bugun ne yemeliyim?',
        mode: 'balanced coach',
        localeCode: 'tr',
      );

      expect(reply, 'AI koc su anda yanit veremiyor.');
    });
  });

  group('NotificationPayload', () {
    test('normalizes shell routes from map and json payloads', () {
      final payload = NotificationPayload.fromMap(<String, dynamic>{
        'type': 'reminder',
        'screen': '/coachChat',
        'entityId': 'coach-1',
        'title': 'Koctan mesaj var',
        'body': 'Bugunku hedefini kontrol et.',
      });

      expect(payload.type, 'reminder');
      expect(payload.route, '/coach');
      expect(payload.entityId, 'coach-1');

      final reparsed = NotificationPayload.tryParse(payload.toJsonString());
      expect(reparsed, isNotNull);
      expect(reparsed!.route, '/coach');
      expect(reparsed.title, 'Koctan mesaj var');
    });

    test('preserves standalone app routes for buddy and hydration', () {
      final buddyPayload = NotificationPayload.fromMap(<String, dynamic>{
        'type': 'buddy_nudge',
        'route': '/buddy',
      });
      final hydrationPayload = NotificationPayload.fromMap(<String, dynamic>{
        'type': 'nudge',
        'route': '/hydration',
      });

      expect(buddyPayload.route, '/buddy');
      expect(hydrationPayload.route, '/hydration');
    });
  });
}
