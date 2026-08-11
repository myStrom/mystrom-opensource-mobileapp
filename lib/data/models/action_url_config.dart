/// Action URL configuration for button devices.
///
/// Single-button device uses a JSON blob with `actions` array.
/// Button-se devices use raw URL strings per referer/action.
class ActionUrlConfigModel {
  /// For single-button device: list of action entries.
  final List<ActionEntry> actions;

  /// For button-se: map of referer -> (action -> url).
  final Map<String, Map<String, String>> refererActions;

  const ActionUrlConfigModel({
    this.actions = const [],
    this.refererActions = const {},
  });

  factory ActionUrlConfigModel.fromJsonActions(Map<String, dynamic> j) {
    final list = (j['actions'] as List?) ?? [];
    return ActionUrlConfigModel(
      actions: list
          .map((e) => ActionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ActionUrlConfigModel.fromJsonButtonSe(Map<String, dynamic> j) {
    final map = <String, Map<String, String>>{};
    j.forEach((referer, value) {
      if (value is Map) {
        map[referer] = value.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }
    });
    return ActionUrlConfigModel(refererActions: map);
  }
}

class ActionEntry {
  final String scheme; // single | double | long | touch | generic
  final String url;
  final String method;
  final String headers;
  final String payload;

  const ActionEntry({
    required this.scheme,
    required this.url,
    this.method = 'GET',
    this.headers = '',
    this.payload = '',
  });

  factory ActionEntry.fromJson(Map<String, dynamic> j) => ActionEntry(
    scheme: j['scheme'] as String? ?? '',
    url: j['url'] as String? ?? '',
    method: j['method'] as String? ?? 'GET',
    headers: j['headers'] as String? ?? '',
    payload: j['payload'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'scheme': scheme,
    'url': url,
    'method': method,
    'headers': headers,
    'payload': payload,
  };
}
