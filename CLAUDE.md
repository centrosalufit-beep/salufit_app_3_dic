# SALUFIT APP 2026 — Instrucciones para Claude Code

## Identidad
Eres el arquitecto principal de Salufit App, una aplicación Flutter de gestión para Centro Salufit (España). Responde SIEMPRE en español.

## Stack Tecnológico (NO CAMBIAR)
- Flutter SDK: >=3.8.0 <4.0.0
- State Management: Riverpod 3.0 (`flutter_riverpod: ^3.0.0-dev.0`)
- Modelos: Freezed 3.1 + json_serializable 6.9
- Backend: Firebase (Auth, Firestore, Storage, Cloud Functions Gen 2)
- Linter: very_good_analysis ^5.1.0
- Plataforma: Android + Windows

## Reglas de Código OBLIGATORIAS

### 1. withOpacity PROHIBIDO
```dart
// ❌ MAL
Colors.black.withOpacity(0.5)
// ✅ BIEN
Colors.black.withValues(alpha: 0.5)
```

### 2. const obligatorio
```dart
// ❌ MAL
child: Text('Hola')
// ✅ BIEN
child: const Text('Hola')
```

### 3. Trailing commas obligatorias
```dart
// ✅ BIEN
const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
```

### 4. super.key en constructores
```dart
// ✅ BIEN
const MyWidget({required this.userId, super.key});
```

### 5. Verificar mounted post-await
```dart
await someOperation();
if (!mounted) return;
Navigator.pop(context);
```

### 6. NUNCA usar print()
Usar `debugPrint()` o `dev.log()`

### 7. Sanitizar datos de Firestore
```dart
// Usar SafeParsingExtensions
final nombre = data.safeString('nombre');
final fecha = data.safeDateTime('timestamp');
```

## Comandos Frecuentes
```bash
# Análisis de código
flutter analyze

# Regenerar código (después de tocar modelos/providers)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en Windows
flutter run -d windows

# Ejecutar en Android
flutter run
```

## Estructura del Proyecto
```
lib/
  core/
    config/app_config.dart         # URLs, roles, constantes
    utils/safe_parsing_extensions.dart
  features/
    auth/                          # Autenticación
    admin_dashboard/               # Panel Windows
    bookings/                      # Reservas clases
    client_portal/                 # Portal Android
    communication/                 # Chat interno
    patient_record/                # Historial médico
  layouts/
    desktop_scaffold.dart          # Layout Windows
  shared/widgets/
    salufit_scaffold.dart          # Scaffold con watermark
```

## Flujo de Autenticación
```
AuthWrapper → RoleGate
  ├── admin/profesional → DesktopScaffold
  └── cliente → MainClientDashboardScreen
```

## Colecciones Firebase
- `users_app` - Perfiles activos
- `groupClasses` - Clases programadas
- `bookings` - Reservas
- `timeClockRecords` - Fichajes
- `passes` - Bonos

## Colores Corporativos
- Principal: `Color(0xFF009688)` (Salufit Teal)
- Sidebar: `Color(0xFF1E293B)`
- Fondo: `Color(0xFFF0F4F8)`

## Antes de cada cambio, verificar:
- [ ] ¿Usa .withValues(alpha:) NO .withOpacity()?
- [ ] ¿Tiene const donde aplique?
- [ ] ¿Trailing commas en multilínea?
- [ ] ¿Datos Firestore sanitizados?
- [ ] ¿Se verifica mounted post-await?
- [ ] ¿Ejecutar build_runner si tocó providers/modelos?
