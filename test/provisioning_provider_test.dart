import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';
import 'package:mystrom_local/data/repositories/provisioning_repository.dart';
import 'package:mystrom_local/domain/usecases/provision_wifi.dart';
import 'package:mystrom_local/presentation/providers/provisioning_provider.dart';

void main() {
  late ProvisioningProvider provider;

  setUp(() {
    final client = DeviceHttpClient(timeout: const Duration(milliseconds: 500));
    provider = ProvisioningProvider(
      ProvisionWifi(ProvisioningRepository(DeviceRemoteDataSource(client))),
    );
    addTearDown(client.dispose);
    addTearDown(provider.dispose);
  });

  test('unreachable AP cannot be reported as a successful setup', () async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();

    expect(
      await provider.sendCredentials('Test Wi-Fi', null, ip: '127.0.0.1:$port'),
      false,
    );
    expect(provider.stage, isNot(ProvisioningStage.done));
    expect(provider.error, isNotNull);
  });

  for (final acknowledge in [true, false]) {
    test(
      'credentials POST ${acknowledge ? 'with ACK' : 'with lost response'}',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final request = Completer<(String, String, Object?)>();
        server.listen((req) async {
          final body = jsonDecode(await utf8.decoder.bind(req).join());
          request.complete((req.method, req.uri.path, body));
          if (acknowledge) await req.response.close();
        });

        expect(
          await provider.sendCredentials(
            'Test Wi-Fi',
            null,
            ip: '127.0.0.1:${server.port}',
          ),
          acknowledge,
        );
        final (method, path, body) = await request.future;
        expect((method, path), ('POST', '/api/v1/connect'));
        expect(body, {'ssid': 'Test Wi-Fi', 'roaming': false});
        expect(
          provider.stage,
          acknowledge ? ProvisioningStage.done : ProvisioningStage.unconfirmed,
        );
      },
    );
  }
}
