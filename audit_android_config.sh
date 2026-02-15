#!/bin/zsh

echo "🤖 Iniciando Auditoría de la Carpeta Android..."
echo "--------------------------------------------------"

# 1. Verificar Application ID
APP_ID=$(grep "applicationId" android/app/build.gradle | awk '{print $2}' | tr -d '"' | tr -d "'")
echo "📌 Application ID: $APP_ID"

# 2. Verificar SDK Versions
MIN_SDK=$(grep "minSdkVersion" android/app/build.gradle | awk '{print $2}')
TARGET_SDK=$(grep "targetSdkVersion" android/app/build.gradle | awk '{print $2}')
echo "📌 Min SDK: $MIN_SDK (Recomendado: 21+)"
echo "📌 Target SDK: $TARGET_SDK (Recomendado: 34+)"

# 3. Verificar Google Services JSON
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json detectado."
else
    echo "❌ ERROR: No se encuentra google-services.json en android/app/"
fi

# 4. Verificar Kotlin Version (Importante para compatibilidad)
KOTLIN_VER=$(grep "ext.kotlin_version" android/build.gradle | awk -F "'" '{print $2}')
echo "📌 Kotlin Version: $KOTLIN_VER"

# 5. Comprobar multidex (Necesario si la app crece mucho con Firebase)
if grep -q "multiDexEnabled true" android/app/build.gradle; then
    echo "✅ Multidex habilitado."
else
    echo "⚠️ Multidex no detectado. Si la app falla al compilar, actívalo."
fi

echo "--------------------------------------------------"
echo "✅ Auditoría finalizada."
