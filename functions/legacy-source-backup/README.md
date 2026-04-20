# Cloud Functions — Backup de código fuente legacy

## Contexto

Las funciones listadas aquí están **desplegadas en producción** pero su código fuente
nunca se había commiteado al repositorio. Se recuperaron del archivo
`auditoria app/03_Backend_Cloud_Functions.txt` el **20 de abril de 2026**.

## ⚠️ IMPORTANTE

- **Este directorio está FUERA de `src/`** deliberadamente, para que TypeScript
  no compile este código ni se despliegue automáticamente con `firebase deploy`.
- **No es el código actualmente en ejecución** en producción (ese es la versión
  compilada que vive en Cloud Functions). Es un backup aproximado al estado
  de **enero de 2026** según el archivo de auditoría.
- **Si necesitas modificar una de estas funciones**, el procedimiento correcto es:
  1. Descargar el código actual desde Firebase Console / gcloud CLI
  2. Verificar que coincide con este backup
  3. Mover a `src/` (convertir a TypeScript si aplica)
  4. Integrar en `src/index.ts` o un archivo separado
  5. Redesplegar

## Funciones incluidas

### Activas y en uso por la app (3)
- **`generarClasesMensuales`** — Batch de creación de clases mensuales.
  Llamada desde `admin_class_manager_screen.dart:65` vía HTTP POST.
- **`registrarFichaje`** — Sistema de fichaje del staff.
  Llamada desde `staff_service.dart:67` vía HTTP POST.
- **`renovarBonosBatch`** — Renovación masiva de bonos.
  No hay llamada directa desde la app; probablemente se dispara manualmente
  desde Firebase Console o via Cloud Scheduler.

### Triggers Firestore (6) — inactivos actualmente
Observan escrituras en colecciones y "hidratan" o notifican:
- `autoEmailAppointments` — trigger en `appointments/{id}`
- `autoEmailBookings` — trigger en `bookings/{id}`
- `autoEmailPasses` — trigger en `passes/{id}`
- `autoEmailTimeRecords` — trigger en `timeClockRecords/{id}`
- `autoEmailExerciseAssignments` — trigger en `exercise_assignments/{id}`
- `notificarCambioReserva` — trigger en `bookings/{bookingId}` para FCM push

Los 5 `autoEmail*` comparten el helper `hidratarEmail()` — rellenan el campo
`userEmail` del documento si viene vacío, consultándolo desde `users/{userId}`.

`notificarCambioReserva` envía una notificación push al usuario cuando cambia
el estado de su reserva.

## Dependencias que usa este código legacy

```json
{
  "nodemailer": "^X",
  "pdf-lib": "^X",
  "axios": "^X",
  "cors": "^X"
}
```

Estas dependencias **no están en el `package.json` actual** porque las funciones
nuevas (`src/index.ts`) no las usan. Si vas a redesplegar el código legacy,
tendrás que añadirlas.

## Cómo recuperar este código y redesplegarlo

1. Copiar `legacy_functions.js` a `src/legacy_functions.ts`
2. Adaptar `require(...)` a `import ... from '...'`
3. Añadir las dependencias faltantes al `package.json`
4. Importar y re-exportar desde `src/index.ts`:
   ```ts
   export {
     generarClasesMensuales,
     registrarFichaje,
     renovarBonosBatch,
     autoEmailAppointments,
     // ...
   } from './legacy_functions';
   ```
5. Ejecutar `npm run build` y verificar que compila
6. Desplegar con `firebase deploy --only functions:generarClasesMensuales,...`

## Secretos requeridos

El helper `getTransporter()` usa el secreto `GMAIL_PASSWORD` definido vía
`defineSecret()`. Este secreto ya existe en Firebase (la función `activarCuenta`
borrada hoy lo usaba). Se puede gestionar con:

```bash
firebase functions:secrets:access GMAIL_PASSWORD
firebase functions:secrets:set GMAIL_PASSWORD
```
