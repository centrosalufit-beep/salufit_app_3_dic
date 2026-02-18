const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

if (admin.apps.length === 0) { admin.initializeApp(); }
const db = admin.firestore();

exports.cancelarReserva = onRequest((req, res) => cors(req, res, async () => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: "No autorizado" });
    }
    
    const { bookingId } = req.body;
    if (!bookingId) return res.status(400).json({ error: "Falta bookingId" });

    try {
        await db.runTransaction(async (t) => {
            const bRef = db.collection("bookings").doc(bookingId);
            const bSnap = await t.get(bRef);
            if (!bSnap.exists) throw new Error("La reserva ya no existe.");
            const bData = bSnap.data();

            const cRef = db.collection("groupClasses").doc(bData.groupClassId);
            const cSnap = await t.get(cRef);
            if (!cSnap.exists) throw new Error("La clase no existe.");
            const cData = cSnap.data();

            const ahora = new Date();
            const fechaClase = cData.fechaHoraInicio.toDate();
            const diffHoras = (fechaClase - ahora) / (1000 * 60 * 60);
            
            // DEVOLUCIÓN: Más de 24h de antelación
            if (diffHoras >= 24) {
                // Buscamos CUALQUIER bono activo del usuario (el más reciente)
                const passesSnap = await t.get(db.collection("passes")
                    .where("userId", "==", bData.userId)
                    .where("activo", "==", true)
                    .orderBy("fechaCreacion", "desc")
                    .limit(1));

                if (!passesSnap.empty) {
                    const passRef = passesSnap.docs[0].ref;
                    const tokensActuales = passesSnap.docs[0].data().tokensRestantes || 0;
                    t.update(passRef, { tokensRestantes: tokensActuales + 1 });
                }
            }

            // Actualizamos aforo y borramos reserva
            const nuevoAforo = Math.max(0, (cData.aforoActual || 1) - 1);
            t.update(cRef, { aforoActual: nuevoAforo });
            t.delete(bRef);
        });

        res.json({ success: true, message: "Reserva cancelada y token gestionado." });
    } catch (e) {
        console.error("Error en transacción:", e.message);
        res.status(400).json({ error: e.message });
    }
}));
