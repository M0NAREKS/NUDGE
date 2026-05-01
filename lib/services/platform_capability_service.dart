import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum PushProviderKind { none, fcm, hms }

class PlatformCapabilities {
  const PlatformCapabilities({
    required this.isWeb,
    required this.isAndroid,
    required this.hasGoogleServices,
    required this.hasHuaweiServices,
    required this.brand,
    required this.manufacturer,
  });

  const PlatformCapabilities.unknown()
    : isWeb = false,
      isAndroid = false,
      hasGoogleServices = false,
      hasHuaweiServices = false,
      brand = '',
      manufacturer = '';

  final bool isWeb;
  final bool isAndroid;
  final bool hasGoogleServices;
  final bool hasHuaweiServices;
  final String brand;
  final String manufacturer;

  PushProviderKind get preferredPushProvider {
    if (isWeb) return PushProviderKind.fcm;
    if (hasGoogleServices) return PushProviderKind.fcm;
    if (hasHuaweiServices) return PushProviderKind.hms;
    return PushProviderKind.none;
  }

  bool get supportsHuaweiAnalytics => isAndroid && hasHuaweiServices;
}

class PlatformCapabilityService {
  PlatformCapabilityService({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('nudge/platform_capabilities');

  final MethodChannel _methodChannel;

  PlatformCapabilities _capabilities = const PlatformCapabilities.unknown();

  PlatformCapabilities get capabilities => _capabilities;

  Future<PlatformCapabilities> refresh() async {
    if (kIsWeb) {
      _capabilities = const PlatformCapabilities(
        isWeb: true,
        isAndroid: false,
        hasGoogleServices: true,
        hasHuaweiServices: false,
        brand: 'web',
        manufacturer: 'web',
      );
      return _capabilities;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      _capabilities = const PlatformCapabilities(
        isWeb: false,
        isAndroid: false,
        hasGoogleServices: false,
        hasHuaweiServices: false,
        brand: '',
        manufacturer: '',
      );
      return _capabilities;
    }

    try {
      final raw =
          await _methodChannel.invokeMapMethod<String, dynamic>(
            'getCapabilities',
          ) ??
          const <String, dynamic>{};

      _capabilities = PlatformCapabilities(
        isWeb: false,
        isAndroid: true,
        hasGoogleServices: raw['hasGms'] == true,
        hasHuaweiServices: raw['hasHms'] == true,
        brand: (raw['brand'] as String? ?? '').trim(),
        manufacturer: (raw['manufacturer'] as String? ?? '').trim(),
      );
    } catch (_) {
      _capabilities = const PlatformCapabilities(
        isWeb: false,
        isAndroid: true,
        hasGoogleServices: false,
        hasHuaweiServices: false,
        brand: '',
        manufacturer: '',
      );
    }

    return _capabilities;
  }
}
