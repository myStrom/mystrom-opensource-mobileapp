// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'myStrom Local';

  @override
  String get add => 'Hinzufügen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get saved => 'Gespeichert';

  @override
  String get delete => 'Löschen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get reload => 'Aktualisieren';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get enable => 'Aktivieren';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get set => 'Starten';

  @override
  String get advanced => 'Erweitert';

  @override
  String get loading => 'Wird geladen …';

  @override
  String get loadingEllipsis => '…';

  @override
  String get noDataDash => '--';

  @override
  String get unknown => 'unbekannt';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get noIpAddress => 'Keine IP-Adresse';

  @override
  String get noIp => 'keine IP';

  @override
  String get online => 'online';

  @override
  String get offline => 'offline';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get schedulerTooltip => 'Zeitplan';

  @override
  String get identify => 'Identifizieren';

  @override
  String get identifySignalSent =>
      'Identifikationssignal gesendet — achten Sie auf das Blinken.';

  @override
  String get timerSet => 'Timer gesetzt';

  @override
  String get on => 'Ein';

  @override
  String get off => 'Aus';

  @override
  String get toggle => 'Umschalten';

  @override
  String get locked => 'Gesperrt';

  @override
  String get power => 'Leistung';

  @override
  String get totalPower => 'Gesamtleistung';

  @override
  String get totalEnergy => 'Gesamtenergie';

  @override
  String get color => 'Farbe';

  @override
  String get name => 'Name';

  @override
  String get device => 'Gerät';

  @override
  String get action => 'Aktion';

  @override
  String get room => 'Raum';

  @override
  String get favorite => 'Favorit';

  @override
  String get firmware => 'Firmware';

  @override
  String get connection => 'Verbindung';

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Getrennt';

  @override
  String get roaming => 'Roaming';

  @override
  String get handshake => 'Handshake';

  @override
  String get login => 'Anmeldung';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get notConfigured => 'Nicht konfiguriert';

  @override
  String get mac => 'MAC';

  @override
  String get ip => 'IP';

  @override
  String get type => 'Typ';

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
  String get deviceTypeUnknown => 'Unbekanntes Gerät';

  @override
  String discoveryCountFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gefunden',
      one: '1 gefunden',
    );
    return '$_temp0';
  }

  @override
  String get discoveryListening => 'Suche läuft …';

  @override
  String get sectionScenes => 'Szenen';

  @override
  String get sectionMyDevices => 'Meine Geräte';

  @override
  String get sectionNewlyDiscovered => 'Neu gefunden';

  @override
  String get noDevicesInCategory => 'Keine Geräte in dieser Kategorie';

  @override
  String noToggleableDevicesInRoom(String room) {
    return 'Keine schaltbaren Geräte in „$room“';
  }

  @override
  String turnAllInRoomOn(String room) {
    return 'Alle in „$room“ einschalten';
  }

  @override
  String turnAllInRoomOff(String room) {
    return 'Alle in „$room“ ausschalten';
  }

  @override
  String bulkToggleResultOn(int ok, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$ok/$total Geräte eingeschaltet',
      one: '$ok/$total Gerät eingeschaltet',
    );
    return '$_temp0';
  }

  @override
  String bulkToggleResultOff(int ok, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$ok/$total Geräte ausgeschaltet',
      one: '$ok/$total Gerät ausgeschaltet',
    );
    return '$_temp0';
  }

  @override
  String sceneExecuted(String name) {
    return 'Szene „$name“ ausgeführt';
  }

  @override
  String sceneExecuteFailed(String list) {
    return 'Fehlgeschlagen: $list';
  }

  @override
  String get categoryAll => 'Alle';

  @override
  String get categoryFavorite => 'Favoriten';

  @override
  String roomChipLongPressHint(String room) {
    return 'Gedrückt halten, um alle in „$room“ ein- bzw. auszuschalten';
  }

  @override
  String get emptyStateListening =>
      'Suche nach Geräten …\nNoch keine Geräte gefunden.\nStellen Sie sicher, dass sich die myStrom-Geräte im selben WLAN befinden.';

  @override
  String get emptyStateStartingDiscovery =>
      'UDP-Suche wird gestartet …\nFalls das System nach Zugriff auf das lokale Netzwerk gefragt hat,\nstellen Sie sicher, dass Sie ihn erlaubt haben.';

  @override
  String get addDeviceManually => 'Gerät manuell hinzufügen';

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
    return '$value %';
  }

  @override
  String get sinceBoot => 'Seit dem Start';

  @override
  String get deviceLockedToggleDisabled =>
      'Dieses Gerät ist gesperrt — Ein/Aus ist deaktiviert.';

  @override
  String get addDeviceTitle => 'Gerät hinzufügen';

  @override
  String get addDevice => 'Gerät hinzufügen';

  @override
  String get tabDiscovered => 'Gefunden';

  @override
  String get tabSoftAp => 'SoftAP';

  @override
  String get tabWps => 'WPS';

  @override
  String get noNewDevicesFound =>
      'Keine neuen Geräte im lokalen Netzwerk gefunden.\n\nStellen Sie sicher, dass Ihre myStrom-Geräte eingeschaltet und mit demselben WLAN verbunden sind. Die Suche läuft automatisch im Hintergrund.';

  @override
  String deviceAddedSnack(String displayName) {
    return '$displayName hinzugefügt';
  }

  @override
  String get credentialsSentSnackbar =>
      'Zugangsdaten gesendet. Das Gerät startet neu und verbindet sich mit Ihrem WLAN.';

  @override
  String get howToEnterApMode => 'So aktivieren Sie den AP-Modus';

  @override
  String get apModeInstructionsSubtitle =>
      'Unterschiedlich je Gerätetyp — zum Aufklappen tippen';

  @override
  String get apModeSwitchesTitle =>
      'Switches (WS2, WSE, WSX, LCS), Strip (WRS), Cube (WLL), Motion Sensor (WMS)';

  @override
  String get apModeSwitchResetStep1 =>
      'Werkseinstellungen wiederherstellen: die „+“-Taste 10–20 s gedrückt halten, bis die LED weiß blinkt.';

  @override
  String get apModeSwitchResetStep2 =>
      'Nach dem Zurücksetzen blinkt die LED kurz rot, danach wechselt das Gerät in den AP-Modus.';

  @override
  String get apModeButtonsTitle => 'Buttons (BP2, BM1, WBS/WBP)';

  @override
  String get apModeButtonResetStep1 =>
      'Werkseinstellungen wiederherstellen: eine beliebige Taste 10–20 s gedrückt halten, bis die LED abwechselnd weiß/rot blinkt, dann loslassen und innerhalb von 2 s nochmals drücken, um zu bestätigen (die LED blinkt weiß).';

  @override
  String get apModeButtonResetStep2 =>
      'Nach dem Zurücksetzen startet das Gerät im WPS-Modus (weißes Blinken, 2 Min.). Für den AP-Modus die Taste 3 s gedrückt halten — die LED blinkt langsam abwechselnd weiß/rot.';

  @override
  String get apModeBulbTitle => 'Bulb (WRB)';

  @override
  String get apModeBulbResetStep1 =>
      'Werkseinstellungen wiederherstellen: den Strom 5-mal aus- und einschalten, mit ca. 5 s Pause. Nach dem 5. Einschalten blinkt die Lampe 10× weiß.';

  @override
  String get apModeBulbResetStep2 =>
      'Der WPS-Modus läuft 3 Min. (weißes Blinken), danach startet der AP-Modus automatisch und läuft 5 Min.';

  @override
  String get apModeLedSignalsTitle => 'LED-Signale (alle Geräte)';

  @override
  String get apModeLedFastRed =>
      'Schnelles rotes Blinken — das Gerät verbindet sich mit dem WLAN.';

  @override
  String get apModeLedSlowRed =>
      'Langsames rotes Blinken — verbunden, die IP-Adresse wird bezogen.';

  @override
  String get apModeLedWhite =>
      'Weißes Blinken — das Gerät verbindet sich mit der Cloud.';

  @override
  String get apModeLedGreenSuccess => '3× grün — erfolgreich verbunden.';

  @override
  String get apModeLedRedFailure => '3× rot — Verbindung fehlgeschlagen.';

  @override
  String get softApSelectApIntro =>
      'Versetzen Sie Ihr Gerät in den AP-Modus (siehe Anleitung unten). Wählen Sie es anschließend aus der Liste aus oder verbinden Sie sich manuell mit seinem WLAN und tippen Sie auf „Ich bin bereits verbunden“.';

  @override
  String get softApSelectApIntroManual =>
      'Versetzen Sie Ihr Gerät in den AP-Modus (siehe Anleitung unten). Verbinden Sie sich in den Systemeinstellungen mit seinem WLAN und tippen Sie anschließend hier auf „Ich bin bereits verbunden“.';

  @override
  String get scanForMyStromDevices => 'Nach myStrom-Geräten suchen';

  @override
  String get noMyStromApsFound =>
      'Keine myStrom-APs gefunden.\n\n• Stellen Sie sicher, dass sich das Gerät im AP-Modus befindet.\n• Erteilen Sie die Standortberechtigung (Einstellungen → Apps → mystrom_local → Berechtigungen).\n• Schalten Sie den Standort (GPS) in den Systemeinstellungen ein — Android benötigt ihn für WLAN-Scans.\n• Falls Sie bereits mit dem Geräte-AP verbunden sind, tippen Sie unten auf „Ich bin bereits verbunden“.';

  @override
  String apCandidateSubtitle(String displayName, String signal) {
    return '$displayName • $signal dBm';
  }

  @override
  String get alreadyConnectedToAp => 'Ich bin bereits verbunden';

  @override
  String get connectedManual => 'Verbunden (manuell)';

  @override
  String deviceInfoMacLine(String type, String mac) {
    return '$type • MAC $mac';
  }

  @override
  String get scanNetworksIntro =>
      'Sucht nach den WLAN-Netzwerken, die das Gerät sieht. Das dauert bis zu 5 s.';

  @override
  String get deviceApIp => 'IP des Geräte-AP';

  @override
  String get scanWifiNetworks => 'WLAN-Netzwerke suchen';

  @override
  String get noNetworksFound =>
      'Keine Netzwerke gefunden. Starten Sie die Suche erneut oder geben Sie die SSID im nächsten Schritt manuell ein.';

  @override
  String signalDbm(String signal) {
    return '$signal dBm';
  }

  @override
  String get enterSsidManually =>
      'SSID manuell eingeben (verborgenes Netzwerk)';

  @override
  String get pickNetworkOrSsid => 'Netzwerk auswählen oder SSID eingeben:';

  @override
  String get wifiSsid => 'WLAN-SSID';

  @override
  String get wifiSsidHint => 'HomeWiFi (oder verborgenes Netzwerk)';

  @override
  String get wifiPassword => 'WLAN-Passwort';

  @override
  String get deviceNameOptional => 'Gerätename (optional)';

  @override
  String get staticIpOptional => 'Statische IP (optional)';

  @override
  String get subnetMaskOptional => 'Subnetzmaske (optional)';

  @override
  String get gatewayOptional => 'Gateway (optional)';

  @override
  String get dnsOptional => 'DNS (optional)';

  @override
  String get roaming80211r => 'Roaming (802.11r)';

  @override
  String get sendCredentials => 'Zugangsdaten senden';

  @override
  String get sendingCredentials => 'Zugangsdaten werden gesendet …';

  @override
  String get credentialsSentSuccess => 'Zugangsdaten erfolgreich gesendet.';

  @override
  String get deviceRebootingMessage =>
      'Das Gerät startet neu und verbindet sich mit Ihrem WLAN. Es sollte innerhalb einer Minute im Tab „Gefunden“ erscheinen.';

  @override
  String macLabel(String mac) {
    return 'MAC: $mac';
  }

  @override
  String typeLabel(String displayName) {
    return 'Typ: $displayName';
  }

  @override
  String get addToDeviceListNow => 'Jetzt zur Geräteliste hinzufügen';

  @override
  String get deviceAddedWillComeOnline =>
      'Gerät hinzugefügt. Es ist in Kürze online.';

  @override
  String get provisionAnotherDevice => 'Weiteres Gerät einrichten';

  @override
  String get provisioningFailed => 'Einrichtung fehlgeschlagen';

  @override
  String get startOver => 'Von vorne beginnen';

  @override
  String get wpsIntro =>
      'Mit WPS verbindet sich das Gerät über ein Pairing mit Ihrem Router. Der Weg in den WPS-Modus unterscheidet sich je nach Gerätetyp:';

  @override
  String get wpsSwitchStep1 =>
      'Die „+“-Taste 3 s gedrückt halten — die LED beginnt langsam weiß zu blinken.';

  @override
  String get wpsSwitchStep2 =>
      'Drücken Sie innerhalb von 2 Min. die WPS-Taste an Ihrem Router.';

  @override
  String get wpsSwitchStep3 =>
      'Das Gerät verbindet sich automatisch; bei Erfolg blinkt die LED 3× grün, bei einem Fehler 3× rot.';

  @override
  String get wpsResultHint =>
      '3× grünes Blinken = Erfolg, 3× rotes Blinken = Fehler.';

  @override
  String get wpsButtonWpsModeAuto =>
      'Nach dem Zurücksetzen startet das Gerät automatisch im WPS-Modus (weißes Blinken, 2 Min.).';

  @override
  String get wpsButtonPressRouter =>
      'Drücken Sie in diesem Zeitfenster die WPS-Taste an Ihrem Router.';

  @override
  String get wpsBulbReset =>
      'Werkseinstellungen wiederherstellen: den Strom 5-mal aus- und einschalten, mit ca. 5 s Pause. Nach dem 5. Einschalten blinkt die Lampe 10× weiß.';

  @override
  String get wpsBulbMode =>
      'Der WPS-Modus läuft 3 Min. (weißes Blinken). Drücken Sie in diesem Zeitfenster WPS an Ihrem Router.';

  @override
  String get triggerWpsOnDevice => 'WPS am Gerät auslösen';

  @override
  String get wpsTriggerSnackbar =>
      'Stellen Sie sicher, dass sich das Gerät im WPS-Modus befindet, und drücken Sie dann WPS an Ihrem Router.';

  @override
  String get nameHintExample => 'z. B. Stehlampe Wohnzimmer';

  @override
  String get deviceNameSection => 'Gerätename';

  @override
  String get customName => 'Eigener Name';

  @override
  String get favoriteSubtitle =>
      'Dieses Gerät auf dem Dashboard unter „Favoriten“ anzeigen.';

  @override
  String get lockOnOff => 'Ein/Aus sperren';

  @override
  String get lockOnOffSubtitle =>
      'Deaktiviert den Ein/Aus-Schalter (z. B. für einen Kühlschrank). Timer und Zeitplan bleiben weiterhin möglich.';

  @override
  String get temperatureOffset => 'Temperatur-Offset';

  @override
  String temperatureOffsetValue(String sign, String value) {
    return '$sign$value °C';
  }

  @override
  String get tileColor => 'Kachelfarbe';

  @override
  String get tileColorSubtitle =>
      'Hilft dabei, dieses Gerät auf dem Dashboard von anderen zu unterscheiden.';

  @override
  String get stripChannelMode => 'Kanalmodus des LED-Streifens';

  @override
  String get stripChannelModeSubtitle =>
      'Farben / Kanäle / Kaltweiß-Warmweiß konfigurieren';

  @override
  String get buttonAction => 'Tastenaktion';

  @override
  String get buttonActionSubtitle =>
      'Wählen Sie, welches Gerät bzw. welche Aktion ausgelöst wird, wenn die physische Taste der Steckdose gedrückt wird.';

  @override
  String get pirActions => 'Aktionen des Bewegungsmelders';

  @override
  String get pirActionsSubtitle =>
      'Wählen Sie für jede Bedingung ein Gerät und eine Aktion (Bewegung bei unterschiedlicher Helligkeit).';

  @override
  String get identifySubtitle =>
      'Lässt das Gerät blinken, damit Sie erkennen, um welches es sich handelt.';

  @override
  String get deviceInfo => 'Geräteinformationen';

  @override
  String get noInfoAvailable => 'Keine Informationen verfügbar';

  @override
  String typeSubtitle(String model, String displayName) {
    return '$model — $displayName';
  }

  @override
  String get removeDevice => 'Gerät entfernen';

  @override
  String get discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String get discardChangesMessage =>
      'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich ohne Speichern beenden?';

  @override
  String get quitWithoutSaving => 'Ohne Speichern beenden';

  @override
  String get ipMask => 'IP / Maske';

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
    return 'Tastenaktion gespeichert: $url';
  }

  @override
  String saveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get whenRelayTurnsOn => 'Wenn das Relais einschaltet';

  @override
  String get whenRelayTurnsOff => 'Wenn das Relais ausschaltet';

  @override
  String slotActionSaved(String slot, String url) {
    return 'Aktion „$slot“ gespeichert: $url';
  }

  @override
  String get pirActionGeneric => 'Allgemein (jede Bewegung)';

  @override
  String get pirActionNight => 'Nacht (dunkel)';

  @override
  String get pirActionTwilight => 'Dämmerung (Morgen-/Abenddämmerung)';

  @override
  String get pirActionDay => 'Tag (hell)';

  @override
  String get pirActionRise => 'Bewegung beginnt';

  @override
  String get pirActionFall => 'Bewegung endet';

  @override
  String get lightThresholds => 'Helligkeitsschwellen';

  @override
  String get lightThresholdsSubtitle =>
      'Nacht- und Tag-Grenzwerte, mit denen der Bewegungsmelder Bewegungsereignisse einordnet. Die Werte nutzen dieselbe Skala wie der Lichtsensor. Der Nachtwert muss unter dem Tagwert liegen.';

  @override
  String get nightThresholdBelowDay =>
      'Der Nacht-Schwellenwert muss unter dem Tag-Schwellenwert liegen';

  @override
  String get thresholdsSaved => 'Schwellenwerte gespeichert';

  @override
  String nightValue(String value) {
    return 'Nacht: $value';
  }

  @override
  String dayValue(String value) {
    return 'Tag: $value';
  }

  @override
  String get saveThresholds => 'Schwellenwerte speichern';

  @override
  String get pirSettings => 'Einstellungen des Bewegungsmelders';

  @override
  String get pirSettingsSubtitle =>
      'Die Wartezeit (Backoff) ist die Sperrzeit in Sekunden nach einem Bewegungsereignis (1–3600). „LED aktivieren“ steuert die Statusanzeige am Gerät.';

  @override
  String get pirSettingsSaved =>
      'Einstellungen des Bewegungsmelders gespeichert';

  @override
  String backoffTimeValue(String seconds) {
    return 'Wartezeit (Backoff): $seconds s';
  }

  @override
  String get ledEnable => 'LED aktivieren';

  @override
  String get ledEnableSubtitle =>
      'Zeigt die Status-LED an, wenn eine Bewegung erkannt wird.';

  @override
  String get savePirSettings => 'Einstellungen speichern';

  @override
  String get newScene => 'Neue Szene';

  @override
  String get editScene => 'Szene bearbeiten';

  @override
  String get sceneName => 'Szenenname';

  @override
  String get icon => 'Symbol';

  @override
  String get actions => 'Aktionen';

  @override
  String get noActionsYet =>
      'Noch keine Aktionen. Fügen Sie eine Geräteaktion hinzu, die mit dieser Szene ausgeführt wird.';

  @override
  String get addDeviceAction => 'Geräteaktion hinzufügen';

  @override
  String get addTimerAction => 'Timer-Aktion hinzufügen';

  @override
  String get noDevicesAddedYet => 'Noch keine Geräte hinzugefügt';

  @override
  String get sceneDefaultName => 'Szene';

  @override
  String get sensorNoAction => 'Sensor (keine Aktion)';

  @override
  String get selectDevice => 'Gerät auswählen';

  @override
  String get timerMode => 'Timer-Modus';

  @override
  String durationHms(String hh, String mm, String ss) {
    return 'Dauer: $hh:$mm:$ss';
  }

  @override
  String get actionOn => 'ein';

  @override
  String get actionOff => 'aus';

  @override
  String get actionToggle => 'umschalten';

  @override
  String get actionTimer => 'Timer';

  @override
  String get actionColor => 'Farbe';

  @override
  String get sceneIconArriveHome => 'Heimkommen';

  @override
  String get sceneIconGoodNight => 'Gute Nacht';

  @override
  String get sceneIconMorning => 'Guten Morgen';

  @override
  String get sceneIconMovie => 'Film';

  @override
  String get sceneIconDinner => 'Abendessen';

  @override
  String get sceneIconAway => 'Abwesend';

  @override
  String get sceneIconSleep => 'Schlafen';

  @override
  String get sceneIconWeekend => 'Wochenende';

  @override
  String get sceneIconLights => 'Licht';

  @override
  String get sceneIconPower => 'Strom';

  @override
  String schedulerTitle(String displayName) {
    return '$displayName — Zeitplan';
  }

  @override
  String get saveAll => 'Alle speichern';

  @override
  String get noSchedulesYet => 'Noch keine Zeitpläne';

  @override
  String get addNewSchedule => 'Neuen Zeitplan hinzufügen';

  @override
  String get addSchedule => 'Zeitplan hinzufügen';

  @override
  String get hour => 'Stunde';

  @override
  String get minute => 'Minute';

  @override
  String get setColorOnly => 'setzen (nur Farbe)';

  @override
  String get colorHsv => 'Farbe (HSV)';

  @override
  String get rampMs => 'Übergangszeit (ms)';

  @override
  String get valuePercent => 'Wert (%)';

  @override
  String get daySun => 'So';

  @override
  String get dayMon => 'Mo';

  @override
  String get dayTue => 'Di';

  @override
  String get dayWed => 'Mi';

  @override
  String get dayThu => 'Do';

  @override
  String get dayFri => 'Fr';

  @override
  String get daySat => 'Sa';

  @override
  String get days => 'Tage';

  @override
  String get scheduleSaved => 'Zeitplan gespeichert';

  @override
  String get schedulerNotSupported =>
      'Der Zeitplan wird von diesem Gerät nicht unterstützt';

  @override
  String get schedulerDeviceList =>
      'Der Zeitplan ist nur auf WS2, WSE, WRS, WMS, WSX und WLL verfügbar.';

  @override
  String get firmwareVersionUnreadable =>
      'Die Firmware-Version konnte nicht gelesen werden. Erfordert Firmware 5.0.0 oder neuer.';

  @override
  String firmwareVersionRequired(String fw) {
    return 'Erfordert Firmware 5.0.0 oder neuer (aktuell: $fw).';
  }

  @override
  String get energyHistory => 'Energieverlauf';

  @override
  String get historyNotSupported => 'Der Verlauf wird nicht unterstützt.';

  @override
  String get failedToLoadHistory => 'Der Verlauf konnte nicht geladen werden';

  @override
  String get historyDeviceList =>
      'Der Energieverlauf ist nur auf WS2, WSE und WSX verfügbar.';

  @override
  String get noHistoryDataYet =>
      'Noch keine Verlaufsdaten vorhanden.\nBerichte werden stündlich gespeichert, sobald auf dem Gerät Firmware 5.0.0 oder neuer läuft.';

  @override
  String get previousDay => 'Vorheriger Tag';

  @override
  String get nextDay => 'Nächster Tag';

  @override
  String get latest => 'Neuster Tag';

  @override
  String get noDataForSelectedDay => 'Keine Daten für den gewählten Tag';

  @override
  String noDataForDate(String date) {
    return 'Keine Daten für $date';
  }

  @override
  String get avgPower => 'Ø-Leistung';

  @override
  String get peakPower => 'Spitzenleistung';

  @override
  String get intervals => 'Intervalle';

  @override
  String get energyPerIntervalLegend => 'Energie pro Intervall (kWh)';

  @override
  String get discovery => 'Gerätesuche';

  @override
  String get discoveryPlaceholder =>
      'Die Gerätesuche läuft dauerhaft im Hintergrund. Gefundene Geräte erscheinen in der Geräteliste.';

  @override
  String get wifiSetup => 'WLAN-Einrichtung';

  @override
  String get wifiSetupPlaceholder =>
      'Um ein Gerät in ein anderes WLAN zu übernehmen, verwenden Sie „Gerät hinzufügen“ → „SoftAP“.';

  @override
  String get stripSettings => 'Einstellungen des LED-Streifens';

  @override
  String get channelMode => 'Kanalmodus';

  @override
  String get chModeColorsDesc =>
      'WRGB-Streifen — volle Farbsteuerung (HSV oder WRGB)';

  @override
  String get chModeChannelsDesc =>
      '4 unabhängige dimmbare Kanäle (z. B. 4 weiße Streifen)';

  @override
  String get chModeColdWarmDesc =>
      '2 Warmweiß- + 2 Kaltweiß-Kanäle (W+R = warmweiß, G+B = kaltweiß)';

  @override
  String get chModeChangeNote =>
      'Der Kanalmodus ändert die Steuerung des Streifens. Die Steuerungsseite passt sich automatisch an.';

  @override
  String channelModeSet(String mode) {
    return 'Kanalmodus auf $mode gesetzt';
  }

  @override
  String get ramp => 'Übergangszeit';

  @override
  String rampSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get tabColor => 'Farbe';

  @override
  String get tabWhites => 'Weißtöne';

  @override
  String get tabWrgb => 'WRGB';

  @override
  String get whitesColdWarm => 'Weißtöne (kalt / warm)';

  @override
  String get whites => 'Weißtöne';

  @override
  String get whitesInternalConversion =>
      'Das Gerät rechnet die Farbtemperatur intern in WRGB-Werte um.';

  @override
  String deviceMode(String mode) {
    return 'Gerätemodus: $mode';
  }

  @override
  String stripMode(String mode) {
    return 'Modus: $mode';
  }

  @override
  String whiteIndex(String index) {
    return 'Weiß: $index';
  }

  @override
  String brightnessPercent(String value) {
    return 'Helligkeit: $value %';
  }

  @override
  String get colorWhite => 'Weiß';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorBlue => 'Blau';

  @override
  String get channels => 'Kanäle';

  @override
  String channelN(int n) {
    return 'Kanal $n';
  }

  @override
  String get warm => 'Warm';

  @override
  String get cold => 'Kalt';

  @override
  String get coldWarm => 'Kalt / Warm';

  @override
  String labelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get motion => 'Bewegung';

  @override
  String get light => 'Licht';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get battery => 'Batterie';

  @override
  String get unitLux => 'Lux';

  @override
  String get actionUrls => 'Aktions-URLs';

  @override
  String get actionUrlsSubtitle =>
      'Tippen Sie auf ein Schema, um festzulegen, welches Gerät bzw. welche Aktion ausgelöst wird.';

  @override
  String get singlePress => 'Einmal drücken';

  @override
  String get doublePress => 'Zweimal drücken';

  @override
  String get longPress => 'Lange drücken';

  @override
  String get touch => 'Berühren';

  @override
  String get generic => 'Allgemein';

  @override
  String buttonN(int n) {
    return 'Taste $n';
  }

  @override
  String get overThreshold => 'Schwellenwert überschritten';

  @override
  String get underThreshold => 'Schwellenwert unterschritten';

  @override
  String schemeUrlSaved(String scheme, String url) {
    return '$scheme → $url';
  }

  @override
  String refererActionUrlSaved(String referer, String action, String url) {
    return '$referer/$action → $url';
  }

  @override
  String get assignAction => 'Aktion zuweisen';

  @override
  String get targetDevice => 'Zielgerät';

  @override
  String deviceWithModel(String displayName, String model) {
    return '$displayName ($model)';
  }

  @override
  String get colorHsvShort => 'Farbe (H;S;V)';

  @override
  String get assign => 'Zuweisen';

  @override
  String macColon(String mac) {
    return 'MAC: $mac';
  }

  @override
  String ipColon(String ip) {
    return 'IP: $ip';
  }

  @override
  String get noIpForDevice => 'Für dieses Gerät ist keine IP-Adresse bekannt.';

  @override
  String get deviceOffline =>
      'Das Gerät ist offline. Stellen Sie sicher, dass es eingeschaltet und verbunden ist.';

  @override
  String couldNotReachDevice(String error) {
    return 'Gerät nicht erreichbar: $error';
  }

  @override
  String get statusMotion => 'Bewegung';

  @override
  String get statusIdle => 'Keine Bewegung';

  @override
  String get statusButton => 'Taste';

  @override
  String statusOnPercent(String value) {
    return 'Ein $value %';
  }

  @override
  String deviceCardSubtitle(String ip, String status) {
    return '$ip • $status';
  }

  @override
  String get timerNone => 'Kein Timer';

  @override
  String get hourShort => 'Std.';

  @override
  String get minuteShort => 'Min.';

  @override
  String get secondShort => 'Sek.';

  @override
  String secondsShort(String seconds) {
    return '$seconds s';
  }

  @override
  String hueValue(String value) {
    return 'Farbton: $value°';
  }

  @override
  String saturationValue(String value) {
    return 'Sättigung: $value %';
  }

  @override
  String get featureTimer => 'Timer';

  @override
  String get featureScheduler => 'Zeitplan';

  @override
  String get featureHistory => 'Verlauf';

  @override
  String get noPowerData => 'Keine Leistungsdaten';

  @override
  String couldNotScanWifi(String error) {
    return 'WLAN-Suche fehlgeschlagen: $error';
  }

  @override
  String get totalEnergyTitleCase => 'Gesamtenergie';
}

