import 'functions_gateway.dart';

class GroqCoachService {
  GroqCoachService({FunctionsGateway? gateway})
    : _gateway = gateway ?? FirebaseFunctionsGateway();

  final FunctionsGateway _gateway;

  Future<String> sendMessage({
    required String uid,
    required String content,
    required String mode,
    required String localeCode,
  }) async {
    final trimmedContent = content.trim();
    final isEnglish = localeCode == 'en';
    if (trimmedContent.isEmpty) {
      return isEnglish
          ? 'Write a message before sending it to the coach.'
          : 'Lütfen koça göndermek için bir mesaj yaz.';
    }

    try {
      final data = await _gateway.postJson(
        'coachChat',
        body: {
          'uid': uid,
          'content': trimmedContent,
          'mode': mode,
          'locale': localeCode,
          'dateKey': _todayKey(DateTime.now()),
        },
      );

      final reply = data['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        return isEnglish
            ? 'The coach did not return a meaningful response. Please try again.'
            : 'Koçtan anlamlı bir yanıt alınamadı. Lütfen tekrar deneyin.';
      }

      return reply;
    } on FunctionGatewayException catch (error) {
      if (isEnglish) {
        return 'The coach service is unavailable right now. Please try again soon.';
      }
      return error.message;
    } catch (_) {
      return isEnglish
          ? 'The coach service is unavailable right now. Please try again soon.'
          : 'Koç servisine şu anda ulaşılamıyor. Lütfen birazdan tekrar deneyin.';
    }
  }

  String _todayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
