import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
const cors = require("cors")({ origin: true });

if (admin.apps.length === 0) { admin.initializeApp(); }
const db = admin.firestore();

export const cancelarReserva = onRequest((req, res) => {
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
                if (!bSnap.exists) throw new Error("La reserva no existe.");
                
                const bData = bSnap.data();
                const cRef = db.collection("groupClasses").doc(bData!.groupClassId);
                const cSnap = await t.get(cRef);
                if (!cSnap.exists) throw new Error("La clase no existe.");
                
                const cData = cSnap.data();
                const ahora = new Date();
                const fechaClase = cData!.fechaHoraInicio.toDate();
                const diffHoras = (fechaClase.getTime() - ahora.getTime()) / (1000 * 60 * 60);
                
                if (diffHoras >= 24) {
                    const passesSnap = await t.get(db.collection("passes")
                        .where("userId", "==", bData!.userId)
                        .where("activo", "==", true)
                        .limit(1));

                    if (!passesSnap.empty) {
                        const passRef = passesSnap.docs[0].ref;
                        const tokensActuales = passesSnap.docs[0].data().tokensRestantes || 0;
                        t.update(passRef, { tokensRestantes: tokensActuales + 1 });
                        reembolsoRealizado = true;
                    }
                }

                const nuevoAforo = Math.max(0, (cData!.aforoActual || 1) - 1);
                t.update(cRef, { aforoActual: nuevoAforo });
                t.delete(bRef);
            });

            res.json({ 
                success: true, 
                tokenDevuelto: reembolsoRealizado,
                message: reembolsoRealizado ? "Reserva anulada y token devuelto." : "Reserva anulada (sin devolución de token)."
            });
            return;
        } catch (e: any) {
            res.status(400).json({ error: e.message });
            return;
        }
    });
});
