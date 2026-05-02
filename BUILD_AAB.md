# Build del .aab para Play Store — guía rápida

Esta guía es para compilar el bundle Android firmado en una máquina que **ya
tiene el keystore** (la Microsoft Surface u otro ordenador donde se generaron
las versiones anteriores subidas a Play Store).

> ⚠️ La compilación NO se puede hacer en la máquina principal de Windows
> (la del despacho) porque NO tiene `android/key.properties` ni el `.jks`.
> El `.aab` debe firmarse con la **misma upload key** que las versiones
> anteriores subidas a Play Store, si no, Google la rechaza.

---

## 1. Clonar el proyecto y poner el keystore en su sitio

```bash
# 1.1 Clonar la rama actual desde GitHub
git clone https://github.com/centrosalufit-beep/salufit_app_3_dic.git
cd salufit_app_3_dic
git checkout feat/admin-windows-bot

# 1.2 Copiar el keystore al sitio que espera build.gradle.
# El nombre puede variar; lo importante es que la ruta coincida con storeFile.
# Ejemplo (ajusta a tu caso):
cp /ruta/donde/lo/tengas/salufit_upload.jks android/app/salufit_upload.jks

# 1.3 Crear android/key.properties con las credenciales reales.
# Plantilla en android/key.properties.template (ver más abajo).
```

**Plantilla `android/key.properties`** (el archivo está gitignored — los
valores reales NUNCA deben subirse a git):

```properties
storePassword=••••••••
keyPassword=••••••••
keyAlias=upload
storeFile=salufit_upload.jks
```

Notas:
- `storeFile` es **relativo a `android/app/`**, no a la raíz. Si pones
  el `.jks` ahí dentro, basta el nombre.
- Si tu alias no es `upload`, cambia `keyAlias` al que figura en
  `keytool -list -v -keystore tu.jks`.

---

## 2. Preparar el entorno

```bash
flutter --version           # 3.41.7+ recomendado (probado y limpio)
flutter doctor              # debe estar todo verde excepto Chrome (no afecta)
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze             # debe dar "No issues found!"
```

Si `flutter analyze` da errores, **NO lances el build** — repórtalos y se
arreglan antes.

---

## 3. Compilar el .aab

```bash
flutter build appbundle --release
```

Sale por consola algo como:

```
Running Gradle task 'bundleRelease'...
✓ Built build/app/outputs/bundle/release/app-release.aab (52.3MB).
```

El archivo final está en:

```
build/app/outputs/bundle/release/app-release.aab
```

Ese es el que se sube a Play Console → Producción / Pruebas → Crear release
nueva → Subir bundle.

---

## 4. Versión actual (ya bumpeada)

`pubspec.yaml` ya está en:

```yaml
version: 2.0.9+140
```

Es decir:
- **versionName**: `2.0.9` (lo que ve el usuario en Play Store)
- **versionCode**: `140` (entero único; Play exige que cada subida sea mayor
  que la anterior — la última en producción era 137).

Si haces más cambios y necesitas re-subir, sube **ambos**: por ejemplo
`2.0.10+141`. Si solo cambias `versionCode` sin tocar `versionName`, Play
lo acepta como hotfix.

---

## 5. Avisos de Play Console que ya están resueltos en esta versión

Si Play te muestra estas notas en la 137, **ya están corregidas en la 140**:

| Aviso | Estado en 140 |
|---|---|
| `play-services-safetynet` deprecated | ✅ Excluido en `android/app/build.gradle:101-103` |
| Edge-to-edge / APIs deprecadas (Android 15) | ✅ Flutter 3.41.7 ya usa las APIs nuevas |
| AGP 9 newDsl warning | Informativo. El build funciona. Migrar más tarde. |

---

## 6. Si el build de Gradle falla

Errores comunes y cómo resolverlos:

### `signReleaseBundle > NullPointerException`
Es lo que falló en la máquina principal: significa que `key.properties`
o el `.jks` no existen / no son legibles. Verifica:

```bash
ls android/key.properties
ls android/app/*.jks
keytool -list -v -keystore android/app/salufit_upload.jks
```

El último comando debe pedirte la contraseña y mostrar el alias y la huella.

### `Execution failed for task ':app:processReleaseGoogleServices'`
Falta `android/app/google-services.json`. Descárgalo de
https://console.firebase.google.com/project/salufitnewapp/settings/general
→ App Android → archivo de configuración.

### `Java heap space` / OOM
Aumenta memoria Gradle en `android/gradle.properties`:
```
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
```

---

## 7. Tras subir a Play Console

1. Sube el `.aab` a la pista que toque (Producción / Cerrada / Interna).
2. Rellena las notas de la versión (cambios en español).
3. Si es la primera vez en este móvil, **revisa el firma de la app**:
   - Settings → App signing
   - La "Upload certificate" SHA-1 debe coincidir con el `.jks` que usaste.
   - Si no coincide → es un keystore distinto al de la 137 y Google
     rechazará el bundle. Hay que recuperar el original.

---

## 8. Notas de versión sugeridas para Play Store (2.0.9)

```
- Nuevo Hub de inicio en Windows con tarjetas por feature.
- Filtro de visibilidad por rol: profesionales solo ven lo que necesitan.
- Tipografía y colores uniformes en todas las pantallas admin.
- Mobile staff: nuevo botón "Escanear QR" en el dashboard.
- Lista de apuntados a una clase visible para profesional/admin (mobile).
- Bloqueo automático de doble consumo de token (5 min) al escanear el
  mismo cliente por error.
- Mensajes de empty state legibles en todas las pantallas.
- Correcciones varias de UI y rendimiento.
```
