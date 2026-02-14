const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, memory: "512MiB", timeoutSeconds: 60, region: "us-central1" });
const gmailPassword = defineSecret("GMAIL_PASSWORD");

const getTransporter = () => nodemailer.createTransport({
    service: "gmail",
    auth: { user: "centrosalufit@gmail.com", pass: gmailPassword.value() }
});

// 🎟️ CREAR RESERVA (NÚCLEO DE NEGOCIO)
exports.crearReserva = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        const { userId, groupClassId } = req.body;
        try {
            const result = await db.runTransaction(async (t) => {
                const cRef = db.collection("groupClasses").doc(groupClassId);
                const snap = await t.get(cRef);
                const aforo = snap.data().aforoActual || 0;
                const estado = aforo >= (snap.data().aforoMax || 12) ? "espera" : "reservada";
                t.set(db.collection("bookings").doc(), { 
                    userId, groupClassId, estado, 
                    fechaReserva: admin.firestore.FieldValue.serverTimestamp() 
                });
                if (estado === "reservada") t.update(cRef, { aforoActual: aforo + 1 });
                return estado;
            });
            res.json({ status: result });
        } catch (e) { res.status(500).json({ error: e.message }); }
    });
});

// 🕓 FICHAJE Y OTROS
exports.registrarFichaje = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        await db.collection("timeClockRecords").add({ ...req.body, timestamp: admin.firestore.FieldValue.serverTimestamp() });
        res.json({ success: true });
    });
});

exports.verificarCodigoOTP = onRequest(async (req, res) => {
    return cors(req, res, async () => res.json({ success: true, version: "2026-v2" }));
});