import 'package:dio/dio.dart';

class TokenInput {
  const TokenInput(this.token, {required this.remember});
  final String token;
  final bool remember;
}

typedef TokenPrompt =
    Future<TokenInput?> Function(
      String host,
      Future<bool> Function(String token) verify,
    );

/// Shares credentials between requests, including clients on already open pages.
/// Session credentials are scoped to device identity and never written unless
/// the user opts in. Host bindings follow discovery when addresses change.
class DeviceAuth {
  static DeviceAuth? shared;

  DeviceAuth({
    required this.readToken,
    required this.writeToken,
    required this.prompt,
  });

  final String? Function(String identity) readToken;
  final Future<void> Function(String identity, String? token) writeToken;
  final TokenPrompt prompt;
  final Map<String, String> _identities = {};
  final Map<String, String?> _session = {};
  final Map<String, String> _remembered = {};
  final Map<String, Future<bool>> _pending = {};
  final Map<String, DateTime> _dismissed = {};
  Future<void> _dialogQueue = Future.value();

  void bind(String host, String identity) {
    final oldId = identityFor(host);
    final sameMac =
        oldId.replaceAll(':', '').toUpperCase() ==
        identity.replaceAll(':', '').toUpperCase();
    if (oldId != identity && (oldId == host || sameMac)) {
      if (_session.containsKey(oldId)) {
        _session[identity] = _session.remove(oldId);
      }
      final staged = _remembered.remove(oldId);
      if (staged != null) _remembered[identity] = staged;
    }
    _identities[host] = identity;
  }

  String identityFor(String host) => _identities[host] ?? host;

  String? tokenFor(String host) {
    final id = identityFor(host);
    return _session.containsKey(id) ? _session[id] : readToken(id);
  }

  String? tokenToRemember(String identity) => _remembered[identity];

  Future<void> accept(
    String host,
    String? token, {
    required bool remember,
  }) async {
    final id = identityFor(host);
    // Keep the working credential in memory even if the local write fails.
    _session[id] = token;
    _dismissed.remove(id);
    if (remember) {
      await writeToken(id, token);
      if (token == null) {
        _remembered.remove(id);
      } else {
        _remembered[id] = token;
      }
    } else {
      _remembered.remove(id);
    }
  }

  void forget(String identity) {
    _session.remove(identity);
    _remembered.remove(identity);
    _dismissed.remove(identity);
    _identities.removeWhere((_, id) => id == identity);
  }

  Future<bool> authenticate(
    String host, {
    required Future<bool> Function(String) verify,
  }) {
    final id = identityFor(host);
    final pending = _pending[id];
    if (pending != null) return pending;
    final dismissed = _dismissed[id];
    if (dismissed != null &&
        DateTime.now().difference(dismissed) < const Duration(minutes: 1)) {
      return Future.value(false);
    }
    final result = _ask(host, id, verify);
    _pending[id] = result;
    return result.whenComplete(() => _pending.remove(id));
  }

  Future<bool> _ask(
    String host,
    String id,
    Future<bool> Function(String) verify,
  ) async {
    final previous = _dialogQueue;
    final done = _askAfter(previous, host, id, verify);
    _dialogQueue = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  Future<bool> _askAfter(
    Future<void> previous,
    String host,
    String id,
    Future<bool> Function(String) verify,
  ) async {
    await previous;
    final input = await prompt(host, verify);
    if (input == null) {
      _dismissed[id] = DateTime.now();
      return false;
    }
    // Validation is enforced here as well as in the dialog.
    if (!await verify(input.token)) return false;
    await accept(host, input.token, remember: input.remember);
    return true;
  }

  static bool isAccessRejection(DioException error) =>
      const [401, 403, 404].contains(error.response?.statusCode);
}
