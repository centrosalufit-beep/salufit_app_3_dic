# Checklists de privacidad para las tiendas

> Para rellenar los formularios de **Data Safety** (Google Play Console) y
> **App Privacy Details** (App Store Connect) con coherencia vs
> `PrivacyInfo.xcprivacy` e implementación real de la app.

---

## 🔐 Datos recopilados

### Información personal

| Dato | ¿Recopilado? | ¿Enviado a servidor? | ¿Requerido? | Propósito |
|---|---|---|---|---|
| Nombre | ✅ Sí | ✅ Firebase | Sí | Identificación en consulta |
| Apellidos | ✅ Sí | ✅ Firebase | Sí | Identificación en consulta |
| Email | ✅ Sí | ✅ Firebase Auth | Sí | Login + notificaciones |
| Teléfono | ✅ Sí | ✅ Firestore | Sí | Contacto del centro |
| Dirección postal | ❌ No | — | — | — |
| Fecha nacimiento | ✅ Sí | ✅ Firestore | Sí | Validación edad RGPD |
| Foto perfil | ✅ Opcional | ✅ Firebase Storage | No | Identificación visual |
| Género / sexo | ❌ No | — | — | — |
| DNI / doc. identidad | ❌ No directamente | — | — | (solo profesionales en firma digital) |

### Datos de salud

| Dato | ¿Recopilado? | ¿Enviado a servidor? | ¿Requerido? | Propósito |
|---|---|---|---|---|
| Historia clínica (nº) | ✅ Sí | ✅ Firestore | Sí | Vinculación con ficha médica |
| Peso | ✅ Opcional | ✅ Firestore | No | Seguimiento clínico |
| Tensión arterial | ✅ Opcional | ✅ Firestore | No | Seguimiento clínico |
| Evaluaciones psicológicas (GAD-7, PHQ-9) | ✅ Opcional | ✅ Firestore | No | Seguimiento de salud mental |
| Documentos médicos subidos | ✅ Opcional | ✅ Firebase Storage | No | Expediente médico |
| Consentimientos firmados | ✅ Sí | ✅ Firestore + Storage | Sí (para tratamientos) | Cumplimiento Ley 41/2002 |

### Datos de ubicación

| Dato | ¿Recopilado? | Propósito |
|---|---|---|
| Ubicación precisa | ❌ No | — |
| Ubicación aproximada | ⚠️ Solo on-demand | Validación de fichaje WiFi del centro (staff) |

### Datos del dispositivo e identificadores

| Dato | ¿Recopilado? | Propósito |
|---|---|---|
| Device ID (FCM token) | ✅ Sí | Notificaciones push |
| SSID de WiFi actual | ⚠️ Solo staff | Validar fichaje en centro |
| IP address | ✅ Sí (logs backend) | Auditoría de seguridad RGPD |
| User Agent | ✅ Sí (logs backend) | Auditoría de seguridad RGPD |
| Crash logs | ✅ Sí (Crashlytics) | Estabilidad de la app |
| Analytics de uso | ⚠️ Opt-in (si el usuario lo acepta en MigrationGate) | Mejorar la app |

### Contenido generado por el usuario

| Dato | ¿Recopilado? | Propósito |
|---|---|---|
| Fotos subidas | ✅ Opcional | Documentos médicos / radiografías |
| Vídeos de ejercicios | ✅ Opcional | Ejecución de plan de entrenamiento |
| Audio | ❌ No | — |
| Mensajes de chat | ✅ Sí (solo staff) | Comunicación interna del equipo |

---

## 📋 Respuestas para Google Play — Data Safety

### Sección 1: Data collection and security

**1.1. ¿Tu app recopila o comparte datos del usuario requeridos?**
> ✅ **Sí**

**1.2. ¿Todos los datos recopilados se cifran en tránsito?**
> ✅ **Sí** (HTTPS obligatorio, `usesCleartextTraffic="false"` en manifest)

