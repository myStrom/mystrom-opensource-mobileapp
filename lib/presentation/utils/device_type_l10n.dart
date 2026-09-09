import '../../core/utils/device_type.dart';
import '../../l10n/app_localizations.dart';

/// Localized product name for a [DeviceType] (smart-home wording).
extension DeviceTypeL10n on DeviceType {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      DeviceType.ws2 => l10n.deviceTypeWifiSwitchCh,
      DeviceType.wse => l10n.deviceTypeWifiSwitchEu,
      DeviceType.wsx => l10n.deviceTypeWifiSwitchX,
      DeviceType.wrs => l10n.deviceTypeWifiStrip,
      DeviceType.wll => l10n.deviceTypeWifiCube,
      DeviceType.wms => l10n.deviceTypeWifiPir,
      DeviceType.bp2 => l10n.deviceTypeWifiButtonPlus2,
      DeviceType.bp1 => l10n.deviceTypeWifiButtonPlus1,
      DeviceType.bm1 => l10n.deviceTypeWifiButtonMax,
      DeviceType.bulb => l10n.deviceTypeWifiBulb,
      DeviceType.lcs => l10n.deviceTypeWifiSwitchLcs,
      DeviceType.button => l10n.deviceTypeWifiButton,
      DeviceType.unknown => l10n.deviceTypeUnknown,
    };
  }
}
