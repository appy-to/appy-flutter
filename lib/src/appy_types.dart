import 'package:flutter/foundation.dart';

enum AppyLogLevel { none, error, warning, info, debug }

enum AppyError { timeout, network, invalidResponse }

@immutable
final class AppyAndroidOptions {
  const AppyAndroidOptions({this.collectInstallReferrer = true, this.metaAppId});

  final bool collectInstallReferrer;
  final String? metaAppId;

  Map<String, Object?> toMap() => {
        'collectInstallReferrer': collectInstallReferrer,
        'metaAppId': metaAppId,
      };
}

@immutable
final class AppyConfiguration {
  const AppyConfiguration({
    required this.publishableKey,
    this.linkDomains = const [],
    this.emailLinkDomains = const [],
    this.logLevel = AppyLogLevel.error,
    this.openDeferredDeepLinks = false,
    this.deferredDeepLinkTimeout = const Duration(seconds: 5),
    this.launchLinkWaitInterval = const Duration(milliseconds: 500),
    this.requestTimeout = const Duration(seconds: 10),
    this.apiBaseUrl,
    this.android = const AppyAndroidOptions(),
  });

  final String publishableKey;
  final List<String> linkDomains;
  final List<String> emailLinkDomains;
  final AppyLogLevel logLevel;
  final bool openDeferredDeepLinks;
  final Duration deferredDeepLinkTimeout;
  final Duration launchLinkWaitInterval;
  final Duration requestTimeout;
  final Uri? apiBaseUrl;
  final AppyAndroidOptions android;

  Map<String, Object?> toMap() => {
        'publishableKey': publishableKey,
        'linkDomains': linkDomains,
        'emailLinkDomains': emailLinkDomains,
        'logLevel': logLevel.name,
        'openDeferredDeepLinks': openDeferredDeepLinks,
        'deferredDeepLinkTimeoutMillis': deferredDeepLinkTimeout.inMilliseconds,
        'launchLinkWaitMillis': launchLinkWaitInterval.inMilliseconds,
        'requestTimeoutMillis': requestTimeout.inMilliseconds,
        'apiBaseUrl': apiBaseUrl?.toString(),
        'android': android.toMap(),
      };
}

@immutable
final class AppyDeepLink {
  const AppyDeepLink({
    this.url,
    this.deeplinkUrl,
    required this.slug,
    this.parameters = const {},
    this.isDeferred = false,
    this.clickedAt,
  });

  final Uri? url;
  final Uri? deeplinkUrl;
  final String slug;
  final Map<String, String> parameters;
  final bool isDeferred;
  final DateTime? clickedAt;

  @override
  bool operator ==(Object other) =>
      other is AppyDeepLink &&
      other.url == url &&
      other.deeplinkUrl == deeplinkUrl &&
      other.slug == slug &&
      mapEquals(other.parameters, parameters) &&
      other.isDeferred == isDeferred &&
      other.clickedAt == clickedAt;

  @override
  int get hashCode => Object.hash(
        url,
        deeplinkUrl,
        slug,
        Object.hashAllUnordered(parameters.entries.map((e) => Object.hash(e.key, e.value))),
        isDeferred,
        clickedAt,
      );

  @override
  String toString() =>
      'AppyDeepLink(slug: $slug, url: $url, deeplinkUrl: $deeplinkUrl, parameters: $parameters, '
      'isDeferred: $isDeferred, clickedAt: $clickedAt)';
}

@immutable
sealed class AppyDeepLinkResult {
  const AppyDeepLinkResult();
}

final class AppyDeepLinkFound extends AppyDeepLinkResult {
  const AppyDeepLinkFound(this.link);

  final AppyDeepLink link;

  @override
  bool operator ==(Object other) => other is AppyDeepLinkFound && other.link == link;

  @override
  int get hashCode => link.hashCode;

  @override
  String toString() => 'AppyDeepLinkFound($link)';
}

final class AppyDeepLinkNotFound extends AppyDeepLinkResult {
  const AppyDeepLinkNotFound();

  @override
  bool operator ==(Object other) => other is AppyDeepLinkNotFound;

  @override
  int get hashCode => (AppyDeepLinkNotFound).hashCode;

  @override
  String toString() => 'AppyDeepLinkNotFound()';
}

final class AppyDeepLinkFailed extends AppyDeepLinkResult {
  const AppyDeepLinkFailed(this.error);

  final AppyError error;

  @override
  bool operator ==(Object other) => other is AppyDeepLinkFailed && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AppyDeepLinkFailed(${error.name})';
}

@immutable
final class AppyAdNetwork {
  const AppyAdNetwork({
    required this.name,
    this.campaignId,
    this.campaignName,
    this.adGroupId,
    this.adGroupName,
    this.adId,
    this.clickId,
    this.touch,
  });

  final String name;
  final String? campaignId;
  final String? campaignName;
  final String? adGroupId;
  final String? adGroupName;
  final String? adId;
  final String? clickId;
  final String? touch;

  @override
  bool operator ==(Object other) =>
      other is AppyAdNetwork &&
      other.name == name &&
      other.campaignId == campaignId &&
      other.campaignName == campaignName &&
      other.adGroupId == adGroupId &&
      other.adGroupName == adGroupName &&
      other.adId == adId &&
      other.clickId == clickId &&
      other.touch == touch;

  @override
  int get hashCode => Object.hash(name, campaignId, campaignName, adGroupId, adGroupName, adId, clickId, touch);

  @override
  String toString() => 'AppyAdNetwork(name: $name, campaignId: $campaignId, adGroupId: $adGroupId, adId: $adId)';
}

@immutable
final class AppyAttribution {
  const AppyAttribution({
    required this.isOrganic,
    this.linkSlug,
    this.linkTitle,
    this.source,
    this.medium,
    this.campaign,
    this.clickedAt,
    this.network,
  });

  final bool isOrganic;
  final String? linkSlug;
  final String? linkTitle;
  final String? source;
  final String? medium;
  final String? campaign;
  final DateTime? clickedAt;
  final AppyAdNetwork? network;

  @override
  bool operator ==(Object other) =>
      other is AppyAttribution &&
      other.isOrganic == isOrganic &&
      other.linkSlug == linkSlug &&
      other.linkTitle == linkTitle &&
      other.source == source &&
      other.medium == medium &&
      other.campaign == campaign &&
      other.clickedAt == clickedAt &&
      other.network == network;

  @override
  int get hashCode => Object.hash(isOrganic, linkSlug, linkTitle, source, medium, campaign, clickedAt, network);

  @override
  String toString() =>
      'AppyAttribution(isOrganic: $isOrganic, linkSlug: $linkSlug, source: $source, medium: $medium, '
      'campaign: $campaign, network: $network)';
}