**1.3. ¿Los usuarios pueden solicitar la eliminación de sus datos?**
> ✅ **Sí** — implementado via Cloud Function `deleteUserData` (cascada completa RGPD Art. 17)

### Sección 2: Por categoría de datos — marca cada una

**Información personal**:
- ✅ Nombre — Recopilado + Requerido
- ✅ Dirección de email — Recopilado + Requerido
- ✅ Número teléfono — Recopilado + Requerido

**Info de salud y fitness**:
- ✅ Salud — Recopilado + Requerido (historia clínica)
- ✅ Fitness — Opcional

**Fotos y vídeos**:
- ✅ Fotos — Recopilado + Opcional
- ✅ Vídeos — Recopilado + Opcional

**Archivos y documentos**:
- ✅ Archivos y documentos — Recopilado + Opcional

**Identificadores del dispositivo u otros**:
- ✅ ID del dispositivo (para push) — Recopilado + Requerido

**Actividad en la app**:
- ✅ Interacciones en app — Recopilado + Opcional (si el usuario acepta analytics)
- ✅ Historial de búsqueda en app — ❌ No
- ✅ Otras acciones generadas por el usuario — ✅ Sí (reservas, chats)

**Info financiera**:
- ❌ No (no procesamos pagos dentro de la app)

**Mensajes**:
- ✅ Otros mensajes in-app — Solo profesionales entre sí

### Sección 3: Para cada dato marcado, rellenar

Para cada dato:
- **Purpose**: "App functionality" (principalmente) + "Analytics" (solo para Analytics si el usuario lo acepta)
- **Is data processing optional?**: Marcar "Required" o "Optional" según la tabla de arriba
- **Is data encrypted in transit?**: ✅ Sí (Firebase usa HTTPS)
- **Can users request data be deleted?**: ✅ Sí

---

## 📋 Respuestas para App Store Connect — App Privacy Details

### Ya declarado en `PrivacyInfo.xcprivacy`

Verifica coherencia — el archivo actual declara:

**NSPrivacyCollectedDataTypes**:
- Name
- Email Address
- Phone Number
- Health and Fitness
- User Content
- Device ID

Todos marcados como:
- `Linked`: ✅ Sí (linkados al usuario)
- `Tracking`: ❌ No (no se usan para seguimiento cross-app)
- `Purposes`: App Functionality

### En App Store Connect

Vas a **My Apps → Salufit → App Privacy** y rellenas **exactamente lo mismo** que en `PrivacyInfo.xcprivacy`:

1. **¿Recopilas datos?** → Sí

2. **Tipos de datos**: marca los 6 ya declarados + **Health and Fitness → Health** para ser más específico

3. Para cada tipo:
   - **¿Se enlaza con el usuario?** → Sí
   - **¿Se usa para seguimiento?** → No
   - **Purpose** → "App Functionality"

4. **¿Haces seguimiento?** → **No**
   - Justificación: "La app no combina datos con apps de terceros ni los comparte con redes publicitarias."

5. **¿Recopilas datos de salud?** → Sí
   - Justificación: "Centro Salufit es un centro médico; los datos de historia clínica, métricas y documentos se usan exclusivamente para la atención sanitaria del paciente en consulta."

---

## ⚠️ Discrepancias a corregir antes de subir

Si Crashlytics + Analytics quedan instalados (como acabamos de hacer), debes **AÑADIR** estas declaraciones en AMBAS tiendas:

**Añadir a Data Safety (Play) y App Privacy (iOS)**:
- **Crash logs** (Diagnostics → App crash logs)
  - Purpose: **Analytics + App Functionality** (estabilidad)
  - Linked to user: Sí
  - Tracking: No
- **Performance data** (Diagnostics → Performance data)
  - Purpose: **Analytics + App Functionality**
  - Linked to user: Sí
  - Tracking: No

Esto lo gestiona Firebase Crashlytics automáticamente — solo tienes que declararlo.
