# Build del .ipa para App Store — guía rápida (iOS)

Compañera de [`BUILD_AAB.md`](BUILD_AAB.md). Esta guía es para compilar el
`.ipa` firmado en un **Mac** y subirlo a App Store Connect.

> ⚠️ La compilación NO se puede hacer en Windows. iOS exige un Mac con
> Xcode + cuenta Apple Developer del equipo Salufit + provisioning
> profile de distribución instalado en el Keychain.

---

## 1. Requisitos en el Mac (una sola vez)

```bash
# Xcode 15+ desde la Mac App Store
# Aceptar la licencia tras instalar:
sudo xcodebuild -license accept

# CocoaPods
brew install cocoapods

# Flutter (si no lo tienes)
brew install --cask flutter
flutter --version       # 3.41.7+ recomendado
flutter doctor          # debe estar todo verde menos Chrome
```

Y verifica que la cuenta Apple Developer del equipo Salufit está
firmada en Xcode:

```
Xcode → Settings → Accounts → tu Apple ID con membresía Salufit
```

---

## 2. Clonar el proyecto

```bash
git clone https://github.com/centrosalufit-beep/salufit_app_3_dic.git
cd salufit_app_3_dic
git checkout feat/admin-windows-bot

# Verifica que estás en el commit correcto:
git log --oneline -1
# Debería mostrar: 7b22fc2 (o más reciente) bump 2.0.9+141
```

---

## 3. Poner los archivos sensibles que NO están en git

### 3.1 GoogleService-Info.plist (Firebase iOS)

1. https://console.firebase.google.com/project/salufitnewapp/settings/general
2. Sección "Tus apps" → app iOS de Salufit → descarga `GoogleService-Info.plist`.
3. Cópialo a:

```bash
cp ~/Downloads/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
```

⚠️ **NO** lo subas a git. El `.gitignore` debería excluirlo; si no, añade:

```
echo "ios/Runner/GoogleService-Info.plist" >> .gitignore
```

### 3.2 Certificados y provisioning (si Xcode no los tiene)

Si la cuenta Apple Developer ya está enlazada y "Automatically manage
signing" está activado, Xcode los gestiona solo. Si no, importa el
`.p12` y el `.mobileprovision` desde otro Mac vía Keychain Access.

---

## 4. Verificar versión y build number

`pubspec.yaml` está en:

```yaml
version: 2.0.9+141
```

iOS lleva su **propia secuencia de build numbers** en App Store Connect,
independiente de Android. Antes de compilar:

1. Entra a https://appstoreconnect.apple.com → Salufit iOS → última build.
2. Si el último build subido es **menor que 141** → 141 se acepta, no
   tocar `pubspec.yaml`.
3. Si el último es **mayor o igual que 141** (porque alguna vez subiste
   builds iOS independientes), edita temporalmente:

```yaml
version: 2.0.9+250    # cualquier número mayor que el último iOS subido
```

⚠️ Si modificas eso para iOS, **NO lo commitees** — rompería la
numeración Android. Tras el upload puedes revertir con `git checkout
pubspec.yaml`.

Alternativa más limpia (avanzada): pasar `--build-number` al comando
de build sin tocar `pubspec.yaml`:

```bash
flutter build ipa --release --build-number=250
```

---

## 5. Preparar el entorno

```bash
flutter pub get

cd ios
pod install --repo-update
cd ..

dart run build_runner build --delete-conflicting-outputs
flutter analyze     # debe dar "No issues found!"
```

Si `flutter analyze` da errores, **NO lances el build** — repórtalos
y se arreglan antes (mismo principio que `BUILD_AAB.md`).

---

## 6. Compilar el `.ipa`

```bash
flutter build ipa --release
```

Sale por consola algo como:

```
Running Xcode build...
Built /Users/.../build/ios/ipa/salufit_app.ipa.
```

Archivo final:

```
build/ios/ipa/salufit_app.ipa
```

---

## 7. Subir a App Store Connect

### Opción A — Transporter (recomendada)

Es la app oficial de Apple, gratis en la Mac App Store.

1. Abre Transporter.
2. Sign in con la Apple ID del equipo Salufit.
3. Arrastra `build/ios/ipa/salufit_app.ipa` a la ventana.
4. Click **DELIVER**.

Subida tarda 5-15 min (depende de la red). Apple procesa el binario
otros 10-30 min antes de que aparezca como "Build disponible" en App
Store Connect.

### Opción B — Xcode Organizer

