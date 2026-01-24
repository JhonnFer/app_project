# 📱 GUÍA COMPLETA: REGISTRO Y LOGIN EN FIREBASE

## 🎯 Objetivo

Registrarse como usuario, guardar datos en Firebase, iniciar sesión y acceder al dashboard.

---

## 📋 FLUJO GENERAL

```
INICIO
  ↓
PANTALLA DE LOGIN
  ├─ ¿Tiene cuenta?
  │  └─ SÍ → Ingresar email y contraseña → LOGIN → Dashboard
  │
  └─ NO → Ir a REGISTRO
       ↓
    PANTALLA DE REGISTRO
    ├─ Paso 1: Seleccionar Rol (Cliente, Técnico, Invitado)
    ├─ Paso 2: Ingresa datos (Email, Contraseña, Nombre, Teléfono)
    ├─ Paso 3: Si es Técnico → Seleccionar Servicios
    └─ REGISTRARSE → Guardar en Firebase → Login automático → Dashboard
```

---

## 🔐 PASO 1: PANTALLA DE LOGIN

**Ubicación:** [lib/features/auth/presentation/pages/screens/auth/login_screen.dart](lib/features/auth/presentation/pages/screens/auth/login_screen.dart)

### Cómo ingresar:

```
1. Abre la app (inicia en /login por defecto)

2. Ingresa tu email
   Ejemplo: cliente@ejemplo.com

3. Ingresa tu contraseña
   Ejemplo: 123456 (mínimo 6 caracteres)

4. Toca "Iniciar Sesión"

5. Si los datos son correctos:
   ✅ Se verifica en Firebase
   ✅ Se obtiene tu usuario de Firestore
   ✅ Se determina tu rol (cliente, técnico, invitado)
   ✅ Se abre el Dashboard correspondiente
```

---

## ✍️ PASO 2: PANTALLA DE REGISTRO

**Ubicación:** [lib/features/auth/presentation/pages/screens/auth/register_screen.dart](lib/features/auth/presentation/pages/screens/auth/register_screen.dart)

### PASO 2.1 - Seleccionar Rol

```
1. En la pantalla de LOGIN, toca "¿No tienes cuenta?"
   O toca "Registrarse"

2. Aparecen 2 opciones:

   👤 CLIENTE
      - Solicita servicios técnicos
      - Paga por los servicios
      - Califica técnicos
      - Chatea con técnicos

   🔧 TÉCNICO
      - Ofrece servicios
      - Recibe solicitudes
      - Completa trabajos
      - Recibe pagos

   👥 INVITADO (opcional)
      - Ver técnicos disponibles
      - Ver información pública
      - No puede crear servicios

3. Selecciona tu rol tocando una tarjeta

4. Toca "Siguiente" o "Continuar"
```

### PASO 2.2 - Ingresa tus Datos

```
Completa los siguientes campos:

📧 CORREO ELECTRÓNICO
   Ejemplo: juan.perez@gmail.com
   ⚠️ IMPORTANTE: Debe ser único (no registrado antes)

🔐 CONTRASEÑA
   Mínimo 6 caracteres
   Ejemplo: MiPassword123
   ⚠️ IMPORTANTE: Usa una contraseña fuerte

🔐 CONFIRMAR CONTRASEÑA
   Repite la misma contraseña
   ⚠️ Debe coincidir exactamente

👤 NOMBRE COMPLETO
   Ejemplo: Juan Pérez García
   ⚠️ Visible para otros usuarios

📱 TELÉFONO (Opcional)
   Ejemplo: 612345678
   ⚠️ Importante para contacto

Toca "Siguiente"
```

### PASO 2.3 - Seleccionar Servicios (Solo si eres Técnico)

```
Si seleccionaste "TÉCNICO", aparecerá este paso:

Selecciona qué servicios ofreces:

☑️ Refrigeración
☑️ Lavadoras
☑️ Secadoras
☑️ Cocinas
☑️ Hornos
☑️ Microondas

(Puedes marcar varios)

Toca "Registrarse"
```

### PASO 2.4 - Confirmación y Guardado

```
Cuando tocas "Registrarse":

1️⃣ Se crea usuario en Firebase Auth
   └─ Email y contraseña guardados

2️⃣ Se guarda perfil en Firestore (collection "users")
   ├─ uid: Tu ID único
   ├─ email: Tu correo
   ├─ name: Tu nombre
   ├─ role: "client", "technician" o "guest"
   ├─ phone: Tu teléfono
   ├─ rating: 0.0 (solo técnicos)
   ├─ serviceCount: 0 (solo técnicos)
   └─ createdAt: Fecha de creación

3️⃣ Si eres técnico, se guardan tus servicios
   └─ En collection "technician_services"

4️⃣ ✅ Se registra exitosamente

5️⃣ Se inicia sesión automáticamente

6️⃣ Se abre tu Dashboard
```

