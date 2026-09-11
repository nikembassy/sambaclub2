# GUIDA — Fare l'APK su GitHub (click per click)

Non serve installare nulla. Tempo: ~5 minuti + la compilazione.
Devi avere: un PC, un browser, e l'email per l'account.

---

## PASSO 1 — Crea l'account (una volta sola)
1. Vai su **https://github.com**
2. Clicca **Sign up** (in alto a destra)
3. Inserisci email, password, un nome utente -> conferma l'email
   (GitHub ti manda un codice: copialo e incollalo)

## PASSO 2 — Crea il repository
1. Clicca il **+** in alto a destra -> **New repository**
2. **Repository name:** `sambaclub`
3. Lascia **Public** (o metti **Private**, va bene lo stesso)
4. Clicca **Create repository**

## PASSO 3 — Carica il progetto
1. **Prima estrai** il file `SAMBACLUB_APP.zip` sul PC
   (tasto destro -> Estrai tutto). Dentro trovi: `lib`, `.github`, `pubspec.yaml`, `README.md`, `BUILD_APK.md`
2. Nella pagina del repository clicca **Add file** -> **Upload files**
3. **Trascina dentro il CONTENUTO** della cartella estratta (i file e le cartelle, non la cartella che li contiene)
4. In fondo clicca **Commit changes**

> Se non riesci a caricare la cartella `.github` (a volte il browser non la prende):
> 1. clicca **Add file** -> **Create new file**
> 2. nel nome scrivi esattamente:  `.github/workflows/build-apk.yml`
> 3. incolla il contenuto di quel file (lo trovi dentro il tuo ZIP)
> 4. **Commit changes**

## PASSO 4 — Avvia la compilazione
1. Vai sulla scheda **Actions** (in alto)
2. Se compare un pulsante verde **"I understand my workflows, go ahead and enable them"**, cliccalo
3. A sinistra clicca **Build APK** -> a destra **Run workflow** -> **Run workflow**
4. Attendi ~5 minuti: comparirà un pallino giallo, poi una **spunta verde** ✅

## PASSO 5 — Scarica l'APK
1. Clicca sulla riga dell'esecuzione (quella con la spunta verde)
2. Scorri **in fondo alla pagina** fino a **Artifacts**
3. Clicca **sambaclub-apk** -> scarica lo ZIP
4. Dentro c'è **`app-release.apk`**

## PASSO 6 — Installalo sul telefono
1. Passa `app-release.apk` sul telefono (cavo, email, WhatsApp a te stesso, Google Drive...)
2. Aprilo dal telefono -> Android dirà di consentire le **"origini sconosciute"**
   -> vai in Impostazioni e consenti per l'app che stai usando (File/Chrome)
3. Installalo. Fine.

---

## Perché la live funzioni (importante)
L'APK si collega al **server** `sambaclub_server.py`. Senza server, l'app si apre ma
l'elenco delle live è vuoto.

1. Sul PC: apri la cartella di `SAMBACLUB_LIVE.zip` (estratto) e lancia
   `python sambaclub_server.py` (serve Python installato)
2. La finestra nera mostra un indirizzo tipo:  `http://192.168.1.10:8000`
3. Nell'app, alla schermata di accesso, scrivi nel campo server:
   - telefono reale sulla stessa Wi-Fi:  `ws://192.168.1.10:8000/ws`
   - emulatore Android:  `ws://10.0.2.2:8000/ws`
4. **Vai in Live** sul primo telefono -> il secondo apre l'app, vede la live e la guarda.

> Per collegarsi da fuori casa serve un indirizzo **HTTPS** (tunnel o hosting).
> Dettagli in `README_SAMBACLUB_LIVE.md`.

---

## Se la build diventa ROSSA (❌)
Clicca sull'esecuzione fallita -> clicca lo step diventato rosso -> copia le ultime
righe di log e mandamele: sistemo il punto preciso.
