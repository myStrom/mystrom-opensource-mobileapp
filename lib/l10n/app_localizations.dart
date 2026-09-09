import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('de', 'CH'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'myStrom Local'**
  String get appTitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'…'**
  String get loadingEllipsis;

  /// No description provided for @noDataDash.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get noDataDash;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @noIpAddress.
  ///
  /// In en, this message translates to:
  /// **'No IP address'**
  String get noIpAddress;

  /// No description provided for @noIp.
  ///
  /// In en, this message translates to:
  /// **'no IP'**
  String get noIp;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offline;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @schedulerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get schedulerTooltip;

  /// No description provided for @identify.
  ///
  /// In en, this message translates to:
  /// **'Identify'**
  String get identify;

  /// No description provided for @identifySignalSent.
  ///
  /// In en, this message translates to:
  /// **'Identification signal sent — look for a blink.'**
  String get identifySignalSent;

  /// No description provided for @timerSet.
  ///
  /// In en, this message translates to:
  /// **'Timer set'**
  String get timerSet;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @toggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle'**
  String get toggle;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @totalPower.
  ///
  /// In en, this message translates to:
  /// **'Total power'**
  String get totalPower;

  /// No description provided for @totalEnergy.
  ///
  /// In en, this message translates to:
  /// **'Total energy'**
  String get totalEnergy;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @firmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get firmware;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @roaming.
  ///
  /// In en, this message translates to:
  /// **'Roaming'**
  String get roaming;

  /// No description provided for @handshake.
  ///
  /// In en, this message translates to:
  /// **'Handshake'**
  String get handshake;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @mac.
  ///
  /// In en, this message translates to:
  /// **'MAC'**
  String get mac;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ip;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @ntp.
  ///
  /// In en, this message translates to:
  /// **'NTP'**
  String get ntp;

  /// No description provided for @dns.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get dns;

  /// No description provided for @deviceTypeWifiSwitchCh.
  ///
  /// In en, this message translates to:
  /// **'WiFi Switch CH'**
  String get deviceTypeWifiSwitchCh;

  /// No description provided for @deviceTypeWifiSwitchEu.
  ///
  /// In en, this message translates to:
  /// **'WiFi Switch EU'**
  String get deviceTypeWifiSwitchEu;

  /// No description provided for @deviceTypeWifiSwitchX.
  ///
  /// In en, this message translates to:
  /// **'WiFi Switch X'**
  String get deviceTypeWifiSwitchX;

  /// No description provided for @deviceTypeWifiStrip.
  ///
  /// In en, this message translates to:
  /// **'WiFi Strip'**
  String get deviceTypeWifiStrip;

  /// No description provided for @deviceTypeWifiCube.
  ///
  /// In en, this message translates to:
  /// **'WiFi Cube'**
  String get deviceTypeWifiCube;

  /// No description provided for @deviceTypeWifiPir.
  ///
  /// In en, this message translates to:
  /// **'WiFi Motion Sensor'**
  String get deviceTypeWifiPir;

  /// No description provided for @deviceTypeWifiButtonPlus2.
  ///
  /// In en, this message translates to:
  /// **'WiFi Button Plus 2'**
  String get deviceTypeWifiButtonPlus2;

  /// No description provided for @deviceTypeWifiButtonPlus1.
  ///
  /// In en, this message translates to:
  /// **'WiFi Button Plus 1'**
  String get deviceTypeWifiButtonPlus1;

  /// No description provided for @deviceTypeWifiButtonMax.
  ///
  /// In en, this message translates to:
  /// **'WiFi Button Max'**
  String get deviceTypeWifiButtonMax;

  /// No description provided for @deviceTypeWifiBulb.
  ///
  /// In en, this message translates to:
  /// **'WiFi Bulb'**
  String get deviceTypeWifiBulb;

  /// No description provided for @deviceTypeWifiSwitchLcs.
  ///
  /// In en, this message translates to:
  /// **'WiFi Switch LCS'**
  String get deviceTypeWifiSwitchLcs;

  /// No description provided for @deviceTypeWifiButton.
  ///
  /// In en, this message translates to:
  /// **'WiFi Button'**
  String get deviceTypeWifiButton;

  /// No description provided for @deviceTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get deviceTypeUnknown;

  /// No description provided for @discoveryCountFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 found} other{{count} found}}'**
  String discoveryCountFound(int count);

  /// No description provided for @discoveryListening.
  ///
  /// In en, this message translates to:
  /// **'searching…'**
  String get discoveryListening;

  /// No description provided for @sectionScenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get sectionScenes;

  /// No description provided for @sectionMyDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get sectionMyDevices;

  /// No description provided for @sectionNewlyDiscovered.
  ///
  /// In en, this message translates to:
  /// **'Newly found'**
  String get sectionNewlyDiscovered;

  /// No description provided for @noDevicesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No devices in this category'**
  String get noDevicesInCategory;

  /// No description provided for @noToggleableDevicesInRoom.
  ///
  /// In en, this message translates to:
  /// **'No switchable devices in \"{room}\"'**
  String noToggleableDevicesInRoom(String room);

  /// No description provided for @turnAllInRoomOn.
  ///
  /// In en, this message translates to:
  /// **'Turn all in \"{room}\" on'**
  String turnAllInRoomOn(String room);

  /// No description provided for @turnAllInRoomOff.
  ///
  /// In en, this message translates to:
  /// **'Turn all in \"{room}\" off'**
  String turnAllInRoomOff(String room);

  /// Result of a bulk on command; ok is the number that answered, total the number attempted
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{ok}/{total} device switched on} other{{ok}/{total} devices switched on}}'**
  String bulkToggleResultOn(int ok, int total);

  /// Result of a bulk off command; ok is the number that answered, total the number attempted
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{ok}/{total} device switched off} other{{ok}/{total} devices switched off}}'**
  String bulkToggleResultOff(int ok, int total);

  /// No description provided for @sceneExecuted.
  ///
  /// In en, this message translates to:
  /// **'Scene \"{name}\" executed'**
  String sceneExecuted(String name);

  /// No description provided for @sceneExecuteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {list}'**
  String sceneExecuteFailed(String list);

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get categoryFavorite;

  /// No description provided for @roomChipLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold to turn all in \"{room}\" on/off'**
  String roomChipLongPressHint(String room);

  /// No description provided for @emptyStateListening.
  ///
  /// In en, this message translates to:
  /// **'Searching for devices…\nNo devices found yet.\nMake sure the myStrom devices are on the same WiFi.'**
  String get emptyStateListening;

  /// No description provided for @emptyStateStartingDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Starting UDP discovery…\nIf your system asked for local network access,\nmake sure you allowed it.'**
  String get emptyStateStartingDiscovery;

  /// No description provided for @addDeviceManually.
  ///
  /// In en, this message translates to:
  /// **'Add device manually'**
  String get addDeviceManually;

  /// No description provided for @powerWatts.
  ///
  /// In en, this message translates to:
  /// **'{value} W'**
  String powerWatts(String value);

  /// No description provided for @energyKwh.
  ///
  /// In en, this message translates to:
  /// **'{value} kWh'**
  String energyKwh(String value);

  /// No description provided for @temperatureCelsius.
  ///
  /// In en, this message translates to:
  /// **'{value} °C'**
  String temperatureCelsius(String value);

  /// A bare percentage reading; German locales add a space before the sign
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(String value);

  /// No description provided for @sinceBoot.
  ///
  /// In en, this message translates to:
  /// **'Since boot'**
  String get sinceBoot;

  /// No description provided for @deviceLockedToggleDisabled.
  ///
  /// In en, this message translates to:
  /// **'This device is locked — on/off toggle is disabled.'**
  String get deviceLockedToggleDisabled;

  /// No description provided for @addDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDeviceTitle;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDevice;

  /// No description provided for @tabDiscovered.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get tabDiscovered;

  /// No description provided for @tabSoftAp.
  ///
  /// In en, this message translates to:
  /// **'SoftAP'**
  String get tabSoftAp;

  /// No description provided for @tabWps.
  ///
  /// In en, this message translates to:
  /// **'WPS'**
  String get tabWps;

  /// No description provided for @noNewDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No new devices found on the local network.\n\nMake sure your myStrom devices are powered on and connected to the same WiFi. Discovery runs automatically in the background.'**
  String get noNewDevicesFound;

  /// No description provided for @deviceAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'{displayName} added'**
  String deviceAddedSnack(String displayName);

  /// No description provided for @credentialsSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Credentials sent. The device will reboot and join your WiFi.'**
  String get credentialsSentSnackbar;

  /// No description provided for @howToEnterApMode.
  ///
  /// In en, this message translates to:
  /// **'How to enter AP mode'**
  String get howToEnterApMode;

  /// No description provided for @apModeInstructionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Differs by device type — tap to expand'**
  String get apModeInstructionsSubtitle;

  /// No description provided for @apModeSwitchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Switches (WS2, WSE, WSX, LCS), Strip (WRS), Cube (WLL), Motion Sensor (WMS)'**
  String get apModeSwitchesTitle;

  /// No description provided for @apModeSwitchResetStep1.
  ///
  /// In en, this message translates to:
  /// **'Factory reset: press and hold the \"+\" button for 10–20 s until the LED blinks white.'**
  String get apModeSwitchResetStep1;

  /// No description provided for @apModeSwitchResetStep2.
  ///
  /// In en, this message translates to:
  /// **'After the reset the LED blinks red briefly, then the device enters AP mode.'**
  String get apModeSwitchResetStep2;

  /// No description provided for @apModeButtonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buttons (BP2, BM1, WBS/WBP)'**
  String get apModeButtonsTitle;

  /// No description provided for @apModeButtonResetStep1.
  ///
  /// In en, this message translates to:
  /// **'Factory reset: press and hold any button for 10–20 s until the LED blinks alternating white/red, then release and press once more within 2 s to confirm (LED blinks white).'**
  String get apModeButtonResetStep1;

  /// No description provided for @apModeButtonResetStep2.
  ///
  /// In en, this message translates to:
  /// **'After the reset the device starts in WPS mode (white blink, 2 min). To switch to AP mode, press and hold the button for 3 s — the LED blinks slowly alternating white/red.'**
  String get apModeButtonResetStep2;

  /// No description provided for @apModeBulbTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulb (WRB)'**
  String get apModeBulbTitle;

  /// No description provided for @apModeBulbResetStep1.
  ///
  /// In en, this message translates to:
  /// **'Factory reset: cycle power off/on 5 times with ~5 s pauses. After the 5th \"on\" the bulb blinks white 10×.'**
  String get apModeBulbResetStep1;

  /// No description provided for @apModeBulbResetStep2.
  ///
  /// In en, this message translates to:
  /// **'WPS mode runs for 3 min (white blink), then AP mode starts automatically and runs for 5 min.'**
  String get apModeBulbResetStep2;

  /// No description provided for @apModeLedSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'LED signals (all devices)'**
  String get apModeLedSignalsTitle;

  /// No description provided for @apModeLedFastRed.
  ///
  /// In en, this message translates to:
  /// **'Fast red blink — the device is connecting to WiFi.'**
  String get apModeLedFastRed;

  /// No description provided for @apModeLedSlowRed.
  ///
  /// In en, this message translates to:
  /// **'Slow red blink — connected, obtaining an IP address.'**
  String get apModeLedSlowRed;

  /// No description provided for @apModeLedWhite.
  ///
  /// In en, this message translates to:
  /// **'White blink — the device is connecting to the cloud.'**
  String get apModeLedWhite;

  /// No description provided for @apModeLedGreenSuccess.
  ///
  /// In en, this message translates to:
  /// **'3× green — connected successfully.'**
  String get apModeLedGreenSuccess;

  /// No description provided for @apModeLedRedFailure.
  ///
  /// In en, this message translates to:
  /// **'3× red — connection failed.'**
  String get apModeLedRedFailure;

  /// No description provided for @softApSelectApIntro.
  ///
  /// In en, this message translates to:
  /// **'Put your device into AP mode (see instructions below). Then pick it from the list, or connect to its WiFi manually and tap \"I\'m already connected\".'**
  String get softApSelectApIntro;

  /// No description provided for @softApSelectApIntroManual.
  ///
  /// In en, this message translates to:
  /// **'Put your device into AP mode (see instructions below). Connect to its WiFi in your device settings, then return here and tap \"I\'m already connected\".'**
  String get softApSelectApIntroManual;

  /// No description provided for @scanForMyStromDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan for myStrom devices'**
  String get scanForMyStromDevices;

  /// No description provided for @noMyStromApsFound.
  ///
  /// In en, this message translates to:
  /// **'No myStrom APs found.\n\n• Make sure the device is in AP mode.\n• Grant Location permission (Settings → Apps → mystrom_local → Permissions).\n• Turn on Location (GPS) in system settings — Android requires it for WiFi scans.\n• If you are already connected to the device AP, tap \"I\'m already connected\" below.'**
  String get noMyStromApsFound;

  /// No description provided for @apCandidateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{displayName} • {signal} dBm'**
  String apCandidateSubtitle(String displayName, String signal);

  /// No description provided for @alreadyConnectedToAp.
  ///
  /// In en, this message translates to:
  /// **'I\'m already connected'**
  String get alreadyConnectedToAp;

  /// No description provided for @connectedManual.
  ///
  /// In en, this message translates to:
  /// **'Connected (manual)'**
  String get connectedManual;

  /// No description provided for @deviceInfoMacLine.
  ///
  /// In en, this message translates to:
  /// **'{type} • MAC {mac}'**
  String deviceInfoMacLine(String type, String mac);

  /// No description provided for @scanNetworksIntro.
  ///
  /// In en, this message translates to:
  /// **'Scan for the WiFi networks the device can see. This takes up to 5 s.'**
  String get scanNetworksIntro;

  /// No description provided for @deviceApIp.
  ///
  /// In en, this message translates to:
  /// **'Device AP IP'**
  String get deviceApIp;

  /// No description provided for @scanWifiNetworks.
  ///
  /// In en, this message translates to:
  /// **'Scan WiFi networks'**
  String get scanWifiNetworks;

  /// No description provided for @noNetworksFound.
  ///
  /// In en, this message translates to:
  /// **'No networks found. Run the scan again or enter the SSID manually in the next step.'**
  String get noNetworksFound;

  /// No description provided for @signalDbm.
  ///
  /// In en, this message translates to:
  /// **'{signal} dBm'**
  String signalDbm(String signal);

  /// No description provided for @enterSsidManually.
  ///
  /// In en, this message translates to:
  /// **'Enter SSID manually (hidden network)'**
  String get enterSsidManually;

  /// No description provided for @pickNetworkOrSsid.
  ///
  /// In en, this message translates to:
  /// **'Pick a network or type the SSID:'**
  String get pickNetworkOrSsid;

  /// No description provided for @wifiSsid.
  ///
  /// In en, this message translates to:
  /// **'WiFi SSID'**
  String get wifiSsid;

  /// No description provided for @wifiSsidHint.
  ///
  /// In en, this message translates to:
  /// **'HomeWiFi (or hidden network)'**
  String get wifiSsidHint;

  /// No description provided for @wifiPassword.
  ///
  /// In en, this message translates to:
  /// **'WiFi Password'**
  String get wifiPassword;

  /// No description provided for @deviceNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Device name (optional)'**
  String get deviceNameOptional;

  /// No description provided for @staticIpOptional.
  ///
  /// In en, this message translates to:
  /// **'Static IP (optional)'**
  String get staticIpOptional;

  /// No description provided for @subnetMaskOptional.
  ///
  /// In en, this message translates to:
  /// **'Subnet mask (optional)'**
  String get subnetMaskOptional;

  /// No description provided for @gatewayOptional.
  ///
  /// In en, this message translates to:
  /// **'Gateway (optional)'**
  String get gatewayOptional;

  /// No description provided for @dnsOptional.
  ///
  /// In en, this message translates to:
  /// **'DNS (optional)'**
  String get dnsOptional;

  /// No description provided for @roaming80211r.
  ///
  /// In en, this message translates to:
  /// **'Roaming (802.11r)'**
  String get roaming80211r;

  /// No description provided for @sendCredentials.
  ///
  /// In en, this message translates to:
  /// **'Send credentials'**
  String get sendCredentials;

  /// No description provided for @sendingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Sending credentials…'**
  String get sendingCredentials;

  /// No description provided for @credentialsSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Credentials sent successfully.'**
  String get credentialsSentSuccess;

  /// No description provided for @deviceRebootingMessage.
  ///
  /// In en, this message translates to:
  /// **'The device is rebooting and joining your WiFi. It should appear in the \"Found\" tab within a minute.'**
  String get deviceRebootingMessage;

  /// No description provided for @macLabel.
  ///
  /// In en, this message translates to:
  /// **'MAC: {mac}'**
  String macLabel(String mac);

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type: {displayName}'**
  String typeLabel(String displayName);

  /// No description provided for @addToDeviceListNow.
  ///
  /// In en, this message translates to:
  /// **'Add to device list now'**
  String get addToDeviceListNow;

  /// No description provided for @deviceAddedWillComeOnline.
  ///
  /// In en, this message translates to:
  /// **'Device added. It will come online shortly.'**
  String get deviceAddedWillComeOnline;

  /// No description provided for @provisionAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'Provision another device'**
  String get provisionAnotherDevice;

  /// No description provided for @provisioningFailed.
  ///
  /// In en, this message translates to:
  /// **'Provisioning failed'**
  String get provisioningFailed;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @wpsIntro.
  ///
  /// In en, this message translates to:
  /// **'WPS lets the device join your WiFi by pairing with your router. The procedure to enter WPS mode differs by device type:'**
  String get wpsIntro;

  /// No description provided for @wpsSwitchStep1.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the \"+\" button for 3 s — the LED starts blinking white slowly.'**
  String get wpsSwitchStep1;

  /// No description provided for @wpsSwitchStep2.
  ///
  /// In en, this message translates to:
  /// **'Within 2 min, press the WPS button on your router.'**
  String get wpsSwitchStep2;

  /// No description provided for @wpsSwitchStep3.
  ///
  /// In en, this message translates to:
  /// **'The device connects automatically; on success the LED blinks 3× green, on failure 3× red.'**
  String get wpsSwitchStep3;

  /// No description provided for @wpsResultHint.
  ///
  /// In en, this message translates to:
  /// **'3× green blink = success, 3× red blink = failure.'**
  String get wpsResultHint;

  /// No description provided for @wpsButtonWpsModeAuto.
  ///
  /// In en, this message translates to:
  /// **'After the reset the device starts in WPS mode automatically (white blink, 2 min).'**
  String get wpsButtonWpsModeAuto;

  /// No description provided for @wpsButtonPressRouter.
  ///
  /// In en, this message translates to:
  /// **'Press the WPS button on your router within that window.'**
  String get wpsButtonPressRouter;

  /// No description provided for @wpsBulbReset.
  ///
  /// In en, this message translates to:
  /// **'Factory reset: cycle power off/on 5× with ~5 s pauses. After the 5th \"on\" the bulb blinks white 10×.'**
  String get wpsBulbReset;

  /// No description provided for @wpsBulbMode.
  ///
  /// In en, this message translates to:
  /// **'WPS mode runs for 3 min (white blink). Press WPS on your router during this window.'**
  String get wpsBulbMode;

  /// No description provided for @triggerWpsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Trigger WPS on device'**
  String get triggerWpsOnDevice;

  /// No description provided for @wpsTriggerSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Make sure the device is in WPS mode, then press WPS on your router.'**
  String get wpsTriggerSnackbar;

  /// No description provided for @nameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living room floor lamp'**
  String get nameHintExample;

  /// No description provided for @deviceNameSection.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceNameSection;

  /// No description provided for @customName.
  ///
  /// In en, this message translates to:
  /// **'Custom name'**
  String get customName;

  /// No description provided for @favoriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show this device under the \"Favorite\" category on the dashboard.'**
  String get favoriteSubtitle;

  /// No description provided for @lockOnOff.
  ///
  /// In en, this message translates to:
  /// **'Lock on/off'**
  String get lockOnOff;

  /// No description provided for @lockOnOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable the on/off toggle (e.g. for a fridge). Timers and scheduler are still allowed.'**
  String get lockOnOffSubtitle;

  /// No description provided for @temperatureOffset.
  ///
  /// In en, this message translates to:
  /// **'Temperature offset'**
  String get temperatureOffset;

  /// No description provided for @temperatureOffsetValue.
  ///
  /// In en, this message translates to:
  /// **'{sign}{value} °C'**
  String temperatureOffsetValue(String sign, String value);

  /// No description provided for @tileColor.
  ///
  /// In en, this message translates to:
  /// **'Tile color'**
  String get tileColor;

  /// No description provided for @tileColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps tell this device apart from others on the dashboard.'**
  String get tileColorSubtitle;

  /// No description provided for @stripChannelMode.
  ///
  /// In en, this message translates to:
  /// **'Strip channel mode'**
  String get stripChannelMode;

  /// No description provided for @stripChannelModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure colors / channels / cold-warm white'**
  String get stripChannelModeSubtitle;

  /// No description provided for @buttonAction.
  ///
  /// In en, this message translates to:
  /// **'Button action'**
  String get buttonAction;

  /// No description provided for @buttonActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which device/action the switch triggers when its physical button is pressed.'**
  String get buttonActionSubtitle;

  /// No description provided for @pirActions.
  ///
  /// In en, this message translates to:
  /// **'Motion sensor actions'**
  String get pirActions;

  /// No description provided for @pirActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which device/action the motion sensor triggers for each condition (motion detected at different light levels).'**
  String get pirActionsSubtitle;

  /// No description provided for @identifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blink the device so you can tell which one it is.'**
  String get identifySubtitle;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfo;

  /// No description provided for @noInfoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No info available'**
  String get noInfoAvailable;

  /// No description provided for @typeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{model} — {displayName}'**
  String typeSubtitle(String model, String displayName);

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDevice;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to quit without saving?'**
  String get discardChangesMessage;

  /// No description provided for @quitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Quit without saving'**
  String get quitWithoutSaving;

  /// No description provided for @ipMask.
  ///
  /// In en, this message translates to:
  /// **'IP / Mask'**
  String get ipMask;

  /// No description provided for @ipMaskValue.
  ///
  /// In en, this message translates to:
  /// **'{ip} / {mask}'**
  String ipMaskValue(String ip, String mask);

  /// No description provided for @gatewayDns.
  ///
  /// In en, this message translates to:
  /// **'Gateway / DNS'**
  String get gatewayDns;

  /// No description provided for @gatewayDnsValue.
  ///
  /// In en, this message translates to:
  /// **'{gw} / {dns}'**
  String gatewayDnsValue(String gw, String dns);

  /// No description provided for @buttonActionSaved.
  ///
  /// In en, this message translates to:
  /// **'Button action saved: {url}'**
  String buttonActionSaved(String url);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @whenRelayTurnsOn.
  ///
  /// In en, this message translates to:
  /// **'When the relay turns ON'**
  String get whenRelayTurnsOn;

  /// No description provided for @whenRelayTurnsOff.
  ///
  /// In en, this message translates to:
  /// **'When the relay turns OFF'**
  String get whenRelayTurnsOff;

  /// No description provided for @slotActionSaved.
  ///
  /// In en, this message translates to:
  /// **'\"{slot}\" action saved: {url}'**
  String slotActionSaved(String slot, String url);

  /// No description provided for @pirActionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic (any motion)'**
  String get pirActionGeneric;

  /// No description provided for @pirActionNight.
  ///
  /// In en, this message translates to:
  /// **'Night (dark)'**
  String get pirActionNight;

  /// No description provided for @pirActionTwilight.
  ///
  /// In en, this message translates to:
  /// **'Twilight (dawn/dusk)'**
  String get pirActionTwilight;

  /// No description provided for @pirActionDay.
  ///
  /// In en, this message translates to:
  /// **'Day (bright)'**
  String get pirActionDay;

  /// No description provided for @pirActionRise.
  ///
  /// In en, this message translates to:
  /// **'Motion begins'**
  String get pirActionRise;

  /// No description provided for @pirActionFall.
  ///
  /// In en, this message translates to:
  /// **'Motion ends'**
  String get pirActionFall;

  /// No description provided for @lightThresholds.
  ///
  /// In en, this message translates to:
  /// **'Light thresholds'**
  String get lightThresholds;

  /// No description provided for @lightThresholdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Night and day light boundaries the motion sensor uses to classify motion events. Values share the same scale as the light sensor. Night must be below day.'**
  String get lightThresholdsSubtitle;

  /// No description provided for @nightThresholdBelowDay.
  ///
  /// In en, this message translates to:
  /// **'The night threshold must be below the day threshold'**
  String get nightThresholdBelowDay;

  /// No description provided for @thresholdsSaved.
  ///
  /// In en, this message translates to:
  /// **'Thresholds saved'**
  String get thresholdsSaved;

  /// No description provided for @nightValue.
  ///
  /// In en, this message translates to:
  /// **'Night: {value}'**
  String nightValue(String value);

  /// No description provided for @dayValue.
  ///
  /// In en, this message translates to:
  /// **'Day: {value}'**
  String dayValue(String value);

  /// No description provided for @saveThresholds.
  ///
  /// In en, this message translates to:
  /// **'Save thresholds'**
  String get saveThresholds;

  /// No description provided for @pirSettings.
  ///
  /// In en, this message translates to:
  /// **'Motion sensor settings'**
  String get pirSettings;

  /// No description provided for @pirSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backoff time is the cooldown in seconds after a motion event (1–3600). \"LED enable\" controls the status indicator on the device.'**
  String get pirSettingsSubtitle;

  /// No description provided for @pirSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Motion sensor settings saved'**
  String get pirSettingsSaved;

  /// No description provided for @backoffTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Backoff time: {seconds} s'**
  String backoffTimeValue(String seconds);

  /// No description provided for @ledEnable.
  ///
  /// In en, this message translates to:
  /// **'LED enable'**
  String get ledEnable;

  /// No description provided for @ledEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the status LED when motion is detected.'**
  String get ledEnableSubtitle;

  /// No description provided for @savePirSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get savePirSettings;

  /// No description provided for @newScene.
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get newScene;

  /// No description provided for @editScene.
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get editScene;

  /// No description provided for @sceneName.
  ///
  /// In en, this message translates to:
  /// **'Scene name'**
  String get sceneName;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @noActionsYet.
  ///
  /// In en, this message translates to:
  /// **'No actions yet. Add a device action to run with this scene.'**
  String get noActionsYet;

  /// No description provided for @addDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Add device action'**
  String get addDeviceAction;

  /// No description provided for @addTimerAction.
  ///
  /// In en, this message translates to:
  /// **'Add timer action'**
  String get addTimerAction;

  /// No description provided for @noDevicesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No devices added yet'**
  String get noDevicesAddedYet;

  /// No description provided for @sceneDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get sceneDefaultName;

  /// No description provided for @sensorNoAction.
  ///
  /// In en, this message translates to:
  /// **'Sensor (no action)'**
  String get sensorNoAction;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a device'**
  String get selectDevice;

  /// No description provided for @timerMode.
  ///
  /// In en, this message translates to:
  /// **'Timer mode'**
  String get timerMode;

  /// No description provided for @durationHms.
  ///
  /// In en, this message translates to:
  /// **'Duration: {hh}:{mm}:{ss}'**
  String durationHms(String hh, String mm, String ss);

  /// No description provided for @actionOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get actionOn;

  /// No description provided for @actionOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get actionOff;

  /// No description provided for @actionToggle.
  ///
  /// In en, this message translates to:
  /// **'toggle'**
  String get actionToggle;

  /// No description provided for @actionTimer.
  ///
  /// In en, this message translates to:
  /// **'timer'**
  String get actionTimer;

  /// No description provided for @actionColor.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get actionColor;

  /// No description provided for @sceneIconArriveHome.
  ///
  /// In en, this message translates to:
  /// **'Coming Home'**
  String get sceneIconArriveHome;

  /// No description provided for @sceneIconGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get sceneIconGoodNight;

  /// No description provided for @sceneIconMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get sceneIconMorning;

  /// No description provided for @sceneIconMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get sceneIconMovie;

  /// No description provided for @sceneIconDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get sceneIconDinner;

  /// No description provided for @sceneIconAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get sceneIconAway;

  /// No description provided for @sceneIconSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sceneIconSleep;

  /// No description provided for @sceneIconWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get sceneIconWeekend;

  /// No description provided for @sceneIconLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get sceneIconLights;

  /// No description provided for @sceneIconPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get sceneIconPower;

  /// No description provided for @schedulerTitle.
  ///
  /// In en, this message translates to:
  /// **'{displayName} — Scheduler'**
  String schedulerTitle(String displayName);

  /// No description provided for @saveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get saveAll;

  /// No description provided for @noSchedulesYet.
  ///
  /// In en, this message translates to:
  /// **'No schedules yet'**
  String get noSchedulesYet;

  /// No description provided for @addNewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add new schedule'**
  String get addNewSchedule;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add schedule'**
  String get addSchedule;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @setColorOnly.
  ///
  /// In en, this message translates to:
  /// **'set (color only)'**
  String get setColorOnly;

  /// No description provided for @colorHsv.
  ///
  /// In en, this message translates to:
  /// **'Color (HSV)'**
  String get colorHsv;

  /// No description provided for @rampMs.
  ///
  /// In en, this message translates to:
  /// **'Ramp (ms)'**
  String get rampMs;

  /// No description provided for @valuePercent.
  ///
  /// In en, this message translates to:
  /// **'Value (%)'**
  String get valuePercent;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @scheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get scheduleSaved;

  /// No description provided for @schedulerNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Scheduler not supported on this device'**
  String get schedulerNotSupported;

  /// No description provided for @schedulerDeviceList.
  ///
  /// In en, this message translates to:
  /// **'Scheduler is only available on WS2, WSE, WRS, WMS, WSX and WLL.'**
  String get schedulerDeviceList;

  /// No description provided for @firmwareVersionUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the firmware version. Requires firmware 5.0.0 or newer.'**
  String get firmwareVersionUnreadable;

  /// No description provided for @firmwareVersionRequired.
  ///
  /// In en, this message translates to:
  /// **'Requires firmware 5.0.0 or newer (current: {fw}).'**
  String firmwareVersionRequired(String fw);

  /// No description provided for @energyHistory.
  ///
  /// In en, this message translates to:
  /// **'Energy History'**
  String get energyHistory;

  /// No description provided for @historyNotSupported.
  ///
  /// In en, this message translates to:
  /// **'History not supported.'**
  String get historyNotSupported;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get failedToLoadHistory;

  /// No description provided for @historyDeviceList.
  ///
  /// In en, this message translates to:
  /// **'Report history is only available on WS2, WSE and WSX.'**
  String get historyDeviceList;

  /// No description provided for @noHistoryDataYet.
  ///
  /// In en, this message translates to:
  /// **'No history data available yet.\nReports are stored hourly once the device runs firmware 5.0.0 or newer.'**
  String get noHistoryDataYet;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @noDataForSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'No data for the selected day'**
  String get noDataForSelectedDay;

  /// No description provided for @noDataForDate.
  ///
  /// In en, this message translates to:
  /// **'No data for {date}'**
  String noDataForDate(String date);

  /// No description provided for @avgPower.
  ///
  /// In en, this message translates to:
  /// **'Avg Power'**
  String get avgPower;

  /// No description provided for @peakPower.
  ///
  /// In en, this message translates to:
  /// **'Peak Power'**
  String get peakPower;

  /// No description provided for @intervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get intervals;

  /// No description provided for @energyPerIntervalLegend.
  ///
  /// In en, this message translates to:
  /// **'Energy per interval (kWh)'**
  String get energyPerIntervalLegend;

  /// No description provided for @discovery.
  ///
  /// In en, this message translates to:
  /// **'Device discovery'**
  String get discovery;

  /// No description provided for @discoveryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Device discovery runs continuously in the background. Devices show up in the device list as soon as they answer.'**
  String get discoveryPlaceholder;

  /// No description provided for @wifiSetup.
  ///
  /// In en, this message translates to:
  /// **'WiFi Setup'**
  String get wifiSetup;

  /// No description provided for @wifiSetupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'To move a device to a different WiFi network, use \"Add device\" → \"SoftAP\".'**
  String get wifiSetupPlaceholder;

  /// No description provided for @stripSettings.
  ///
  /// In en, this message translates to:
  /// **'Strip Settings'**
  String get stripSettings;

  /// No description provided for @channelMode.
  ///
  /// In en, this message translates to:
  /// **'Channel Mode'**
  String get channelMode;

  /// No description provided for @chModeColorsDesc.
  ///
  /// In en, this message translates to:
  /// **'WRGB strip — full color control (HSV or WRGB)'**
  String get chModeColorsDesc;

  /// No description provided for @chModeChannelsDesc.
  ///
  /// In en, this message translates to:
  /// **'4 independent dimmable channels (e.g. 4 white strips)'**
  String get chModeChannelsDesc;

  /// No description provided for @chModeColdWarmDesc.
  ///
  /// In en, this message translates to:
  /// **'2 warm-white + 2 cold-white channels (W+R = warm, G+B = cold)'**
  String get chModeColdWarmDesc;

  /// No description provided for @chModeChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Changing the channel mode affects how the strip is controlled. The control page will adapt automatically.'**
  String get chModeChangeNote;

  /// No description provided for @channelModeSet.
  ///
  /// In en, this message translates to:
  /// **'Channel mode set to {mode}'**
  String channelModeSet(String mode);

  /// No description provided for @ramp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get ramp;

  /// No description provided for @rampSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String rampSeconds(String seconds);

  /// No description provided for @tabColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tabColor;

  /// No description provided for @tabWhites.
  ///
  /// In en, this message translates to:
  /// **'Whites'**
  String get tabWhites;

  /// No description provided for @tabWrgb.
  ///
  /// In en, this message translates to:
  /// **'WRGB'**
  String get tabWrgb;

  /// No description provided for @whitesColdWarm.
  ///
  /// In en, this message translates to:
  /// **'Whites (Cold / Warm)'**
  String get whitesColdWarm;

  /// No description provided for @whites.
  ///
  /// In en, this message translates to:
  /// **'Whites'**
  String get whites;

  /// No description provided for @whitesInternalConversion.
  ///
  /// In en, this message translates to:
  /// **'The device internally converts the color temperature to WRGB values.'**
  String get whitesInternalConversion;

  /// No description provided for @deviceMode.
  ///
  /// In en, this message translates to:
  /// **'Device mode: {mode}'**
  String deviceMode(String mode);

  /// No description provided for @stripMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String stripMode(String mode);

  /// No description provided for @whiteIndex.
  ///
  /// In en, this message translates to:
  /// **'White: {index}'**
  String whiteIndex(String index);

  /// No description provided for @brightnessPercent.
  ///
  /// In en, this message translates to:
  /// **'Brightness: {value}%'**
  String brightnessPercent(String value);

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @channelN.
  ///
  /// In en, this message translates to:
  /// **'Channel {n}'**
  String channelN(int n);

  /// No description provided for @warm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get warm;

  /// No description provided for @cold.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get cold;

  /// No description provided for @coldWarm.
  ///
  /// In en, this message translates to:
  /// **'Cold / Warm'**
  String get coldWarm;

  /// No description provided for @labelValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String labelValue(String label, String value);

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motion;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @unitLux.
  ///
  /// In en, this message translates to:
  /// **'lux'**
  String get unitLux;

  /// No description provided for @actionUrls.
  ///
  /// In en, this message translates to:
  /// **'Action URLs'**
  String get actionUrls;

  /// No description provided for @actionUrlsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a scheme to configure which device/action is triggered.'**
  String get actionUrlsSubtitle;

  /// No description provided for @singlePress.
  ///
  /// In en, this message translates to:
  /// **'Press once'**
  String get singlePress;

  /// No description provided for @doublePress.
  ///
  /// In en, this message translates to:
  /// **'Press twice'**
  String get doublePress;

  /// No description provided for @longPress.
  ///
  /// In en, this message translates to:
  /// **'Press and hold'**
  String get longPress;

  /// No description provided for @touch.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get touch;

  /// No description provided for @generic.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get generic;

  /// No description provided for @buttonN.
  ///
  /// In en, this message translates to:
  /// **'Button {n}'**
  String buttonN(int n);

  /// No description provided for @overThreshold.
  ///
  /// In en, this message translates to:
  /// **'Above threshold'**
  String get overThreshold;

  /// No description provided for @underThreshold.
  ///
  /// In en, this message translates to:
  /// **'Below threshold'**
  String get underThreshold;

  /// No description provided for @schemeUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'{scheme} → {url}'**
  String schemeUrlSaved(String scheme, String url);

  /// No description provided for @refererActionUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'{referer}/{action} → {url}'**
  String refererActionUrlSaved(String referer, String action, String url);

  /// No description provided for @assignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign action'**
  String get assignAction;

  /// No description provided for @targetDevice.
  ///
  /// In en, this message translates to:
  /// **'Target device'**
  String get targetDevice;

  /// No description provided for @deviceWithModel.
  ///
  /// In en, this message translates to:
  /// **'{displayName} ({model})'**
  String deviceWithModel(String displayName, String model);

  /// No description provided for @colorHsvShort.
  ///
  /// In en, this message translates to:
  /// **'Color (H;S;V)'**
  String get colorHsvShort;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @macColon.
  ///
  /// In en, this message translates to:
  /// **'MAC: {mac}'**
  String macColon(String mac);

  /// No description provided for @ipColon.
  ///
  /// In en, this message translates to:
  /// **'IP: {ip}'**
  String ipColon(String ip);

  /// No description provided for @noIpForDevice.
  ///
  /// In en, this message translates to:
  /// **'No IP address for this device.'**
  String get noIpForDevice;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Device is offline. Make sure it is powered on and connected.'**
  String get deviceOffline;

  /// No description provided for @couldNotReachDevice.
  ///
  /// In en, this message translates to:
  /// **'Could not reach device: {error}'**
  String couldNotReachDevice(String error);

  /// No description provided for @statusMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get statusMotion;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'No motion'**
  String get statusIdle;

  /// No description provided for @statusButton.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get statusButton;

  /// No description provided for @statusOnPercent.
  ///
  /// In en, this message translates to:
  /// **'On {value}%'**
  String statusOnPercent(String value);

  /// No description provided for @deviceCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{ip} • {status}'**
  String deviceCardSubtitle(String ip, String status);

  /// No description provided for @timerNone.
  ///
  /// In en, this message translates to:
  /// **'No timer'**
  String get timerNone;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @minuteShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minuteShort;

  /// No description provided for @secondShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String secondsShort(String seconds);

  /// No description provided for @hueValue.
  ///
  /// In en, this message translates to:
  /// **'Hue: {value}°'**
  String hueValue(String value);

  /// No description provided for @saturationValue.
  ///
  /// In en, this message translates to:
  /// **'Saturation: {value}%'**
  String saturationValue(String value);

  /// No description provided for @featureTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get featureTimer;

  /// No description provided for @featureScheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get featureScheduler;

  /// No description provided for @featureHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get featureHistory;

  /// No description provided for @noPowerData.
  ///
  /// In en, this message translates to:
  /// **'No power data'**
  String get noPowerData;

  /// No description provided for @couldNotScanWifi.
  ///
  /// In en, this message translates to:
  /// **'Could not scan WiFi: {error}'**
  String couldNotScanWifi(String error);

  /// No description provided for @totalEnergyTitleCase.
  ///
  /// In en, this message translates to:
  /// **'Total Energy'**
  String get totalEnergyTitleCase;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'de':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsDeCh();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
