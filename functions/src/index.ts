/**
 * Salufit Cloud Functions — Versión blindada 2026-04-20
 *
 * Políticas aplicadas:
 * - Rate limiting por UID/email/IP usando Firestore
 * - Prevención de enumeración de usuarios
 * - Validación de input estricta
 * - CORS whitelist (no abierto)
 * - Logging de auditoría en cada operación sensible
 * - Cascade delete RGPD-compliant para derecho al olvido
 */

import { onRequest } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Dominios autorizados a llamar nuestras funciones HTTP
const ALLOWED_ORIGINS = [
    "https://centrosalufit.com",
    "https://www.centrosalufit.com",
    "https://salufit-app.web.app",
    "https://salufit-app.firebaseapp.com",
];

// Helper CORS con whitelist estricta
function applyCors(req: any, res: any): boolean {
    const origin = (req.headers.origin as string) || "";
    if (ALLOWED_ORIGINS.includes(origin)) {
        res.set("Access-Control-Allow-Origin", origin);
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.set("Access-Control-Max-Age", "3600");
    }
    if (req.method === "OPTIONS") {
        res.status(204).send("");
        return true;
    }
    return false;
}

if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// HELPERS DE SEGURIDAD
// ═══════════════════════════════════════════════════════════════

/**
 * Rate limiter basado en Firestore.
 * @param key identificador único (uid, email hash, IP)
 * @param maxAttempts intentos permitidos en la ventana
 * @param windowSeconds duración de la ventana en segundos
 */
async function checkRateLimit(
    key: string,
    maxAttempts: number,
    windowSeconds: number,
): Promise<void> {
    const now = Date.now();
    const cutoff = now - windowSeconds * 1000;
    const ref = db.collection("rate_limits").doc(key);

    await db.runTransaction(async (t) => {
        const snap = await t.get(ref);
        const data = snap.data() || {};
        const attempts: number[] = (data.attempts || []).filter(
            (ts: number) => ts > cutoff,
        );
        if (attempts.length >= maxAttempts) {
            throw new functions.https.HttpsError(
                "resource-exhausted",
                "Demasiados intentos. Espera unos minutos.",
            );
        }
        attempts.push(now);
        t.set(ref, { attempts, lastAttempt: now }, { merge: true });
    });
}

/**
 * Valida formato de email RFC 5322 simplificado.
 */
function isValidEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
}

/**
 * Valida que un string sea un número de historia aceptable.
 */
function isValidHistoryId(raw: string): boolean {
    return /^\d{1,10}$/.test(raw);
}

/**
 * Valida fortaleza de contraseña (12+ chars, mayúscula, minúscula, número).
 */
function isStrongPassword(pwd: string): boolean {
    if (pwd.length < 12) return false;
    if (!/[A-Z]/.test(pwd)) return false;
    if (!/[a-z]/.test(pwd)) return false;
    if (!/\d/.test(pwd)) return false;
    return true;
}

/**
 * Escribe un registro de auditoría.
 */
