import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// 🔔 Servicio centralizado para Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// ✅ PASO 1: Inicializar FCM
  Future<void> initialize() async {
    try {
      // Solicitar permisos de notificación (iOS requiere este paso explícito)
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Permisos de notificación: ${settings.authorizationStatus}');

      // Obtener el token FCM del dispositivo
      String? token = await _firebaseMessaging.getToken();
      print('📱 Token FCM obtenido: $token');

      // Configurar listeners para notificaciones
      _setupMessageHandlers();
    } catch (e) {
      print('❌ Error inicializando FCM: $e');
    }
  }

  /// ✅ PASO 2: Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Notificación recibida en primer plano:');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Data: ${message.data}');
      // TODO: Mostrar notificación local
    });

    // Mensajes cuando el usuario toca la notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('✅ Notificación abierta desde background');
      print('   Data: ${message.data}');
      // TODO: Navegar a pantalla específica
    });
  }

  /// ✅ PASO 3: Obtener el token FCM del usuario actual
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🔑 Token FCM: $token');
      return token;
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  /// ✅ PASO 4: Guardar el token FCM en Firebase Firestore
  Future<void> saveFCMTokenToFirebase(String userId, String? token) async {
    try {
      if (token == null) {
        print('⚠️ Token FCM es null, no se puede guardar');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Token FCM guardado para usuario: $userId');
    } catch (e) {
      print('❌ Error guardando token FCM: $e');
    }
  }

  /// ✅ PASO 5: Obtener todos los tokens de técnicos disponibles
  Future<List<String>> getAvailableTechnicianTokens() async {
    try {
      print('🔍 Buscando técnicos disponibles...');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .where('isAvailable', isEqualTo: true)
          .get();

      final tokens = snapshot.docs
          .where((doc) => doc.data()['fcmToken'] != null)
          .map((doc) => doc.data()['fcmToken'] as String)
          .toList();

      print('✅ Encontrados ${tokens.length} técnicos con tokens FCM');
      return tokens;
    } catch (e) {
      print('❌ Error obteniendo tokens de técnicos: $e');
      return [];
    }
  }

  /// ✅ PASO 6: Enviar notificación a un técnico específico (usará REST API)
  /// Nota: Este método se ejecutará en un Cloud Function en el backend
  Future<void> notifyTechnician({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📤 Enviando notificación FCM...');
      // Este método se implementará desde un Cloud Function
      // El Flutter solo maneja la recepción
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  /// ✅ PASO 7: Marcar un técnico como disponible/no disponible
  Future<void> setTechnicianAvailability(
      String userId, bool isAvailable) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isAvailable': isAvailable,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Disponibilidad del técnico actualizada: $isAvailable');
    } catch (e) {
      print('❌ Error actualizando disponibilidad: $e');
    }
  }

  /// 🚀 OPCIÓN 2 SIN CLOUD FUNCTIONS: Notificar técnicos manualmente
  /// Se ejecuta desde la app del cliente cuando crea una solicitud
  Future<int> notifyAvailableTechniciansManual({
    required String requestId,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String serviceType,
    required String description,
    required String urgencyLevel,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime preferredDate,
  }) async {
    try {
      print('📲 === NOTIFICANDO TÉCNICOS (OPCIÓN 2 - SIN CLOUD FUNCTIONS) ===');

      // 1️⃣ Buscar técnicos disponibles
      print('🔍 Buscando técnicos disponibles...');
      final techniciansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (techniciansSnapshot.docs.isEmpty) {
        print('⚠️ No hay técnicos disponibles');
        return 0;
      }

      print('✅ Técnicos encontrados: ${techniciansSnapshot.docs.length}');

      int notificationsSent = 0;

      // 2️⃣ Crear documento de notificación para cada técnico
      for (final doc in techniciansSnapshot.docs) {
        final technicianId = doc.id;
        final technicianData = doc.data();
        final technicianName = technicianData['name'] ?? 'Técnico';

        try {
          // Crear notificación en colección "notifications"
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': technicianId,
            'recipientEmail': technicianData['email'],
            'recipientName': technicianName,
            'type': 'new_service_request',
            'requestId': requestId,
            'clientName': clientName,
            'clientEmail': clientEmail,
            'clientPhone': clientPhone,
            'serviceType': serviceType,
            'description': description,
            'urgencyLevel': urgencyLevel,
            'latitude': latitude,
            'longitude': longitude,
            'address': address,
            'preferredDate': preferredDate,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(Duration(hours: 24)),
          });

          print('   ✅ Notificación enviada a: $technicianName');
          notificationsSent++;
        } catch (e) {
          print('   ❌ Error enviando notificación a $technicianName: $e');
        }
      }

      // 3️⃣ Registrar el conteo en la solicitud
      if (notificationsSent > 0) {
        await FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .update({
          'notificationsSentCount': notificationsSent,
          'notificationsSentAt': FieldValue.serverTimestamp(),
          'notificationType': 'manual_from_app',
        });
      }

      print('✅ Total notificaciones creadas: $notificationsSent');
      return notificationsSent;
    } catch (e) {
      print('❌ Error notificando técnicos: $e');
      return 0;
    }
  }

  /// 📋 NUEVO: Notificar solo técnicos seleccionados por el cliente
  Future<int> notifySelectedTechnicians({
    required String requestId,
    required List<String> selectedTechnicianIds,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String serviceType,
    required String description,
    required String urgencyLevel,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime preferredDate,
    required double proposedPrice,
  }) async {
    try {
      print('📲 === NOTIFICANDO TÉCNICOS SELECCIONADOS ===');
      print('✅ Técnicos a notificar: ${selectedTechnicianIds.length}');

      if (selectedTechnicianIds.isEmpty) {
        print('⚠️ No hay técnicos seleccionados');
        return 0;
      }

      int notificationsSent = 0;

      // Obtener datos de cada técnico seleccionado
      for (final technicianId in selectedTechnicianIds) {
        try {
          final techDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(technicianId)
              .get();

          if (!techDoc.exists) {
            print('   ⚠️ Técnico no encontrado: $technicianId');
            continue;
          }

          final technicianData = techDoc.data();
          final technicianName = technicianData?['name'] ?? 'Técnico';

          // Crear notificación para este técnico
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': technicianId,
            'recipientEmail': technicianData?['email'],
            'recipientName': technicianName,
            'type': 'new_service_request',
            'requestId': requestId,
            'clientName': clientName,
            'clientEmail': clientEmail,
            'clientPhone': clientPhone,
            'serviceType': serviceType,
            'description': description,
            'urgencyLevel': urgencyLevel,
            'latitude': latitude,
            'longitude': longitude,
            'address': address,
            'preferredDate': preferredDate,
            'proposedPrice': proposedPrice,
            'uid': clientName, // uid del cliente para identificar la solicitud
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(Duration(hours: 24)),
          });

          print('   ✅ Notificación enviada a: $technicianName');
          notificationsSent++;
        } catch (e) {
          print('   ❌ Error notificando a $technicianId: $e');
        }
      }

      // Actualizar conteo en la solicitud
      if (notificationsSent > 0) {
        await FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .update({
          'notificationsSentCount': notificationsSent,
          'notificationsSentAt': FieldValue.serverTimestamp(),
          'notificationType': 'manual_selected',
          'selectedTechnicianIds': selectedTechnicianIds,
        });
      }

      print('✅ Total notificaciones creadas: $notificationsSent');
      return notificationsSent;
    } catch (e) {
      print('❌ Error notificando técnicos seleccionados: $e');
      return 0;
    }
  }

  /// 📋 Obtener técnicos cercanos a una ubicación
  Future<List<Map<String, dynamic>>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      print('🔍 Buscando técnicos cercanos...');

      // Obtener todos los técnicos disponibles
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> nearbyTechs = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final techLat = data['location']?['latitude'] as double?;
        final techLng = data['location']?['longitude'] as double?;

        if (techLat != null && techLng != null) {
          // Calcular distancia usando fórmula de Haversine simplificada
          double distance =
              _calculateDistance(latitude, longitude, techLat, techLng);

          if (distance <= radiusKm) {
            nearbyTechs.add({
              'id': doc.id,
              'name': data['name'] ?? 'Técnico',
              'email': data['email'],
              'phone': data['phone'],
              'latitude': techLat,
              'longitude': techLng,
              'distance': distance,
              'rating': data['rating'] ?? 0.0,
            });
          }
        }
      }

      // Ordenar por distancia
      nearbyTechs.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));
      print('✅ Técnicos cercanos encontrados: ${nearbyTechs.length}');

      return nearbyTechs;
    } catch (e) {
      print('❌ Error buscando técnicos cercanos: $e');
      return [];
    }
  }

  /// Calcular distancia entre dos puntos (Haversine)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// 📋 Obtener notificaciones pendientes para un técnico (simplificado)
  Stream<QuerySnapshot> getNotificationsForTechnician(String technicianId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: technicianId)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  /// ✅ Marcar notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      print('✅ Notificación marcada como leída: $notificationId');
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  /// 🎯 ACEPTAR SOLICITUD: Técnico acepta la solicitud de servicio
  Future<bool> acceptServiceRequest({
    required String requestId,
    required String technicianId,
    required String technicianName,
    required String technicianEmail,
  }) async {
    try {
      print('🎯 Técnico aceptando solicitud: $requestId');

      // 1️⃣ Actualizar service_request
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update({
        'technician': technicianId,
        'technicianName': technicianName,
        'technicianEmail': technicianEmail,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Solicitud asignada a técnico: $technicianName');

      // 2️⃣ Crear documento en collection "service_assignments" para historial
      await FirebaseFirestore.instance.collection('service_assignments').add({
        'requestId': requestId,
        'technicianId': technicianId,
        'technicianName': technicianName,
        'technicianEmail': technicianEmail,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Registro de asignación creado');

      // 3️⃣ Marcar todas las notificaciones de esta solicitud como leídas
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('requestId', isEqualTo: requestId)
          .get();

      for (final doc in notificationsSnapshot.docs) {
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'acceptedBy': technicianId,
        });
      }

      print('✅ Notificaciones relacionadas marcadas como leídas');
      return true;
    } catch (e) {
      print('❌ Error aceptando solicitud: $e');
      return false;
    }
  }

  /// ❌ RECHAZAR SOLICITUD: Técnico rechaza la solicitud de servicio
  Future<bool> rejectServiceRequest({
    required String requestId,
    required String technicianId,
    required String technicianName,
    required String rejectionReason,
  }) async {
    try {
      print('❌ Técnico rechazando solicitud: $requestId');

      // 1️⃣ Crear registro de rechazo
      await FirebaseFirestore.instance.collection('service_rejections').add({
        'requestId': requestId,
        'technicianId': technicianId,
        'technicianName': technicianName,
        'reason': rejectionReason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rechazo registrado');

      // 2️⃣ Marcar notificación como rechazada
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('requestId', isEqualTo: requestId)
          .where('recipientId', isEqualTo: technicianId)
          .get();

      if (notificationsSnapshot.docs.isNotEmpty) {
        await notificationsSnapshot.docs.first.reference.update({
          'status': 'rejected',
          'rejectionReason': rejectionReason,
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Notificación marcada como rechazada');
      return true;
    } catch (e) {
      print('❌ Error rechazando solicitud: $e');
      return false;
    }
  }

  /// 📞 Obtener detalles completos de una solicitud
  Future<Map<String, dynamic>?> getServiceRequestDetails(
      String requestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .get();

      if (!doc.exists) {
        print('⚠️ Solicitud no encontrada: $requestId');
        return null;
      }

      print('✅ Detalles de solicitud cargados');
      return doc.data();
    } catch (e) {
      print('❌ Error cargando detalles: $e');
      return null;
    }
  }

  // ============================================================
  // 💰 MÉTODOS PARA NEGOCIACIÓN DE PRECIOS
  // ============================================================

  /// 💬 Enviar contraoferta de precio (técnico envía contraoferta al cliente)
  Future<bool> sendPriceCounterOffer({
    required String requestId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String recipientName,
    required double proposedPrice,
    required double originalPrice,
    required String reason,
  }) async {
    try {
      print('💬 Enviando contraoferta de precio...');
      print('   De: $senderName');
      print('   Para: $recipientName');
      print('   Precio: \$$proposedPrice (Original: \$$originalPrice)');

      // 1️⃣ Crear documento de negociación
      final negotiationRef = await FirebaseFirestore.instance
          .collection('price_negotiations')
          .add({
        'requestId': requestId,
        'senderId': senderId,
        'senderName': senderName,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'proposedPrice': proposedPrice,
        'originalPrice': originalPrice,
        'reason': reason,
        'status': 'pending', // pending, accepted, rejected, expired
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'responseReason': null,
      });

      print('✅ Contraoferta creada: ${negotiationRef.id}');

      // 2️⃣ Actualizar estado de negociación en la solicitud
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update({
        'negotiationStatus': 'active',
        'lastCounterOfferPrice': proposedPrice,
        'lastCounterOfferAt': FieldValue.serverTimestamp(),
        'priceStatus': 'negotiating',
      });

      print('✅ Estado de solicitud actualizado');

      // 3️⃣ Crear notificación para el cliente/técnico
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': senderId,
        'senderName': senderName,
        'type': 'price_counter_offer',
        'requestId': requestId,
        'negotiationId': negotiationRef.id,
        'proposedPrice': proposedPrice,
        'originalPrice': originalPrice,
        'reason': reason,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(hours: 24)),
      });

      print('✅ Notificación de contraoferta enviada');
      return true;
    } catch (e) {
      print('❌ Error enviando contraoferta: $e');
      return false;
    }
  }

  /// ✅ Aceptar contraoferta de precio
  Future<bool> acceptPriceCounterOffer({
    required String negotiationId,
    required String requestId,
    required String acceptedByUserId,
    required double agreedPrice,
  }) async {
    try {
      print('✅ Aceptando contraoferta de precio...');
      print('   Precio acordado: \$$agreedPrice');

      // 1️⃣ Actualizar negociación como aceptada
      await FirebaseFirestore.instance
          .collection('price_negotiations')
          .doc(negotiationId)
          .update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
        'acceptedBy': acceptedByUserId,
      });

      print('✅ Negociación marcada como aceptada');

      // 2️⃣ Actualizar solicitud con precio acordado
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(requestId)
          .update({
        'proposedPrice': agreedPrice,
        'priceStatus': 'agreed',
        'negotiationStatus': 'agreed',
        'agreedPrice': agreedPrice,
        'agreedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Precio acordado actualizado en la solicitud');

      // 3️⃣ Rechazar todas las otras negociaciones pendientes
      final otherNegotiations = await FirebaseFirestore.instance
          .collection('price_negotiations')
          .where('requestId', isEqualTo: requestId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in otherNegotiations.docs) {
        if (doc.id != negotiationId) {
          await doc.reference.update({
            'status': 'expired',
            'responseReason': 'Otra contraoferta fue aceptada',
          });
        }
      }

      print('✅ Otras negociaciones canceladas');
      return true;
    } catch (e) {
      print('❌ Error aceptando contraoferta: $e');
      return false;
    }
  }

  /// ❌ Rechazar contraoferta de precio
  Future<bool> rejectPriceCounterOffer({
    required String negotiationId,
    required String requestId,
    required String rejectedByUserId,
    required String rejectionReason,
  }) async {
    try {
      print('❌ Rechazando contraoferta de precio...');

      // 1️⃣ Actualizar negociación como rechazada
      await FirebaseFirestore.instance
          .collection('price_negotiations')
          .doc(negotiationId)
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'rejectedBy': rejectedByUserId,
        'responseReason': rejectionReason,
      });

      print('✅ Negociación rechazada');

      // 2️⃣ Crear nueva notificación informando el rechazo
      final negotiationDoc = await FirebaseFirestore.instance
          .collection('price_negotiations')
          .doc(negotiationId)
          .get();

      final data = negotiationDoc.data() as Map<String, dynamic>;
      final recipientId = data['senderId'] as String;
      final senderName = data['recipientName'] as String;

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': rejectedByUserId,
        'senderName': senderName,
        'type': 'price_offer_rejected',
        'requestId': requestId,
        'negotiationId': negotiationId,
        'rejectionReason': rejectionReason,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(Duration(hours: 24)),
      });

      print('✅ Notificación de rechazo enviada');
      return true;
    } catch (e) {
      print('❌ Error rechazando contraoferta: $e');
      return false;
    }
  }

  /// 📋 Obtener negociaciones de precios para una solicitud
  Future<List<Map<String, dynamic>>> getPriceNegotiations(
      String requestId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('price_negotiations')
          .where('requestId', isEqualTo: requestId)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ Negociaciones cargadas: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('❌ Error cargando negociaciones: $e');
      return [];
    }
  }

  /// 🔄 Stream de negociaciones pendientes para técnico/cliente
  Stream<QuerySnapshot> getNegotiationUpdatesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('price_negotiations')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ Marcar contraoferta como leída
  Future<void> markCounterOfferAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      print('✅ Contraoferta marcada como leída');
    } catch (e) {
      print('❌ Error marcando como leída: $e');
    }
  }

  /// 🏁 Cancelar todas las negociaciones de una solicitud
  Future<void> cancelAllNegotiations(String requestId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('price_negotiations')
          .where('requestId', isEqualTo: requestId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'responseReason': 'Solicitud cancelada por el cliente',
        });
      }

      print('✅ Todas las negociaciones canceladas');
    } catch (e) {
      print('❌ Error cancelando negociaciones: $e');
    }
  }
}
