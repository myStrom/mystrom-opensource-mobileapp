# myStrom Local

Flutter/Dart mobile app for **local** control of myStrom IoT devices (no cloud).

## Features

- **UDP device discovery** (port 7979, 13-byte broadcast packets)
- **Discovered-device status** — the app shows a simple "Locked" badge when a device is not yet reachable over HTTP (e.g. HTTP disabled for security); no extra text is shown when everything is reachable.
- **Local database** (Hive) — devices persist across sessions
- **Custom device names & colors** — when adding a device you can override the default name and pick a color that appears on the device card.
- **Favorite flag & categories** — mark devices as favorite and filter the dashboard by All / Favorite / room. Long-press a room chip to turn all toggleable, non-locked devices in that room on or off.
- **Scenes** — create named bundles of device actions (e.g. "Arrive Home", "Good Night"). Each scene has an icon, color, and a list of device actions (on/off/toggle). Run a scene to execute all actions at once. Devices are picked from the already-added list. Tap a scene chip to run it, long-press to edit (name, icon, color, actions).
- **Device identification** — currently **disabled** globally (`DeviceType.identifyEnabled = false`). The capability code stays in place; flip the flag to `true` to re-enable the "Identify" button on discovered-device cards and in device settings.
- **REST API control** on port 80 for all device types:
  - WS2 / WSE / WSX / LCS — relay, power, temperature (shown on the device card even when the relay is off), timer
  - WRS — RGBW LED strip, color picker, effects, ramp, timer
  - WLL — dimmer (0-100, ramp), timer
  - Bulb — color, brightness, ramp, timer
  - WMS — PIR motion/light/temperature
  - BP2 / BM1 / Button — action URL configuration
- **Lockable devices** — mark a device as locked (e.g. a fridge) to disable its on/off toggle everywhere (dashboard card, detail page, scenes, room bulk-toggle). The card turns yellow and the power button shows a lock icon. Timers and scheduler are still allowed.
- **Total power** — the dashboard shows the total current power draw (W) for the selected category (All / Favorite / a room), aggregating the `power` field reported by each device.
- **Temperature offset** — devices with a temperature sensor (WS2, WSE, WSX, WMS, BP2, BP1, BM1) expose a ±30 °C offset slider in Settings (one decimal). The offset is applied to the raw reading everywhere temperature is shown (cards, detail pages, sensors).
- **Total energy** — the dashboard summary card shows the accumulated total energy (kWh) for the selected category (All / Favorite / room) on top of the total power.
- **Scene timer actions** — scenes support two kinds of actions: a toggle action (on/off/toggle, as before) and a timer action (set a timer that switches the device on/off/toggle after a duration). Timer actions are added via the "Add timer action" button in the scene editor and stored as `action: 'timer'` with `timerMode` + `timerSeconds` (SceneAction HiveField 4-5, null for legacy actions).
- **Null-safe device info** — the settings page only shows info lines (`/info`) whose values are present; missing fields are omitted instead of showing empty values.
- **Scheduler** (firmware >= 5.0.0; WS2, WSE, WRS, WMS, WSX, WLL) — timed `on`/`off`/`toggle` actions per weekday. Entry is unified: a big round Scheduler tile on each detail page (Switch, Strip, Dimmer) plus a Scheduler tile in the device settings page. Variant-aware: color (WRS), ramp (WRS + WLL), value (WLL). Schedule times are stored as UTC on the device; the UI converts to/from local time automatically. Settings stays as a small icon in the AppBar.- **WiFi provisioning (SoftAP)** — full AP-mode wizard: scan host WiFi for myStrom APs by SSID prefix, join the AP, probe `/api/v1/info` to confirm type/MAC, scan home networks via `GET /api/v1/scan` (flat SSID/RSSI array, retry up to 15 s), enter SSID/password (+ advanced: static IP/mask/gateway/DNS, roaming, device name), `POST /api/v1/connect` with legacy-firmware fallback (400 → retry without `roaming`), then add the device to the list. Dropped connect responses (AP shuts down before 200) are treated as success.
- **WPS provisioning** — instructions + `POST /api/v1/wps`
- **Action URL builder** — pick target device + action, URL generated automatically

## Architecture

Clean architecture in three layers:

```
lib/
  core/          # config, network (UDP + HTTP), error, utils (DeviceType)
  data/          # models, datasources (Hive + dio), repositories
  domain/        # entities, use cases
  presentation/  # pages, widgets, providers (ChangeNotifier + Provider)
```

## Device types

| Code | Model | Name |
|------|-------|------|
| 106 | WS2 | WiFi Switch CH |
| 107 | WSE | WiFi Switch EU |
| 122 | WSX | WiFi Switch X |
| 105 | WRS | WiFi Strip |
| 113 | WLL | WiFi Cube (Dimmer) |
| 110 | WMS | WiFi PIR |
| 118 | BP2 | WiFi Button Plus 2 |
| 121 | BM1 | WiFi Button Max |
| 102 | Bulb | WiFi Bulb |
| 104 | LCS | WiFi Switch |
| 101 | Button | WiFi Button |

