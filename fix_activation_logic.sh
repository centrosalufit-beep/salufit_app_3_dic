#!/bin/zsh
# Actualiza la pantalla para llamar a la función en lugar de a la DB directamente
sed -i '' 's/FirebaseFirestore.instance.collection('\''users'\'').where('\''email'\'', isEqualTo: email).get()/await FirebaseFunctions.instance.httpsCallable('\''checkAccountStatus'\'').call({'\''email'\'': email, '\''historyId'\'': idH})/g' lib/features/auth/presentation/activation_screen.dart
echo "✅ Flutter actualizado para usar la Cloud Function."
