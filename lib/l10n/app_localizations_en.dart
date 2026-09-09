// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'myStrom Local';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get retry => 'Retry';

  @override
  String get reload => 'Reload';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get enable => 'Enable';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get set => 'Set';

  @override
  String get advanced => 'Advanced';

  @override
  String get loading => 'Loading…';

  @override
  String get loadingEllipsis => '…';

  @override
  String get noDataDash => '--';

  @override
  String get unknown => 'unknown';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get noIpAddress => 'No IP address';

  @override
  String get noIp => 'no IP';

  @override
  String get online => 'online';

  @override
  String get offline => 'offline';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get schedulerTooltip => 'Scheduler';

  @override
  String get identify => 'Identify';

  @override
  String get identifySignalSent =>
      'Identification signal sent — look for a blink.';

  @override
  String get timerSet => 'Timer set';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get toggle => 'Toggle';

  @override
  String get locked => 'Locked';

  @override
  String get power => 'Power';

  @override
  String get totalPower => 'Total power';

  @override
  String get totalEnergy => 'Total energy';

  @override
  String get color => 'Color';

  @override
  String get name => 'Name';

  @override
  String get device => 'Device';

  @override
  String get action => 'Action';

  @override
  String get room => 'Room';

  @override
  String get favorite => 'Favorite';

  @override
  String get firmware => 'Firmware';

  @override
  String get connection => 'Connection';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get roaming => 'Roaming';

  @override
  String get handshake => 'Handshake';

  @override
  String get login => 'Login';

  @override
  String get failed => 'Failed';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get mac => 'MAC';

  @override
  String get ip => 'IP';

  @override
  String get type => 'Type';

  @override
  String get ntp => 'NTP';

  @override
  String get dns => 'DNS';

  @override
  String get deviceTypeWifiSwitchCh => 'WiFi Switch CH';

  @override
  String get deviceTypeWifiSwitchEu => 'WiFi Switch EU';

  @override
  String get deviceTypeWifiSwitchX => 'WiFi Switch X';

  @override
  String get deviceTypeWifiStrip => 'WiFi Strip';

  @override
  String get deviceTypeWifiCube => 'WiFi Cube';

  @override
  String get deviceTypeWifiPir => 'WiFi Motion Sensor';

  @override
  String get deviceTypeWifiButtonPlus2 => 'WiFi Button Plus 2';

  @override
  String get deviceTypeWifiButtonPlus1 => 'WiFi Button Plus 1';

  @override
  String get deviceTypeWifiButtonMax => 'WiFi Button Max';

  @override
  String get deviceTypeWifiBulb => 'WiFi Bulb';

  @override
  String get deviceTypeWifiSwitchLcs => 'WiFi Switch LCS';

  @override
  String get deviceTypeWifiButton => 'WiFi Button';

  @override
  String get deviceTypeUnknown => 'Unknown Device';

  @override
  String discoveryCountFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count found',
      one: '1 found',
    );
    return '$_temp0';
  }

  @override
  String get discoveryListening => 'searching…';

  @override
  String get sectionScenes => 'Scenes';

  @override
  String get sectionMyDevices => 'My devices';

  @override
  String get sectionNewlyDiscovered => 'Newly found';

  @override
  String get noDevicesInCategory => 'No devices in this category';

  @override
  String noToggleableDevicesInRoom(String room) {
    return 'No switchable devices in \"$room\"';
  }

  @override
  String turnAllInRoomOn(String room) {
    return 'Turn all in \"$room\" on';
  }

  @override
  String turnAllInRoomOff(String room) {
    return 'Turn all in \"$room\" off';
  }

  @override
  String bulkToggleResultOn(int ok, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$ok/$total devices switched on',
      one: '$ok/$total device switched on',
    );
    return '$_temp0';
  }

  @override
  String bulkToggleResultOff(int ok, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$ok/$total devices switched off',
      one: '$ok/$total device switched off',
    );
    return '$_temp0';
  }

  @override
  String sceneExecuted(String name) {
    return 'Scene \"$name\" executed';
  }

  @override
  String sceneExecuteFailed(String list) {
    return 'Failed: $list';
  }

  @override
  String get categoryAll => 'All';

  @override
  String get categoryFavorite => 'Favorite';

  @override
  String roomChipLongPressHint(String room) {
    return 'Press and hold to turn all in \"$room\" on/off';
  }

  @override
  String get emptyStateListening =>
      'Searching for devices…\nNo devices found yet.\nMake sure the myStrom devices are on the same WiFi.';

  @override
  String get emptyStateStartingDiscovery =>
      'Starting UDP discovery…\nIf your system asked for local network access,\nmake sure you allowed it.';

  @override
  String get addDeviceManually => 'Add device manually';

  @override
  String powerWatts(String value) {
    return '$value W';
  }

  @override
  String energyKwh(String value) {
    return '$value kWh';
  }

  @override
  String temperatureCelsius(String value) {
    return '$value °C';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get sinceBoot => 'Since boot';

  @override
  String get deviceLockedToggleDisabled =>
      'This device is locked — on/off toggle is disabled.';

  @override
  String get addDeviceTitle => 'Add Device';

  @override
  String get addDevice => 'Add device';

  @override
  String get tabDiscovered => 'Found';

  @override
  String get tabSoftAp => 'SoftAP';

  @override
  String get tabWps => 'WPS';

  @override
  String get noNewDevicesFound =>
      'No new devices found on the local network.\n\nMake sure your myStrom devices are powered on and connected to the same WiFi. Discovery runs automatically in the background.';

  @override
  String deviceAddedSnack(String displayName) {
    return '$displayName added';
  }

  @override
  String get credentialsSentSnackbar =>
      'Credentials sent. The device will reboot and join your WiFi.';

  @override
  String get howToEnterApMode => 'How to enter AP mode';

  @override
  String get apModeInstructionsSubtitle =>
      'Differs by device type — tap to expand';

  @override
  String get apModeSwitchesTitle =>
      'Switches (WS2, WSE, WSX, LCS), Strip (WRS), Cube (WLL), Motion Sensor (WMS)';

  @override
  String get apModeSwitchResetStep1 =>
      'Factory reset: press and hold the \"+\" button for 10–20 s until the LED blinks white.';

  @override
  String get apModeSwitchResetStep2 =>
      'After the reset the LED blinks red briefly, then the device enters AP mode.';

  @override
  String get apModeButtonsTitle => 'Buttons (BP2, BM1, WBS/WBP)';

  @override
  String get apModeButtonResetStep1 =>
      'Factory reset: press and hold any button for 10–20 s until the LED blinks alternating white/red, then release and press once more within 2 s to confirm (LED blinks white).';

  @override
  String get apModeButtonResetStep2 =>
      'After the reset the device starts in WPS mode (white blink, 2 min). To switch to AP mode, press and hold the button for 3 s — the LED blinks slowly alternating white/red.';

  @override
  String get apModeBulbTitle => 'Bulb (WRB)';

  @override
  String get apModeBulbResetStep1 =>
      'Factory reset: cycle power off/on 5 times with ~5 s pauses. After the 5th \"on\" the bulb blinks white 10×.';

  @override
  String get apModeBulbResetStep2 =>
      'WPS mode runs for 3 min (white blink), then AP mode starts automatically and runs for 5 min.';

  @override
  String get apModeLedSignalsTitle => 'LED signals (all devices)';

  @override
  String get apModeLedFastRed =>
      'Fast red blink — the device is connecting to WiFi.';

  @override
  String get apModeLedSlowRed =>
      'Slow red blink — connected, obtaining an IP address.';

  @override
  String get apModeLedWhite =>
      'White blink — the device is connecting to the cloud.';

  @override
  String get apModeLedGreenSuccess => '3× green — connected successfully.';

  @override
  String get apModeLedRedFailure => '3× red — connection failed.';

  @override
  String get softApSelectApIntro =>
      'Put your device into AP mode (see instructions below). Then pick it from the list, or connect to its WiFi manually and tap \"I\'m already connected\".';

  @override
  String get scanForMyStromDevices => 'Scan for myStrom devices';

  @override
  String get noMyStromApsFound =>
      'No myStrom APs found.\n\n• Make sure the device is in AP mode.\n• Grant Location permission (Settings → Apps → mystrom_local → Permissions).\n• Turn on Location (GPS) in system settings — Android requires it for WiFi scans.\n• If you are already connected to the device AP, tap \"I\'m already connected\" below.';

  @override
  String apCandidateSubtitle(String displayName, String signal) {
    return '$displayName • $signal dBm';
  }

  @override
  String get alreadyConnectedToAp => 'I\'m already connected';

  @override
  String get connectedManual => 'Connected (manual)';

  @override
  String deviceInfoMacLine(String type, String mac) {
    return '$type • MAC $mac';
  }

  @override
  String get scanNetworksIntro =>
      'Scan for the WiFi networks the device can see. This takes up to 5 s.';

  @override
  String get deviceApIp => 'Device AP IP';

  @override
  String get scanWifiNetworks => 'Scan WiFi networks';

  @override
  String get noNetworksFound =>
      'No networks found. Run the scan again or enter the SSID manually in the next step.';

  @override
  String signalDbm(String signal) {
    return '$signal dBm';
  }

  @override
  String get enterSsidManually => 'Enter SSID manually (hidden network)';

  @override
  String get pickNetworkOrSsid => 'Pick a network or type the SSID:';

  @override
  String get wifiSsid => 'WiFi SSID';

  @override
  String get wifiSsidHint => 'HomeWiFi (or hidden network)';

  @override
  String get wifiPassword => 'WiFi Password';

  @override
  String get deviceNameOptional => 'Device name (optional)';

  @override
  String get staticIpOptional => 'Static IP (optional)';

  @override
  String get subnetMaskOptional => 'Subnet mask (optional)';

  @override
  String get gatewayOptional => 'Gateway (optional)';

  @override
  String get dnsOptional => 'DNS (optional)';

  @override
  String get roaming80211r => 'Roaming (802.11r)';

  @override
  String get sendCredentials => 'Send credentials';

  @override
  String get sendingCredentials => 'Sending credentials…';

  @override
  String get credentialsSentSuccess => 'Credentials sent successfully.';

  @override
  String get deviceRebootingMessage =>
      'The device is rebooting and joining your WiFi. It should appear in the \"Found\" tab within a minute.';

  @override
  String macLabel(String mac) {
    return 'MAC: $mac';
  }

  @override
  String typeLabel(String displayName) {
    return 'Type: $displayName';
  }

  @override
  String get addToDeviceListNow => 'Add to device list now';

  @override
  String get deviceAddedWillComeOnline =>
      'Device added. It will come online shortly.';

  @override
  String get provisionAnotherDevice => 'Provision another device';

  @override
  String get provisioningFailed => 'Provisioning failed';

  @override
  String get startOver => 'Start over';

  @override
  String get wpsIntro =>
      'WPS lets the device join your WiFi by pairing with your router. The procedure to enter WPS mode differs by device type:';

  @override
  String get wpsSwitchStep1 =>
      'Press and hold the \"+\" button for 3 s — the LED starts blinking white slowly.';

  @override
  String get wpsSwitchStep2 =>
      'Within 2 min, press the WPS button on your router.';

  @override
  String get wpsSwitchStep3 =>
      'The device connects automatically; on success the LED blinks 3× green, on failure 3× red.';

  @override
  String get wpsResultHint =>
      '3× green blink = success, 3× red blink = failure.';

  @override
  String get wpsButtonWpsModeAuto =>
      'After the reset the device starts in WPS mode automatically (white blink, 2 min).';

  @override
  String get wpsButtonPressRouter =>
      'Press the WPS button on your router within that window.';

  @override
  String get wpsBulbReset =>
      'Factory reset: cycle power off/on 5× with ~5 s pauses. After the 5th \"on\" the bulb blinks white 10×.';

  @override
  String get wpsBulbMode =>
      'WPS mode runs for 3 min (white blink). Press WPS on your router during this window.';

  @override
  String get triggerWpsOnDevice => 'Trigger WPS on device';

  @override
  String get wpsTriggerSnackbar =>
      'Make sure the device is in WPS mode, then press WPS on your router.';

  @override
  String get nameHintExample => 'e.g. Living room floor lamp';

  @override
  String get deviceNameSection => 'Device name';

  @override
  String get customName => 'Custom name';

  @override
  String get favoriteSubtitle =>
      'Show this device under the \"Favorite\" category on the dashboard.';

  @override
  String get lockOnOff => 'Lock on/off';

  @override
  String get lockOnOffSubtitle =>
      'Disable the on/off toggle (e.g. for a fridge). Timers and scheduler are still allowed.';

  @override
  String get temperatureOffset => 'Temperature offset';

  @override
  String temperatureOffsetValue(String sign, String value) {
    return '$sign$value °C';
  }

  @override
  String get tileColor => 'Tile color';

  @override
  String get tileColorSubtitle =>
      'Helps tell this device apart from others on the dashboard.';

  @override
  String get stripChannelMode => 'Strip channel mode';

  @override
  String get stripChannelModeSubtitle =>
      'Configure colors / channels / cold-warm white';

  @override
  String get buttonAction => 'Button action';

  @override
  String get buttonActionSubtitle =>
      'Choose which device/action the switch triggers when its physical button is pressed.';

  @override
  String get pirActions => 'Motion sensor actions';

  @override
  String get pirActionsSubtitle =>
      'Choose which device/action the motion sensor triggers for each condition (motion detected at different light levels).';

  @override
  String get identifySubtitle =>
      'Blink the device so you can tell which one it is.';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get noInfoAvailable => 'No info available';

  @override
  String typeSubtitle(String model, String displayName) {
    return '$model — $displayName';
  }

  @override
  String get removeDevice => 'Remove device';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Are you sure you want to quit without saving?';

  @override
  String get quitWithoutSaving => 'Quit without saving';

  @override
  String get ipMask => 'IP / Mask';

  @override
  String ipMaskValue(String ip, String mask) {
    return '$ip / $mask';
  }

  @override
  String get gatewayDns => 'Gateway / DNS';

  @override
  String gatewayDnsValue(String gw, String dns) {
    return '$gw / $dns';
  }

  @override
  String buttonActionSaved(String url) {
    return 'Button action saved: $url';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get whenRelayTurnsOn => 'When the relay turns ON';

  @override
  String get whenRelayTurnsOff => 'When the relay turns OFF';

  @override
  String slotActionSaved(String slot, String url) {
    return '\"$slot\" action saved: $url';
  }

  @override
  String get pirActionGeneric => 'Generic (any motion)';

  @override
  String get pirActionNight => 'Night (dark)';

  @override
  String get pirActionTwilight => 'Twilight (dawn/dusk)';

  @override
  String get pirActionDay => 'Day (bright)';

  @override
  String get pirActionRise => 'Motion begins';

  @override
  String get pirActionFall => 'Motion ends';

  @override
  String get lightThresholds => 'Light thresholds';

  @override
  String get lightThresholdsSubtitle =>
      'Night and day light boundaries the motion sensor uses to classify motion events. Values share the same scale as the light sensor. Night must be below day.';

  @override
  String get nightThresholdBelowDay =>
      'The night threshold must be below the day threshold';

  @override
  String get thresholdsSaved => 'Thresholds saved';

  @override
  String nightValue(String value) {
    return 'Night: $value';
  }

  @override
  String dayValue(String value) {
    return 'Day: $value';
  }

  @override
  String get saveThresholds => 'Save thresholds';

  @override
  String get pirSettings => 'Motion sensor settings';

  @override
  String get pirSettingsSubtitle =>
      'Backoff time is the cooldown in seconds after a motion event (1–3600). \"LED enable\" controls the status indicator on the device.';

  @override
  String get pirSettingsSaved => 'Motion sensor settings saved';

  @override
  String backoffTimeValue(String seconds) {
    return 'Backoff time: $seconds s';
  }

  @override
  String get ledEnable => 'LED enable';

  @override
  String get ledEnableSubtitle =>
      'Show the status LED when motion is detected.';

  @override
  String get savePirSettings => 'Save settings';

  @override
  String get newScene => 'New scene';

  @override
  String get editScene => 'Edit scene';

  @override
  String get sceneName => 'Scene name';

  @override
  String get icon => 'Icon';

  @override
  String get actions => 'Actions';

  @override
  String get noActionsYet =>
      'No actions yet. Add a device action to run with this scene.';

  @override
  String get addDeviceAction => 'Add device action';

  @override
  String get addTimerAction => 'Add timer action';

  @override
  String get noDevicesAddedYet => 'No devices added yet';

  @override
  String get sceneDefaultName => 'Scene';

  @override
  String get sensorNoAction => 'Sensor (no action)';

  @override
  String get selectDevice => 'Select a device';

  @override
  String get timerMode => 'Timer mode';

  @override
  String durationHms(String hh, String mm, String ss) {
    return 'Duration: $hh:$mm:$ss';
  }

  @override
  String get actionOn => 'on';

  @override
  String get actionOff => 'off';

  @override
  String get actionToggle => 'toggle';

  @override
  String get actionTimer => 'timer';

  @override
  String get actionColor => 'color';

  @override
  String get sceneIconArriveHome => 'Coming Home';

  @override
  String get sceneIconGoodNight => 'Good Night';

  @override
  String get sceneIconMorning => 'Good Morning';

  @override
  String get sceneIconMovie => 'Movie';

  @override
  String get sceneIconDinner => 'Dinner';

  @override
  String get sceneIconAway => 'Away';

  @override
  String get sceneIconSleep => 'Sleep';

  @override
  String get sceneIconWeekend => 'Weekend';

  @override
  String get sceneIconLights => 'Lights';

  @override
  String get sceneIconPower => 'Power';

  @override
  String schedulerTitle(String displayName) {
    return '$displayName — Scheduler';
  }

  @override
  String get saveAll => 'Save all';

  @override
  String get noSchedulesYet => 'No schedules yet';

  @override
  String get addNewSchedule => 'Add new schedule';

  @override
  String get addSchedule => 'Add schedule';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get setColorOnly => 'set (color only)';

  @override
  String get colorHsv => 'Color (HSV)';

  @override
  String get rampMs => 'Ramp (ms)';

  @override
  String get valuePercent => 'Value (%)';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get days => 'Days';

  @override
  String get scheduleSaved => 'Schedule saved';

  @override
  String get schedulerNotSupported => 'Scheduler not supported on this device';

  @override
  String get schedulerDeviceList =>
      'Scheduler is only available on WS2, WSE, WRS, WMS, WSX and WLL.';

  @override
  String get firmwareVersionUnreadable =>
      'Could not read the firmware version. Requires firmware 5.0.0 or newer.';

  @override
  String firmwareVersionRequired(String fw) {
    return 'Requires firmware 5.0.0 or newer (current: $fw).';
  }

  @override
  String get energyHistory => 'Energy History';

  @override
  String get historyNotSupported => 'History not supported.';

  @override
  String get failedToLoadHistory => 'Failed to load history';

  @override
  String get historyDeviceList =>
      'Report history is only available on WS2, WSE and WSX.';

  @override
  String get noHistoryDataYet =>
      'No history data available yet.\nReports are stored hourly once the device runs firmware 5.0.0 or newer.';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get latest => 'Latest';

  @override
  String get noDataForSelectedDay => 'No data for the selected day';

  @override
  String noDataForDate(String date) {
    return 'No data for $date';
  }

  @override
  String get avgPower => 'Avg Power';

  @override
  String get peakPower => 'Peak Power';

  @override
  String get intervals => 'Intervals';

  @override
  String get energyPerIntervalLegend => 'Energy per interval (kWh)';

  @override
  String get discovery => 'Device discovery';

  @override
  String get discoveryPlaceholder =>
      'Device discovery runs continuously in the background. Devices show up in the device list as soon as they answer.';

  @override
  String get wifiSetup => 'WiFi Setup';

  @override
  String get wifiSetupPlaceholder =>
      'To move a device to a different WiFi network, use \"Add device\" → \"SoftAP\".';

  @override
  String get stripSettings => 'Strip Settings';

  @override
  String get channelMode => 'Channel Mode';

  @override
  String get chModeColorsDesc =>
      'WRGB strip — full color control (HSV or WRGB)';

  @override
  String get chModeChannelsDesc =>
      '4 independent dimmable channels (e.g. 4 white strips)';

  @override
  String get chModeColdWarmDesc =>
      '2 warm-white + 2 cold-white channels (W+R = warm, G+B = cold)';

  @override
  String get chModeChangeNote =>
      'Changing the channel mode affects how the strip is controlled. The control page will adapt automatically.';

  @override
  String channelModeSet(String mode) {
    return 'Channel mode set to $mode';
  }

  @override
  String get ramp => 'Ramp';

  @override
  String rampSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get tabColor => 'Color';

  @override
  String get tabWhites => 'Whites';

  @override
  String get tabWrgb => 'WRGB';

  @override
  String get whitesColdWarm => 'Whites (Cold / Warm)';

  @override
  String get whites => 'Whites';

  @override
  String get whitesInternalConversion =>
      'The device internally converts the color temperature to WRGB values.';

  @override
  String deviceMode(String mode) {
    return 'Device mode: $mode';
  }

  @override
  String stripMode(String mode) {
    return 'Mode: $mode';
  }

  @override
  String whiteIndex(String index) {
    return 'White: $index';
  }

  @override
  String brightnessPercent(String value) {
    return 'Brightness: $value%';
  }

  @override
  String get colorWhite => 'White';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get channels => 'Channels';

  @override
  String channelN(int n) {
    return 'Channel $n';
  }

  @override
  String get warm => 'Warm';

  @override
  String get cold => 'Cold';

  @override
  String get coldWarm => 'Cold / Warm';

  @override
  String labelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get motion => 'Motion';

  @override
  String get light => 'Light';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get battery => 'Battery';

  @override
  String get unitLux => 'lux';

  @override
  String get actionUrls => 'Action URLs';

  @override
  String get actionUrlsSubtitle =>
      'Tap a scheme to configure which device/action is triggered.';

  @override
  String get singlePress => 'Press once';

  @override
  String get doublePress => 'Press twice';

  @override
  String get longPress => 'Press and hold';

  @override
  String get touch => 'Touch';

  @override
  String get generic => 'Generic';

  @override
  String buttonN(int n) {
    return 'Button $n';
  }

  @override
  String get overThreshold => 'Above threshold';

  @override
  String get underThreshold => 'Below threshold';

  @override
  String schemeUrlSaved(String scheme, String url) {
    return '$scheme → $url';
  }

  @override
  String refererActionUrlSaved(String referer, String action, String url) {
    return '$referer/$action → $url';
  }

  @override
  String get assignAction => 'Assign action';

  @override
  String get targetDevice => 'Target device';

  @override
  String deviceWithModel(String displayName, String model) {
    return '$displayName ($model)';
  }

  @override
  String get colorHsvShort => 'Color (H;S;V)';

  @override
  String get assign => 'Assign';

  @override
  String macColon(String mac) {
    return 'MAC: $mac';
  }

  @override
  String ipColon(String ip) {
    return 'IP: $ip';
  }

  @override
  String get noIpForDevice => 'No IP address for this device.';

  @override
  String get deviceOffline =>
      'Device is offline. Make sure it is powered on and connected.';

  @override
  String couldNotReachDevice(String error) {
    return 'Could not reach device: $error';
  }

  @override
  String get statusMotion => 'Motion';

  @override
  String get statusIdle => 'No motion';

  @override
  String get statusButton => 'Button';

  @override
  String statusOnPercent(String value) {
    return 'On $value%';
  }

  @override
  String deviceCardSubtitle(String ip, String status) {
    return '$ip • $status';
  }

  @override
  String get timerNone => 'No timer';

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'min';

  @override
  String get secondShort => 's';

  @override
  String secondsShort(String seconds) {
    return '$seconds s';
  }

  @override
  String hueValue(String value) {
    return 'Hue: $value°';
  }

  @override
  String saturationValue(String value) {
    return 'Saturation: $value%';
  }

  @override
  String get featureTimer => 'Timer';

  @override
  String get featureScheduler => 'Scheduler';

  @override
  String get featureHistory => 'History';

  @override
  String get noPowerData => 'No power data';

  @override
  String couldNotScanWifi(String error) {
    return 'Could not scan WiFi: $error';
  }

  @override
  String get totalEnergyTitleCase => 'Total Energy';
}
