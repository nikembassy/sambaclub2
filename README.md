# Sambaclub

**Sambaclub** is a Flutter UI scaffold for a Bigo-Live-style live-streaming + social
app, themed in **black & gold** (`#0A0A0C` background, `#D4AF37` gold accent).

It is a **source scaffold**: login, a home feed of live rooms with category
filters, a live-room screen with a gradient "video" placeholder, a live chat,
a free-gift tray with a burst animation, a messages list, a profile, and a coin
recharge screen.

## Feature v2

This version brings the scaffold much closer to a Bigo-Live-style feature set.
Everything below is **UI-only / mocked** — there is still no backend.

- **Home a tab segmentati** — Discovery / Party / Seguiti / Nuovi filter the
  room grid, plus a quick-actions row (Match, Moments, Classifica, Ricarica).
- **Match 1:1** — a video-match stub with a pulsing avatar and an "Avvia
  ricerca" button that simulates a ~2 s search and shows "Match con <nome>!".
- **Moments** — a social feed with 4 posts (avatar, text, gradient image block,
  like/comment row).
- **Avvia live** — a "go live" setup screen (title + category chips); the start
  button explains that real streaming needs the backend.
- **PK battles** — an optional PK widget in the live room ("Team Oro" vs
  "Team Rival") toggled from the ⚔️ header button; scores rise as gifts are
  sent.
- **Contributors** — a top-3 gift-sender row in the live room (👑 🥈 🥉).
- **Treasure box** — a 🎁 button in the live room that grants a mock coin reward.
- **Gift tiers** — Gratis / Popolari / Lusso / Leggendari, from a 1-coin Rosa
  up to the Drago (🐉 59 999) and the legendary Drago Supremo (🐲 520 000) and
  Olimpo (🏛️ 999 999).
- **Combo x10 / x88 / x520** — a quantity selector in the gift tray (with a
  "x88 COMBO!" badge) and a combo overlay in the live room when qty > 1.
- **Party rooms a 9 posti** — a 3×3 seat grid (👑 host, 🎙️ members, ➕ "Libero"
  seats) with live chat, input and gifts.
- **Classifiche** — "Top Host" / "Top Fans" tabs with medals and coin totals.

## Media

Real, device-local media features (still no backend / no upload):

- **Profile photo** — `image_picker` (`ImageSource.gallery`). The profile header
  renders the chosen picture with `CircleAvatar(backgroundImage: FileImage(...))`
  and falls back to the emoji avatar when no photo is set. Tap the avatar or the
  **"Cambia foto profilo"** tile to pick one; a SnackBar confirms the update.
- **Audio messages** — pick an existing clip with `file_picker`
  (`FileType.audio`) from the 📎 button, or record a voice note with `record`
  from the 🎤 button. Files are written to the app documents directory via
  `path_provider`. The 🎤 button turns **red** while recording; tap it again to
  stop and send.
- **Playback** — audio bubbles render a ▶️ play button + duration label, and
  tapping plays the file with `just_audio`.
- **Permissions** — requested at runtime with `permission_handler`
  (`Permission.microphone` before recording). All plugin calls in
  `lib/services/media_service.dart` are wrapped in `try/catch` and fail safe:
  they return `null` / do nothing instead of throwing, so the UI can also be
  exercised on a desktop/web target where a plugin is unavailable.

Everything is stored locally on the device: this scaffold does **not** upload
the photo or the audio anywhere.

### Platform permissions to add

The `lib/` code is complete, but the generated platform projects need the usual
manifest entries. Add them after `flutter create` (see below).

**Android — `android/app/src/main/AndroidManifest.xml` (`<manifest>` root):**

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- Android 12 and below -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**iOS — `ios/Runner/Info.plist`:**

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sambaclub usa il microfono per registrare messaggi vocali.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Sambaclub accede alla galleria per scegliere la foto profilo.</string>
```

Then fetch the new packages:

```bash
flutter pub get
```

## What is real vs. mocked

- **Mocked / UI-only:** authentication (`AuthService`), the discovery room grid
  and chats (`mock_data.dart`), conversations, matchmaking and moments. There is
  no persistence for them.
- **Live streaming is REAL (WebRTC):** the host publishes camera + mic and the
  viewers receive the stream, with chat, gifts, PK, viewer count and room
  lifecycle driven by the Sambaclub signaling server over `ws://…:8000/ws`
  (`LiveService` + `WebRtcService`). See **"APK con live vera"** below.