/// The translations for German, as used in Switzerland (`de_CH`).
class AppLocalizationsDeCh extends AppLocalizationsDe {
  AppLocalizationsDeCh() : super('de_CH');

  @override
  String noToggleableDevicesInRoom(String room) {
    return 'Keine schaltbaren Geräte in «$room»';
  }

  @override
  String turnAllInRoomOn(String room) {
    return 'Alle in «$room» einschalten';
  }

  @override
  String turnAllInRoomOff(String room) {
    return 'Alle in «$room» ausschalten';
  }

  @override
  String sceneExecuted(String name) {
    return 'Szene «$name» ausgeführt';
  }

  @override
  String roomChipLongPressHint(String room) {
    return 'Gedrückt halten, um alle in «$room» ein- bzw. auszuschalten';
  }

  @override
  String get apModeSwitchResetStep1 =>
      'Werkseinstellungen wiederherstellen: die «+»-Taste 10–20 s gedrückt halten, bis die LED weiss blinkt.';

  @override
  String get apModeButtonResetStep1 =>
      'Werkseinstellungen wiederherstellen: eine beliebige Taste 10–20 s gedrückt halten, bis die LED abwechselnd weiss/rot blinkt, dann loslassen und innerhalb von 2 s nochmals drücken, um zu bestätigen (die LED blinkt weiss).';

