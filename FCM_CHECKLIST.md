## 🚀 FCM IMPLEMENTATION CHECKLIST

### ✅ PARTE 1: FLUTTER (Ya Completado)

- [x] Agregar `firebase_messaging: ^15.1.3` en pubspec.yaml
- [x] Crear `core/services/notification_service.dart`
  - [x] `initialize()` - Inicializar FCM y solicitar permisos
  - [x] `getFCMToken()` - Obtener token del dispositivo
  - [x] `saveFCMTokenToFirebase()` - Guardar token en Firestore
  - [x] `_setupMessageHandlers()` - Listener para notificaciones
- [x] Importar NotificationService en `main.dart`
- [x] Inicializar FCM en `main()`
- [x] Guardar token FCM en `login_screen.dart`

**Estado:** ✅ COMPLETO

---

### ⏳ PARTE 2: CLOUD FUNCTIONS (Pasos Manual)

#### 🔧 Instalación Local

```bash
# 1. Abre terminal en C:\Users\USUARIO\Documents\Semestre-25B\Proyecto2B\app_project

# 2. Inicializar Firebase Functions
firebase init functions

# 3. Instalar dependencias
cd functions
npm install firebase-functions firebase-admin

# 4. Reemplazar functions/index.js
# (El contenido ya está creado en: functions/index.js)

# 5. Desplegar
cd ..
firebase deploy --only functions
```

**Tiempo estimado:** 5-10 minutos

---

### 🧪 PARTE 3: TESTING

#### Test 1: Verificar Token FCM Guardado

```
1. Ejecutar app: flutter run
2. Inicia sesión como TÉCNICO
3. Firebase Console > Firestore > users > [técnico]
4. Debe existir campo 'fcmToken' con valor
✅ ESPERADO: Token guardado correctamente
```

#### Test 2: Verificar Cloud Functions

```
1. Firebase Console > Cloud Functions
2. Debe aparecer: notifyTechniciansOnNewServiceRequest (Active)
✅ ESPERADO: Función visible y activa
```

#### Test 3: Enviar Solicitud de Servicio

```
1. Ejecutar app como CLIENTE
2. Dashboard > Solicitar Nuevo Servicio
3. Completar y enviar
4. Observar console: flutter run
✅ ESPERADO: Logs mostrando "Nueva solicitud detectada..."
```

#### Test 4: Recibir Notificación

```
1. Técnico debe estar registrado en app
2. App abierta O en background
✅ ESPERADO: Notificación llega en console o pantalla
```

---

### 📊 MONITOREO

#### Ver Logs de Cloud Functions

```bash
firebase functions:log
```

Verás mensajes como:

```
✅ Nueva solicitud de servicio detectada: abc123
🔍 Técnicos encontrados: 2
✅ Notificaciones enviadas: 2/2
```

#### Ver Base de Datos

- **Colección 'users':** Buscar campo `fcmToken`
- **Colección 'service_requests':** Ver campo `notificationsSentCount`

---

### 🎯 INFORMACIÓN IMPORTANTE

**¿Qué hace la Cloud Function?**

```
Cuándo: Se dispara cuando se crea un documento en 'service_requests'

Qué hace:
1. Lee los datos de la solicitud
2. Busca técnicos con:
   - role = 'technician'
   - isAvailable = true
3. Obtiene sus tokens FCM
4. Envía notificación a cada uno

Datos que envía:
- requestId
- clientName, clientEmail, clientPhone
- serviceType, description
- urgency, latitude, longitude
- address, preferredDate
- createdAt
```

**¿Cómo recibe la app la notificación?**

```
Cuando llega un FCM message:
- App abierta: Se dispara FirebaseMessaging.onMessage
- App background: Se muestra notificación del sistema
- Usuario toca notificación: Se dispara onMessageOpenedApp
```

---

## 📋 RESUMEN VISUAL DEL FLUJO

```
CLIENTE
  ↓
  └─ Inicia sesión
     └─ Token FCM guardado en 'users.fcmToken'

CLIENTE
  ↓
  └─ Crea solicitud de servicio
     └─ Se guarda en collection 'service_requests'

CLOUD FUNCTION (Automático)
  ↓
  ├─ Se dispara onCreate
  ├─ Lee solicitud
  ├─ Busca técnicos disponibles
  ├─ Obtiene sus tokens FCM
  └─ Envía notificación a cada técnico

TÉCNICOS
  ↓
  ├─ Reciben notificación FCM
  ├─ Ven datos de la solicitud
  └─ Pueden aceptar la solicitud
```

---

## 🚨 CHECKLIST ANTES DE DESPLEGAR

- [ ] Ejecuté `flutter pub get`
- [ ] NotificationService está en `lib/core/services/`
- [ ] main.dart importa y inicializa NotificationService
- [ ] login_screen.dart guarda el token FCM
- [ ] Ejecuté `firebase init functions` exitosamente
- [ ] Instalé dependencias en `functions/` con `npm install`
- [ ] Copié el contenido de `index.js` en `functions/index.js`
- [ ] Ejecuté `firebase deploy --only functions` sin errores
- [ ] Verifiqué que Cloud Function está activa en Firebase Console
- [ ] Probé enviando una solicitud de servicio
- [ ] Técnico recibió la notificación

---

## 📱 COMANDOS ÚTILES

```bash
# Ver logs en tiempo real
firebase functions:log

# Redeploy de functions
firebase deploy --only functions

# Test local (opcional)
npm --prefix functions start

# Ver estado de deployment
firebase deploy --only functions --debug
```

---

## ✨ RESULTADO ESPERADO

Cuando completes todo:

1. ✅ Cliente crea solicitud → Cloud Function se dispara
2. ✅ Técnicos reciben notificación automáticamente
3. ✅ Datos de solicitud incluyen ubicación, cliente, urgencia
4. ✅ Técnico puede ver y responder a la solicitud

**¡El sistema está configurado para tiempo real! 🎉**