- **Media is real but local:** gallery photo picking, audio-file picking, voice
  recording and audio playback use the device plugins listed above; nothing is
  uploaded and the paths are not persisted across app restarts.
- **No network images:** covers are CSS-like `LinearGradient` placeholders plus
  emoji. Nothing is fetched from the internet.
- **Payments are intentionally disabled stubs:** `PayPalGateway` and
  `GooglePlayGateway` both return `PurchaseResult.notAvailable('Presto disponibile')`.
  The recharge screen shows the buttons **disabled**. In this phase **all coins
  are free** (`FreeCoinService`): a starting balance on login plus a free daily
  bonus.
- Coins are the in-app currency used to send gifts.

## Requirements

- **Flutter SDK 3.x** (Dart 3, `sdk: ">=3.0.0 <4.0.0"`).
- Android/iOS toolchain for device builds (Android Studio / Xcode).

## Dependencies

- `provider: ^6.1.0` (state management — `AppState` is a `ChangeNotifier`).
- `image_picker: ^1.1.2` (profile photo from the gallery).
- `file_picker: ^8.1.2` (pick an existing audio file).
- `record: ^5.1.2` (in-app voice recording).
- `just_audio: ^0.9.40` (audio playback).
- `path_provider: ^2.1.4` (writable directory for recordings).
- `permission_handler: ^11.3.1` (runtime mic / media permissions).
- `web_socket_channel: ^2.4.5` (JSON signaling frames over the websocket).
- `flutter_webrtc: ^0.11.7` (camera/mic capture + `RTCPeerConnection`).
- dev: `flutter_test`, `flutter_lints: ^4.0.0`.

## Create the project and run it

The `lib/` folder and `pubspec.yaml` in this scaffold are meant to be dropped
into a folder generated by `flutter create`.

```bash
# 1. Generate the platform scaffolding in an EMPTY folder
mkdir sambaclub && cd sambaclub
flutter create --project-name sambaclub .

# 2. Copy in the source from this scaffold
#    - replace the generated pubspec.yaml with this one
#    - replace the generated lib/ with this scaffold's lib/
cp -r /path/to/sambaclub_flutter/lib ./lib
cp /path/to/sambaclub_flutter/pubspec.yaml ./pubspec.yaml

# 3. Fetch packages (required after adding the media deps)
flutter pub get

# 4. Run (choose a device)
flutter run

# 5. Release APK
flutter build apk --release
```

> Note: `flutter create --project-name sambaclub .` needs the target directory to
> already exist and, ideally, be empty (it will refuse or merge into a folder
> that already has a project). Create it first, then copy `lib/` and
> `pubspec.yaml` over the generated files.

## Project layout

```
lib/
  main.dart                     # runApp + MultiProvider + MaterialApp (AppTheme.dark)
  theme/app_theme.dart          # AppColors design tokens + AppTheme.dark
  models/                       # AppUser, LiveRoom (+ RoomType), Gift (+ GiftTier/GiftOrder),
                                # ChatMessage (+ ChatMessageType text/audio, audioPath/durationSeconds)
  data/mock_data.dart           # 12 live rooms + 3 party rooms across 5 categories + chat lines
  state/app_state.dart          # ChangeNotifier: auth, coins, chat, audio messages,
                                # profile photo, gifts (+bundles), contributors, PK, follows
  services/
    auth_service.dart           # mock auth
    free_coin_service.dart      # starting + daily free coins
    media_service.dart          # image_picker / file_picker / record / just_audio wrappers
    live_service.dart           # WebSocket client for the signaling server (rooms/chat/gifts/PK/signals)
    webrtc_service.dart         # flutter_webrtc: local capture, per-peer RTCPeerConnection, offer/answer/ICE
    payments/                   # PaymentGateway + CoinPack + PurchaseResult (+ stubs)
  screens/                      # login, home, live room, party room, match, moments,
                                # go live, rank, messages, profile, recharge
  widgets/                      # room_card, gift_tray, live_chat
```

