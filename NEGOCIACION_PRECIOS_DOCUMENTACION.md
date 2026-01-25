# 💰 SISTEMA DE OFERTA Y DEMANDA - NEGOCIACIÓN DE PRECIOS

## 📋 Descripción General

El sistema implementa un modelo de **oferta y demanda** donde:

1. **Cliente propone precio**: Al crear una solicitud de servicio, especifica un precio propuesto
2. **Técnicos reciben solicitud**: Los técnicos seleccionados ven la solicitud con el precio
3. **Técnicos envían contraoferta**: Si consideran el precio inadecuado, pueden enviar una contraoferta
4. **Negociación**: Se continúa hasta que uno de los dos acepte o rechace

---

## 🔄 FLUJO DE NEGOCIACIÓN

### 1️⃣ CREACIÓN DE SOLICITUD (Cliente)

**Archivo**: `service_request_form_screen.dart`

**Nuevos campos agregados**:

- 💰 **Precio Propuesto**: Campo numérico donde el cliente ingresa su precio propuesto

**Datos guardados en Firestore**:

```dart
{
  'proposedPrice': 50000.0,           // Precio del cliente
  'priceStatus': 'proposed',          // Estado del precio
  'negotiationStatus': 'pending',     // Estado de negociación
}
```

---

### 2️⃣ TÉCNICO VE LA SOLICITUD

**Ubicación**: `technician_notifications_tab.dart`

El técnico recibe notificación con:

- Descripción del servicio
- Precio propuesto por el cliente
- Ubicación y detalles

---

### 3️⃣ TÉCNICO ENVÍA CONTRAOFERTA

**Archivos Involucrados**:

- `price_negotiation_screen.dart` - Pantalla de negociación
- `notification_service.dart` - Métodos de envío

**Método**: `NotificationService.sendPriceCounterOffer()`

**Parámetros**:

```dart
sendPriceCounterOffer({
  required String requestId,
  required String senderId,           // ID del técnico
  required String senderName,
  required String recipientId,        // ID del cliente
  required String recipientName,
  required double proposedPrice,      // Nuevo precio del técnico
  required double originalPrice,      // Precio original del cliente
  required String reason,             // Razón de la contraoferta
})
```

**Lo que hace**:

1. Crea documento en colección `price_negotiations`
2. Actualiza `service_requests` con estado 'negotiating'
3. Envía notificación al cliente
4. Guarda razón de la contraoferta

---

### 4️⃣ CLIENTE RESPONDE CONTRAOFERTA

**Ubicación**: Dashboard → Pestaña "Explorar" → "Negociaciones Activas"

**Opciones**:

- ✅ **Aceptar**: Acepta el precio propuesto por el técnico
- ❌ **Rechazar**: Rechaza la contraoferta y propone otra

---

### 5️⃣ CICLO DE NEGOCIACIÓN CONTINÚA

Si se rechaza, el cliente puede:

- Aceptar el precio original nuevamente
- Proponer otro precio diferente
- El ciclo continúa hasta acuerdo o rechazo final

---

## 📁 COLECCIONES EN FIRESTORE

### 1. `service_requests`

**Campos nuevos/actualizados**:

```json
{
  "proposedPrice": 50000,
  "priceStatus": "proposed|negotiating|agreed|rejected",
  "negotiationStatus": "pending|active|agreed|cancelled",
  "lastCounterOfferPrice": 60000,
  "lastCounterOfferAt": "timestamp",
  "agreedPrice": 55000,
  "agreedAt": "timestamp"
}
```

### 2. `price_negotiations` (NUEVA)

Almacena todas las contrapropuestas:

```json
{
  "requestId": "abc123",
  "senderId": "tech123",
  "senderName": "Juan Técnico",
  "recipientId": "client456",
  "recipientName": "María Cliente",
  "proposedPrice": 60000,
  "originalPrice": 50000,
  "reason": "El precio es muy bajo para el trabajo requerido",
  "status": "pending|accepted|rejected|expired",
  "createdAt": "timestamp",
  "respondedAt": "timestamp",
  "responseReason": "No puedo pagar ese precio"
}
```

---

## 🎯 MÉTODOS EN `NotificationService`

### Enviar Contraoferta

```dart
Future<bool> sendPriceCounterOffer({
  required String requestId,
  required String senderId,
  required String senderName,
  required String recipientId,
  required String recipientName,
  required double proposedPrice,
  required double originalPrice,
  required String reason,
}) async
```

### Aceptar Contraoferta

```dart
Future<bool> acceptPriceCounterOffer({
  required String negotiationId,
  required String requestId,
  required String acceptedByUserId,
  required double agreedPrice,
}) async
```

### Rechazar Contraoferta

```dart
Future<bool> rejectPriceCounterOffer({
  required String negotiationId,
  required String requestId,
  required String rejectedByUserId,
  required String rejectionReason,
}) async
```

### Obtener Negociaciones

```dart
Future<List<Map<String, dynamic>>> getPriceNegotiations(
  String requestId
) async
```

### Stream de Negociaciones

```dart
Stream<QuerySnapshot> getNegotiationUpdatesStream(String userId)
```

### Cancelar Todas las Negociaciones

```dart
Future<void> cancelAllNegotiations(String requestId) async
```

---

## 🎨 INTERFAZ DE USUARIO