---

## 🏠 PASO 3: ACCESO AL DASHBOARD

### Dashboard según tu Rol

#### 👤 Si eres CLIENTE:

```
Ver en tu Dashboard:

1️⃣ PANEL PRINCIPAL
   ├─ Bienvenida: "Bienvenido de nuevo, [Nombre]"
   ├─ Servicios activos (0 al inicio)
   └─ Servicios completados (0 al inicio)

2️⃣ PESTAÑA "SOLICITAR SERVICIO"
   ├─ Botón para crear nueva solicitud
   ├─ Lista de mis servicios
   └─ Estado de cada servicio

3️⃣ PESTAÑA "TÉCNICOS"
   ├─ Mapa con técnicos cercanos
   ├─ Técnicos disponibles en tu zona
   └─ Rating y servicios completados de cada uno

4️⃣ PESTAÑA "CHATS"
   ├─ Conversaciones con técnicos
   └─ Mensajes

5️⃣ PESTAÑA "PERFIL"
   ├─ Ver tu información
   ├─ Editar teléfono
   ├─ Cerrar sesión
   └─ Configuración
```

#### 🔧 Si eres TÉCNICO:

```
Ver en tu Dashboard:

1️⃣ PANEL PRINCIPAL
   ├─ Bienvenida: "Bienvenido de nuevo, [Nombre]"
   ├─ Rating: 0.0 (aumenta con calificaciones)
   ├─ Servicios completados: 0
   └─ Servicios en progreso

2️⃣ PESTAÑA "SERVICIOS"
   ├─ Solicitudes disponibles cerca de ti
   ├─ Botón para aceptar servicio
   └─ Ver detalles del cliente

3️⃣ PESTAÑA "UBICACIÓN"
   ├─ Mapa con tu ubicación
   ├─ Técnicos cercanos
   └─ Servicios próximos a ti

4️⃣ PESTAÑA "CHATS"
   ├─ Conversaciones con clientes
   └─ Mensajes

5️⃣ PESTAÑA "PERFIL"
   ├─ Ver tu información
   ├─ Ver tus servicios
   ├─ Rating y reseñas
   ├─ Editar perfil
   ├─ Cerrar sesión
   └─ Configuración
```

#### 👥 Si eres INVITADO:

```
Ver en tu Dashboard:

1️⃣ PANEL LIMITADO
   ├─ Mensaje: "Acceso limitado como invitado"
   ├─ Botón para "Crear Cuenta Ahora"
   └─ Información sobre TechServe

2️⃣ PESTAÑA "SERVICIOS"
   ├─ Ver servicios disponibles
   ├─ Ver técnicos (solo lectura)
   └─ NO puedes crear solicitudes

3️⃣ PESTAÑA "TÉCNICOS"
   ├─ Ver técnicos disponibles
   ├─ Ver ubicación de técnicos
   ├─ Ver rating
   └─ NO puedes contactar directamente

4️⃣ PESTAÑA "INFORMACIÓN"
   ├─ Sobre TechServe
   ├─ Características de la plataforma
   ├─ Cómo funciona
   └─ Botón para registrarse

❌ NO PUEDES:
   - Crear solicitudes
   - Chatear
   - Aceptar servicios
   - Acceder a funciones avanzadas
```

---

## 🔄 FLUJO COMPLETO DE PRUEBA

### Prueba 1: Registrarse como Cliente

