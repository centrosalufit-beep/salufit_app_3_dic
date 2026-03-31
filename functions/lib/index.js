"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cancelarReserva = exports.checkAccountStatus = void 0;
const https_1 = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
// ── Activación de clientes (v1 onCall para compatibilidad con Flutter) ──
exports.checkAccountStatus = functions.https.onCall(async (data, _context) => {
    const email = data.email.trim().toLowerCase();
    const historyIdRaw = data.historyId.toString().trim();
    const idString = historyIdRaw.padStart(6, "0");
    const idNumber = parseInt(historyIdRaw, 10);
    try {
        // Verificar si ya existe en users_app (colección activa)
        const userSnapshot = await db.collection("users_app")
            .where("email", "==", email)
            .limit(1)
            .get();
        if (!userSnapshot.empty) {
            return { status: "ALREADY_REGISTERED" };
        }
        // Buscar en bbdd y legacy_import por email
        const [bbddSnapshot, legacySnapshot] = await Promise.all([
            db.collection("bbdd").where("email", "==", email).get(),
            db.collection("legacy_import").where("email", "==", email).get(),
        ]);
        const allDocs = [...bbddSnapshot.docs, ...legacySnapshot.docs];
        if (allDocs.length === 0) {
            return { status: "NOT_FOUND" };
        }
        // Verificación híbrida de ID de historia
        const match = allDocs.find(doc => {
            const d = doc.data();
            const dbId = d.historyId || d.idH || d.numero || d.numHistoria;
            return dbId == idString || dbId == idNumber || dbId == historyIdRaw;
        });
        if (match) {
            const matchData = match.data();
            // Crear usuario en Firebase Auth (si no existe ya)
            let uid;
            try {
                const existingUser = await admin.auth().getUserByEmail(email);
                uid = existingUser.uid;
            }
            catch {
                // Usuario no existe en Auth, lo creamos con contraseña temporal
                const newUser = await admin.auth().createUser({
                    email: email,
                    displayName: matchData.nombreCompleto || matchData.nombre || email,
                });
                uid = newUser.uid;
            }
            // Crear perfil en users_app
            await db.collection("users_app").doc(uid).set({
                email: email,
                nombre: matchData.nombre || "",
                nombreCompleto: matchData.nombreCompleto || matchData.nombre || "",
                numHistoria: matchData.numHistoria || matchData.historyId || matchData.idH || historyIdRaw,
                rol: "cliente",
                activo: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                activatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            return { status: "ACTIVATION_PENDING" };
        }
        else {
            return { status: "NOT_FOUND" };
        }
    }
    catch (error) {
        console.error("Error en checkAccountStatus:", error);
        throw new Error("Error al verificar la cuenta");
    }
});
exports.cancelarReserva = (0, https_1.onRequest)((req, res) => {
    return cors(req, res, async () => {
        const { bookingId } = req.body;
        if (!bookingId) {
            res.status(400).json({ error: "Falta bookingId" });
            return;
        }
        try {
            let reembolsoRealizado = false;
            await db.runTransaction(async (t) => {
                const bRef = db.collection("bookings").doc(bookingId);
                const bSnap = await t.get(bRef);
                if (!bSnap.exists)
                    throw new Error("La reserva no existe.");
                const bData = bSnap.data();
                const cRef = db.collection("groupClasses").doc(bData.groupClassId);
                const cSnap = await t.get(cRef);
                if (!cSnap.exists)
                    throw new Error("La clase no existe.");
                const cData = cSnap.data();
                const ahora = new Date();
                const fechaClase = cData.fechaHoraInicio.toDate();
                const diffHoras = (fechaClase.getTime() - ahora.getTime()) / (1000 * 60 * 60);
                if (diffHoras >= 24) {
                    const passesSnap = await t.get(db.collection("passes")
                        .where("userId", "==", bData.userId)
                        .where("activo", "==", true)
                        .limit(1));
                    if (!passesSnap.empty) {
                        const passRef = passesSnap.docs[0].ref;
                        const tokensActuales = passesSnap.docs[0].data().tokensRestantes || 0;
                        t.update(passRef, { tokensRestantes: tokensActuales + 1 });
                        reembolsoRealizado = true;
                    }
                }
                const nuevoAforo = Math.max(0, (cData.aforoActual || 1) - 1);
                t.update(cRef, { aforoActual: nuevoAforo });
                t.delete(bRef);
            });
            res.json({
                success: true,
                tokenDevuelto: reembolsoRealizado,
                message: reembolsoRealizado ? "Reserva anulada y token devuelto." : "Reserva anulada (sin devolución de token)."
            });
            return;
        }
        catch (e) {
            res.status(400).json({ error: e.message });
            return;
        }
    });
});
//# sourceMappingURL=index.js.map