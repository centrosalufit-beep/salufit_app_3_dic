/**
 * ==============================================================================
 * SALUFIT BACKEND - LEGACY FUNCTIONS BACKUP
 *
 * ⚠️  IMPORTANTE: Este archivo NO se despliega automáticamente. Vive fuera de
 *     src/ para que TypeScript no lo compile. Es un backup del código que
 *     actualmente corre en producción pero que nunca estuvo versionado.
 *
 * Origen: reconstruido desde `auditoria app/03_Backend_Cloud_Functions.txt`
 * Estado: aproximación al código de enero de 2026
 * Fecha backup en repo: 2026-04-20
 *
 * Para información completa: ver README.md en este mismo directorio.
 * ==============================================================================
 */

const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require('nodemailer');

const cors = require('cors')({ origin: true });

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, memory: '512MiB', timeoutSeconds: 60, region: 'us-central1' });

const gmailPassword = defineSecret("GMAIL_PASSWORD");

// eslint-disable-next-line no-unused-vars
const getTransporter = () => {
    return nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'centrosalufit@gmail.com',
            pass: gmailPassword.value()
        }
    });
};

// ==========================================
// HELPER: VALIDADOR DE TOKEN
// ==========================================
async function validarUsuario(req, res) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: "Acceso denegado: Falta credencial." });
        return null;
    }
    const token = authHeader.split('Bearer ')[1];
    try {
        return await admin.auth().verifyIdToken(token);
    } catch (error) {
        res.status(403).json({ error: "Acceso denegado: Credencial caducada." });
        return null;
    }
}

// ==========================================
// HELPER: HIDRATACIÓN DE EMAIL
// ==========================================
async function hidratarEmail(change) {
    if (!change.after.exists) return null;
    const dataNew = change.after.data();
    if (dataNew.userEmail && dataNew.userEmail.includes('@')) return null;
    if (!dataNew.userId) return null;
    try {
        let userSnapshot = await db.collection("users").doc(String(dataNew.userId)).get();
        if (!userSnapshot.exists) {
            const q = await db.collection("users").where("id", "==", String(dataNew.userId)).limit(1).get();
            if (!q.empty) userSnapshot = q.docs[0];
        }
        if (userSnapshot.exists && userSnapshot.data().email) {
            return change.after.ref.update({ userEmail: userSnapshot.data().email });
        }
    } catch (e) {
        console.error("Error hidratando email:", e);
    }
    return null;
}

// ==========================================
// TRIGGERS DE FIRESTORE - HIDRATACIÓN DE EMAIL
// ==========================================
exports.autoEmailAppointments = onDocumentWritten("appointments/{id}", (e) => hidratarEmail(e));
exports.autoEmailBookings = onDocumentWritten("bookings/{id}", (e) => hidratarEmail(e));
exports.autoEmailPasses = onDocumentWritten("passes/{id}", (e) => hidratarEmail(e));
exports.autoEmailTimeRecords = onDocumentWritten("timeClockRecords/{id}", (e) => hidratarEmail(e));
exports.autoEmailExerciseAssignments = onDocumentWritten("exercise_assignments/{id}", (e) => hidratarEmail(e));

// ==========================================
// NOTIFICACIONES PUSH (RGPD) - Cambio de reserva
// ==========================================
exports.notificarCambioReserva = onDocumentWritten("bookings/{bookingId}", async (event) => {
    const newData = event.data?.after.exists ? event.data.after.data() : null;
    const oldData = event.data?.before.exists ? event.data.before.data() : null;
    const bookingId = event.params.bookingId;
    if (!newData) return;

    const userId = newData.userId;
    if (!userId) return;

    const esNueva = !oldData;
    const cambioEstado = oldData && newData.estado !== oldData.estado;
    if (!esNueva && !cambioEstado) return;

    try {
        let userDoc = await db.collection("users").doc(String(userId)).get();
        if (!userDoc.exists) {
            const q = await db.collection("users").where("id", "==", String(userId)).limit(1).get();
            if (!q.empty) userDoc = q.docs[0];
        }

        if (!userDoc.exists) return;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) return;

        const messagePayload = {
            token: fcmToken,
            notification: {
                title: "Aviso de Salufit",
                body: "Tienes una actualización en tu agenda. Pulsa para gestionar.",
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                tipo: "actualizacion_reserva",
                bookingId: bookingId,
                estado: newData.estado || "desconocido",
                fechaTimestamp: newData.fechaReserva ? newData.fechaReserva.toDate().toISOString() : ""
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "salufit_citas_channel",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            apns: {
                payload: {
                    aps: { sound: "default", badge: 1 }
                }
            }
        };
        await admin.messaging().send(messagePayload);
    } catch (error) {
        console.error("Error enviando push:", error);
    }
});