```
┌─ REGISTRO ─────────────────────────────────────┐
│                                                 │
│ 1. Toca "¿No tienes cuenta?"                   │
│ 2. Selecciona "Cliente"                        │
│ 3. Ingresa:                                    │
│    ├─ Email: cliente@test.com                 │
│    ├─ Contraseña: 123456                      │
│    ├─ Nombre: Juan Pérez                      │
│    └─ Teléfono: 612345678                     │
│ 4. Toca "Registrarse"                         │
│                                                 │
│ ✅ RESULTADO:                                   │
│    └─ Aparece Dashboard de Cliente             │
│                                                 │
└─────────────────────────────────────────────────┘

┌─ VERIFICAR FIREBASE ──────────────────────────┐
│                                                 │
│ Abre Firebase Console:                        │
│ https://console.firebase.google.com/          │
│                                                 │
│ 1. Selecciona tu proyecto "epn-proyectos..."  │
│ 2. Ve a "Autenticación" → "Usuarios"         │
│    └─ Verás: cliente@test.com ✅              │
│                                                 │
│ 3. Ve a "Firestore Database" → "users"       │
│    └─ Document: {uid_del_usuario}            │
│       ├─ email: "cliente@test.com"           │
│       ├─ name: "Juan Pérez"                  │
│       ├─ role: "client"                      │
│       └─ phone: "612345678"                  │
│                                                 │
└─────────────────────────────────────────────────┘

┌─ LOGIN ────────────────────────────────────────┐
│                                                 │
│ 1. Cierra la app                               │
│ 2. Toca "Cerrar Sesión" o reinicia la app     │
│ 3. Abre nueva sesión con:                     │
│    ├─ Email: cliente@test.com                │
│    └─ Contraseña: 123456                     │
│ 4. Toca "Iniciar Sesión"                     │
│                                                 │
│ ✅ RESULTADO:                                   │
│    └─ Se abre Dashboard de Cliente             │
│       (mismo usuario se mantiene)              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Prueba 2: Registrarse como Técnico

```
┌─ REGISTRO ─────────────────────────────────────┐
│                                                 │
│ 1. Toca "¿No tienes cuenta?"                   │
│ 2. Selecciona "Técnico"                       │
│ 3. Ingresa en Paso 1:                         │
│    ├─ Email: tecnico@test.com                │
│    ├─ Contraseña: 123456                     │
│    ├─ Nombre: Carlos García                  │
│    └─ Teléfono: 612345679                    │
│ 4. Toca "Siguiente"                          │
│                                                 │
│ 5. Selecciona servicios:                      │
│    ├─ ☑️ Refrigeración                        │
│    ├─ ☑️ Lavadoras                            │
│    └─ ☑️ Microondas                           │
│                                                 │
│ 6. Toca "Registrarse"                        │
│                                                 │
│ ✅ RESULTADO:                                   │
│    └─ Aparece Dashboard de Técnico             │
│       (Con servicios guardados)                │
│                                                 │
└─────────────────────────────────────────────────┘

┌─ VERIFICAR EN FIREBASE ──────────────────────┐
│                                                 │
│ Firestore → "users" → {uid_tecnico}          │
│ ├─ email: "tecnico@test.com"                │
│ ├─ name: "Carlos García"                    │
│ ├─ role: "technician"  ← Diferente           │
│ ├─ phone: "612345679"                       │
│ ├─ rating: 0.0         ← Solo técnico       │
│ └─ serviceCount: 0     ← Solo técnico       │
│                                                 │
│ Firestore → "technician_services"           │
│ └─ {uid_tecnico}                            │
│    ├─ Refrigeración                         │
│    ├─ Lavadoras                             │
│    └─ Microondas                            │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Prueba 3: Login con Credenciales Inválidas

```
┌─ LOGIN FALLIDO ────────────────────────────────┐
│                                                 │
│ 1. Email: cliente@test.com                    │
│ 2. Contraseña: INCORRECTA                    │
│ 3. Toca "Iniciar Sesión"                     │
│                                                 │
│ ❌ RESULTADO:                                   │
│    └─ Error: "Contraseña incorrecta."        │
│       (Mensaje de Firebase)                   │
│                                                 │
└─────────────────────────────────────────────────┘

┌─ LOGIN CON EMAIL NO REGISTRADO ────────────────┐
│                                                 │
│ 1. Email: noexiste@test.com                   │
│ 2. Contraseña: 123456                        │
│ 3. Toca "Iniciar Sesión"                     │
│                                                 │
│ ❌ RESULTADO:                                   │
│    └─ Error: "No existe una cuenta            │
│              con este correo electrónico."   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🔍 CÓMO VERIFICAR EN FIREBASE

### 1. Firebase Authentication (Usuarios)

```
1. Abre: https://console.firebase.google.com/
2. Selecciona proyecto: "epn-proyectos-38e79"
3. Ve a: Autenticación → Usuarios

Verás todos los emails registrados:
├─ cliente@test.com ✅
└─ tecnico@test.com ✅

Cada usuario mostrará:
├─ Email (verificado o no)
├─ Fecha de creación
├─ Último login
└─ UID único
```

### 2. Firestore Database (Datos de Usuarios)

```
1. Ve a: Firestore Database

Estructura esperada:
─────────────────────────────────────────
users/
├─ {uid_1}/
│  ├─ uid: "xyz123..."
│  ├─ email: "cliente@test.com"
│  ├─ name: "Juan Pérez"
│  ├─ role: "client"
│  ├─ phone: "612345678"
│  └─ createdAt: timestamp
│
├─ {uid_2}/
│  ├─ uid: "abc456..."
│  ├─ email: "tecnico@test.com"
│  ├─ name: "Carlos García"
│  ├─ role: "technician"
│  ├─ phone: "612345679"
│  ├─ rating: 0.0
│  ├─ serviceCount: 0
│  └─ createdAt: timestamp
│
└─ {uid_3}/
   ├─ uid: "def789..."
   ├─ email: "invitado@test.com"
   ├─ name: "Usuario Invitado"
   ├─ role: "guest"
   └─ createdAt: timestamp