### 1. Formulario de Solicitud

- Campo de precio propuesto (requerido)
- Validación de precio > 0
- Se envía con la solicitud

### 2. Pantalla de Negociación (`price_negotiation_screen.dart`)

- Muestra precio propuesto original
- Campo para ingresar nueva contraoferta
- Campo para explicar razón
- Botón "Enviar Contraoferta"

### 3. Dashboard - Pestaña Explorar

**3 secciones principales**:

#### a) Negociaciones Activas

- Listado de contrapropuestas pendientes
- Muestra diferencia de precio (% más/menos)
- Botón para abrir detalles

#### b) Solicitudes Pendientes

- Solicitudes sin contraoferta aún
- Esperando respuesta de técnicos

#### c) Acuerdos Completados

- Negociaciones finalizadas con acuerdo
- Muestra precio acordado final

### 4. Widget de Contraoferta

- Compara precio original vs propuesto
- Muestra razón de la contraoferta
- Botones: Aceptar/Rechazar
- Indicador visual de aumento/disminución

---

## 📊 ESTADOS DE NEGOCIACIÓN

### Estados en `price_negotiations`:

- **pending**: Esperando respuesta
- **accepted**: Contraoferta aceptada
- **rejected**: Contraoferta rechazada
- **expired**: Negociación expirada (por acuerdo a otro precio)

### Estados en `service_requests`:

- **priceStatus**:
  - `proposed`: Precio inicial del cliente
  - `negotiating`: En proceso de negociación
  - `agreed`: Precio acordado
  - `rejected`: Sin acuerdo

- **negotiationStatus**:
  - `pending`: Esperando inicio de negociación
  - `active`: Negociación en curso
  - `agreed`: Acuerdo alcanzado
  - `cancelled`: Negociación cancelada

---

## 🔔 NOTIFICACIONES

Se crean notificaciones para:

1. **Nueva contraoferta**: Cliente recibe alerta de nueva contraoferta
2. **Contraoferta rechazada**: Técnico recibe notificación de rechazo
3. **Acuerdo completado**: Ambos reciben confirmación

---

## 📁 ARCHIVOS CREADOS/MODIFICADOS

### Nuevos Archivos:

```
lib/features/auth/data/models/price_negotiation_model.dart
lib/features/auth/domain/entities/price_negotiation_entity.dart
lib/features/auth/presentation/pages/screens/dashboard/price_negotiation_screen.dart
lib/features/auth/presentation/widgets/common/price_counter_offer_widget.dart
NEGOCIACION_PRECIOS_DOCUMENTACION.md (este archivo)
```

### Archivos Modificados:

```
lib/features/auth/presentation/pages/screens/dashboard/service_request_form_screen.dart
  - Agregado campo de precio propuesto
  - Validación de precio

lib/core/services/notification_service.dart
  - Nuevos métodos de negociación

lib/features/auth/presentation/pages/screens/dashboard/dashboard_screen.dart
  - Integración de pantalla de negociación en pestaña "Explorar"
```

---

## 🧪 CÓMO PROBAR

### Paso 1: Crear Solicitud como Cliente

1. Ir a "Solicitar Nuevo Servicio"
2. Llenar formulario completo
3. **Ingresar Precio Propuesto** (nuevo campo)
4. Seleccionar técnicos
5. Enviar solicitud

### Paso 2: Técnico Envía Contraoferta

1. Ir a Tab "Explorar"
2. Seleccionar "Negociaciones Activas"
3. (Si es técnico) Ver solicitud recibida
4. Enviar contraoferta con precio diferente

### Paso 3: Cliente Responde

1. Ir a Tab "Explorar"
2. Ver "Negociaciones Activas"
3. Hacer clic en contraoferta
4. Aceptar o rechazar

### Paso 4: Acuerdo Completado

1. Cuando se acepte, aparecer en "Acuerdos Completados"
2. Se verá el precio final acordado

---

## 🔐 FIRESTORE RULES (Recomendadas)

```javascript
match /price_negotiations/{document=**} {
  // Solo el remitente o destinatario pueden leer
  allow read: if
    request.auth.uid == resource.data.senderId ||
    request.auth.uid == resource.data.recipientId;

  // Solo técnicos pueden crear
  allow create: if
    request.auth != null &&
    resource.data.senderId == request.auth.uid;

  // Solo destinatario puede actualizar
  allow update: if
    request.auth.uid == resource.data.recipientId;
}
```

---

## 💡 NOTAS IMPORTANTES

1. **Precio Validado**: Se valida que sea > 0
2. **Historial**: Todas las negociaciones se guardan para auditoría
3. **Expiración**: Las negociaciones pendientes expiran en 24 horas
4. **Notificaciones**: Se envían en tiempo real vía Firestore listeners
5. **Rol del Usuario**: Sistema válido para cliente ↔ técnico
6. **Múltiples Técnicos**: Cada técnico puede enviar contraoferta independientemente
7. **Un Acuerdo**: Cuando se acepta una contraoferta, todas las demás se marcan como expiradas

---

## 📞 SOPORTE

Para dudas o problemas con la negociación:

1. Revisar los logs en la consola de Flutter
2. Verificar que `price_negotiations` exista en Firestore
3. Confirmar que el usuario esté autenticado correctamente
4. Verificar permisos en Firestore Rules