// ==========================================
// REGISTRO DE JORNADA (FICHAJE)
// Llamada desde lib/services/staff_service.dart:67
// ==========================================
exports.registrarFichaje = onRequest((req, res) => {
    return cors(req, res, async () => {
        const usuarioAuth = await validarUsuario(req, res);
        if (!usuarioAuth) return;

        const { userId, type, wifiSsid, deviceId, manualTime } = req.body;

        try {
            if (!userId || !type || !deviceId) return res.status(400).json({ error: "Faltan datos" });

            let timestampFinal = admin.firestore.FieldValue.serverTimestamp();
            let isManual = false;

            if (manualTime) {
                const adminCheck = await db.collection('users').doc(usuarioAuth.uid).get();
                const rol = adminCheck.exists ? adminCheck.data().rol : 'cliente';
                if (['admin', 'administrador', 'staff'].includes(rol)) {
                    timestampFinal = admin.firestore.Timestamp.fromDate(new Date(manualTime));
                    isManual = true;
                }
            } else {
                const config = await db.collection("config").doc("time_clock_settings").get();
                const wifis = config.exists ? (config.data().allowedWifis || []) : [];
                if (wifis.length > 0 && (!wifiSsid || !wifis.includes(wifiSsid))) {
                    return res.status(403).json({ error: "WiFi no autorizada." });
                }
            }

            const lastSnap = await db.collection("timeClockRecords")
                .where("userId", "==", userId)
                .orderBy("timestamp", "desc")
                .limit(1)
                .get();

            const last = lastSnap.empty ? null : lastSnap.docs[0].data();
            const hoyStart = new Date(); hoyStart.setHours(0, 0, 0, 0);

            if (type === "IN" && last && last.type === "IN" && last.timestamp.toDate() >= hoyStart) {
                return res.status(400).json({ error: "Ya has fichado entrada hoy" });
            }
            if (type === "OUT" && (!last || last.type === "OUT")) {
                return res.status(400).json({ error: "No tienes entrada registrada" });
            }

            let userEmail = usuarioAuth.email;
            if (!userEmail) {
                const uDoc = await db.collection("users").doc(userId).get();
                if (uDoc.exists) userEmail = uDoc.data().email;
            }

            await db.collection("timeClockRecords").add({
                userId, userEmail, type, timestamp: timestampFinal,
                deviceId, wifiSsid: wifiSsid || "Unknown", isManualEntry: isManual,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return res.status(200).json({ success: true, message: "Fichaje registrado" });
        } catch (error) {
            return res.status(500).json({ error: error.message });
        }
    });
});

// ==========================================
// GENERACIÓN MENSUAL DE CLASES (ADMIN)
// Llamada desde lib/features/admin_dashboard/presentation/admin_class_manager_screen.dart:65
// ==========================================
exports.generarClasesMensuales = onRequest((req, res) => {
    return cors(req, res, async () => {
        const usuarioAuth = await validarUsuario(req, res);
        if (!usuarioAuth) return;

        const { nombre, diasSemana, hora, minutos, mes, anio, profesional } = req.body;
        const startDate = new Date(anio, mes, 1);
        const endDate = new Date(anio, mes + 1, 0);
        const batch = db.batch();
        let count = 0;

        for (let d = startDate; d <= endDate; d.setDate(d.getDate() + 1)) {
            let jsDay = d.getDay();
            if (jsDay === 0) jsDay = 7;
            if (diasSemana.includes(jsDay)) {
                const inicio = new Date(d); inicio.setHours(hora, minutos, 0, 0);
                const fin = new Date(inicio); fin.setHours(hora + 1, minutos, 0, 0);
                const ref = db.collection("groupClasses").doc();
                batch.set(ref, {
                    nombre, monitor: profesional || "Staff",
                    aforoMax: 12, aforoActual: 0,
                    fechaHoraInicio: admin.firestore.Timestamp.fromDate(inicio),
                    fechaHoraFin: admin.firestore.Timestamp.fromDate(fin),
                    activa: true
                });
                count++;
            }
        }
        await batch.commit();
        return res.json({ success: true, count });
    });
});

// ==========================================
// RENOVACIÓN MASIVA DE BONOS (ADMIN)
// Disparada manualmente desde Firebase Console o Cloud Scheduler
// ==========================================
exports.renovarBonosBatch = onRequest((req, res) => {
    return cors(req, res, async () => {
        const usuarioAuth = await validarUsuario(req, res);
        if (!usuarioAuth) return;

        const { listaUsuarios, mes, anio, tokensPorDefecto } = req.body;
        const batch = db.batch();

        listaUsuarios.forEach(item => {
            const ref = db.collection("passes").doc();
            batch.set(ref, {
                userId: item.userId, mes, anio,
                tokensTotales: item.tokens || tokensPorDefecto || 8,
                tokensRestantes: item.tokens || tokensPorDefecto || 8,
                activo: true,
                fechaCreacion: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();
        return res.json({ success: true });
    });
});