## Getting started

### Prerequisites

- Flutter 3.x / Dart 3.x
- Android or iOS device on the same WiFi as the myStrom devices

### Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # regenerate Hive adapters
flutter run
```

### Build

```bash
flutter build apk --release    # Android
flutter build ios --release     # iOS (requires Xcode)
flutter build windows --release # Windows
```

## Configuration

- UDP discovery port: **7979** (see `lib/core/config/app_config.dart`)
- Device HTTP port: **80**
- SoftAP default IP: **192.168.254.1**
- HTTP timeout: 10 s (devices on LAN) / 30 s (provisioning) / 5 s (`/info` probe in AP mode)
- WiFi scan retry: up to 15 s (device scan takes ~5 s)
- Offline threshold: 30 s

### AP SSID prefixes

The wizard recognises myStrom device APs by SSID prefix (`lib/core/utils/ap_ssid.dart`):

| Prefix           | Type          |
|------------------|---------------|
| `my-bulb-`       | Bulb (WRB)    |
| `my-button-`     | Button (WBS/WBP) |
| `my-switch-`     | LCS           |
| `my-pir-`        | PIR (WMS)     |
| `my-cube-lamp-`  | Cube (WLL)    |
| `my-strip-`      | Strip (WRS)   |
| `my-bp2-`        | BP2           |
| `my-bm1-`        | BM1           |
| `my-`            | WS2/WSE/WSX (generic; confirmed via `/info`) |

## Dependencies

- `dio` — HTTP client
- `hive` / `hive_flutter` — local NoSQL database
- `provider` — state management
- `uuid` — UUID generation
- `path_provider` — Hive storage path

## Permissions

### Android

- `INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`
- `CHANGE_WIFI_MULTICAST_STATE` (UDP broadcast reception)
- `CHANGE_WIFI_STATE` (provisioning)

### iOS

- Local network access (Bonjour / NSLocalNetworkUsageDescription)

## Notes

- All communication is local HTTP (no HTTPS on LAN).
- Battery-powered buttons (BP2, BM1, Button) may sleep and not broadcast UDP continuously.
- Strip/dimmer/bulb POST endpoints use URL-encoded form bodies, not JSON.
- A fake `Origin` header is sent to satisfy firmware CORS checks.

## App icon

The launcher icon is generated from `assets/icon.png` (1024×1024) via the
`flutter_launcher_icons` package. To regenerate after changing the source:

```bash
dart run flutter_launcher_icons
```

## Tests

### Smoke integration test (UI)

`integration_test/smoke_test.dart` drives the real Flutter app on Windows
desktop with an isolated Hive store (temp dir) and a silent UDP discovery
service (no socket binding). It walks the main screens to make sure nothing
crashes:

- dashboard empty state + Add Device page (tabs: Discovered / SoftAP / WPS)
- scene editor: open, fill name, save, reopen via long-press, delete

Run on Windows desktop:

```bash
flutter test integration_test/smoke_test.dart -d windows
```

Key widgets are tagged with stable `Key`s (`appbar_add_device`,
`scene_add_button`, `scene_name_field`, `scene_save_fab`,
`scene_delete_button`, `tab_discovered`, `tab_softap`, `tab_wps`,
`add_device_back_button`, `detail_back_button`, `detail_settings_button`,
`settings_name_field`, `settings_room_field`, `settings_favorite_switch`,
`settings_lockable_switch`, `settings_save_fab`, `settings_back_button`,
`device_card_<mac>`, `empty_state`, `switch_power_card`,
`detail_timer_tile`, `detail_scheduler_tile`, `timer_set_button`,
`card_power_button`, `card_favorite_star`, `strip_on_switch`,
`strip_settings_button`, `dimmer_on_switch`, `dimmer_value_slider`,
`dimmer_ramp_slider`, `bulb_on_switch`, `bulb_settings_button`,
`pir_scheduler_button`, `lcs_action_url_field`, `lcs_save_url_button`,
`scheduler_hour_field`, `scheduler_minute_field`, `scheduler_add_button`,
`schedule_clock` (AnalogTimePicker), `schedule_action_chip_on/off/toggle`,
`schedule_day_chip_0..6`, `schedule_color/ramp/value_field`,
`schedule_add_button` (AddSchedulePage FAB), `add_schedule_back_button`,
`scheduler_save_fab`, `scheduler_back_button`, `scheduler_settings_button`,
`scheduler_discard_cancel`, `scheduler_discard_confirm`,
`settings_remove_button`, `settings_color_palette`,
`settings_strip_settings_tile`, `lcs_action_tile` (LCS button action in settings),
`settings_identify_tile`, `identify_<mac>` (discovered-device card),
`scene_discard_cancel`, `scene_discard_confirm`,
`strip_chmode_<mode>`, `strip_settings_back_button`,
`button_scheme_<scheme>`, `button_settings_button`,
`strip_tab_color/whites/wrgb`, `strip_wrgb_white/red/green/blue`,
`strip_whites_white`, `strip_whites_brightness`, `strip_channel_1-4`,
`strip_warm`, `strip_cold`, `bulb_tab_color/whites/wrgb`,
`bulb_wrgb_white/red/green/blue`, `bulb_whites_white`,
`bulb_whites_brightness`, `bulb_ramp_slider`, `timer_mode_dropdown`,
`scene_action_device_dropdown`,
`scene_action_chip_on/off/toggle`, `scene_action_add_button`,
`scene_action_cancel`) so the tests do
not depend on copy that may change.

### Control integration test (E2E against a fake device)

`integration_test/control_test.dart` drives the real Flutter app against
a local fake myStrom HTTP server (`integration_test/fake_mystrom_server.dart`,
one `HttpServer` per device on `127.0.0.1`). No real hardware is needed.
The fake server emulates the REST endpoints used by the UI — `/info`,
`/report`, `/relay`, `/toggle`, `/timer`, `/api/v1/device`,
`/api/v1/device/self`, `/api/v1/ch_mode`, `/api/v1/ch_mode/<mode>`,
`/api/v1/scheduler`, `/api/v1/sensors`, `/api/v1/action/button`,
`/api/v1/actions` and `/api/v1/action` — and keeps per-device
state in memory (relay, on, color, ramp, dimmer value, timer, scheduler,
LCS button action URL, button action map, button-se action body).

The test seeds the Hive store with two devices (a WSE switch and a WRS
strip) pointing at the fake servers, then exercises:

- switch toggle (ON → OFF) from the detail page power card
- strip turn ON, recolor (HSV POST), turn OFF
- device settings: rename, assign room, toggle favorite, save (verified
  against the Hive store)
- scheduler: add an entry, save (verified against the fake server state)
- scene editor: name a scene, save
- final assertion: every fake device is OFF after the suite

Run on Windows desktop:

```bash
flutter test integration_test/control_test.dart -d windows
```

### Per-device-type integration test

`integration_test/devices_test.dart` runs one test per supported device
type against the fake server, each seeding its own device + server and
cleaning up afterwards:

| Type | Test |
|------|------|
| WS2, WSE, WSX (switch) | toggle relay ON → OFF via the power card |
| LCS (switch + button) | toggle relay + set & save the LCS button action URL |
| WRS (strip) | turn ON, recolor (HSV), turn OFF |
| WLL (dimmer) | turn ON, drag brightness slider 0–100, drag ramp 0–15 s, turn OFF |
| Bulb | turn ON, recolor, turn OFF |
| WMS (PIR) | open the detail page (motion/light/temperature) — smoke |
| Switch timer | open the timer bottom sheet, set minutes, POST `/timer?mode=&time=` |
| Favorite | tap the star on a card, verify Hive `favorite=true`, filter by "Favorite" category |

Run on Windows desktop:

```bash
flutter test integration_test/devices_test.dart -d windows
```

### Settings & dialog integration test

`integration_test/settings_test.dart` covers the remaining UI flows:

- device removal from settings (verified against Hive + dashboard)
- color palette selection persists `colorValue` on save
- scheduler discard-changes dialog (Cancel keeps edits, Confirm discards)
- scene editor discard-changes dialog (Cancel keeps edits, Confirm discards)
- strip channel-mode page (`StripSettingsPage`): switch colors ↔ channels, POST `/api/v1/ch_mode/<mode>`
- button detail page: action URL schemes list + `ActionUrlPicker` dialog open (smoke)

```bash
flutter test integration_test/settings_test.dart -d windows
```

### Sliders, tabs & dropdowns integration test

`integration_test/sliders_test.dart` covers the remaining interactive
controls:

- strip **WRGB sliders** (0-255) → color POST on release
- strip **whites sliders** (white 1-18 + brightness 0-100) → mono color POST
- strip **ramp slider** stays within 0-15000 ms (0–15 s, shown with one decimal)
- bulb **WRGB sliders** + **whites sliders**
- **timer mode dropdown** (none/on/off/toggle) changes the posted mode
- **scheduler action dropdown** (on/off/toggle) changes the saved action
- **scene editor action picker**: device dropdown + action chips + Add

```bash
flutter test integration_test/sliders_test.dart -d windows
```

Note: run each integration test file separately — the Windows desktop
runner does not always restart cleanly between files in one invocation.

Note: the seeded devices use `lastSeen = now`; the `touchLastSeen()`
helper refreshes it before tests that rely on the dashboard card power
button (the app hides the toggle when a device is considered offline,
i.e. `lastSeen` more than 30s ago).

### Data-layer integration script

`test/integration_test.dart` is a plain `dart run` script (NOT a Flutter
`integration_test`) that exercises the device REST API for every device
stored in Hive:

```bash
dart run test/integration_test.dart
```

This updates Android (mipmap + adaptive), iOS (AppIcon) and Windows (`app_icon.ico`).