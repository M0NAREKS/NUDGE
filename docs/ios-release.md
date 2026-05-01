# iOS Release Build

Bu proje icin iOS yukleyici dosyasi `.ipa` formatindadir. Windows ortaminda `flutter build ipa` calismaz; iOS release build icin macOS + Xcode gerekir.

## Mevcut Durum

- Uygulama gorunen adi: `Nudge`
- Flutter surumu: `1.0.0+1`
- Su anki iOS bundle id: `com.example.fitcoach`
- Firebase iOS config de ayni bundle id'yi kullaniyor

Kontrol edilen dosyalar:

- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `lib/firebase_options.dart`

## Gercek IPA Icin Gerekenler

1. macOS uzerinde Xcode kurulu olmali
2. Apple Developer hesabi olmali
3. Gecerli bir bundle id belirlenmeli
4. Apple signing / provisioning tanimlanmali
5. Bundle id degisirse Firebase iOS app kaydi da ayni id ile guncellenmeli

## Onerilen Bundle ID

`com.<seninmarkan>.nudge`

Ornek:

- `com.oguzhanbodur.nudge`

## Bundle ID Degisirse

Su dosyalarda ayni kimlik kullanilmali:

- `ios/Runner.xcodeproj/project.pbxproj`
- `lib/firebase_options.dart`

Firebase iOS app kaydini da ayni bundle id ile yeniden olusturup FlutterFire config guncellenmeli.

## macOS Uzerinde Build Adimlari

Proje klasorunde:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release
```

Olusan dosya genelde burada olur:

```text
build/ios/ipa/Runner.ipa
```

## TestFlight / App Store Icin

Xcode ile de archive alinabilir:

```bash
open ios/Runner.xcworkspace
```

Sonra:

1. Runner target sec
2. Signing & Capabilities altinda Team sec
3. Bundle Identifier'i guncelle
4. Product > Archive
5. Distribute App > TestFlight veya App Store Connect

## Bu Repoda Yapisal Not

Bu Windows makinede Android icin `apk` uretebiliyoruz, iOS icin ise yalnizca proje hazirligini yapabiliyoruz. Gercek `.ipa` cikarmak icin build'in macOS tarafinda alinmasi gerekiyor.
