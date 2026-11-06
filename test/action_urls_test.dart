import 'package:flutter_test/flutter_test.dart';
import 'package:mystrom_local/core/utils/device_type.dart';
import 'package:mystrom_local/domain/usecases/configure_button_action.dart';

void main() {
  String url(DeviceType target, String action, {String? color, int? ramp}) =>
      ConfigureButtonAction.buildUrl(
        targetIp: '192.0.2.170',
        targetType: target,
        action: action,
        color: color,
        ramp: ramp,
      );

  for (final model in [
    DeviceType.ws2,
    DeviceType.wse,
    DeviceType.wsx,
    DeviceType.lcs,
  ]) {
    test('${model.model} actions match the relay control API', () {
      expect(url(model, 'on'), 'get://192.0.2.170/relay?state=1');
      expect(url(model, 'off'), 'get://192.0.2.170/relay?state=0');
      expect(url(model, 'toggle'), 'get://192.0.2.170/toggle');
      expect(() => url(model, 'color'), throwsArgumentError);
    });
  }

  test(
    'WRS color action uses the legacy form without an invalid action enum',
    () {
      expect(
        url(DeviceType.wrs, 'color', color: '120;100;20', ramp: 500),
        'post://192.0.2.170/device?color=120;100;20&ramp=500',
      );
    },
  );

  test('Bulb color action uses the same fields as the app color control', () {
    expect(
      url(DeviceType.bulb, 'color', color: '120;100;20', ramp: 500),
      'post://192.0.2.170/api/v1/device/self?action=on&color=120;100;20&ramp=500&mode=hsv',
    );
  });
}
