## 📲 IMPLEMENTACIÓN DE FCM - GUÍA COMPLETA

### ✅ PASOS COMPLETADOS EN FLUTTER

#### 1. **Agregar dependencia en pubspec.yaml**

```yaml
firebase_messaging: ^15.1.3
```

#### 2. **Crear NotificationService**

Archivo: `lib/core/services/notification_service.dart`

- ✅ Inicializar FCM
- ✅ Solicitar permisos de notificación
- ✅ Obtener token FCM
- ✅ Guardar token en Firebase
- ✅ Configurar handlers de mensajes

#### 3. **Inicializar FCM en main.dart**

```dart
final notificationService = NotificationService();
await notificationService.initialize();
```

#### 4. **Guardar token FCM en login**

En `login_screen.dart`:

```dart
NotificationService().saveFCMTokenToFirebase(
  user.uid,
  await NotificationService().getFCMToken(),
);
```

---

## 📁 PASOS PARA CONFIGURAR CLOUD FUNCTIONS

### 📋 Requisitos Previos

- Tener instalado Node.js (v18+) y npm
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project configurado

### 🚀 INSTALACIÓN PASO A PASO

#### 1. **Inicializar Firebase Functions**

```bash
cd c:\Users\USUARIO\Documents\Semestre-25B\Proyecto2B\app_project
firebase init functions
```

- Selecciona: "Use an existing project"
- Selecciona tu proyecto Firebase
- Lenguaje: JavaScript
- Usar ESLint: No

#### 2. **Instalar dependencias necesarias**

```bash
cd functions
npm install firebase-functions firebase-admin
```

#### 3. **Reemplazar functions/index.js**

```bash
# Copiar el contenido del archivo proporcionado
# El archivo está en: functions/index.js
```

#### 4. **Verificar que existe el archivo**

```bash
# Verificar que el archivo se creó correctamente
dir functions
```

#### 5. **Desplegar las Cloud Functions**

```bash
# Desde la raíz del proyecto
firebase deploy --only functions
```

Esperarás un output similar a:

```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/[tu-proyecto]/overview
```

---

## 🔐 CONFIGURACIONES NECESARIAS EN FIREBASE CONSOLE

### 1. **Habilitar Cloud Messaging**

- Ir a: Firebase Console > Configuración del Proyecto > Cloud Messaging
- Copiar el "Server API Key" (lo necesitarás para testing)

### 2. **Permisos de Firestore para Cloud Functions**

Las Cloud Functions necesitan estos permisos (suelen estar habilitados por defecto):

```
- Leer/escribir en collection 'users'
- Leer/escribir en collection 'service_requests'
- Ejecutar Firestore transactions
```

### 3. **Probar notificaciones**

Ver el próximo apartado...

---

## 🧪 TESTING - VERIFICAR QUE TODO FUNCIONA

### Verificación 1: Tokens FCM guardados

1. Ejecutar la app
2. Inicia sesión con cuenta de TÉCNICO
3. En Firebase Console > Firestore > collection 'users'
4. Busca el documento del técnico
5. Debe tener un campo `fcmToken` con un valor largo (token)

**Esperado:**

```
{
  uid: "xyz123"
  email: "tecnico@example.com"
  role: "technician"
  fcmToken: "eKOw5o7aQdiGzN..." ← DEBE EXISTIR
  isAvailable: true
}
```

### Verificación 2: Cloud Functions Desplegadas

1. Firebase Console > Cloud Functions
2. Debe aparecer: `notifyTechniciansOnNewServiceRequest`
3. Estado: ✅ Active

**Si no aparece:**

```bash
firebase deploy --only functions
```

### Verificación 3: Simular solicitud de servicio

1. Ejecutar la app como CLIENTE
2. Dashboard > "Solicitar Nuevo Servicio"
3. Completar formulario (descripción min 10 caracteres)
4. Enviar

**En la consola verás:**

```
✅ Nueva solicitud de servicio detectada: [id]
🔍 Técnicos encontrados: 1
   → Técnico: jhonn lugmana (email@example.com)
✅ Notificaciones enviadas: 1/1
```

### Verificación 4: Recibir notificación

