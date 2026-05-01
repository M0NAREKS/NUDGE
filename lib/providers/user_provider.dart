import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/app_analytics.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

const Object _retainBirthDate = Object();

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.birthDate,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.activity,
    this.bmr,
    this.dailyCalories,
  });

  final String uid;
  final String email;
  final String name;
  final DateTime? birthDate;
  final int? age;
  final double? height;
  final double? weight;
  final String? gender;
  final String? activity;
  final double? bmr;
  final double? dailyCalories;

  int? get resolvedAge {
    final date = birthDate;
    if (date == null) {
      return age;
    }
    final now = DateTime.now();
    var years = now.year - date.year;
    final birthdayReached =
        now.month > date.month ||
        (now.month == date.month && now.day >= date.day);
    if (!birthdayReached) {
      years -= 1;
    }
    return years >= 0 ? years : null;
  }

  bool get isComplete {
    return resolvedAge != null &&
        height != null &&
        weight != null &&
        gender != null &&
        activity != null;
  }

  AppUserProfile copyWith({
    String? name,
    Object? birthDate = _retainBirthDate,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? activity,
    double? bmr,
    double? dailyCalories,
  }) {
    final resolvedBirthDate = identical(birthDate, _retainBirthDate)
        ? this.birthDate
        : birthDate as DateTime?;
    return AppUserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      birthDate: resolvedBirthDate,
      age: resolvedBirthDate != null ? null : age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activity: activity ?? this.activity,
      bmr: bmr ?? this.bmr,
      dailyCalories: dailyCalories ?? this.dailyCalories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'birthDate': birthDate,
      if (birthDate == null) 'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'activity': activity,
      'bmr': bmr,
      'dailyCalories': dailyCalories,
    }..removeWhere((key, value) => value == null);
  }

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      birthDate: _readBirthDate(data['birthDate']),
      age: (data['age'] as num?)?.round(),
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      gender: data['gender'] as String?,
      activity: data['activity'] as String?,
      bmr: (data['bmr'] as num?)?.toDouble(),
      dailyCalories: (data['dailyCalories'] as num?)?.toDouble(),
    );
  }

  static DateTime? _readBirthDate(Object? raw) {
    if (raw is Timestamp) {
      final date = raw.toDate();
      return DateTime(date.year, date.month, date.day);
    }
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }
}

class UserProvider extends ChangeNotifier {
  UserProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    AppAnalytics? analytics,
    NotificationService? notificationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _analytics = analytics,
        _notificationService = notificationService {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final AppAnalytics? _analytics;
  final NotificationService? _notificationService;

  StreamSubscription<User?>? _authSubscription;

  AppUserProfile? _profile;
  bool _loading = false;
  bool _profileLoading = false;
  bool _googleInitialized = false;
  bool _authResolved = false;

  User? get firebaseUser => _auth.currentUser;
  AppUserProfile? get profile => _profile;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isLoading => _loading || _profileLoading;
  bool get isReady => _authResolved && !_profileLoading;
  bool get hasCompleteProfile => _profile?.isComplete ?? false;

  Future<void> initGoogleSignIn() async {
    if (kIsWeb || _googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    if (user == null) {
      _profile = null;
      _authResolved = true;
      await _analytics?.clearUserIdentity();
      await _notificationService?.syncUser(null);
      notifyListeners();
      return;
    }

    await _loadProfile(user.uid, markResolved: true);
    await _analytics?.setUserId(user.uid);
    await _notificationService?.syncUser(user.uid);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not created',
        );
      }

      final profile = AppUserProfile(uid: user.uid, email: email, name: name);
      await _firestore.collection('users').doc(user.uid).set(profile.toMap());
      await _syncUserDirectory(profile);
      _profile = profile;
      _authResolved = true;
      await _analytics?.logEvent(
        'sign_up',
        {
          'method': 'email',
        },
      );
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw Exception(await _mapAuthError(error));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics?.logEvent(
        'login',
        {
          'method': 'email',
        },
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(await _mapAuthError(error));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      final userCredential = await _signInWithGoogleCredential();
      final user = userCredential.user;
      var createdProfile = false;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Google sign-in failed',
        );
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        _profile = await _createProfileFromFirebaseUser(user);
        createdProfile = true;
      } else {
        _profile = AppUserProfile.fromMap(snapshot.id, snapshot.data()!);
      }

