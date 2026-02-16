#!/bin/zsh

OUTPUT_DIR="AUDIT_CONTEXT"
mkdir -p $OUTPUT_DIR

# Función para añadir archivos con separadores
add_files() {
  local target_file="$OUTPUT_DIR/$1"
  shift
  echo "--- INICIO DE CONTEXTO ---" > $target_file
  for pattern in "$@"; do
    # Buscamos archivos según el patrón, ignorando carpetas pesadas
    find . -maxdepth 4 -name "$pattern" -not -path "*/.*" -not -path "*/build/*" -not -path "*/node_modules/*" | while read file; do
      echo "\n\n--- FILE: $file ---" >> $target_file
      cat "$file" >> $target_file
    done
  done
  echo "✅ Generado: $target_file"
}

echo "📂 1/4: Generando Módulo de Seguridad y Protección de Datos..."
add_files "AUDIT_1_SECURITY_GDPR.txt" "firestore.rules" "index.ts" "auth_service.dart" "AndroidManifest.xml" "Info.plist"

echo "📂 2/4: Generando Módulo de Diseño, UI y UX..."
add_files "AUDIT_2_UI_UX_DESIGN.txt" "app_theme.dart" "*_screen.dart" "*_widget.dart" "main.dart"

echo "📂 3/4: Generando Módulo de Legalidad y Documentación..."
# Aquí buscamos cualquier archivo de términos, política de privacidad o diálogos de consentimiento
add_files "AUDIT_3_LEGAL_CONSENT.txt" "*privacy*" "*terms*" "*consent*" "activation_screen_helper.dart"

echo "📂 4/4: Generando Módulo de Arquitectura y Rendimiento..."
add_files "AUDIT_4_ARCH_PERF.txt" "pubspec.yaml" "auth_providers.dart" "database_service.dart" "api_client.dart"

echo "\n--------------------------------------------------"
echo "🚀 AUDITORÍA LISTA. Tienes 4 archivos en la carpeta $OUTPUT_DIR."
echo "💡 Súbelos de uno en uno o todos juntos según la potencia de la IA."