## Enabling real payments later

`lib/services/payments/paypal_gateway.dart` and
`lib/services/payments/google_play_gateway.dart` contain `TODO(payments)` notes
describing the required SDKs, backend order creation/capture, server-side
verification and Play Console SKUs. Until those are implemented, both gateways
keep returning `PurchaseResult.notAvailable('Presto disponibile')` and the
recharge buttons stay disabled.

## APK con live vera

Questo scaffold ora parla **davvero** con il server di segnalazione Sambaclub
(`ws://HOST:8000/ws`) e usa **WebRTC** per video/audio: l'host pubblica camera e
microfono, gli spettatori ricevono lo stream, e chat/regali/PK/numero
spettatori/ciclo di vita della stanza passano dal server.

### 1. Permessi Android

Aggiungi questi permessi in `android/app/src/main/AndroidManifest.xml`, come
figli diretti del nodo `<manifest>` (prima di `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

- `CAMERA` + `RECORD_AUDIO` servono per pubblicare la live (richiesti a runtime
  da `permission_handler` in `WebRtcService.startLocalMedia`).
- `INTERNET` è necessario per il websocket e per WebRTC/STUN.
- `MODIFY_AUDIO_SETTINGS` serve all'audio di WebRTC.
- `BLUETOOTH` / `BLUETOOTH_CONNECT` servono per gli auricolari/route audio
  (su Android 12+ `BLUETOOTH_CONNECT` è un permesso runtime).

### 2. Traffico in chiaro (`ws://` e `http://`)

Il server locale usa `ws://` (non cifrato) e **Android blocca il cleartext di
default** (API 28+). Abilitalo aggiungendo l'attributo
`android:usesCleartextTraffic="true"` al nodo `<application>` della stessa
AndroidManifest:

```xml
<application
    android:usesCleartextTraffic="true"
    android:label="sambaclub"
    android:icon="@mipmap/ic_launcher">
    ...
</application>
```

In alternativa (più pulito) crea
`android/app/src/main/res/xml/network_security_config.xml` con
`<domain-config cleartextTrafficPermitted="true">` per l'IP del server e
referenzialo con `android:networkSecurityConfig="@xml/network_security_config"`.

### 3. Server URL nell'app

Nel login c'è il campo **"Server di segnalazione"** (default
`ws://10.0.2.2:8000/ws`, che è l'host visto dall'**emulatore Android**).

- Emulatore Android → `ws://10.0.2.2:8000/ws`
- Telefono reale → `ws://<IP-del-PC-nella-stessa-rete>:8000/ws`
  (es. `ws://192.168.1.10:8000/ws`)

Se la connessione fallisce, il login mostra un errore chiaro e **non** entra
nella home.

### 4. Build dell'APK

```bash
flutter pub get
flutter build apk --release
```

Il file prodotto è `build/app/outputs/flutter-apk/app-release.apk`. Per
installarlo: `flutter install` oppure copia l'APK sul telefono e aprilo
(serve "Installa app sconosciute").

### 5. Requisito di rete importante

**Entrambi i telefoni devono raggiungere lo stesso server in esecuzione**: il
server di segnalazione deve girare sulla stessa macchina/rete e ascoltare su
`0.0.0.0:8000` (non `127.0.0.1`), e il firewall del PC deve permettere la porta
`8000`. Host e spettatore devono puntare **allo stesso** `ws://HOST:8000/ws`,
altrimenti non si vedono. Lo STUN usato è
`stun:stun.l.google.com:19302` (richiede internet); per reti complesse serve un
TURN server.

> Nota: la pubblicazione live è **mobile-only** (camera/mic via `flutter_webrtc`).
> Su desktop/web il client si connette al server ma `getUserMedia` può non essere
> disponibile.
