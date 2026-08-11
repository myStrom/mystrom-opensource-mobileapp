/// WiFi network scan result (from `GET /api/v1/scan`).
class WifiNetworkModel {
  final String ssid;
  final int signal;

  const WifiNetworkModel({required this.ssid, required this.signal});

  /// The scan endpoint returns a flat array: ["SSID1", rssi1, "SSID2", rssi2, ...]
  static List<WifiNetworkModel> fromScanArray(List<dynamic> arr) {
    final out = <WifiNetworkModel>[];
    for (var i = 0; i + 1 < arr.length; i += 2) {
      out.add(
        WifiNetworkModel(
          ssid: arr[i].toString(),
          signal: (arr[i + 1] as num).toInt(),
        ),
      );
    }
    return out;
  }
}
