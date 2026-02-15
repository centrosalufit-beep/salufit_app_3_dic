#!/bin/zsh

echo "🔍 Rastreando identificadores de Salufit..."
echo "--------------------------------------------------"

# 🤖 Encontrar Package Name (Android)
ANDROID_ID=$(grep "applicationId" android/app/build.gradle | awk '{print $2}' | tr -d '"' | tr -d "'")
if [ -n "$ANDROID_ID" ]; then
    echo "🤖 Android Package Name: $ANDROID_ID"
else
    echo "🤖 Android: No se pudo detectar automáticamente."
fi

# 🍎 Encontrar Bundle ID (iOS)
IOS_ID=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -n 1 | awk -F ' = ' '{print $2}' | tr -d ';' | tr -d ' ')
if [ -n "$IOS_ID" ]; then
    echo "🍎 iOS Bundle ID: $IOS_ID"
else
    # Intento alternativo en Info.plist si el anterior falla
    IOS_ID=$(grep -A 1 "CFBundleIdentifier" ios/Runner/Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "🍎 iOS Bundle ID: $IOS_ID"
fi

echo "--------------------------------------------------"
echo "💡 Estos son los IDs que debemos poner en el script del AuthService."