  @override
  String get apModeButtonResetStep2 =>
      'Nach dem Zurücksetzen startet das Gerät im WPS-Modus (weisses Blinken, 2 Min.). Für den AP-Modus die Taste 3 s gedrückt halten — die LED blinkt langsam abwechselnd weiss/rot.';

  @override
  String get apModeBulbResetStep1 =>
      'Werkseinstellungen wiederherstellen: den Strom 5-mal aus- und einschalten, mit ca. 5 s Pause. Nach dem 5. Einschalten blinkt die Lampe 10× weiss.';

  @override
  String get apModeBulbResetStep2 =>
      'Der WPS-Modus läuft 3 Min. (weisses Blinken), danach startet der AP-Modus automatisch und läuft 5 Min.';

  @override
  String get apModeLedWhite =>
      'Weisses Blinken — das Gerät verbindet sich mit der Cloud.';

  @override
  String get softApSelectApIntro =>
      'Versetzen Sie Ihr Gerät in den AP-Modus (siehe Anleitung unten). Wählen Sie es anschliessend aus der Liste aus oder verbinden Sie sich manuell mit seinem WLAN und tippen Sie auf «Ich bin bereits verbunden».';

  @override
  String get softApSelectApIntroManual =>
      'Versetzen Sie Ihr Gerät in den AP-Modus (siehe Anleitung unten). Verbinden Sie sich in den Systemeinstellungen mit seinem WLAN und tippen Sie anschliessend hier auf «Ich bin bereits verbunden».';

