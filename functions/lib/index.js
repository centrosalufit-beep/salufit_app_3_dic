"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkAccountStatus = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length)
    admin.initializeApp();
exports.checkAccountStatus = functions.https.onCall(async (data, context) => {
    const email = data.email.toLowerCase().trim();
    const historyId = data.historyId.toString().padStart(6, '0');
    try {
        // 1. Verificar si ya existe en la colección de usuarios activos
        const userQuery = await admin.firestore().collection('users')
            .where('email', '==', email).limit(1).get();
        if (!userQuery.empty) {
            return { status: 'ALREADY_REGISTERED' };
        }
        // 2. Verificar en la colección de importación legacy
        const legacyDoc = await admin.firestore().collection('legacy_import').doc(historyId).get();
        if (legacyDoc.exists && legacyDoc.data()?.email === email) {
            return { status: 'ACTIVATION_PENDING' };
        }
        return { status: 'NOT_FOUND' };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', 'Error verificando cuenta');
    }
});
//# sourceMappingURL=index.js.map