1. Tener abierta la app del TÉCNICO
2. O tenerla en background en el mismo dispositivo

**En la consola Flutter verás:**

```
📬 Notificación recibida en primer plano:
   Título: Nueva Solicitud: Horno Microondas
   Cuerpo: jhonn casanova solicita: no sirve ayuda...
   Data: {requestId: "xyz...", ...}
```

---

## 🎯 FLUJO COMPLETO DE NOTIFICACIONES

```
┌─────────────────────────────────┐
│ 1. CLIENTE inicia sesión        │
│    → Se guarda token FCM        │
└────────────┬────────────────────┘
             │
             ↓
┌─────────────────────────────────┐
│ 2. CLIENTE solicita servicio    │
│    → Se crea doc en             │
│       collection 'service_...'  │
└────────────┬────────────────────┘
             │
             ↓
┌─────────────────────────────────┐
│ 3. Cloud Function se dispara    │
│    → Busca técnicos disponibles │
│    → Obtiene sus tokens FCM     │
└────────────┬────────────────────┘
             │
             ↓
┌─────────────────────────────────┐
│ 4. Envía notificaciones FCM     │
│    → A cada técnico por su token│
│    → Con datos de la solicitud  │
└────────────┬────────────────────┘
             │
             ↓
┌─────────────────────────────────┐
│ 5. TÉCNICO recibe notificación  │
│    → Se muestra en pantalla     │
│    → Puede abrir y ver detalles │
└─────────────────────────────────┘
```

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### ❌ "LateInitializationError en nearby_technicians_tab"

**Solución:** Ya corregido - Se movió `mapController.move()` a `addPostFrameCallback`

### ❌ "Técnicos con Lat: null, Lng: null"

**Solución:** Ya corregido - Se convierte `num` a `double` correctamente

### ❌ "No aparecen tokens FCM en Firebase"

1. Verifica permisos: `requestPermission()` en `NotificationService`
2. Verifica que `saveFCMTokenToFirebase()` se llame en login
3. Revisa logs: `print()` en NotificationService

### ❌ "Cloud Functions no se ejecutan"

1. Verifica que el trigger es: `onCreate` en `service_requests`
2. Revisa logs: `firebase functions:log`
3. Vuelve a desplegar: `firebase deploy --only functions`

### ❌ "Notificaciones no llegan a técnicos"

1. Verifica que técnico tenga `isAvailable: true`
2. Verifica que tenga un `fcmToken` válido
3. Revisa logs de Cloud Functions: `firebase functions:log`

---

## 📊 CAMPOS GUARDADOS EN FIREBASE

### Colección: `users`

```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "phone": "string",
  "role": "technician",
  "fcmToken": "eKOw5o7aQdiGzN...",
  "fcmTokenUpdatedAt": "timestamp",
  "isAvailable": true,
  "latitude": "number",
  "longitude": "number",
  "rating": "number"
}
```

### Colección: `service_requests`

```json
{
  "uid": "string",
  "clientName": "string",
  "clientEmail": "string",
  "clientPhone": "string",
  "serviceType": "string",
  "serviceName": "string",
  "description": "string",
  "latitude": "number",
  "longitude": "number",
  "address": "string",
  "urgencyLevel": "string",
  "preferredDate": "timestamp",
  "status": "pending|accepted|completed",
  "technician": null,
  "notificationsSentCount": "number",
  "notificationsSentAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## 🎯 PRÓXIMOS PASOS (Opcionales)

1. **Lista de solicitudes para técnicos**
   - Crear tab que muestre las solicitudes recibidas
   - Mostrar ubicación, cliente, urgencia

2. **Aceptar solicitud**
   - Técnico toca "Aceptar" en notificación
   - Se actualiza `technician` field en `service_requests`
   - Se notifica al cliente

3. **Chat en tiempo real**
   - Usar Firestore Realtime Listeners
   - Chat entre cliente y técnico

4. **Calificación después del servicio**
   - Formulario de review
   - Guardar rating del técnico

---

## 📞 SOPORTE

Si tienes problemas:

1. Revisa los logs: `firebase functions:log`
2. Verifica console en VS Code
3. Comprueba que Firebase está correctamente inicializado
