import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('tr'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr'));
  }

  bool get isEnglish => locale.languageCode == 'en';

  String t(String key, {Map<String, String>? params}) {
    final localizedValues =
        _localizedValues[locale.languageCode] ?? _localizedValues['tr']!;
    var value = localizedValues[key] ?? _localizedValues['tr']![key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }


  String activityLabel(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'sedentary':
        return t('activity_sedentary');
      case 'light':
        return t('activity_light');
      case 'moderate':
        return t('activity_moderate');
      case 'active':
        return t('activity_active');
      case 'athlete':
        return t('activity_athlete');
      case 'very_active':
        return t('activity_very_active');
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : '-';
    }
  }

  String coachModeLabel(String value) {
    switch (value) {
      case 'hardcore coach':
        return t('coach_mode_hardcore');
      case 'friendly coach':
        return t('coach_mode_friendly');
      case 'balanced coach':
      default:
        return t('coach_mode_balanced');
    }
  }

  String coachModeDescription(String value) {
    switch (value) {
      case 'hardcore coach':
        return t('coach_mode_hardcore_desc');
      case 'friendly coach':
        return t('coach_mode_friendly_desc');
      case 'balanced coach':
      default:
        return t('coach_mode_balanced_desc');
    }
  }

  String workoutPlanTitle(String planId, String fallback) {
    final key = 'workout_plan_${planId}_title';
    final value = t(key);
    return value == key ? fallback : value;
  }

  String workoutPlanSubtitle(String planId, String fallback) {
    final key = 'workout_plan_${planId}_subtitle';
    final value = t(key);
    return value == key ? fallback : value;
  }

  List<String> workoutPlanBlocks(String planId, List<String> fallback) {
    final keys = <String>[
      'workout_plan_${planId}_block_1',
      'workout_plan_${planId}_block_2',
      'workout_plan_${planId}_block_3',
      'workout_plan_${planId}_block_4',
    ];
    final values = <String>[];
    for (final key in keys) {
      final translated = t(key);
      if (translated != key) {
        values.add(translated);
      }
    }
    return values.isEmpty ? fallback : values;
  }

  String workoutMediaTitle(String planId, String fallback) {
    final key = 'workout_media_${planId}_title';
    final value = t(key);
    return value == key ? fallback : value;
  }

  String workoutMediaFocus(String planId, String fallback) {
    final key = 'workout_media_${planId}_focus';
    final value = t(key);
    return value == key ? fallback : value;
  }

  String sourceLabel(String source) {
    switch (source) {
      case 'fatsecret':
        return t('source_fatsecret');
      case 'ai_estimate':
        return t('source_ai_estimate');
      case 'manual':
      default:
        return t('source_manual');
    }
  }

  String intensityLabel(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return t('intensity_high');
      case 'medium':
        return t('intensity_medium');
      case 'low-medium':
      default:
        return t('intensity_low_medium');
    }
  }

  String durationMinutesLabel(int minutes) {
    return t('duration_minutes', params: {'minutes': minutes.toString()});
  }

  String progressCompletedLabel(int percent) {
    return t('progress_completed', params: {'percent': percent.toString()});
  }

  String consumedCaloriesLabel(double calories) {
    return t(
      'consumed_summary',
      params: {'calories': calories.toStringAsFixed(0)},
    );
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((item) => item.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _localizedValues = {
  'tr': {
    'app_name': 'Nudge',
    'tab_home': 'Ana Sayfa',
    'tab_food': 'Beslenme',
    'tab_workout': 'Antrenman',
    'tab_coach': 'Koç',
    'tab_profile': 'Profil',
    'loading_nudge': 'Nudge yükleniyor',
    'loading_bootstrap':
        'İlk ekran hemen açılır, servisler arka planda hazırlanır.',
    'loading_bootstrap_error':
        'Başlangıç sırasında bir hata oluştu. Uygulamayı yeniden açmayı dene.',
    'splash_preparing': 'Hesap akışı hazırlanıyor',
    'auth_welcome': "Nudge'a hoş geldin",
    'auth_welcome_subtitle':
        'Dengeli ve sağlıklı bir gün için giriş yap.',
    'login_title': 'Giriş yap',
    'register_title': 'Kayıt ol',
    'email': 'E-posta',
    'password': 'Şifre',
    'full_name': 'Ad soyad',
    'google_login': 'Google ile devam et',
    'no_account': 'Hesabın yok mu?',
    'have_account': 'Zaten hesabın var mı?',
    'create_account': 'Hesabını oluştur',
    'register_subtitle':
        'Nudge deneyimine başlamak için birkaç bilgi yeterli.',
    'continue_button': 'Kaydet ve devam et',
    'save_changes': 'Değişiklikleri kaydet',
    'saving': 'Kaydediliyor',
    'gender': 'Cinsiyet',
    'male': 'Erkek',
    'female': 'Kadın',
    'age': 'Yaş',
    'birth_date': 'Doğum tarihi',
    'height_cm': 'Boy (cm)',
    'weight_kg': 'Kilo (kg)',
    'activity_level': 'Aktivite seviyesi',
    'activity_sedentary': 'Sedanter',
    'activity_light': 'Hafif',
    'activity_moderate': 'Orta',
    'activity_active': 'Aktif',
    'activity_athlete': 'Sporcu',
    'activity_very_active': 'Çok aktif',
    'setup_title': 'Hedeflerini kişiselleştir',
    'setup_subtitle': 'Günlük hedeflerini birlikte hesaplayalım.',
    'home_daily_balance': 'Günlük denge',
    'home_greeting': 'Merhaba, {name}',
    'home_summary':
        'Hedeflerini daha sakin ve okunabilir bir panelde takip et.',
    'daily_insight_title': 'Günlük analiz',
    'consistency_score': 'Tutarlılık skoru',
    'recovery_mode': 'Toparlanma',
    'positive_signal': 'İyi giden',
    'risk_signal': 'Risk',
    'tomorrow_action': 'Yarın tek aksiyon',
    'target': 'Hedef',
    'remaining': 'Kalan',
    'consumed': 'Tüketilen',
    'protein': 'Protein',
    'carbs': 'Karbonhidrat',
    'fat': 'Yağ',
    'today': 'Bugün',
    'daily': 'Günlük',
    'tracking': 'Takip',
    'quick_add_food': 'Yemek ekle',
    'quick_hydration': 'Su takibi',
    'quick_workout': 'Antrenman',
    'quick_coach': 'Koçla konuş',
    'today_meals': 'Bugünün yemekleri',
    'no_meals_yet': 'Henüz yemek eklenmedi',
    'start_day_meal': 'Güne başlamak için bir öğün ekle.',
    'profile_edit': 'Profili düzenle',
    'profile_edit_subtitle': 'Kişisel bilgilerini güncelle',
    'settings': 'Ayarlar',
    'settings_subtitle': 'Koç ve uygulama tercihleri',
    'profile_buddy': 'Buddy',
    'profile_buddy_subtitle': 'Arkadaşlarınla günlük su durumunu paylaş',
    'premium': 'Premium',
    'premium_subtitle':
        'Üyelik, faturalama ve premium paket alanı ayrı bir yapıda hazır.',
    'profile_future_section': 'Yak\u0131nda',
    'future_watch_title': 'Ak\u0131ll\u0131 saat ve cihaz entegrasyonu',
    'future_watch_desc':
        'Ad\u0131m, aktivite ve kalori harcamas\u0131 ileride ger\u00e7ek entegrasyonla eklenecek. \u015eimdilik aktif bir e\u015fle\u015fme veya sync yok.',
    'goals': 'Hedefler',
    'daily_calories': 'Günlük kalori',
    'logout': 'Çıkış yap',
    'profile_settings_title': 'Profil ayarları',
    'profile_settings_desc':
        'Temel bilgilerini düzenli ve tutarlı tutarak hesaplamaları güvenilir kıl.',
    'settings_title': 'Ayarlar',
    'app_settings_title': 'Uygulama ayarları',
    'app_settings_desc':
        'Koç tonu, tema, dil ve bildirim tercihleri burada yönetilir.',
    'coach_section': 'Koç',
    'coach_mode': 'Koç modu',
    'coach_mode_desc':
        'Sohbet ekranında seçim göstermiyoruz. Aktif tonu burada belirliyorsun.',
    'coach_mode_hardcore': 'Hardcore',
    'coach_mode_hardcore_desc': 'Daha sert ve direkt',
    'coach_mode_friendly': 'Kibar',
    'coach_mode_friendly_desc': 'Daha destekleyici',
    'coach_mode_balanced': 'Dengeli',
    'coach_mode_balanced_desc': 'Daha profesyonel',
    'theme_section': 'Tema',
    'theme_mode': 'Tema modu',
    'theme_system': 'Sistem',
    'theme_light': 'Açık',
    'theme_dark': 'Koyu',
    'language_section': 'Dil',
    'language_title': 'Uygulama dili',
    'language_beta': 'Beta',
    'language_turkish': 'Türkçe',
    'language_english': 'English',
    'notifications_section': 'Bildirimler',
    'notifications_title': 'Bildirim tercihleri',
    'notifications_master':
        'Öğün, antrenman, günlük kontrol ve akıllı yönlendirme bildirimlerini yönet.',
    'notifications_enable': 'Bildirimleri aç',
    'notifications_enable_desc':
        'İzin yalnızca bu özelliği aktif ettiğinde istenir.',
    'notifications_meal': 'Öğün hatırlatmaları',
    'notifications_workout': 'Antrenman hatırlatmaları',
    'notifications_checkin': 'Günlük kontrol',
    'notifications_smart_nudges': 'Akıllı yönlendirmeler',
    'notifications_smart_nudges_desc':
        'Gün içi davranışa göre en fazla üç müdahale gönderilir.',
    'notifications_premium': 'Premium ve kampanyalar',
    'notifications_test_button': 'Test bildirimi gönder',
    'notifications_test_sent': 'Test bildirimi gönderildi.',
    'notifications_test_disabled':
        'Önce ana bildirim anahtarını açman gerekiyor.',
    'notifications_denied':
        'Bildirim izni verilmedi. Sistem ayarlarından izin verip tekrar deneyebilirsin.',
    'hydration_title': 'Su takibi',
    'hydration_daily_title': 'Günlük hidrasyon',
    'hydration_greeting': 'Su ritmini koru, {name}',
    'hydration_summary':
        'Gün boyu bardak ve şişe ekleyerek su hedefini görünür tut.',
    'hydration_consumed': 'İçilen su',
    'hydration_goal': 'Su hedefi',
    'hydration_progress': '%{percent} hedefe ulaşıldı',
    'hydration_goal_panel': 'Bugünkü su hedefi',
    'hydration_goal_desc':
        'Ağırlığına göre önerilen litreyi seçebilir veya biraz daha yukarı çekebilirsin.',
    'hydration_quick_add': 'Hızlı ekleme',
    'hydration_quick_add_desc':
        'En sık kullandığın bardak ve şişe miktarlarıyla tek dokunuşta su ekle.',
    'hydration_glass': 'Bir bardak su',
    'hydration_bottle_small': 'Küçük şişe',
    'hydration_sports_bottle': 'Spor şişesi',
    'hydration_bottle_large': 'Büyük şişe',
    'hydration_recent_entries': 'Son eklenenler',
    'hydration_no_entries':
        'Bugün henüz su eklenmedi. İlk bardağı ekleyip akışı başlat.',
    'hydration_added': '{amount} su eklendi.',
    'buddy_title': 'Buddy alanı',
    'buddy_small_title': 'Günlük destek',
    'buddy_greeting': 'Buddy ritmini aç, {name}',
    'buddy_summary':
        'Günlük su durumunu arkadaşlarınla paylaş, gelen istekleri yönet ve birbirinizi gün içinde diri tutun.',
    'buddy_invite_title': 'Buddy daveti gönder',
    'buddy_invite_desc':
        'Arkadaşının e-postasını gir. Kabul ettiğinde bugünkü su hedefi ve ilerleme kartı görünür olacak.',
    'buddy_email_hint': 'Buddy e-postası',
    'buddy_send_request': 'İstek gönder',
    'buddy_request_sent': 'Buddy isteği gönderildi.',
    'buddy_requests_title': 'Gelen istekler',
    'buddy_requests_empty': 'Şu anda bekleyen buddy isteği yok.',
    'buddy_accept': 'Kabul et',
    'buddy_decline': 'Reddet',
    'buddy_list_title': 'Buddy listesi',
    'buddy_list_empty':
        'Henüz bağlı buddy yok. Bir arkadaş davet ederek başlayabilirsin.',
    'buddy_nudge_action': 'Dürt',
    'buddy_nudge_sent': 'Buddy dürtmesi gönderildi.',
    'buddy_nudge_helper':
        'Su ritmini hatırlatmak için tek dokunuşla buddy dürtmesi gönder.',
    'coach_empty_state':
        'AI koç ile hedeflerin, yemeklerin ve günlük planın hakkında konuş.',
    'coach_input_hint': 'Mesajını yaz',
    'coach_title': 'AI Koç',
    'workout_title': 'Antrenman',
    'workout_hero_title': 'Bugünkü tempo planı',
    'calorie_deficit': 'Kalori açığı',
    'daily_plan': 'Günlük plan',
    'extra_session': 'Ekstra telafi seansı',
    'recovery_desc': 'Bugünü mobilite, uyku ve hidrasyon disipliniyle kapat.',
    'video_title': 'Önerilen video',
    'video_open_youtube': "YouTube'da aç",
    'video_fallback':
        'Video yüklenemezse dış bağlantı ile güvenli şekilde açabilirsin.',
    'balance_high':
        'Bugün hedefinin üzerindesin. Ana planın yanına ekstra telafi seansı eklendi.',
    'balance_low':
        'Kalori açığın belirgin. Ana planı kontrollü tut, ek seans gerekmiyor.',
    'balance_stable':
        'Kalori dengesi stabil. Ana antrenman bugünkü ritmi korumak için yeterli.',
    'afterburn_reason':
        '{calories} kcal fazla alım tespit edildi. Ek seans dengeli bir kapanış için hazırlandı.',
    'workout_hero_subtitle_clean':
        'Kalori dengene g\u00f6re net ve uygulanabilir bir workout haz\u0131r.',
    'workout_hero_desc':
        'Plan bu s\u00fcr\u00fcmde yaln\u0131zca profilin, g\u00fcnl\u00fck beslenmen ve hedef kalorinle \u00e7al\u0131\u015f\u0131r.',
    'recovery_title_clean': 'Toparlanma rutini',
    'recovery_mobility': 'Mobilite',
    'recovery_hydration': 'Hidrasyon',
    'add_food_title': 'Yemek ekle',
    'search_food_or_manual': 'Yemek ara veya manuel ekle',
    'search_food_desc':
        'FatSecret sonucu yoksa AI tahmini ve manuel giriş akışı devreye girer.',
    'search_hint': 'Yemek veya porsiyon girin',
    'manual_entry': 'Manuel giriş',
    'start_with_query': 'Bu aramayla başla',
    'results': 'Sonuçlar',
    'food_source': 'Kaynak: {source}',
    'food_portion': 'Porsiyon: {portion}',
    'edit': 'Düzenle',
    'estimated_tag': 'Tahmini',
    'search_empty_with_query':
        'Sonuç bulunamadı. Manuel giriş yapabilirsin.',
    'search_empty_without_query':
        'Aramak için bir besin yazın veya manuel giriş kullanın.',
    'manual_entry_open': 'Manuel girişi aç',
    'food_detail_title': 'Yemek ayrıntısı',
    'food_edit_title': 'Yemeği düzenle',
    'food_name': 'Yemek adı',
    'food_name_required': 'Yemek adı gerekli',
    'base_portion': 'Baz porsiyon',
    'unknown': 'Bilinmiyor',
    'grams_hint':
        'Gramaj değiştiğinde kalori ve makrolar otomatik olarak çarpılır.',
    'grams_label': 'Gramaj (g)',
    'grams_invalid': 'Gramaj geçersiz',
    'calories_title': 'Kalori',
    'protein_grams': 'Protein (g)',
    'carbs_grams': 'Karbonhidrat (g)',
    'fat_grams': 'Yağ (g)',
    'estimated_data': 'Tahmini veri',
    'confidence_short': 'Güven {value}%',
    'meal_updated': 'Yemek güncellendi.',
    'meal_added': 'Yemek eklendi.',
    'meal_deleted': 'Yemek silindi.',
    'delete_meal_title': 'Yemeği sil',
    'delete_meal_confirm': 'Bu kayıt silinsin mi?',
    'cancel': 'Vazgeç',
    'delete': 'Sil',
    'operation_failed': 'İşlem başarısız: {error}',
    'delete_failed': 'Silme başarısız: {error}',
    'valid_email_error': 'Geçerli bir e-posta girin',
    'min_chars_error': 'En az 6 karakter',
    'enter_name_error': 'Adınızı girin',
    'field_required': '{field} gerekli',
    'invalid_value': '{field} geçersiz',
    'macro_summary': 'Makro özeti',
    'progress_completed': '%{percent} tamamlandı',
    'consumed_summary': '{calories} kcal tükettin.',
    'profile_update_failed': 'Profil güncellenemedi: {error}',
    'source_fatsecret': 'FatSecret',
    'source_ai_estimate': 'AI tahmini',
    'source_manual': 'Manuel giriş',
    'premium_experience': 'Premium deneyim',
    'premium_desc':
        'Bu alan satış sürümünde premium değer teklifini göstermek için ayrıldı.',
    'beta_badge': 'Beta',
    'feature_planned': 'Planlandı',
    'feature_roadmap': 'Roadmap',
    'feature_soon': 'Yakında',
    'feature_preparation': 'Hazırlık',
    'view_all': 'Hepsini gör',
    'premium_feature_1_title': 'Geliştirilmiş koç tonları',
    'premium_feature_1_desc':
        'Daha keskin, daha stratejik ve hedefe göre özelleştirilmiş premium koç modları.',
    'premium_feature_2_title': 'Haftalık analiz ve içgörü',
    'premium_feature_2_desc':
        'Kalori, makro ve workout verilerinden yönetici özeti gibi premium raporlar.',
    'premium_feature_4_title': 'Üyelik ve faturalama',
    'premium_feature_4_desc':
        'Aylık paketler, kullanıcı segmentasyonu ve satın alma akışı için ayrılmış premium alan.',
    'intensity_high': 'Yüksek',
    'intensity_medium': 'Orta',
    'intensity_low_medium': 'Düşük-Orta',
    'duration_minutes': '{minutes} dk',
    'recovery_heart_rate': 'Nabız trendi',
    'recovery_sleep': 'Uyku kalitesi',
    'recovery_steps': 'Adım hacmi',
    'workout_plan_fireline_title': 'Fireline Performance',
    'workout_plan_fireline_subtitle':
        'Patlayıcı interval ve alt vücut güç odağı.',
    'workout_plan_fireline_block_1':
        '6 dk dinamik ısınma ve ayak bileği aktivasyonu',
    'workout_plan_fireline_block_2':
        '4 x 4 dk eğimli yürüyüş veya rower itiş seti',
    'workout_plan_fireline_block_3':
        '3 tur split squat + push-up + mountain climber merdiveni',
    'workout_plan_fireline_block_4': '6 dk soğuma ve nefes toparlama',
    'workout_plan_orbit_title': 'Orbit Strength Circuit',
    'workout_plan_orbit_subtitle':
        'Duruş ve istikrar odaklı dengeli tüm vücut seansı.',
    'workout_plan_orbit_block_1': '5 dk mobilite ve omuz hazırlığı',
    'workout_plan_orbit_block_2': '3 tur goblet squat + hinge + push + plank',
    'workout_plan_orbit_block_3': '8 dk tempolu eğimli yürüyüş bitirişi',
    'workout_plan_orbit_block_4': '4 dk soğuma esnemesi',
    'workout_plan_ignition_title': 'Ignition Starter Session',
    'workout_plan_ignition_subtitle':
        'Düşük etkili ama tüm vücudu aktive eden kalori yakımı.',
    'workout_plan_ignition_block_1':
        '4 dk yerinde yürüyüş ve kol salınımı',
    'workout_plan_ignition_block_2':
        '3 tur otur-kalk + duvar şınavı + step touch',
    'workout_plan_ignition_block_3': '8 dk hızlı yürüyüş veya bisiklet',
    'workout_plan_ignition_block_4': '4 dk mobilite ile soğuma',
    'workout_plan_afterburn_title': 'Afterburn Reset',
    'workout_plan_afterburn_subtitle':
        'Günün kalori fazlasını toparlayan kısa telafi seansı.',
    'workout_plan_afterburn_block_1':
        '2 dk ip atlama veya yerinde yürüyüş açılışı',
    'workout_plan_afterburn_block_2':
        '6 tur 40 sn aktif / 20 sn dinlen hızlı tempo',
    'workout_plan_afterburn_block_3':
        '3 tur squat pulse + high knees + plank taps',
    'workout_plan_afterburn_block_4': '3 dk nefes odaklı soğuma',
    'workout_media_fireline_title': 'Alt vücut güç devresi',
    'workout_media_fireline_focus': 'Alt vücut',
    'workout_media_orbit_title': 'Tüm vücut güç akışı',
    'workout_media_orbit_focus': 'Tüm vücut',
    'workout_media_ignition_title':
        'Başlangıç seviyesi düşük etkili rutin',
    'workout_media_ignition_focus': 'Başlangıç',
    'workout_media_afterburn_title': 'Kısa telafi finisher',
    'workout_media_afterburn_focus': 'Kondisyon',
  },
  'en': {
    'app_name': 'Nudge',
    'tab_home': 'Home',
    'tab_food': 'Food',
    'tab_workout': 'Workout',
    'tab_coach': 'Coach',
    'tab_profile': 'Profile',
    'loading_nudge': 'Loading Nudge',
    'loading_bootstrap':
        'The first screen opens immediately while services initialize in the background.',
    'loading_bootstrap_error':
        'A startup error occurred. Try reopening the app.',
    'splash_preparing': 'Preparing your account flow',
    'auth_welcome': 'Welcome to Nudge',
    'auth_welcome_subtitle': 'Sign in for a balanced and healthier day.',
    'login_title': 'Sign in',
    'register_title': 'Create account',
    'email': 'Email',
    'password': 'Password',
    'full_name': 'Full name',
    'google_login': 'Continue with Google',
    'no_account': 'Do not have an account?',
    'have_account': 'Already have an account?',
    'create_account': 'Create your account',
    'register_subtitle':
        'A few details are enough to start your Nudge experience.',
    'continue_button': 'Save and continue',
    'save_changes': 'Save changes',
    'saving': 'Saving',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'age': 'Age',
    'birth_date': 'Birth date',
    'height_cm': 'Height (cm)',
    'weight_kg': 'Weight (kg)',
    'activity_level': 'Activity level',
    'activity_sedentary': 'Sedentary',
    'activity_light': 'Light',
    'activity_moderate': 'Moderate',
    'activity_active': 'Active',
    'activity_athlete': 'Athlete',
    'activity_very_active': 'Very active',
    'setup_title': 'Personalize your goals',
    'setup_subtitle': 'Let\'s calculate your daily targets together.',
    'home_daily_balance': 'Daily balance',
    'home_greeting': 'Hi, {name}',
    'home_summary': 'Track your goals in a calmer and more readable dashboard.',
    'daily_insight_title': 'Daily insight',
    'consistency_score': 'Consistency score',
    'recovery_mode': 'Recovery',
    'positive_signal': 'Good signal',
    'risk_signal': 'Risk',
    'tomorrow_action': 'One action tomorrow',
    'target': 'Target',
    'remaining': 'Remaining',
    'consumed': 'Consumed',
    'protein': 'Protein',
    'carbs': 'Carbs',
    'fat': 'Fat',
    'today': 'Today',
    'daily': 'Daily',
    'tracking': 'Tracking',
    'quick_add_food': 'Add meal',
    'quick_hydration': 'Hydration',
    'quick_workout': 'Workout',
    'quick_coach': 'Talk to coach',
    'today_meals': 'Today\'s meals',
    'no_meals_yet': 'No meals added yet',
    'start_day_meal': 'Add a meal to get your day started.',
    'profile_edit': 'Edit profile',
    'profile_edit_subtitle': 'Update your personal details',
    'settings': 'Settings',
    'settings_subtitle': 'Coach and app preferences',
    'profile_buddy': 'Buddy',
    'profile_buddy_subtitle': 'Share daily hydration with a friend',
    'premium': 'Premium',
    'premium_subtitle':
        'Membership, billing, and premium packages are prepared in a separate lane.',
    'profile_future_section': 'Soon',
    'future_watch_title': 'Smartwatch and device integration',
    'future_watch_desc':
        'Steps, activity, and active calorie data will arrive later through real integrations. There is no active pairing or sync in this version.',
    'goals': 'Goals',
    'daily_calories': 'Daily calories',
    'logout': 'Sign out',
    'profile_settings_title': 'Profile settings',
    'profile_settings_desc':
        'Keep your core details clean and consistent so calculations stay reliable.',
    'settings_title': 'Settings',
    'app_settings_title': 'App settings',
    'app_settings_desc':
        'This is the experience layer. Coach tone, theme, language, and notification preferences live here.',
    'coach_section': 'Coach',
    'coach_mode': 'Coach mode',
    'coach_mode_desc':
        'We do not show mode chips on chat. Pick the active tone here.',
    'coach_mode_hardcore': 'Hardcore',
    'coach_mode_hardcore_desc': 'Sharper and more direct',
    'coach_mode_friendly': 'Friendly',
    'coach_mode_friendly_desc': 'More supportive and warm',
    'coach_mode_balanced': 'Balanced',
    'coach_mode_balanced_desc': 'More professional',
    'theme_section': 'Theme',
    'theme_mode': 'Theme mode',
    'theme_system': 'System',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'language_section': 'Language',
    'language_title': 'App language',
    'language_beta': 'Beta',
    'language_turkish': 'Turkish',
    'language_english': 'English',
    'notifications_section': 'Notifications',
    'notifications_title': 'Notification preferences',
    'notifications_master':
        'Manage meal, workout, daily check-in, and smart nudge notifications.',
    'notifications_enable': 'Enable notifications',
    'notifications_enable_desc':
        'Permission is requested only when you turn this feature on.',
    'notifications_meal': 'Meal reminders',
    'notifications_workout': 'Workout reminders',
    'notifications_checkin': 'Daily check-in',
    'notifications_smart_nudges': 'Smart nudges',
    'notifications_smart_nudges_desc':
        'Send up to three behavior-aware interventions per day.',
    'notifications_premium': 'Premium and campaigns',
    'notifications_test_button': 'Send test notification',
    'notifications_test_sent': 'Test notification sent.',
    'notifications_test_disabled':
        'Turn on the master notification switch first.',
    'notifications_denied':
        'Notification permission was not granted. Enable it in system settings and try again.',
    'hydration_title': 'Hydration',
    'hydration_daily_title': 'Daily hydration',
    'hydration_greeting': 'Keep the water rhythm, {name}',
    'hydration_summary':
        'Add glasses and bottles through the day to keep your water target visible.',
    'hydration_consumed': 'Water logged',
    'hydration_goal': 'Water goal',
    'hydration_progress': '{percent}% of the goal reached',
    'hydration_goal_panel': 'Today\'s water goal',
    'hydration_goal_desc':
        'Pick the recommended liter target based on your weight or push it slightly higher.',
    'hydration_quick_add': 'Quick add',
    'hydration_quick_add_desc':
        'Use one-tap glass and bottle presets to log water fast.',
    'hydration_glass': 'Glass of water',
    'hydration_bottle_small': 'Small bottle',
    'hydration_sports_bottle': 'Sports bottle',
    'hydration_bottle_large': 'Large bottle',
    'hydration_recent_entries': 'Recent entries',
    'hydration_no_entries':
        'No water logged yet today. Add the first glass to start the flow.',
    'hydration_added': '{amount} of water added.',
    'buddy_title': 'Buddy space',
    'buddy_small_title': 'Daily accountability',
    'buddy_greeting': 'Open your buddy lane, {name}',
    'buddy_summary':
        'Share daily hydration with a friend, manage incoming requests, and keep each other switched on through the day.',
    'buddy_invite_title': 'Send a buddy invite',
    'buddy_invite_desc':
        'Enter your friend\'s email. After they accept, today\'s hydration goal and progress card become visible.',
    'buddy_email_hint': 'Buddy email',
    'buddy_send_request': 'Send request',
    'buddy_request_sent': 'Buddy request sent.',
    'buddy_requests_title': 'Incoming requests',
    'buddy_requests_empty': 'There are no pending buddy requests right now.',
    'buddy_accept': 'Accept',
    'buddy_decline': 'Decline',
    'buddy_list_title': 'Buddy list',
    'buddy_list_empty':
        'No connected buddy yet. Invite a friend to get started.',
    'buddy_nudge_action': 'Nudge',
    'buddy_nudge_sent': 'Buddy nudge sent.',
    'buddy_nudge_helper':
        'Send a one-tap nudge to remind your buddy to keep the water rhythm.',
    'coach_empty_state':
        'Talk with the AI coach about your goals, meals, and daily plan.',
    'coach_input_hint': 'Write your message',
    'coach_title': 'AI Coach',
    'workout_title': 'Workout',
    'workout_hero_title': 'Today\'s pace plan',
    'calorie_deficit': 'Calorie gap',
    'daily_plan': 'Daily plan',
    'extra_session': 'Extra recovery session',
    'recovery_desc':
        'Close the day with mobility, sleep, and hydration discipline.',
    'video_title': 'Recommended video',
    'video_open_youtube': 'Open on YouTube',
    'video_fallback':
        'If the embedded video fails, you can safely open the external link.',
    'balance_high':
        'You are above target today. An extra recovery session was added next to the core plan.',
    'balance_low':
        'Your calorie deficit is notable. Keep the main plan controlled and skip extra volume.',
    'balance_stable':
        'Your calorie balance is stable. The main workout is enough to keep today on track.',
    'afterburn_reason':
        '{calories} kcal surplus detected. An extra session is ready for a steadier finish.',
    'workout_hero_subtitle_clean':
        'A clear workout prepared around your calorie balance.',
    'workout_hero_desc':
        'This version uses only your profile, daily nutrition, and calorie target.',
    'recovery_title_clean': 'Recovery routine',
    'recovery_mobility': 'Mobility',
    'recovery_hydration': 'Hydration',
    'add_food_title': 'Add food',
    'search_food_or_manual': 'Search food or add manually',
    'search_food_desc':
        'If FatSecret returns nothing, AI estimate and manual entry take over.',
    'search_hint': 'Enter a food or portion',
    'manual_entry': 'Manual entry',
    'start_with_query': 'Start with this query',
    'results': 'Results',
    'food_source': 'Source: {source}',
    'food_portion': 'Portion: {portion}',
    'edit': 'Edit',
    'estimated_tag': 'Estimated',
    'search_empty_with_query':
        'No results found. You can continue with manual entry.',
    'search_empty_without_query': 'Type a food to search or use manual entry.',
    'manual_entry_open': 'Open manual entry',
    'food_detail_title': 'Food details',
    'food_edit_title': 'Edit food',
    'food_name': 'Food name',
    'food_name_required': 'Food name is required',
    'base_portion': 'Base portion',
    'unknown': 'Unknown',
    'grams_hint':
        'When grams change, calories and macros are scaled automatically.',
    'grams_label': 'Grams (g)',
    'grams_invalid': 'Invalid grams',
    'calories_title': 'Calories',
    'protein_grams': 'Protein (g)',
    'carbs_grams': 'Carbs (g)',
    'fat_grams': 'Fat (g)',
    'estimated_data': 'Estimated data',
    'confidence_short': 'Confidence {value}%',
    'meal_updated': 'Meal updated.',
    'meal_added': 'Meal added.',
    'meal_deleted': 'Meal deleted.',
    'delete_meal_title': 'Delete meal',
    'delete_meal_confirm': 'Delete this record?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'operation_failed': 'Operation failed: {error}',
    'delete_failed': 'Delete failed: {error}',
    'valid_email_error': 'Enter a valid email address',
    'min_chars_error': 'At least 6 characters',
    'enter_name_error': 'Enter your name',
    'field_required': '{field} is required',
    'invalid_value': 'Invalid {field}',
    'macro_summary': 'Macro summary',
    'progress_completed': '{percent}% completed',
    'consumed_summary': 'You consumed {calories} kcal.',
    'profile_update_failed': 'Profile could not be updated: {error}',
    'source_fatsecret': 'FatSecret',
    'source_ai_estimate': 'AI estimate',
    'source_manual': 'Manual entry',
    'premium_experience': 'Premium experience',
    'premium_desc':
        'This area is reserved for the premium value proposition in the commercial release.',
    'beta_badge': 'Beta',
    'feature_planned': 'Planned',
    'feature_roadmap': 'Roadmap',
    'feature_soon': 'Soon',
    'feature_preparation': 'Prep',
    'view_all': 'View all',
    'premium_feature_1_title': 'Advanced coach tones',
    'premium_feature_1_desc':
        'Sharper, more strategic, and goal-tailored premium coach modes.',
    'premium_feature_2_title': 'Weekly analysis and insight',
    'premium_feature_2_desc':
        'Premium reports built from calorie, macro, and workout trends.',
    'premium_feature_4_title': 'Membership and billing',
    'premium_feature_4_desc':
        'Reserved lane for monthly plans, segmentation, and purchase flows.',
    'intensity_high': 'High',
    'intensity_medium': 'Medium',
    'intensity_low_medium': 'Low-Medium',
    'duration_minutes': '{minutes} min',
    'recovery_heart_rate': 'Heart-rate trend',
    'recovery_sleep': 'Sleep quality',
    'recovery_steps': 'Step volume',
    'workout_plan_fireline_title': 'Fireline Performance',
    'workout_plan_fireline_subtitle':
        'Explosive intervals with a lower-body power focus.',
    'workout_plan_fireline_block_1':
        '6 min dynamic warm-up and ankle activation',
    'workout_plan_fireline_block_2': '4 x 4 min incline walk or row push set',
    'workout_plan_fireline_block_3':
        '3 rounds split squat plus push-up plus mountain climber ladder',
    'workout_plan_fireline_block_4': '6 min cooldown and breath reset',
    'workout_plan_orbit_title': 'Orbit Strength Circuit',
    'workout_plan_orbit_subtitle':
        'Balanced full-body session for posture and consistency.',
    'workout_plan_orbit_block_1': '5 min mobility and shoulder prep',
    'workout_plan_orbit_block_2':
        '3 rounds goblet squat plus hinge plus push plus plank',
    'workout_plan_orbit_block_3': '8 min brisk incline walk finisher',
    'workout_plan_orbit_block_4': '4 min cooldown stretch',
    'workout_plan_ignition_title': 'Ignition Starter Session',
    'workout_plan_ignition_subtitle':
        'Low-impact calorie burn with full-body activation.',
    'workout_plan_ignition_block_1': '4 min marching warm-up and arm swings',
    'workout_plan_ignition_block_2':
        '3 rounds sit-to-stand plus wall push plus step touch',
    'workout_plan_ignition_block_3': '8 min fast walk or bike spin',
    'workout_plan_ignition_block_4': '4 min mobility cooldown',
    'workout_plan_afterburn_title': 'Afterburn Reset',
    'workout_plan_afterburn_subtitle':
        'A short reset session to absorb today\'s calorie surplus.',
    'workout_plan_afterburn_block_1': '2 min jump rope or marching opener',
    'workout_plan_afterburn_block_2': '6 rounds of 40 sec on and 20 sec off',
    'workout_plan_afterburn_block_3':
        '3 rounds squat pulse plus high knees plus plank taps',
    'workout_plan_afterburn_block_4': '3 min breathing cooldown',
    'workout_media_fireline_title': 'Lower-body power circuit',
    'workout_media_fireline_focus': 'Lower body',
    'workout_media_orbit_title': 'Full-body strength flow',
    'workout_media_orbit_focus': 'Full body',
    'workout_media_ignition_title': 'Starter low-impact routine',
    'workout_media_ignition_focus': 'Beginner',
    'workout_media_afterburn_title': 'Quick recovery finisher',
    'workout_media_afterburn_focus': 'Conditioning',
  },
};
