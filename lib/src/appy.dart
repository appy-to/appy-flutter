import 'package:flutter/services.dart';

import 'appy_codec.dart';
import 'appy_types.dart';

abstract final class Appy {
  static const String pluginVersion = '1.0.0';

  static const MethodChannel _methods = MethodChannel('to.appy.sdk/methods');
  static const EventChannel _deepLinkEvents = EventChannel('to.appy.sdk/deep_links');
  static const EventChannel _attributionEvents = EventChannel('to.appy.sdk/attribution');

  static final Stream<AppyDeepLinkResult> _deepLinks =
      _deepLinkEvents.receiveBroadcastStream().map(decodeDeepLinkResult);
  static final Stream<AppyAttribution> _attributions =
      _attributionEvents.receiveBroadcastStream().map(decodeAttribution);

  static Future<void> configure(AppyConfiguration configuration) =>
      _methods.invokeMethod<void>('configure', configuration.toMap());

  static Stream<AppyDeepLinkResult> get onDeepLink => _deepLinks;

  static Stream<AppyAttribution> get onAttribution => _attributions;

  static Future<AppyAttribution?> getAttribution() async {
    final raw = await _methods.invokeMethod<Object?>('getAttribution');
    return raw == null ? null : decodeAttribution(raw);
  }

  static Future<AppyDeepLink?> getLatestDeepLink() async {
    final raw = await _methods.invokeMethod<Object?>('getLatestDeepLink');
    return raw == null ? null : decodeDeepLink(raw);
  }

  static Future<bool> handleUrl(Uri url) async =>
      await _methods.invokeMethod<bool>('handleUrl', {'url': url.toString()}) ?? false;

  static Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
    num? revenue,
    String? currency,
    String? deduplicationId,
  }) =>
      _methods.invokeMethod<void>('track', {
        'name': name,
        'properties': {
          for (final entry in properties.entries)
            if (entry.value is String || entry.value is num || entry.value is bool) entry.key: entry.value,
        },
        'revenue': revenue,
        'currency': currency,
        'deduplicationId': deduplicationId,
      });

  static Future<void> setUserId(String? userId) => _methods.invokeMethod<void>('setUserId', {'userId': userId});

  static Future<void> setTrackingEnabled(bool enabled) =>
      _methods.invokeMethod<void>('setTrackingEnabled', {'enabled': enabled});

  static Future<bool> isTrackingEnabled() async => await _methods.invokeMethod<bool>('isTrackingEnabled') ?? true;

  static Future<Uri?> buildLink(String slug, {Map<String, String> parameters = const {}}) async {
    final link = await _methods.invokeMethod<String>('buildLink', {'slug': slug, 'parameters': parameters});
    return link == null ? null : Uri.parse(link);
  }

  static Future<void> flush() => _methods.invokeMethod<void>('flush');

  static Future<String> nativeSdkVersion() async => await _methods.invokeMethod<String>('getNativeSdkVersion') ?? '';
}