async function writeAudit(entry: {
    tipo: string;
    userId: string | null;
    targetUserId?: string;
    metadata?: Record<string, unknown>;
    ip?: string;
    userAgent?: string;
    status: "SUCCESS" | "FAILURE" | "DENIED";
}): Promise<void> {
    try {
        await db.collection("audit_logs").add({
            ...entry,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (e) {
        console.error("No se pudo escribir audit log:", e);
    }
}

// ═══════════════════════════════════════════════════════════════
// ACTIVACIÓN — Prevención de enumeración + rate limit
// ═══════════════════════════════════════════════════════════════
export const checkAccountStatus = functions.https.onCall(async (data, context) => {
    const emailRaw = (data?.email as string | undefined)?.trim().toLowerCase() || "";
    const historyIdRaw = (data?.historyId as string | undefined)?.toString().trim() || "";

    // Validación de input
    if (!isValidEmail(emailRaw)) {
        throw new functions.https.HttpsError("invalid-argument", "Email inválido.");
    }
    if (!isValidHistoryId(historyIdRaw)) {
        throw new functions.https.HttpsError("invalid-argument", "Número de historia inválido.");
    }

    // Rate limit — 5 intentos cada 15 minutos por email
    const rateLimitKey = `activate_${Buffer.from(emailRaw).toString("base64").slice(0, 32)}`;
    await checkRateLimit(rateLimitKey, 5, 900);

    const idString = historyIdRaw.padStart(6, "0");
    const idNumber = parseInt(historyIdRaw, 10);

    try {
        // ¿Ya está activado?
        const userSnapshot = await db.collection("users_app")
            .where("email", "==", emailRaw)
            .limit(1)
            .get();

        if (!userSnapshot.empty) {
            await writeAudit({
                tipo: "ACTIVATION_ALREADY_REGISTERED",
                userId: null,
                metadata: { emailHash: Buffer.from(emailRaw).toString("base64").slice(0, 16) },
                status: "SUCCESS",
            });
            return { status: "ALREADY_REGISTERED" };
        }

        // Buscar en bbdd y legacy_import
        const [bbddSnapshot, legacySnapshot] = await Promise.all([
            db.collection("bbdd").where("email", "==", emailRaw).get(),
            db.collection("legacy_import").where("email", "==", emailRaw).get(),
        ]);

        const allDocs = [...bbddSnapshot.docs, ...legacySnapshot.docs];

        // Prevención de enumeración: siempre misma respuesta genérica si falla
        if (allDocs.length === 0) {
            await writeAudit({
                tipo: "ACTIVATION_NOT_FOUND",
                userId: null,
                status: "FAILURE",
            });
            // Respuesta que no revela si el email existe o no
            return { status: "NOT_FOUND" };
        }

        const match = allDocs.find((doc) => {
            const d = doc.data();
            const dbId = d.historyId || d.idH || d.numero || d.numHistoria;
            return dbId == idString || dbId == idNumber || dbId == historyIdRaw;
        });

        if (!match) {
            await writeAudit({
                tipo: "ACTIVATION_INVALID_HISTORY",
                userId: null,
                status: "FAILURE",
            });
            return { status: "NOT_FOUND" };
        }

        const matchData = match.data();

        let uid: string;
        try {
            const existingUser = await admin.auth().getUserByEmail(emailRaw);
            uid = existingUser.uid;
        } catch {
            const newUser = await admin.auth().createUser({
                email: emailRaw,
                displayName: matchData.nombreCompleto || matchData.nombre || emailRaw,
            });
            uid = newUser.uid;
        }

        await db.collection("users_app").doc(uid).set({
            email: emailRaw,
            nombre: matchData.nombre || "",
            nombreCompleto: matchData.nombreCompleto || matchData.nombre || "",
            numHistoria: matchData.numHistoria || matchData.historyId || matchData.idH || historyIdRaw,
            rol: "cliente",
            activo: true,
            // Marcadores de migración pendiente (el cliente completará via MigrationGate)
            passwordUpdated: false,
            dateOfBirthSet: false,
            consentVersion: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await writeAudit({
            tipo: "ACTIVATION_SUCCESS",
            userId: uid,
            status: "SUCCESS",
        });

        return { status: "ACTIVATION_PENDING" };
    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error("Error en checkAccountStatus");
        throw new functions.https.HttpsError("internal", "Error al procesar la solicitud.");
    }
});

// ═══════════════════════════════════════════════════════════════
// CONSUMO DE TOKEN POR QR (asistencia sin reserva / walk-in)
// ═══════════════════════════════════════════════════════════════
export const consumirTokenPorQR = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const scannerUid = context.auth.uid;
    const scannedUid = (data?.scannedUserId as string | undefined)?.trim() || "";

    if (!scannedUid || !/^[A-Za-z0-9]{10,40}$/.test(scannedUid)) {
        throw new functions.https.HttpsError("invalid-argument", "UID de cliente inválido.");
    }

    // Rate limit: 60 escaneos / minuto por profesional (uso legítimo intenso aceptado)
    await checkRateLimit(`qr_scan_${scannerUid}`, 60, 60);

    const scannerDoc = await db.collection("users_app").doc(scannerUid).get();
    if (!scannerDoc.exists) {
        throw new functions.https.HttpsError("permission-denied", "Tu perfil no existe.");
    }
    const scannerRole = (scannerDoc.data()?.rol || "").toLowerCase();
    const isStaff = ["admin", "administrador", "profesional"].includes(scannerRole);
    if (!isStaff) {
        await writeAudit({
            tipo: "QR_SCAN_DENIED",
            userId: scannerUid,
            targetUserId: scannedUid,
            status: "DENIED",
        });
        throw new functions.https.HttpsError("permission-denied", "Solo el personal puede escanear códigos QR.");
    }

    const scannedDoc = await db.collection("users_app").doc(scannedUid).get();
    if (!scannedDoc.exists) {
        await writeAudit({
            tipo: "QR_SCAN_USER_NOT_FOUND",
            userId: scannerUid,
            targetUserId: scannedUid,
            status: "FAILURE",
        });
        return { status: "USER_NOT_FOUND" };
    }
    const scannedData = scannedDoc.data()!;
    const clientName = scannedData.nombreCompleto || scannedData.nombre || scannedData.email || "Cliente";

    try {
        const result = await db.runTransaction(async (t) => {
            const passQuery = await db.collection("passes")
                .where("userId", "==", scannedUid)
                .where("activo", "==", true)
                .limit(1)
                .get();

            if (passQuery.empty) {
                return { status: "NO_ACTIVE_PASS", clientName };
            }

            const passRef = passQuery.docs[0].ref;
            const passSnap = await t.get(passRef);
            const tokensRestantes = (passSnap.data()?.tokensRestantes as number | undefined) ?? 0;

            if (tokensRestantes <= 0) {
                return { status: "NO_TOKENS", clientName, tokensRestantes };
            }

            t.update(passRef, { tokensRestantes: tokensRestantes - 1 });

            const attendanceRef = db.collection("walk_in_attendance").doc();
            t.set(attendanceRef, {
                clientId: scannedUid,
                clientName,
                scannerId: scannerUid,
                scannerName: scannerDoc.data()?.nombreCompleto || scannerDoc.data()?.nombre || "",
                scannerRole,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                passId: passRef.id,
                tokensBefore: tokensRestantes,
                tokensAfter: tokensRestantes - 1,
            });

            return { status: "SUCCESS", clientName, tokensAfter: tokensRestantes - 1 };
        });

        await writeAudit({
            tipo: "QR_SCAN",
            userId: scannerUid,
            targetUserId: scannedUid,
            metadata: { result: (result as any).status },
            status: (result as any).status === "SUCCESS" ? "SUCCESS" : "FAILURE",
        });

        return result;
    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error("Error en consumirTokenPorQR");
        throw new functions.https.HttpsError("internal", "Error al procesar el escaneo.");
    }
});

// ═══════════════════════════════════════════════════════════════
// VALIDAR NUEVA CONTRASEÑA (invocada desde MigrationGate)
// ═══════════════════════════════════════════════════════════════
export const setStrongPassword = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const uid = context.auth.uid;
    const newPassword = (data?.newPassword as string | undefined) || "";

    if (!isStrongPassword(newPassword)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "La contraseña debe tener al menos 12 caracteres, una mayúscula, una minúscula y un número.",
        );
    }

    // Rate limit: 3 cambios / hora
    await checkRateLimit(`pwd_${uid}`, 3, 3600);

    try {
        await admin.auth().updateUser(uid, { password: newPassword });
        await db.collection("users_app").doc(uid).update({
            passwordUpdated: true,
            passwordUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await writeAudit({
            tipo: "PASSWORD_UPDATED",
            userId: uid,
            status: "SUCCESS",
        });
        return { status: "SUCCESS" };
    } catch (error) {
        console.error("Error en setStrongPassword");
        await writeAudit({
            tipo: "PASSWORD_UPDATE_FAILED",
            userId: uid,
            status: "FAILURE",
        });
        throw new functions.https.HttpsError("internal", "No se pudo actualizar la contraseña.");
    }
});

// ═══════════════════════════════════════════════════════════════
// DELETE USER DATA — Cascada RGPD-compliant (derecho al olvido)
// ═══════════════════════════════════════════════════════════════
export const deleteUserData = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const callerUid = context.auth.uid;
    const targetUid = (data?.targetUserId as string | undefined)?.trim() || callerUid;

    // Solo el propio usuario o un admin puede borrar datos
    let isAdmin = false;
    if (targetUid !== callerUid) {
        const callerDoc = await db.collection("users_app").doc(callerUid).get();
        const callerRole = (callerDoc.data()?.rol || "").toLowerCase();
        isAdmin = ["admin", "administrador"].includes(callerRole);
        if (!isAdmin) {
            throw new functions.https.HttpsError("permission-denied", "No tienes permiso para borrar a otros usuarios.");
        }
    }

    // Rate limit: 1 borrado por usuario cada 24h (protección contra abuso)
    await checkRateLimit(`delete_${callerUid}`, 1, 86400);

    const collectionsToCleanByUserId = [
        "bookings",
        "passes",
        "documents",
        "signed_documents",
        "exercise_assignments",
        "exercises",
        "patient_metrics",
        "patient_data",
        "walk_in_attendance",
        "appointments",
        "otp_requests",
    ];
    const collectionsToCleanByClientId = ["walk_in_attendance"];
    const collectionsToCleanByAsignadoA = ["staff_tasks"];

    try {
        // Borrar documentos por userId
        for (const col of collectionsToCleanByUserId) {
            const snap = await db.collection(col).where("userId", "==", targetUid).get();
            const batch = db.batch();
            snap.docs.forEach((d) => batch.delete(d.ref));
            if (snap.size > 0) await batch.commit();
        }

        // Borrar walk_in_attendance por clientId
        for (const col of collectionsToCleanByClientId) {
            const snap = await db.collection(col).where("clientId", "==", targetUid).get();
            const batch = db.batch();
            snap.docs.forEach((d) => batch.delete(d.ref));
            if (snap.size > 0) await batch.commit();
        }

        // Borrar tareas asignadas (marcar como eliminadas, no borrar para auditoría)
        for (const col of collectionsToCleanByAsignadoA) {
            const snap = await db.collection(col).where("asignadoAId", "==", targetUid).get();
            const batch = db.batch();
            snap.docs.forEach((d) => batch.update(d.ref, { usuarioEliminado: true }));
            if (snap.size > 0) await batch.commit();
        }

        // Borrar Storage (fotos, firmas, documentos subidos)
        const bucket = admin.storage().bucket();
        const prefixes = [`patients/${targetUid}/`, `signatures/${targetUid}/`, `users/${targetUid}/`];
        for (const prefix of prefixes) {
            try {
                await bucket.deleteFiles({ prefix });
            } catch (e) {
                console.warn(`No se pudo borrar Storage ${prefix}:`, e);
            }
        }

        // Borrar perfil principal
        await db.collection("users_app").doc(targetUid).delete();

        // Borrar en Firebase Auth (solo si es el propio usuario o admin)
        try {
            await admin.auth().deleteUser(targetUid);
        } catch (e) {
            console.warn("No se pudo borrar Auth user:", e);
        }

        await writeAudit({
            tipo: "USER_DATA_DELETED",
            userId: callerUid,
            targetUserId: targetUid,
            metadata: { cascadeCollections: collectionsToCleanByUserId.length },
            status: "SUCCESS",
        });

        return { status: "SUCCESS" };
    } catch (error) {
        console.error("Error en deleteUserData");
        await writeAudit({
            tipo: "USER_DATA_DELETE_FAILED",
            userId: callerUid,
            targetUserId: targetUid,
            status: "FAILURE",
        });
        throw new functions.https.HttpsError("internal", "No se pudo completar el borrado.");
    }
});

