import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/network/device_auth.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';
import 'package:mystrom_local/data/models/scene.dart';
import 'package:mystrom_local/domain/usecases/run_scene.dart';

import '../integration_test/fake_mystrom_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeMystromServer server;
  late FakeDeviceState state;
  late DeviceHttpClient client;
  late String host;
  final saved = <String, String?>{};
  var prompts = 0;

  DeviceAuth configure(TokenPrompt prompt) {
    final auth = DeviceAuth(
      readToken: (id) => saved[id],
      writeToken: (id, token) async => saved[id] = token,
      prompt: (host, verify) {
        prompts++;
        return prompt(host, verify);
      },
    )..bind(host, state.mac);
    DeviceAuth.shared = auth;
    return auth;
  }

  setUp(() async {
    HttpOverrides.global = null; // exercise the real loopback HTTP transport
    server = FakeMystromServer();
    await server.start();
    state = server.register(
      FakeDeviceState(
        mac: 'AA:BB:CC:DD:EE:01',
        type: 'ws2',
        model: 'WS2',
        version: 'test',
      ),
    );
    host = '${server.host}:${server.port}';
    client = DeviceHttpClient(timeout: const Duration(seconds: 1));
    prompts = 0;
    saved.clear();
  });

  tearDown(() async {
    client.dispose();
    DeviceAuth.shared = null;
    await server.stop();
  });

  for (final status in [401, 403, 404]) {
    test(
      'rejects wrong token then retries the actual command after $status',
      () async {
        state.token = 'current-fixture-token';
        state.authStatus = status;
        configure((_, verify) async {
          expect(await verify('wrong-fixture-token'), isFalse);
          expect(state.relay, isFalse);
          expect(await verify(state.token), isTrue);
          return TokenInput(state.token, remember: true);
        });
        final result = await DeviceRemoteDataSource(
          client,
        ).setRelay(host, on: true);
        expect(result.relay, isTrue);
        expect(state.relay, isTrue);
        expect(prompts, 1);
        expect(saved[state.mac], state.token);
        final commands = server.requests
            .where((r) => r.path == '/relay')
            .toList();
        expect(commands, hasLength(2));
        expect(commands.first.token, isNull);
        expect(commands.last.method, 'GET');
        expect(commands.last.query, {'state': '1'});
        expect(commands.last.token, state.token);
      },
    );
  }

  test(
    'external token change replaces a saved stale token for existing clients',
    () async {
      state.token = 'before-change';
      saved[state.mac] = state.token;
      configure((_, verify) async {
        expect(await verify('before-change'), isFalse);
        expect(await verify('after-change'), isTrue);
        return const TokenInput('after-change', remember: true);
      });
      final remote = DeviceRemoteDataSource(client);
      await remote.setRelay(host, on: true);
      state.token = 'after-change';
      await remote.setRelay(host, on: false);
      expect(state.relay, isFalse);
      expect(prompts, 1);
      expect(saved[state.mac], 'after-change');
      final last = server.requests.lastWhere((r) => r.path == '/relay');
      expect(last.query, {'state': '0'});
      expect(last.token, 'after-change');
      // Recreate the credential manager as on a cold app start.
      configure((_, _) async => throw StateError('must use the saved token'));
      await remote.setRelay(host, on: true);
      expect(state.relay, isTrue);
      expect(prompts, 1);
    },
  );

  test(
    'cancel does not replay a rejected mutation or save credentials',
    () async {
        state.token = 'required';
        configure((_, _) async => null);
      await expectLater(
        DeviceRemoteDataSource(client).setRelay(host, on: true),
        throwsA(isA<DioException>()),
      );
      expect(state.relay, isFalse);
      expect(saved, isEmpty);
      expect(prompts, 1);
      expect(server.requests.where((r) => r.path == '/relay'), hasLength(1));
    },
  );

  test(
    'incorrect prompt result cannot be saved or authorize a mutation',
    () async {
      state.token = 'required';
      configure((_, _) async => const TokenInput('incorrect', remember: true));
      await expectLater(
        DeviceRemoteDataSource(client).toggleRelay(host),
        throwsA(isA<DioException>()),
      );
      expect(state.relay, isFalse);
      expect(saved, isEmpty);
      expect(server.requests.where((r) => r.path == '/toggle'), hasLength(1));
    },
  );

  test('session-only token is shared but disappears after restart', () async {
    state.token = 'session-only';
    configure((_, _) async => TokenInput(state.token, remember: false));
    await DeviceRemoteDataSource(client).setRelay(host, on: true);
    final other = DeviceHttpClient();
    try {
      await DeviceRemoteDataSource(other).setRelay(host, on: false);
      expect(state.relay, isFalse);
      expect(prompts, 1);
      expect(saved, isEmpty);
      configure((_, _) async => null);
      await expectLater(
        DeviceRemoteDataSource(other).toggleRelay(host),
        throwsA(isA<DioException>()),
      );
      expect(state.relay, isFalse);
      expect(prompts, 2);
    } finally {
      other.dispose();
    }
  });

  test('concurrent access rejections share one prompt', () async {
    state.token = 'concurrent';
    final gate = Completer<TokenInput?>();
    configure((_, _) => gate.future);
    final remote = DeviceRemoteDataSource(client);
    final first = remote.getReport(host);
    final second = remote.getReport(host);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    gate.complete(TokenInput(state.token, remember: true));
    await Future.wait([first, second]);
    expect(prompts, 1);
  });

  test(
    'background requests do not prompt; scenes use the saved credential',
    () async {
      state.token = 'scene-fixture';
      final auth = configure((_, _) async => null);
      final background = DeviceHttpClient(promptForToken: false);
      try {
        await expectLater(
          DeviceRemoteDataSource(background).getReport(host),
          throwsA(isA<DioException>()),
        );
        expect(prompts, 0);
        await auth.accept(host, state.token, remember: true);
        final scene = Scene(
          id: 'test',
          name: 'test',
          iconCode: 0,
          colorValue: 0,
          actions: [
            SceneAction(
              deviceMac: state.mac,
              deviceName: 'test',
              deviceTypeCode: 106,
              action: 'on',
            ),
          ],
        );
        expect(
          await RunScene(DeviceRemoteDataSource(client))(
            scene,
            resolveIp: (_) => host,
          ),
          isEmpty,
        );
        expect(state.relay, isTrue);
        final request = server.requests.lastWhere((r) => r.path == '/relay');
        expect(request.method, 'GET');
        expect(request.query, {'state': '1'});
        expect(request.token, state.token);
      } finally {
        background.dispose();
      }
    },
  );

  test(
    'credentials are not sent to another device or through redirects',
    () async {
      final other = FakeMystromServer();
      await other.start();
      final otherState = other.register(
        FakeDeviceState(
          mac: 'AA:BB:CC:DD:EE:02',
          type: 'ws2',
          model: 'WS2',
          version: 'test',
        ),
      );
      state.token = 'private-fixture';
      saved[state.mac] = state.token;
        final auth = configure((_, _) async => null);
      try {
        await DeviceRemoteDataSource(
          client,
        ).setRelay('${other.host}:${other.port}', on: true);
        expect(otherState.relay, isTrue);
        expect(other.requests.every((r) => r.token == null), isTrue);
        final redirector = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final redirectHost = '${redirector.address.host}:${redirector.port}';
        auth.bind(redirectHost, state.mac);
        String? receivedToken;
        redirector.listen((request) async {
          receivedToken = request.headers.value('Token');
          request.response.statusCode = 302;
          request.response.headers.set(
            HttpHeaders.locationHeader,
            'http://${other.host}:${other.port}/relay?state=1',
          );
          await request.response.close();
        });
        otherState.relay = false;
        final before = other.requests.length;
        try {
          await expectLater(
            client.get(redirectHost, '/redirect'),
            throwsA(isA<DioException>()),
          );
          expect(receivedToken, state.token);
          expect(other.requests, hasLength(before));
          expect(otherState.relay, isFalse);
        } finally {
          await redirector.close(force: true);
        }
      } finally {
        await other.stop();
      }
    },
  );

  test(
    'staged credentials follow device identity across address changes',
    () async {
      final auth = configure((_, _) async => null);
      await auth.accept(host, 'fixture', remember: true);
      auth.bind('new-address', state.mac);
      expect(auth.tokenFor('new-address'), 'fixture');
      expect(auth.tokenToRemember(state.mac), 'fixture');
      auth.forget(state.mac);
      expect(auth.tokenToRemember(state.mac), isNull);
    },
  );

  test('a missing endpoint with working info never asks for a token', () async {
    server.responseStatuses['/missing'] = 404;
    configure((_, _) async => throw StateError('unexpected prompt'));
    await expectLater(
      client.get(host, '/missing'),
      throwsA(isA<DioException>()),
    );
    expect(prompts, 0);
  });

  test(
    'a concurrent credential update retries the rejected command without another prompt',
    () async {
      state.token = 'current-fixture';
      saved[state.mac] = 'outdated-fixture';
      final auth = configure(
        (_, _) async => throw StateError('unexpected prompt'),
      );
      server.onAuthRejected = () async {
        server.onAuthRejected = null;
        await auth.accept(host, state.token, remember: true);
      };
      await DeviceRemoteDataSource(client).setRelay(host, on: true);
      expect(state.relay, isTrue);
      expect(prompts, 0);
      final commands = server.requests
          .where((r) => r.path == '/relay')
          .toList();
      expect(commands, hasLength(2));
      expect(commands.first.token, 'outdated-fixture');
      expect(commands.last.token, state.token);
      expect(commands.last.query, {'state': '1'});
    },
  );

  test(
    'connection timeout fails without prompting or changing stored token',
    () async {
      server.responseDelay = const Duration(milliseconds: 250);
      saved[state.mac] = 'unchanged-fixture';
      configure((_, _) async => throw StateError('unexpected prompt'));
      final short = DeviceHttpClient(timeout: const Duration(milliseconds: 30));
      try {
        await expectLater(
          DeviceRemoteDataSource(short).getReport(host),
          throwsA(isA<DioException>()),
        );
        expect(prompts, 0);
        expect(saved[state.mac], 'unchanged-fixture');
        expect(state.relay, isFalse);
      } finally {
        short.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    },
  );
}
