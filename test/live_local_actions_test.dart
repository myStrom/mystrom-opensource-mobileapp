// Opt-in bench test. Writes and restores action URLs on the named DUTs.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/network/device_http_client.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/data/datasources/device_remote_ds.dart';
import 'package:mystrom_local/domain/usecases/configure_button_action.dart';

const _live = bool.fromEnvironment('MYSTROM_LIVE_ACTIONS');
const _ws2 = String.fromEnvironment('WS2_ACTION_IP');
const _wse = String.fromEnvironment('WSE_ACTION_IP');
const _wms = String.fromEnvironment('WMS_ACTION_IP');

void main() {
  test(
    '5.0.5 bench stores actions and WS2 executes both edges against WSE',
    () async {
      final client = DeviceHttpClient();
      addTearDown(client.dispose);
      final remote = DeviceRemoteDataSource(client);
      const targets = [
        (_ws2, String.fromEnvironment('WS2_ACTION_MAC')),
        (_wse, String.fromEnvironment('WSE_ACTION_MAC')),
        (_wms, String.fromEnvironment('WMS_ACTION_MAC')),
      ];
      expect(targets.map((entry) => entry.$1).toSet(), hasLength(3));
      for (final (ip, mac) in targets) {
        expect(ip, isNotEmpty, reason: 'Pass the bench IP via --dart-define');
        expect(mac, isNotEmpty, reason: 'Pass the bench MAC via --dart-define');
        final info = await remote.getInfo(ip);
        expect(info.mac.replaceAll(':', '').toUpperCase(), mac);
        expect(info.version, '5.0.5');
      }
      final switchUrls = [
        (_ws2, await remote.getSwitchButtonActions(_ws2)),
        (_wse, await remote.getSwitchButtonActions(_wse)),
      ];
      final pirUrls = await remote.getPirActions(_wms);
      for (final snapshot in [
        ...switchUrls.map((entry) => entry.$2),
        pirUrls,
      ]) {
        expect(
          snapshot.values,
          everyElement(isEmpty),
          reason: 'DUT actions must be empty',
        );
      }
      Future<bool> relay(String ip) async =>
          (await client.get<Map<String, dynamic>>(ip, '/report')).data!['relay']
              as bool;
      Future<void> setRelay(String ip, bool on) async {
        await client.get(ip, '/relay', query: {'state': on ? 1 : 0});
        expect(await relay(ip), on);
      }

      Future<void> waitForRelay(String ip, bool on, Duration timeout) async {
        final elapsed = Stopwatch()..start();
        do {
          if (await relay(ip) == on) return;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        } while (elapsed.elapsed < timeout);
        fail('$ip did not reach relay=$on');
      }

      final ws2Relay = await relay(_ws2);
      final wseRelay = await relay(_wse);
      final changed = <Future<void> Function(DeviceRemoteDataSource)>[];
      const probe = 'get://$_wse/info';
      try {
        for (final (ip, snapshot) in switchUrls) {
          for (final slot in snapshot.keys) {
            changed.add((cleanup) async {
              await cleanup.setSwitchButtonAction(
                ip,
                slot,
                url: snapshot[slot]!,
              );
            });
            expect(await remote.setSwitchButtonAction(ip, slot, url: probe), {
              ...snapshot,
              slot: probe,
            });
            expect(
              await remote.setSwitchButtonAction(ip, slot, url: ''),
              snapshot,
            );
            changed.removeLast();
          }
        }
        for (final slot in pirUrls.keys) {
          changed.add((cleanup) async {
            await cleanup.setPirAction(_wms, slot, url: pirUrls[slot]!);
          });
          expect(await remote.setPirAction(_wms, slot, url: probe), {
            ...pirUrls,
            slot: probe,
          });
          expect(await remote.setPirAction(_wms, slot, url: ''), pirUrls);
          changed.removeLast();
        }
        debugPrint('Bench: all twelve action slots confirmed and restored.');

        await setRelay(_ws2, false);
        await setRelay(_wse, true);
        for (final (slot, action) in [('on', 'off'), ('off', 'on')]) {
          changed.add((cleanup) async {
            await cleanup.setSwitchButtonAction(_ws2, slot, url: '');
          });
          await remote.setSwitchButtonAction(
            _ws2,
            slot,
            url: ConfigureButtonAction.buildUrl(
              targetIp: _wse,
              targetType: DeviceType.wse,
              action: action,
            ),
          );
        }
        await client.get(_ws2, '/timer', query: {'mode': 'on', 'time': 8});
        expect(await relay(_ws2), isTrue);
        await waitForRelay(_wse, false, const Duration(seconds: 5));
        await waitForRelay(_ws2, false, const Duration(seconds: 12));
        await waitForRelay(_wse, true, const Duration(seconds: 5));
        debugPrint('Bench: both WS2 timer edges changed the WSE relay.');
      } finally {
        final cleanupClient = DeviceHttpClient();
        final cleanup = DeviceRemoteDataSource(cleanupClient);
        final errors = <Object>[];
        Future<void> restore(Future<void> Function() operation) async {
          try {
            await operation();
          } catch (error) {
            errors.add(error);
          }
        }

        try {
          await restore(() async {
            await cleanupClient.get(
              _ws2,
              '/timer',
              query: {'mode': 'none', 'time': 0},
            );
          });
          for (final restoreSlot in changed.reversed) {
            await restore(() => restoreSlot(cleanup));
          }
          for (final (ip, on) in [(_ws2, ws2Relay), (_wse, wseRelay)]) {
            await restore(() async {
              await cleanupClient.get(
                ip,
                '/relay',
                query: {'state': on ? 1 : 0},
              );
              final report = await cleanupClient.get<Map<String, dynamic>>(
                ip,
                '/report',
              );
              expect(report.data!['relay'], on);
            });
          }
          // Each PIR slot was already read back after its restoration. Any
          // interrupted PIR write is also on the cleanup stack.
          for (final (ip, snapshot) in switchUrls) {
            await restore(() async {
              expect(await cleanup.getSwitchButtonActions(ip), snapshot);
            });
          }
        } finally {
          cleanupClient.dispose();
        }
        expect(errors, isEmpty, reason: 'DUT restoration failed');
      }
    },
    skip: !_live,
  );
}
