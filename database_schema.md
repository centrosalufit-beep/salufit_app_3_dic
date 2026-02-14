# Esquema de Firestore - Salufit

### Colecciones y Campos:
- [cite_start]**users/{uid}**: id (historia), nombreCompleto, email, rol (admin/profesional/cliente), keywords[], fcmToken, termsAccepted (bool)[cite: 1982, 1446].
- [cite_start]**passes/{passId}**: userId, userEmail, mes, anio, tokensTotales, tokensRestantes, activo (bool)[cite: 1594, 1598].
- [cite_start]**bookings/{bookingId}**: userId, userEmail, groupClassId, estado (reservada/espera), fechaReserva (Timestamp), passId[cite: 1868, 1869].
- [cite_start]**groupClasses/{classId}**: nombre, monitor, aforoMax, aforoActual, fechaHoraInicio (Timestamp), fechaHoraFin, activa (bool)[cite: 1018, 1026, 1102].
- [cite_start]**appointments/{apptId}**: userId, patientEmail, profesionalId, especialidad, fechaHoraInicio (Timestamp), estado[cite: 852, 1485, 1486].
- [cite_start]**exercise_assignments/{id}**: userId, userEmail, nombre, urlVideo, familia, instrucciones, completado (bool), feedback{gustado, dificultad, alerta}[cite: 602, 603, 1786].
- [cite_start]**documents/{docId}**: userId, userEmail, titulo, tipo (Clínico/Legal), firmado (bool), urlPdf, fechaCreacion[cite: 469, 474].
- [cite_start]**metrics/{id}**: userId, userEmail, type (Peso/RM), value, unit, date (Timestamp)[cite: 1175, 1176].
- [cite_start]**journal/{id}**: userId, userEmail, title, content, category, date, isStaffRead (bool)[cite: 1206, 1207].