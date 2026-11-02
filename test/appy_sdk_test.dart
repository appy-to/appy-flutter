import 'dart:async';
import 'dart:io';

import 'package:appy_sdk/appy_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('to.appy.sdk/methods');
  const deepLinks = EventChannel('to.appy.sdk/deep_links');
  const attributions = EventChannel('to.appy.sdk/attribution');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Map<String, Object?> replies;

  setUp(() {
    calls = [];
    replies = {};
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return replies[call.method];
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(deepLinks, null);
    messenger.setMockStreamHandler(attributions, null);
  });

  group('configure', () {
    test('sends every option with defaults matching the native SDKs', () async {
      await Appy.configure(const AppyConfiguration(publishableKey: 'appy_pk_test', linkDomains: ['acme.appy.to']));

      expect(calls.single.method, 'configure');
      expect(calls.single.arguments, {
        'publishableKey': 'appy_pk_test',
        'linkDomains': ['acme.appy.to'],
        'emailLinkDomains': <String>[],
        'logLevel': 'error',
        'openDeferredDeepLinks': false,
        'deferredDeepLinkTimeoutMillis': 5000,
        'launchLinkWaitMillis': 500,
        'requestTimeoutMillis': 10000,
        'apiBaseUrl': null,
        'android': {'collectInstallReferrer': true, 'metaAppId': null},
      });
    });

    test('sends custom options', () async {
      await Appy.configure(AppyConfiguration(
        publishableKey: 'appy_pk_test',
        linkDomains: const ['acme.appy.to', 'go.acme.com'],
        emailLinkDomains: const ['links.example.com'],
        logLevel: AppyLogLevel.debug,
        openDeferredDeepLinks: true,
        deferredDeepLinkTimeout: const Duration(seconds: 8),
        launchLinkWaitInterval: const Duration(milliseconds: 250),
        requestTimeout: const Duration(seconds: 20),
        apiBaseUrl: Uri.parse('https://staging-api.appy.to'),
        android: const AppyAndroidOptions(collectInstallReferrer: false, metaAppId: '1234567890'),
      ));

      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['emailLinkDomains'], ['links.example.com']);
      expect(arguments['logLevel'], 'debug');
      expect(arguments['openDeferredDeepLinks'], true);
      expect(arguments['deferredDeepLinkTimeoutMillis'], 8000);
      expect(arguments['launchLinkWaitMillis'], 250);
      expect(arguments['requestTimeoutMillis'], 20000);
      expect(arguments['apiBaseUrl'], 'https://staging-api.appy.to');
      expect(arguments['android'], {'collectInstallReferrer': false, 'metaAppId': '1234567890'});
    });
  });

  group('onDeepLink', () {
    test('delivers found, notFound and failed results', () async {
      messenger.setMockStreamHandler(
        deepLinks,
        MockStreamHandler.inline(onListen: (arguments, events) {
          events.success({
            'status': 'found',
            'link': {
              'url': 'https://acme.appy.to/spring?item=42',
              'deeplinkUrl': 'acme://items?item=42',
              'slug': 'spring',
              'parameters': {'item': '42', 'utm_source': 'newsletter'},
              'isDeferred': true,
              'clickedAtMillis': 1760000000000,
            },
          });
          events.success({'status': 'notFound'});
          events.success({'status': 'failed', 'error': 'timeout'});
          events.success({'status': 'failed', 'error': 'network'});
          events.success({'status': 'failed', 'error': 'invalidResponse'});
        }),
      );

      final results = await Appy.onDeepLink.take(5).toList();

      expect(results, [
        AppyDeepLinkFound(AppyDeepLink(
          url: Uri.parse('https://acme.appy.to/spring?item=42'),
          deeplinkUrl: Uri.parse('acme://items?item=42'),
          slug: 'spring',
          parameters: const {'item': '42', 'utm_source': 'newsletter'},
          isDeferred: true,
          clickedAt: DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
        )),
        const AppyDeepLinkNotFound(),
        const AppyDeepLinkFailed(AppyError.timeout),
        const AppyDeepLinkFailed(AppyError.network),
        const AppyDeepLinkFailed(AppyError.invalidResponse),
      ]);
    });

    test('decodes an offline fallback link without optional fields', () async {
      messenger.setMockStreamHandler(
        deepLinks,
        MockStreamHandler.inline(onListen: (arguments, events) {
          events.success({
            'status': 'found',
            'link': {'url': 'https://acme.appy.to/spring', 'slug': 'spring', 'parameters': {}, 'isDeferred': false},
          });
        }),
      );

      final result = await Appy.onDeepLink.first;

      expect(result, isA<AppyDeepLinkFound>());
      final link = (result as AppyDeepLinkFound).link;
      expect(link.deeplinkUrl, isNull);
      expect(link.clickedAt, isNull);
      expect(link.parameters, isEmpty);
    });

    test('supports exhaustive pattern matching', () async {
      messenger.setMockStreamHandler(
        deepLinks,
        MockStreamHandler.inline(onListen: (arguments, events) {
          events.success({'status': 'failed', 'error': 'timeout'});
        }),
      );

      final result = await Appy.onDeepLink.first;
      final description = switch (result) {
        AppyDeepLinkFound(:final link) => 'found ${link.slug}',
        AppyDeepLinkNotFound() => 'organic',
        AppyDeepLinkFailed(:final error) => 'failed ${error.name}',
      };

      expect(description, 'failed timeout');
    });

    test('cancels the native subscription when the last listener cancels', () async {
      var listens = 0;
      final cancelled = Completer<void>();
      messenger.setMockStreamHandler(
        deepLinks,
        MockStreamHandler.inline(
          onListen: (arguments, events) => listens++,
          onCancel: (arguments) => cancelled.complete(),
        ),
      );

      final first = Appy.onDeepLink.listen((_) {});
      final second = Appy.onDeepLink.listen((_) {});
      await first.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(cancelled.isCompleted, isFalse);
      await second.cancel();
      await cancelled.future.timeout(const Duration(seconds: 1));
      expect(listens, 1);
    });
  });

  group('onAttribution', () {
    test('delivers organic and attributed installs', () async {
      messenger.setMockStreamHandler(
        attributions,
        MockStreamHandler.inline(onListen: (arguments, events) {
          events.success({'isOrganic': true});
          events.success({
            'isOrganic': false,
            'linkSlug': 'spring',
            'linkTitle': 'Spring sale',
            'source': 'newsletter',
            'medium': 'email',
            'campaign': 'spring-2026',
            'clickedAtMillis': 1760000000000,
          });
          events.success({
            'isOrganic': false,
            'network': {'name': 'google_ads', 'campaignId': '42', 'clickId': 'gclid-1', 'touch': 'click'},
          });
        }),
      );

      final receivedAttributions = await Appy.onAttribution.take(3).toList();

      expect(receivedAttributions, [
        const AppyAttribution(isOrganic: true),
        AppyAttribution(
          isOrganic: false,
          linkSlug: 'spring',
          linkTitle: 'Spring sale',
          source: 'newsletter',
          medium: 'email',
          campaign: 'spring-2026',
          clickedAt: DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
        ),
        const AppyAttribution(
          isOrganic: false,
          network: AppyAdNetwork(name: 'google_ads', campaignId: '42', clickId: 'gclid-1', touch: 'click'),
        ),
      ]);
    });
  });

  group('getters', () {
    test('getAttribution returns null before Appy answers', () async {
      expect(await Appy.getAttribution(), isNull);
      expect(calls.single.method, 'getAttribution');
    });

    test('getAttribution decodes the stored attribution', () async {
      replies['getAttribution'] = {'isOrganic': false, 'linkSlug': 'spring'};
      expect(await Appy.getAttribution(), const AppyAttribution(isOrganic: false, linkSlug: 'spring'));
    });

    test('getLatestDeepLink decodes the latest link', () async {
      replies['getLatestDeepLink'] = {'slug': 'spring', 'parameters': {'item': '42'}, 'isDeferred': false};
      expect(await Appy.getLatestDeepLink(), const AppyDeepLink(slug: 'spring', parameters: {'item': '42'}));
    });

    test('isTrackingEnabled defaults to true when the platform returns nothing', () async {
      expect(await Appy.isTrackingEnabled(), isTrue);
      replies['isTrackingEnabled'] = false;
      expect(await Appy.isTrackingEnabled(), isFalse);
    });

    test('nativeSdkVersion returns the native version', () async {
      replies['getNativeSdkVersion'] = '1.0.0';
      expect(await Appy.nativeSdkVersion(), '1.0.0');
    });
  });

  group('links', () {
    test('handleUrl passes the URL and returns whether it was an Appy link', () async {
      replies['handleUrl'] = true;
      expect(await Appy.handleUrl(Uri.parse('https://acme.appy.to/spring')), isTrue);
      expect(calls.single.arguments, {'url': 'https://acme.appy.to/spring'});
    });

    test('buildLink returns the share link or null', () async {
      replies['buildLink'] = 'https://acme.appy.to/spring?item=42';
      expect(await Appy.buildLink('spring', parameters: {'item': '42'}), Uri.parse('https://acme.appy.to/spring?item=42'));
      expect(calls.single.arguments, {
        'slug': 'spring',
        'parameters': {'item': '42'},
      });

      replies['buildLink'] = null;
      expect(await Appy.buildLink('Not a slug'), isNull);
    });
  });

  group('events and users', () {
    test('track sends revenue, currency and deduplicationId', () async {
      await Appy.track(
        'purchase',
        properties: {'sku': 'A1', 'qty': 2, 'gift': false},
        revenue: 19.98,
        currency: 'USD',
        deduplicationId: 'GPA.1234-5678',
      );

      expect(calls.single.method, 'track');
      expect(calls.single.arguments, {
        'name': 'purchase',
        'properties': {'sku': 'A1', 'qty': 2, 'gift': false},
        'revenue': 19.98,
        'currency': 'USD',
        'deduplicationId': 'GPA.1234-5678',
      });
    });

    test('track drops property values the native SDKs cannot store', () async {
      await Appy.track('signup', properties: {'plan': 'pro', 'at': DateTime(2026), 'tags': ['a'], 'none': null});

      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['properties'], {'plan': 'pro'});
      expect(arguments['revenue'], isNull);
    });

    test('setUserId, setTrackingEnabled and flush call the platform', () async {
      await Appy.setUserId('u_123');
      await Appy.setUserId(null);
      await Appy.setTrackingEnabled(false);
      await Appy.flush();

      expect(calls.map((call) => call.method), ['setUserId', 'setUserId', 'setTrackingEnabled', 'flush']);
      expect(calls[0].arguments, {'userId': 'u_123'});
      expect(calls[1].arguments, {'userId': null});
      expect(calls[2].arguments, {'enabled': false});
    });
  });

  test('pluginVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final version = pubspec.firstWhere((line) => line.startsWith('version: ')).substring('version: '.length).trim();
    expect(Appy.pluginVersion, version);
  });

  test('an unknown status from the platform is reported as a format error', () async {
    messenger.setMockStreamHandler(
      deepLinks,
      MockStreamHandler.inline(onListen: (arguments, events) {
        events.success({'status': 'surprise'});
      }),
    );

    await expectLater(Appy.onDeepLink.first, throwsA(isA<FormatException>()));
  });

  test('platform errors on the event channel reach the listener', () async {
    messenger.setMockStreamHandler(
      deepLinks,
      MockStreamHandler.inline(onListen: (arguments, events) {
        events.error(code: 'appy', message: 'boom');
      }),
    );

    final error = Completer<Object>();
    final subscription = Appy.onDeepLink.listen((_) {}, onError: (Object e) => error.complete(e));
    expect(await error.future.timeout(const Duration(seconds: 1)), isA<PlatformException>());
    await subscription.cancel();
  });
}