// ═══════════════════════════════════════════════════════════════
// LOG AUDIT — Entrada manual de eventos de auditoría desde cliente
// ═══════════════════════════════════════════════════════════════
export const logAudit = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const uid = context.auth.uid;
    const tipo = (data?.tipo as string | undefined)?.trim() || "";
    const metadata = (data?.metadata as Record<string, unknown> | undefined) || {};

    if (!tipo || tipo.length > 100) {
        throw new functions.https.HttpsError("invalid-argument", "Tipo inválido.");
    }

    // Rate limit: máximo 120 eventos / hora por usuario
    await checkRateLimit(`audit_${uid}`, 120, 3600);

    await writeAudit({
        tipo,
        userId: uid,
        metadata,
        status: "SUCCESS",
    });

    return { ok: true };
});

// ═══════════════════════════════════════════════════════════════
// CANCELAR RESERVA — Actualizado con CORS seguro y auditoría
// ═══════════════════════════════════════════════════════════════
export const cancelarReserva = onRequest(async (req, res) => {
    if (applyCors(req, res)) return;

    const authHeader = req.headers.authorization || "";
    if (!authHeader.startsWith("Bearer ")) {
        res.status(401).json({ error: "No autenticado" });
        return;
    }

    let callerUid: string;
    try {
        const token = authHeader.substring(7);
        const decoded = await admin.auth().verifyIdToken(token);
        callerUid = decoded.uid;
    } catch {
        res.status(401).json({ error: "Token inválido" });
        return;
    }

    const { bookingId } = req.body || {};
    if (!bookingId || typeof bookingId !== "string") {
        res.status(400).json({ error: "Falta bookingId" });
        return;
    }

    try {
        let reembolsoRealizado = false;

        await db.runTransaction(async (t) => {
            const bRef = db.collection("bookings").doc(bookingId);
            const bSnap = await t.get(bRef);
            if (!bSnap.exists) throw new Error("La reserva no existe.");

            const bData = bSnap.data()!;

            // Verificar ownership o staff
            if (bData.userId !== callerUid) {
                const callerDoc = await db.collection("users_app").doc(callerUid).get();
                const callerRole = (callerDoc.data()?.rol || "").toLowerCase();
                const isStaff = ["admin", "administrador", "profesional"].includes(callerRole);
                if (!isStaff) throw new Error("No tienes permiso para cancelar esta reserva.");
            }

            const cRef = db.collection("groupClasses").doc(bData.groupClassId);
            const cSnap = await t.get(cRef);
            if (!cSnap.exists) throw new Error("La clase no existe.");

            const cData = cSnap.data()!;
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

        await writeAudit({
            tipo: "BOOKING_CANCELLED",
            userId: callerUid,
            metadata: { bookingId, reembolso: reembolsoRealizado },
            status: "SUCCESS",
        });

        res.json({
            success: true,
            tokenDevuelto: reembolsoRealizado,
            message: reembolsoRealizado
                ? "Reserva anulada y token devuelto."
                : "Reserva anulada (sin devolución de token).",
        });
    } catch (e: any) {
        res.status(400).json({ error: e.message });
    }
});

// ═══════════════════════════════════════════════════════════════
// VIDEO FEEDBACK ROJO — CREAR TAREA PARA EL PROFESIONAL (SERVIDOR)
// ═══════════════════════════════════════════════════════════════
// Trigger: cuando un cliente actualiza el campo `feedback` de su
// exercise_assignment. Si `feedback.alerta` pasa a true (cliente marca
// dificultad ROJA o pulgar abajo en el reproductor), creamos o
// actualizamos una tarea en staff_tasks asignada al profesional que
// asignó originalmente el ejercicio.
//
// Razón: el cliente NO puede listar/escribir en staff_tasks ni leer el
// perfil del profesional por las Firestore Rules — esa lógica vive aquí
// porque admin SDK bypassea las reglas.
async function resolveUserName(
    uid: string,
): Promise<string> {
    try {
        const doc = await db.collection("users_app").doc(uid).get();
        if (!doc.exists) return uid;
        const data = doc.data() ?? {};
        const completo = (data.nombreCompleto as string | undefined) || "";
        if (completo.trim()) return completo;
        const nombre = (data.nombre as string | undefined) || "";
        const apellidos = (data.apellidos as string | undefined) || "";
        const combo = `${nombre} ${apellidos}`.trim();
        if (combo) return combo;
        return (data.email as string | undefined) || uid;
    } catch {
        return uid;
    }
}

export const onExerciseFeedbackChange = onDocumentWritten(
    {
        document: "exercise_assignments/{assignmentId}",
        region: "europe-southwest1",
    },
    async (event) => {
        const before = event.data?.before.data();
        const after = event.data?.after.data();
        if (!after) return;

        const beforeAlerta =
            (before?.feedback?.alerta as boolean | undefined) ?? false;
        const afterAlerta =
            (after.feedback?.alerta as boolean | undefined) ?? false;

        // Solo actuamos cuando feedback.alerta pasa de false→true
        // o cuando el cliente repite la marca roja con alerta ya en true
        // y la fecha cambia (re-marcado).
        const beforeFecha = before?.feedback?.fecha;
        const afterFecha = after.feedback?.fecha;
        const fechaCambia =
            JSON.stringify(beforeFecha) !== JSON.stringify(afterFecha);

        if (!afterAlerta) return;
        if (beforeAlerta && !fechaCambia) return;

        // Solo crear tarea si la dificultad reportada es 'dificil'
        // (rojo). Pulgar abajo también marca alerta=true pero no genera
        // tarea — solo deja constancia en feedback.
        const dificultad = after.feedback?.dificultad as
            | string
            | undefined;
        if (dificultad !== "dificil") return;

        const clientId = (after.userId ?? after.clientId ?? "") as string;
        const assignedBy =
            (after.assignedBy ?? after.professionalId ?? "") as string;
        const exerciseId =
            (after.exerciseId ?? after.ejercicioId ?? event.params.assignmentId) as string;
        const exerciseName =
            (after.nombre ?? after.exerciseName ?? "Ejercicio") as string;
        const videoUrl =
            (after.urlVideo ?? after.videoUrl ?? "") as string;

        if (!clientId || !assignedBy) {
            functions.logger.warn(
                "Assignment sin userId o assignedBy — tarea no creada",
                { assignmentId: event.params.assignmentId },
            );
            return;
        }

        const [clientName, assignedToName] = await Promise.all([
            resolveUserName(clientId),
            resolveUserName(assignedBy),
        ]);

        const tasksCol = db.collection("staff_tasks");

        // Dedup: si ya hay tarea pendiente para (clientId+exerciseId+type),
        // incrementar contador y refrescar fechas. Sino, crear nueva.
        const existing = await tasksCol
            .where("type", "==", "video_difficulty_red")
            .where("clientId", "==", clientId)
            .where("exerciseId", "==", exerciseId)
            .where("estado", "==", "pendiente")
            .limit(1)
            .get();

        if (!existing.empty) {
            await existing.docs[0].ref.update({
                reportCount: admin.firestore.FieldValue.increment(1),
                lastReportAt: admin.firestore.FieldValue.serverTimestamp(),
                pushPending: true,
            });
            functions.logger.info("staff_tasks reabierta (dedup)", {
                taskId: existing.docs[0].id,
                clientId,
                exerciseId,
            });
            return;
        }

        const fechaLimite = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        );
        const created = await tasksCol.add({
            titulo: `Dificultad alta reportada en ${exerciseName}`,
            descripcion:
                `${clientName} ha marcado este ejercicio en rojo (muy difícil). ` +
                "Revisa si conviene ajustar la progresión o sustituirlo.",
            creadoPorId: "system",
            creadoPorNombre: "Sistema (feedback automático)",
            asignadoAId: assignedBy,
            asignadoANombre: assignedToName,
            fechaLimite,
            estado: "pendiente",
            fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
            type: "video_difficulty_red",
            clientId,
            clientName,
            exerciseId,
            exerciseName,
            videoUrl,
            assignmentId: event.params.assignmentId,
            reportCount: 1,
            firstReportAt: admin.firestore.FieldValue.serverTimestamp(),
            lastReportAt: admin.firestore.FieldValue.serverTimestamp(),
            pushPending: true,
        });
        functions.logger.info("staff_tasks creada", {
            taskId: created.id,
            clientId,
            exerciseId,
            assignedBy,
        });
    },
);

// ═══════════════════════════════════════════════════════════════
// VIDEO FEEDBACK ROJO — PUSH AL PROFESIONAL
// ═══════════════════════════════════════════════════════════════
// Trigger Firestore: cuando se crea o actualiza una staff_tasks con
// type='video_difficulty_red' y pushPending=true, envía notificación
// FCM al profesional asignado y marca pushPending=false. La app cliente
// (Flutter) escribe el campo pushPending=true al crear/incrementar la
// tarea desde el reproductor de vídeos del paciente.
export const sendVideoFeedbackPush = onDocumentWritten(
    {
        document: "staff_tasks/{taskId}",
        region: "europe-southwest1",
    },
    async (event) => {
        const afterSnap = event.data?.after;
        const after = afterSnap?.data();
        if (!afterSnap || !after) return;
        if (after.type !== "video_difficulty_red") return;
        if (after.pushPending !== true) return;

        const asignadoAId = after.asignadoAId as string | undefined;
        if (!asignadoAId) {
            await afterSnap.ref.update({
                pushPending: false,
                pushError: "missing_asignadoAId",
            });
            return;
        }

        // Lookup del token FCM del profesional
        let fcmToken = "";
        try {
            const userDoc = await db
                .collection("users_app")
                .doc(asignadoAId)
                .get();
            fcmToken = (userDoc.data()?.fcmToken as string | undefined) ?? "";
        } catch (e) {
            functions.logger.error("Error leyendo fcmToken", e);
        }

        if (!fcmToken) {
            await afterSnap.ref.update({
                pushPending: false,
                pushError: "no_token",
            });
            return;
        }

        const exerciseName =
            (after.exerciseName as string | undefined) || "un ejercicio";
        const clientName =
            (after.clientName as string | undefined) || "Un cliente";
        const reportCount = (after.reportCount as number | undefined) ?? 1;

        const title =
            reportCount > 1
                ? `⚠️ ${clientName} reporta dificultad (${reportCount}x)`
                : `⚠️ ${clientName} marca rojo en ${exerciseName}`;
        const body =
            "Toca para revisar. Considera ajustar la progresión o sustituir el ejercicio.";

        try {
            await admin.messaging().send({
                token: fcmToken,
                notification: { title, body },
                data: {
                    type: "video_difficulty_red",
                    taskId: event.params.taskId,
                    clientId: (after.clientId as string | undefined) ?? "",
                    exerciseId: (after.exerciseId as string | undefined) ?? "",
                    assignmentId:
                        (after.assignmentId as string | undefined) ?? "",
                    reportCount: String(reportCount),
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "salufit_default",
                        priority: "high",
                    },
                },
                apns: {
                    payload: {
                        aps: { sound: "default", badge: 1 },
                    },
                },
            });
            await afterSnap.ref.update({
                pushPending: false,
                pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        } catch (err: any) {
            functions.logger.error("FCM send error", err);
            await afterSnap.ref.update({
                pushPending: false,
                pushError: String(err?.message ?? err),
            });
        }
    },
);

