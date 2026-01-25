/**
 * 🚀 CLOUD FUNCTION - Enviar notificaciones a técnicos
 *
 * Esta función se dispara cuando un cliente crea una nueva solicitud de servicio
 * Busca todos los técnicos disponibles y les envía una notificación FCM
 *
 * PASOS PARA INSTALAR:
 * 1. cd functions
 * 2. npm install firebase-functions firebase-admin
 * 3. Copiar este código en functions/index.js
 * 4. firebase deploy --only functions
 */


const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 📲 TRIGGER: Se dispara cuando se crea un nuevo documento en 'service_requests'
 */
exports.notifyTechniciansOnNewServiceRequest = functions.firestore
  .document("service_requests/{requestId}")
  .onCreate(async (snap, context) => {
    try {
      const serviceRequest = snap.data();
      const requestId = snap.id;

      console.log("✅ Nueva solicitud de servicio detectada:", requestId);
      console.log("📋 Datos:", {
        clientName: serviceRequest.clientName,
        serviceType: serviceRequest.serviceType,
        urgency: serviceRequest.urgencyLevel,
        location: serviceRequest.address,
      });

      // 🔍 PASO 1: Obtener todos los técnicos disponibles con tokens FCM
      const techniciansSnapshot = await admin
        .firestore()
        .collection("users")
        .where("role", "==", "technician")
        .where("isAvailable", "==", true)
        .get();

      console.log(
        `🔍 Técnicos encontrados: ${techniciansSnapshot.docs.length}`,
      );

      if (techniciansSnapshot.empty) {
        console.log("⚠️ No hay técnicos disponibles");
        return null;
      }

      // 📤 PASO 2: Preparar payload de notificación
      const notificationPayload = {
        notification: {
          title: `Nueva Solicitud: ${serviceRequest.serviceType}`,
          body: `${serviceRequest.clientName} solicita: ${serviceRequest.description.substring(
            0,
            50,
          )}...`,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          requestId: requestId,
          clientName: serviceRequest.clientName,
          clientEmail: serviceRequest.clientEmail,
          clientPhone: serviceRequest.clientPhone,
          serviceType: serviceRequest.serviceType,
          description: serviceRequest.description,
          urgency: serviceRequest.urgencyLevel,
          latitude: String(serviceRequest.latitude),
          longitude: String(serviceRequest.longitude),
          address: serviceRequest.address,
          preferredDate: serviceRequest.preferredDate.toDate().toISOString(),
          createdAt: serviceRequest.createdAt.toDate().toISOString(),
          type: "service_request",
        },
      };

      // 📨 PASO 3: Enviar notificación a cada técnico
      const fcmTokens = [];
      techniciansSnapshot.forEach((doc) => {
        const techData = doc.data();
        if (techData.fcmToken) {
          fcmTokens.push(techData.fcmToken);
          console.log(`   → Técnico: ${techData.name} (${techData.email})`);
        }
      });

      if (fcmTokens.length === 0) {
        console.log("⚠️ No hay tokens FCM disponibles");
        return null;
      }

      // Enviar en lotes (Firebase permite máx 500 por lote)
      const batchSize = 500;
      for (let i = 0; i < fcmTokens.length; i += batchSize) {
        const batch = fcmTokens.slice(i, i + batchSize);
        try {
          const response = await admin.messaging().sendMulticast({
            ...notificationPayload,
            tokens: batch,
          });

          console.log(
            `✅ Notificaciones enviadas: ${response.successCount}/${batch.length}`,
          );

          if (response.failureCount > 0) {
            console.log(`❌ Fallos: ${response.failureCount}/${batch.length}`);
            response.responses.forEach((resp, index) => {
              if (!resp.success) {
                console.log(`   Token inválido: ${batch[index]}`);
                // Eliminar tokens inválidos
                admin
                  .firestore()
                  .collection("users")
                  .where("fcmToken", "==", batch[index])
                  .get()
                  .then((snap) => {
                    snap.forEach((doc) => {
                      doc.ref.update({ fcmToken: null });
                    });
                  });
              }
            });
          }
        } catch (error) {
          console.error("❌ Error enviando lote:", error);
        }
      }

      // 💾 PASO 4: Guardar log de la notificación
      await admin
        .firestore()
        .collection("service_requests")
        .doc(requestId)
        .update({
          notificationsSentCount: fcmTokens.length,
          notificationsSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("✅ Proceso completado");
      return null;
    } catch (error) {
      console.error("❌ Error en Cloud Function:", error);
      throw error;
    }
  });

/**
 * 🔔 VERIFICAR SALUD DEL SERVICIO
 */
exports.checkFCMHealth = functions.https.onCall(async (data, context) => {
  try {
    const snapshot = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "technician")
      .get();

    const withTokens = snapshot.docs.filter(
      (doc) => doc.data().fcmToken,
    ).length;

    return {
      status: "healthy",
      totalTechnicians: snapshot.docs.length,
      techniciansWithTokens: withTokens,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error("Error en health check:", error);
    return {
      status: "error",
      error: error.message,
    };
  }
});
