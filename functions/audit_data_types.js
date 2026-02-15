const admin = require('firebase-admin');

// Inicializamos sin parámetros (usará las credenciales de tu entorno local)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function audit() {
  console.log("🕵️ Análisis de Tipos de Datos Salufit...");
  
  const collections = ['users', 'legacy_import'];
  
  for (const col of collections) {
    console.log("\n--------------------------------------------------");
    console.log(`📂 Colección: ${col}`);
    const snapshot = await db.collection(col).limit(1).get();
    
    if (snapshot.empty) {
      console.log(`⚠️ La colección ${col} está vacía.`);
      continue;
    }

    const data = snapshot.docs[0].data();
    // Buscamos cualquier campo que huela a ID de historia
    const fieldsToCheck = ['historyId', 'idH', 'numero', 'email'];
    
    fieldsToCheck.forEach(field => {
      if (data[field] !== undefined) {
        const val = data[field];
        console.log(`📌 Campo [${field}]:`);
        console.log(`   - Valor: ${JSON.stringify(val)}`);
        console.log(`   - Tipo: ${typeof val}`);
      }
    });
  }
  process.exit();
}

audit().catch(console.error);
