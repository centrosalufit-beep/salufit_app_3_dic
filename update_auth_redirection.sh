#!/bin/zsh

FILE="lib/features/auth/services/auth_service.dart"

echo "⚙️ Configurando redirección inteligente en el AuthService..."

# Definimos los ActionCodeSettings
# NOTA: Cambia 'com.salufit.app' por tu ID de paquete real si es distinto
cat <<INNER_EOF > action_settings.txt
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://salufitnewapp.page.link/reset', // URL de enlace dinámico (puedes usar tu web)
      handleCodeInApp: true,
      androidPackageName: 'com.salufit.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.salufit.app',
    );
INNER_EOF

# Modificamos el método sendPasswordResetEmail para usar estos ajustes
sed -i '' 's/await _auth.sendPasswordResetEmail(email: email);/final actionCodeSettings = ActionCodeSettings(url: "https:\/\/salufitnewapp.firebaseapp.com", handleCodeInApp: true, androidPackageName: "com.salufit.app", iOSBundleId: "com.salufit.app");\
      await _auth.sendPasswordResetEmail(email: email, actionCodeSettings: actionCodeSettings);/' $FILE

echo "✅ Código actualizado. Ahora Firebase intentará devolver al usuario a la App."
rm action_settings.txt