      _authResolved = true;
      if (createdProfile) {
        await _analytics?.logEvent(
          'sign_up',
          {
            'method': 'google',
          },
        );
      }
      await _analytics?.logEvent(
        'login',
        {
          'method': 'google',
        },
      );
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      throw Exception(await _mapGoogleAuthError(error));
    } on UnimplementedError {
      throw Exception(
        await _isEnglishLocale()
            ? 'Google sign-in is not supported on this platform.'
            : 'Google ile giriş bu platformda desteklenmiyor.',
      );
    } catch (error) {
      throw Exception(
        await _isEnglishLocale()
            ? 'An error occurred during Google sign-in: $error'
            : 'Google ile giriş sırasında hata oluştu: $error',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential> _signInWithGoogleCredential() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      return _auth.signInWithPopup(provider);
    }

    await initGoogleSignIn();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<AppUserProfile> _createProfileFromFirebaseUser(User user) async {
    final profile = AppUserProfile(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
    );
    await _firestore.collection('users').doc(user.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
    await _syncUserDirectory(profile);
    return profile;
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
    await _notificationService?.syncUser(null);
    await _analytics?.clearUserIdentity();
  }

  Future<void> updateProfile({
    String? name,
    DateTime? birthDate,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? activity,
    double? bmr,
    double? dailyCalories,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (birthDate != null) {
      data['birthDate'] = DateTime(
        birthDate.year,
        birthDate.month,
        birthDate.day,
      );
      data['age'] = FieldValue.delete();
    } else if (age != null) {
      data['age'] = age;
    }
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (gender != null) data['gender'] = gender;
    if (activity != null) data['activity'] = activity;
    if (bmr != null) data['bmr'] = bmr;
    if (dailyCalories != null) data['dailyCalories'] = dailyCalories;

    if (data.isEmpty) return;

    _setLoading(true);
    try {
      final wasComplete = _profile?.isComplete ?? false;
      await _firestore.collection('users').doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );
      await _loadProfile(user.uid);
      if (_profile != null) {
        await _syncUserDirectory(_profile!);
      }
      final nowComplete = _profile?.isComplete ?? false;
      if (!wasComplete && nowComplete) {
        await _analytics?.logEvent('profile_completed');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadProfile(String uid, {bool markResolved = false}) async {
    _profileLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        _profile = AppUserProfile.fromMap(uid, snapshot.data()!);
      } else {
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          _profile = await _createProfileFromFirebaseUser(currentUser);
        } else {
          _profile = null;
        }
      }
      if (_profile?.activity != null) {
        await _analytics?.setUserProperty('activity_level', _profile!.activity!);
      }
      if (_profile != null) {
        await _syncUserDirectory(_profile!);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'unavailable') {
        debugPrint('Firestore offline while loading profile: ${error.message}');
      } else {
        Error.throwWithStackTrace(error, stackTrace);
      }
    } finally {
      if (markResolved) {
        _authResolved = true;
      }
      _profileLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> _syncUserDirectory(AppUserProfile profile) async {
    if (profile.uid.trim().isEmpty || profile.email.trim().isEmpty) return;
    await _firestore.collection('userDirectory').doc(profile.uid).set(
      {
        'name': profile.name,
        'email': profile.email,
        'emailLower': profile.email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> _mapAuthError(FirebaseAuthException error) async {
    final isEnglish = await _isEnglishLocale();
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return isEnglish
            ? 'The email or password is incorrect.'
            : 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return isEnglish
            ? 'An account already exists with this email address.'
            : 'Bu e-posta ile zaten bir hesap mevcut.';
      case 'invalid-email':
        return isEnglish
            ? 'Enter a valid email address.'
            : 'Geçerli bir e-posta adresi girin.';
      case 'weak-password':
        return isEnglish
            ? 'The password must be at least 6 characters.'
            : 'Şifre en az 6 karakter olmalı.';
      case 'user-disabled':
        return isEnglish
            ? 'This account has been disabled. Please contact support.'
            : 'Hesabınız devre dışı bırakılmış. Destek ile iletişime geçin.';
      default:
        return isEnglish
            ? 'An unexpected error occurred. Please try again.'
            : 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<String> _mapGoogleAuthError(FirebaseAuthException error) async {
    final isEnglish = await _isEnglishLocale();
    switch (error.code) {
      case 'popup-blocked':
        return isEnglish
            ? 'The Google sign-in popup was blocked. Allow popups and try again.'
            : 'Google giriş popup penceresi engellendi. Popup izni verip tekrar deneyin.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return isEnglish
            ? 'Google sign-in was cancelled.'
            : 'Google giriş işlemi iptal edildi.';
      case 'operation-not-allowed':
        return isEnglish
            ? 'Google sign-in is not enabled in Firebase Authentication.'
            : 'Google girişi Firebase Authentication tarafında etkinleştirilmemiş.';
      case 'unauthorized-domain':
        return isEnglish
            ? 'This domain is not authorized for Firebase Authentication.'
            : 'Bu alan adı Firebase Authentication için yetkili değil.';
      default:
        return _mapAuthError(error);
    }
  }

  Future<bool> _isEnglishLocale() async {
    final settings = await LocalStorageService.getAppSettings();
    return settings.localeCode == 'en';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