  @override
  String get noMyStromApsFound =>
      'Keine myStrom-APs gefunden.\n\n• Stellen Sie sicher, dass sich das Gerät im AP-Modus befindet.\n• Erteilen Sie die Standortberechtigung (Einstellungen → Apps → mystrom_local → Berechtigungen).\n• Schalten Sie den Standort (GPS) in den Systemeinstellungen ein — Android benötigt ihn für WLAN-Scans.\n• Falls Sie bereits mit dem Geräte-AP verbunden sind, tippen Sie unten auf «Ich bin bereits verbunden».';

  @override
  String get deviceRebootingMessage =>
      'Das Gerät startet neu und verbindet sich mit Ihrem WLAN. Es sollte innerhalb einer Minute im Tab «Gefunden» erscheinen.';

  @override
  String get wpsSwitchStep1 =>
      'Die «+»-Taste 3 s gedrückt halten — die LED beginnt langsam weiss zu blinken.';

  @override
  String get wpsButtonWpsModeAuto =>
      'Nach dem Zurücksetzen startet das Gerät automatisch im WPS-Modus (weisses Blinken, 2 Min.).';

  @override
  String get wpsBulbReset =>
      'Werkseinstellungen wiederherstellen: den Strom 5-mal aus- und einschalten, mit ca. 5 s Pause. Nach dem 5. Einschalten blinkt die Lampe 10× weiss.';

