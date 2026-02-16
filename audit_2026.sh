#!/bin/zsh

echo "🛠️ Configurando sALUFIT para Estándares 2026..."

# 1. Sobrescribir analysis_options.yaml con reglas estrictas
cat <<EOT > analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - riverpod_lint
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_use_of_protected_member: error
    invalid_use_of_visible_for_testing_member: error
    avoid_catches_without_on_clauses: error
    use_build_context_synchronously: error

linter:
  rules:
    - avoid_catches_without_on_clauses
    - unawaited_futures
    - prefer_final_locals
    - use_super_parameters
    - use_build_context_synchronously
    - curly_braces_in_flow_control_structures
EOT

# 2. Inyectar dependencias de Riverpod 3.0 Audit en pubspec.yaml
# Usamos un método de búsqueda más seguro para macOS
if ! grep -q "riverpod_lint:" pubspec.yaml; then
  echo "📦 Añadiendo riverpod_lint y custom_lint..."
  sed -i '' '/dev_dependencies:/a\
  riverpod_lint: ^3.0.0\
  custom_lint: ^0.7.0' pubspec.yaml
fi

# 3. Sincronizar
echo "🔄 Ejecutando flutter pub get..."
flutter pub get

# 4. Auditoría de Campo
echo "🔍 ANALIZANDO DIVERGENCIAS (Esto puede tardar un momento)..."
flutter analyze .