technician_services/
├─ {uid_tecnico}/
│  ├─ Refrigeración: true
│  ├─ Lavadoras: true
│  └─ Microondas: true
```

---

## ⚠️ PROBLEMAS COMUNES Y SOLUCIONES

### Problema 1: Email ya registrado

```
❌ ERROR: "Ya existe una cuenta con este correo electrónico."

✅ SOLUCIÓN:
   1. Usa otro email (ej: usuario2@test.com)
   2. O usa el email registrado para hacer login
```

### Problema 2: Contraseña muy corta

```
❌ ERROR: "La contraseña debe tener al menos 6 caracteres."

✅ SOLUCIÓN:
   - Usa 6 caracteres mínimo
   - Ejemplo: "123456" o "MiPass1"
```

### Problema 3: Contraseñas no coinciden

```
❌ ERROR: "Las contraseñas no coinciden."

✅ SOLUCIÓN:
   - Confirma que escribiste bien ambas contraseñas
   - Las dos deben ser IDÉNTICAS
```

### Problema 4: Email no válido

```
❌ ERROR: "Correo inválido"

✅ SOLUCIÓN:
   - Usa formato correcto: usuario@ejemplo.com
   - Debe tener @ y dominio
   - Ejemplo: juan.perez@gmail.com
```

### Problema 5: No aparece en Dashboard después de registrarse

```
❌ NO CARGA EL DASHBOARD

✅ SOLUCIONES:
   1. Revisa que Firebase esté inicializado
      └─ Abre Firebase Console y verifica el proyecto

   2. Revisa que el usuario se guardó en Firestore
      └─ Ve a Firestore → users → verifica el documento

   3. Revisa los logs de la app
      └─ Abre Android Studio o Xcode para ver errores

   4. Reinicia la app
      └─ Cierra completamente y abre de nuevo
```

---

## ✅ CHECKLIST DE FUNCIONAMIENTO

Después de las pruebas, verifica:

```
REGISTRO:
  ☑️ Puedo seleccionar rol (Cliente, Técnico)
  ☑️ Puedo ingresar email, contraseña y nombre
  ☑️ Se validan los campos correctamente
  ☑️ Se muestra error si email ya existe
  ☑️ Se muestra error si contraseña es corta
  ☑️ Se registra en Firebase Auth
  ☑️ Se guarda en Firestore collection "users"
  ☑️ Si es técnico, se guardan servicios

LOGIN:
  ☑️ Puedo ingresar email y contraseña
  ☑️ Funciona con datos correctos
  ☑️ Muestra error con datos incorrectos
  ☑️ Se abre el Dashboard correcto según el rol
  ☑️ Se obtiene el usuario de Firestore

DASHBOARD:
  ☑️ Se muestra según mi rol
  ☑️ Veo mi nombre
  ☑️ Veo mis datos correctos
  ☑️ Los botones aparecen/desaparecen según permisos
  ☑️ Puedo ver mis permisos

FIREBASE:
  ☑️ El usuario aparece en Firebase Auth
  ☑️ El documento se guardó en Firestore
  ☑️ El role es correcto (client, technician, guest)
  ☑️ Los servicios se guardaron (si es técnico)
  ☑️ Las fechas de creación son correctas
```

---

## 🎯 PRÓXIMOS PASOS

Después de verificar que funciona:

1. **Crear servicio** (como cliente)
   - Ir a pantalla de crear servicio
   - Llenar detalles
   - Guardar en Firebase

2. **Aceptar servicio** (como técnico)
   - Ver servicios disponibles
   - Aceptar un servicio
   - Actualizar estado

3. **Chatear** (entre cliente y técnico)
   - Enviar mensajes
   - Guardar en Firestore
   - Recibir mensajes en tiempo real

4. **Calificar** (cliente a técnico)
   - Completar servicio
   - Dejar calificación
   - Actualizar rating del técnico

---

## 📞 RESUMEN

| Operación | Ubicación             | Firebase         | Estado          |
| --------- | --------------------- | ---------------- | --------------- |
| Registro  | register_screen.dart  | Auth + Firestore | ✅ Hecho        |
| Login     | login_screen.dart     | Auth             | ✅ Hecho        |
| Dashboard | dashboard_screen.dart | Firestore        | ✅ Listo        |
| Permisos  | app_permissions.dart  | Código           | ✅ Implementado |
| Guardado  | auth_service.dart     | Firestore        | ✅ Automático   |

¡Ahora a probar! 🚀
