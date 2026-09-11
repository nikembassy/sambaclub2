# Fare l'APK di Sambaclub (con la live vera)

> **Nota onesta:** l'APK **non** si può generare dentro l'assistente (ambienti solo Python, senza Flutter/Android SDK).
> Ma ci sono **due strade**, e la prima **non richiede installare nulla** sul PC.

---

## ✅ Strada A — GitHub (consigliata, niente installazioni)

GitHub compila l'APK **nei suoi server** e te lo fa scaricare.

1. Crea un account gratis su **https://github.com** (se non ce l'hai).
2. Crea un nuovo repository: **New repository** → nome `sambaclub` → **Create**.
3. **Carica i file**: nella pagina del repo clicca **Add file → Upload files** e trascina **tutto il contenuto della cartella** `sambaclub_flutter` (le cartelle `lib`, `.github`, e i file `pubspec.yaml`, `README.md`).
   - In alternativa, dal browser si trascina l'intera cartella.
4. Vai sulla scheda **Actions** → a sinistra scegli **Build APK** → pulsante **Run workflow** → **Run workflow**.
5. Aspetta ~4–6 minuti (pallino giallo → **spunta verde ✅**).
6. Apri l'esecuzione finita → in fondo, **Artifacts** → scarica **`sambaclub-apk`** (è uno ZIP che contiene `app-release.apk`).
7. Passa l'`app-release.apk` sul telefono e installalo. Android chiederà di **consentire l'installazione da origini sconosciute** (Impostazioni → Sicurezza).

Il workflow già incluso (`/.github/workflows/build-apk.yml`) **aggiunge da solo** i permessi di camera/microfono e il permesso di rete.

---

## 🧰 Strada B — Flutter sul PC (se preferisci)

1. Installa **Flutter SDK 3.x**: https://docs.flutter.dev/get-started/install
2. Da terminale, nella cartella del progetto:
   ```bash
   flutter create --project-name sambaclub --platforms android .
   flutter pub get
   flutter build apk --release
   ```
3. L'APK è in: `build/app/outputs/flutter-apk/app-release.apk`
4. Permessi Android: apri `android/app/src/main/AndroidManifest.xml` e aggiungi dentro `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   ```
   e sull'elemento `<application ...>` aggiungi `android:usesCleartextTraffic="true"` (serve per collegarsi al server `ws://` sulla rete locale).

---

## 🔴 Perché la live funzioni, il server deve essere acceso

L'APK **si collega al server** `sambaclub_server.py`. Senza server, l'app parte ma **l'elenco live è vuoto**.

1. Sul PC: `python sambaclub_server.py` (vedi `LEGGIMI.txt`).
2. Nell'app, alla schermata di accesso, scrivi l'indirizzo del server:
   - **Emulatore Android:** `ws://10.0.2.2:8000/ws`
   - **Telefono reale, stessa Wi-Fi del PC:** `ws://IP_DEL_PC:8000/ws` (es. `ws://192.168.1.10:8000/ws`)
   - **Su internet:** `wss://tuo-indirizzo/ws` (serve HTTPS per camera/microfono)
3. **Vai in Live** sul primo telefono → il secondo telefono apre l'app, vede la live nell'elenco e la guarda.

> ⚠️ Due telefoni sulla **stessa Wi-Fi** funzionano subito con `ws://192.168...`. Su reti diverse serve un indirizzo **HTTPS** (tunnel o deploy).

---

## 📌 Cose da sapere

- L'APK generato è **firmato con la chiave di debug**: perfetto per provarlo, **non** per pubblicarlo su Google Play (per lo store serve una firma release dedicata).
- Il video è **uno trasmette → molti guardano**. Per far **parlare tutti insieme** (party a 9 voci) serve un **SFU** (LiveKit/Agora): è il passo successivo.
- Pagamenti (PayPal / Google Play) restano **disattivati** (stub).