```bash
open ios/Runner.xcworkspace
# En Xcode: Product → Archive → Window → Organizer
# → Distribute App → App Store Connect → Upload
```

---

## 8. Crear release en App Store Connect

1. https://appstoreconnect.apple.com → **Salufit iOS** → pestaña **App Store**.
2. Click "**+** Versión" si no la tienes ya creada → introduce `2.0.9`.
3. Sección "Build" → click el "**+**" → selecciona la build recién
   procesada (puede tardar unos minutos en aparecer; refresca).
4. **What's New in This Version** (copia/pega las mismas notas que
   pegaste en Play Console):

```
- Hub de inicio en Windows con tarjetas por feature.
- Filtro de visibilidad por rol: profesionales solo ven lo que necesitan.
- Activación funcional en Windows (HTTP fallback a Cloud Functions).
- Login muestra errores visibles (contraseña errónea, sin red, etc.).
- Pantalla de error explícita si el perfil no se resuelve.
- QR walkin con anti-doble-consumo (5 min).
- Lista de apuntados a clase visible para profesional/admin (mobile).
- Bot WhatsApp: panel arranca con filtro "Solo activas" por defecto.
- Tipografía y colores uniformes en pantallas admin.
- Correcciones varias de UI y rendimiento.
```

5. **App Privacy** y **Encryption Compliance**: si Apple los marca,
   responde como en versiones anteriores (suele heredarse).
6. **Send for Review**.

Apple tarda 24-48 h habitualmente en revisar. Si rechaza, te llega
correo con motivo.

---

## 9. Errores comunes

### `No valid 'iphoneos' provisioning profiles found`

Bundle ID o equipo mal configurado. Abre `ios/Runner.xcworkspace` →
target Runner → "Signing & Capabilities":
- Team: Salufit (Apple Developer).
- Bundle Identifier: `com.salufit.app`.
- "Automatically manage signing": ✓.

Si sigue fallando, en Xcode → Settings → Accounts → Download Manual
Profiles.

### `Pods/FirebaseCore not found` o errores de pod

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### `flutter build ipa` rebuilds infinitos

Limpia el build:
```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release
```

### "ITMS-90683: Missing Purpose String" al subir

Falta entrada en `Info.plist` para algún permiso (NSCameraUsageDescription,
NSPhotoLibraryUsageDescription, NSMicrophoneUsageDescription...). Apple
exige strings descriptivas para todos los permisos que usa la app. Mira
el log del Transporter, te dice cuál falta exactamente.

### "Invalid build number"

El build number ya fue subido antes (mismo problema que tuvimos en Play
con la 138). Bumpea con `--build-number=N` mayor.

---

## 10. Tras subir

- Verifica en App Store Connect → TestFlight → Builds, que la build
  esté ✅ "Ready to submit" (no "Processing" o "Invalid").
- Si quieres testear primero antes de producción → TestFlight con tu
  grupo interno.
- Para mandar a revisión real → App Store → Versión 2.0.9 → Submit.

---

## 11. Resumen comparativo Android vs iOS

| Paso | Android | iOS |
|---|---|---|
| Compila en | Cualquier Windows/Mac/Linux con Flutter | Solo Mac con Xcode |
| Firma | `salufit-release.jks` + `key.properties` | Apple Developer cert + provisioning profile |
| Output | `build/app/outputs/bundle/release/app-release.aab` | `build/ios/ipa/salufit_app.ipa` |
| Tool de subida | Play Console (web) | Transporter o Xcode Organizer |
| Build number único | versionCode `+141` (pubspec) | iOS lleva su propia secuencia, posiblemente distinta |
| Tiempo de compilación | ~5 min | ~8-12 min |
| Tiempo de revisión | Horas (Play) | 24-48 h (Apple) |

---

## 12. Por qué no se puede compilar iOS en Windows

Apple exige firma con su toolchain (codesign + Xcode + Apple silicon o
Intel Mac). Flutter delega la compilación final a `xcodebuild`, que
solo existe en macOS. No hay alternativa legal — ni cross-compile ni
Hackintosh oficial.

Opciones si no tienes Mac propio:
- **Mac mini de segunda mano** (250-400€ usado, suficiente para builds).
- **Mac in the cloud** (MacStadium, Codemagic) — alquiler por hora.
- **GitHub Actions con macOS runner** — si quieres CI/CD futuro,
  podemos montarlo y los builds se hacen automáticamente al hacer push.
