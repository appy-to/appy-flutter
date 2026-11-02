import 'dart:async';

import 'package:appy_sdk/appy_sdk.dart';
import 'package:flutter/material.dart';

const publishableKey = String.fromEnvironment('APPY_PUBLISHABLE_KEY', defaultValue: 'appy_pk_test_replace_me');
const linkDomain = String.fromEnvironment('APPY_LINK_DOMAIN', defaultValue: 'acme.appy.to');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Appy.configure(const AppyConfiguration(
    publishableKey: publishableKey,
    linkDomains: [linkDomain],
    logLevel: AppyLogLevel.debug,
  ));
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _log = <String>[];
  late final StreamSubscription<AppyDeepLinkResult> _deepLinks;
  late final StreamSubscription<AppyAttribution> _attributions;
  bool _trackingEnabled = true;

  @override
  void initState() {
    super.initState();
    _deepLinks = Appy.onDeepLink.listen((result) {
      _add(switch (result) {
        AppyDeepLinkFound(:final link) =>
          'Deep link: ${link.slug} ${link.parameters} deferred=${link.isDeferred} → ${link.deeplinkUrl}',
        AppyDeepLinkNotFound() => 'First launch: no Appy link led to this install',
        AppyDeepLinkFailed(:final error) => 'First launch: no answer (${error.name})',
      });
    });
    _attributions = Appy.onAttribution.listen((attribution) {
      _add(attribution.isOrganic
          ? 'Attribution: organic'
          : 'Attribution: ${attribution.linkSlug ?? attribution.network?.name} '
              '(${attribution.source}/${attribution.medium}/${attribution.campaign})');
    });
    Appy.isTrackingEnabled().then((enabled) => setState(() => _trackingEnabled = enabled));
  }

  @override
  void dispose() {
    _deepLinks.cancel();
    _attributions.cancel();
    super.dispose();
  }

  void _add(String line) => setState(() => _log.insert(0, line));

  Future<void> _trackPurchase() async {
    await Appy.track(
      'purchase',
      properties: {'sku': 'A1', 'qty': 1},
      revenue: 19.98,
      currency: 'USD',
      deduplicationId: 'example-${DateTime.now().millisecondsSinceEpoch}',
    );
    await Appy.flush();
    _add('Tracked purchase 19.98 USD');
  }

  Future<void> _shareLink() async {
    final url = await Appy.buildLink('spring', parameters: {'ref': 'example'});
    _add('Share link: ${url ?? 'needs a valid slug and link domain'}');
  }

  Future<void> _toggleTracking(bool enabled) async {
    await Appy.setTrackingEnabled(enabled);
    setState(() => _trackingEnabled = enabled);
  }

  Future<void> _showStoredValues() async {
    final attribution = await Appy.getAttribution();
    final latest = await Appy.getLatestDeepLink();
    final version = await Appy.nativeSdkVersion();
    _add('Native SDK $version, stored attribution: ${attribution ?? 'none yet'}, latest link: ${latest?.slug ?? 'none'}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appy example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Appy example')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _trackPurchase, child: const Text('Track purchase')),
                OutlinedButton(onPressed: _shareLink, child: const Text('Build share link')),
                OutlinedButton(onPressed: _showStoredValues, child: const Text('Stored values')),
              ],
            ),
            SwitchListTile(
              title: const Text('Tracking enabled'),
              value: _trackingEnabled,
              onChanged: _toggleTracking,
            ),
            const Divider(),
            for (final line in _log) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(line)),
          ],
        ),
      ),
    );
  }
}
