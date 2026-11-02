import 'appy_types.dart';

AppyDeepLinkResult decodeDeepLinkResult(Object? raw) {
  final map = _map(raw);
  switch (map['status']) {
    case 'found':
      return AppyDeepLinkFound(decodeDeepLink(map['link']));
    case 'notFound':
      return const AppyDeepLinkNotFound();
    case 'failed':
      return AppyDeepLinkFailed(_error(map['error']));
    default:
      throw FormatException('Unknown deep link status from the native Appy SDK', map['status']);
  }
}

AppyDeepLink decodeDeepLink(Object? raw) {
  final map = _map(raw);
  return AppyDeepLink(
    url: _uri(map['url']),
    deeplinkUrl: _uri(map['deeplinkUrl']),
    slug: map['slug'] as String? ?? '',
    parameters: _stringMap(map['parameters']),
    isDeferred: map['isDeferred'] as bool? ?? false,
    clickedAt: _date(map['clickedAtMillis']),
  );
}

AppyAttribution decodeAttribution(Object? raw) {
  final map = _map(raw);
  final network = map['network'];
  return AppyAttribution(
    isOrganic: map['isOrganic'] as bool? ?? true,
    linkSlug: map['linkSlug'] as String?,
    linkTitle: map['linkTitle'] as String?,
    source: map['source'] as String?,
    medium: map['medium'] as String?,
    campaign: map['campaign'] as String?,
    clickedAt: _date(map['clickedAtMillis']),
    network: network == null ? null : _adNetwork(_map(network)),
  );
}

AppyAdNetwork _adNetwork(Map<Object?, Object?> map) => AppyAdNetwork(
      name: map['name'] as String? ?? '',
      campaignId: map['campaignId'] as String?,
      campaignName: map['campaignName'] as String?,
      adGroupId: map['adGroupId'] as String?,
      adGroupName: map['adGroupName'] as String?,
      adId: map['adId'] as String?,
      clickId: map['clickId'] as String?,
      touch: map['touch'] as String?,
    );

AppyError _error(Object? raw) => switch (raw) {
      'timeout' => AppyError.timeout,
      'network' => AppyError.network,
      _ => AppyError.invalidResponse,
    };

Map<Object?, Object?> _map(Object? raw) {
  if (raw is Map<Object?, Object?>) {
    return raw;
  }
  throw FormatException('Expected a map from the native Appy SDK', raw);
}

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map<Object?, Object?>) {
    return const {};
  }
  return {
    for (final entry in raw.entries)
      if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
  };
}

Uri? _uri(Object? raw) => raw is String ? Uri.tryParse(raw) : null;

DateTime? _date(Object? raw) => raw is num ? DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true) : null;