  @override
  String get wpsBulbMode =>
      'Der WPS-Modus läuft 3 Min. (weisses Blinken). Drücken Sie in diesem Zeitfenster WPS an Ihrem Router.';

  @override
  String get favoriteSubtitle =>
      'Dieses Gerät auf dem Dashboard unter «Favoriten» anzeigen.';

  @override
  String get stripChannelModeSubtitle =>
      'Farben / Kanäle / Kaltweiss-Warmweiss konfigurieren';

  @override
  String slotActionSaved(String slot, String url) {
    return 'Aktion «$slot» gespeichert: $url';
  }

  @override
  String get pirSettingsSubtitle =>
      'Die Wartezeit (Backoff) ist die Sperrzeit in Sekunden nach einem Bewegungsereignis (1–3600). «LED aktivieren» steuert die Statusanzeige am Gerät.';

  @override
  String get sceneIconDinner => 'Nachtessen';

  @override
  String get wifiSetupPlaceholder =>
      'Um ein Gerät in ein anderes WLAN zu übernehmen, verwenden Sie «Gerät hinzufügen» → «SoftAP».';

  @override
  String get chModeChannelsDesc =>
      '4 unabhängige dimmbare Kanäle (z. B. 4 weisse Streifen)';

  @override
  String get chModeColdWarmDesc =>
      '2 Warmweiss- + 2 Kaltweiss-Kanäle (W+R = warmweiss, G+B = kaltweiss)';

  @override
  String get tabWhites => 'Weisstöne';

  @override
  String get whitesColdWarm => 'Weisstöne (kalt / warm)';

  @override
  String get whites => 'Weisstöne';

  @override
  String whiteIndex(String index) {
    return 'Weiss: $index';
  }

  @override
  String get colorWhite => 'Weiss';
}
