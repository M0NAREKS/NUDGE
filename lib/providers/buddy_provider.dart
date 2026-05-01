import 'package:flutter/foundation.dart';

import '../services/app_analytics.dart';
import '../services/buddy_repository.dart';
import '../services/local_storage_service.dart';
import '../services/models/buddy_connection.dart';
import '../services/models/buddy_request.dart';
import '../services/models/shared_daily_status.dart';
import 'user_provider.dart';

class BuddyProvider extends ChangeNotifier {
  BuddyProvider({
    BuddyRepository? buddyRepository,
    AppAnalytics? analytics,
    DateTime Function()? now,
  })  : _buddyRepository = buddyRepository ?? FirestoreBuddyRepository(),
        _analytics = analytics,
        _now = now ?? DateTime.now;

  final BuddyRepository _buddyRepository;
  final AppAnalytics? _analytics;
  final DateTime Function() _now;

  bool _busy = false;
  String? _errorMessage;

  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;

  Stream<List<BuddyRequest>> incomingRequests(String uid) {
    return _buddyRepository.incomingRequests(uid);
  }

  Stream<List<BuddyConnection>> buddies(String uid) {
    return _buddyRepository.buddies(uid);
  }

  Stream<SharedDailyStatus> sharedStatusForToday(String uid) {
    return _buddyRepository.sharedStatusForDate(uid, _now());
  }

  Future<void> sendRequest({
    required UserProvider userProvider,
    required String buddyEmail,
  }) async {
    final profile = userProvider.profile;
    if (profile == null) return;
    await _runBusy(() async {
      await _buddyRepository.sendRequest(
        currentUser: profile,
        buddyEmail: buddyEmail,
      );
      await _analytics?.logEvent('buddy_request_sent');
    });
  }

  Future<void> acceptRequest({
    required BuddyRequest request,
  }) async {
    await _runBusy(() async {
      await _buddyRepository.acceptRequest(request: request);
      await _analytics?.logEvent('buddy_request_accepted');
    });
  }

  Future<void> declineRequest(BuddyRequest request) async {
    await _runBusy(() async {
      await _buddyRepository.declineRequest(request);
      await _analytics?.logEvent('buddy_request_declined');
    });
  }

  Future<void> sendNudge({
    required BuddyConnection buddy,
    required String localeCode,
  }) async {
    await _runBusy(() async {
      await _buddyRepository.sendNudge(
        buddy: buddy,
        localeCode: localeCode,
      );
      await _analytics?.logEvent('buddy_nudge_sent', {
        'buddy_uid': buddy.uid,
      });
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = await _localizedError(error);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String> _localizedError(Object error) async {
    final settings = await LocalStorageService.getAppSettings();
    final isEnglish = settings.localeCode == 'en';
    final raw = '$error'.replaceFirst('Exception: ', '').trim();

    switch (raw) {
      case 'Buddy email is required.':
        return isEnglish ? raw : 'Buddy e-postası gerekli.';
      case 'You cannot add yourself as a buddy.':
        return isEnglish ? raw : 'Kendini buddy olarak ekleyemezsin.';
      case 'No user was found with this email address.':
        return isEnglish ? raw : 'Bu e-postayla eşleşen bir kullanıcı bulunamadı.';
      case 'This user is already in your buddy list.':
        return isEnglish ? raw : 'Bu kullanıcı zaten buddy listende.';
      case 'A pending buddy request already exists.':
        return isEnglish ? raw : 'Bu kullanıcı için zaten bekleyen bir istek var.';
      case 'Buddy nudge target is missing.':
        return isEnglish ? raw : 'Dürtülecek buddy bulunamadı.';
      default:
        if (raw.contains('permission-denied') ||
            raw.contains('does not have permission')) {
          return isEnglish
              ? 'Buddy access is currently blocked by server permissions. Try again after updating the backend rules.'
              : 'Buddy erişimi şu anda sunucu izinleri tarafından engelleniyor. Backend kuralları güncellendikten sonra tekrar deneyin.';
        }
        if (raw == 'Buddy nudges are cooling down.' ||
            raw == 'Buddy nudge is cooling down.') {
          return isEnglish
              ? 'You recently nudged this buddy. Try again a bit later.'
              : 'Bu buddy için kısa süre önce dürtme gönderildi. Biraz sonra tekrar dene.';
        }
        if (raw == 'Buddy notifications are not ready on the other device yet.') {
          return isEnglish
              ? raw
              : 'Buddy cihazında bildirimler henüz hazır değil.';
        }
        if (raw == 'Only accepted buddies can be nudged.') {
          return isEnglish ? raw : 'Sadece kabul edilmiş buddy bağlantılarına dürtme gönderilebilir.';
        }
        return raw;
    }
  }
}
