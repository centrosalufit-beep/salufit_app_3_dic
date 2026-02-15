#!/bin/zsh
FILE="src/index.ts"

echo "🧠 Inyectando lógica híbrida e infalible en $FILE..."

# Creamos el nuevo contenido del archivo para asegurar que sea perfecto
cat <<'INNER_EOF' > $FILE
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const checkAccountStatus = functions.https.onCall(async (data, context) => {
  const email = (data.email as string).trim().toLowerCase();
  const historyIdRaw = data.historyId.toString().trim();
  
  // 1. Normalización para comparación
  const idString = historyIdRaw.padStart(6, "0"); // "000001"
  const idNumber = parseInt(historyIdRaw, 10);   // 1
  
  try {
    // 2. Primero verificamos si ya existe en 'users'
    const userSnapshot = await db.collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();
      
    if (!userSnapshot.empty) {
      return { status: "ALREADY_REGISTERED" };
    }
    
    // 3. Si no existe, buscamos en 'legacy_import' por EMAIL
    // Buscamos todos los registros con ese email (suele ser solo 1)
    const legacySnapshot = await db.collection("legacy_import")
      .where("email", "==", email)
      .get();
      
    if (legacySnapshot.empty) {
      return { status: "NOT_FOUND" };
    }
    
    // 4. Verificación HÍBRIDA de ID de historia
    // Buscamos en los documentos encontrados si alguno coincide con el ID (como string o como número)
    const match = legacySnapshot.docs.find(doc => {
      const d = doc.data();
      // Buscamos en los nombres de campo más probables
      const dbId = d.historyId || d.idH || d.numero;
      
      // Comparamos sin importar el tipo (== hace cast automático en JS/TS para esto)
      return dbId == idString || dbId == idNumber || dbId == historyIdRaw;
    });
    
    if (match) {
      return { status: "ACTIVATION_PENDING" };
    } else {
      return { status: "NOT_FOUND" };
    }
    
  } catch (error) {
    console.error("Error en checkAccountStatus:", error);
    throw new functions.https.HttpsError("internal", "Error al verificar la cuenta");
  }
});
INNER_EOF

echo "✅ Archivo index.ts actualizado con lógica de detección de tipos."
