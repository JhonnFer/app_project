# 🧪 GUÍA DE PRUEBAS - USUARIO INVITADO (ID-004-RR)

## 📱 Cómo Probar como Invitado

### **Opción 1: Desde la Pantalla de Login (RECOMENDADO)**

1. **Abre la app**
   - Ejecuta: `flutter run`
   - La app te llevará a la pantalla de **Splash Screen**

2. **Veras la Pantalla de Login**
   - En la parte inferior, hay un botón azul: **"Continuar como Invitado"**
   - Haz clic en él

3. **Serás Redirigido al GuestDashboardScreen**
   - Verás 3 pestañas:
     - **Inicio**: Información general sobre TechServe
     - **Explorar**: Técnicos disponibles (cargados desde Firestore)
     - **Información**: Datos de contacto y características

---

## 🔍 Qué Probar en Cada Pestaña

### **Pestaña 1: INICIO**

- ✅ Ver banner de bienvenida "Bienvenido a TechServe"
- ✅ Texto: "Acceso limitado como invitado"
- ✅ Botón **"Crear Cuenta Ahora"** (navega a Registro)
- ✅ Botón **"Iniciar Sesión"** (navega a Login)
- ✅ Tarjetas de servicios: Electrodomésticos, Técnicos Certificados, Garantía de Calidad

### **Pestaña 2: EXPLORAR** (LA MÁS IMPORTANTE)

- ✅ Carga técnicos disponibles desde Firestore
- ✅ Para cada técnico muestra:
  - Nombre
  - Calificación (★)
  - Cantidad de servicios completados
  - Especialidades (chips de colores)
  - Botón "Ver Detalles" (deshabilitado para invitados)

- ✅ Cuando hagas clic en "Ver Detalles":
  - Muestra SnackBar: "Debes iniciar sesión para contactar técnicos"
  - Opción "Ir a Login"

- ✅ Banner informativo:
  - Ícono de candado 🔒
  - Texto: "Acceso Limitado"
  - Dos botones: "Iniciar Sesión" | "Registrarse"

### **Pestaña 3: INFORMACIÓN**

- ✅ Información sobre la plataforma
- ✅ Lista de características
- ✅ Datos de contacto

---

## 🗄️ Datos Requeridos en Firestore

Para que veas técnicos en la pestaña "Explorar", necesitas agregar datos a tu colección `users` en Firestore:

### **Estructura de Documento para Técnico**

```json
{
  "uid": "tech_001",
  "name": "Carlos García",
  "email": "carlos@example.com",
  "role": "technician",
  "rating": 4.8,
  "completedServices": 156,
  "specialties": ["Refrigerador", "Lavadora", "Microondas"],
  "profileImage": "https://via.placeholder.com/150",
  "isAvailable": true,
  "phone": "+34 600 000 001"
}
```

### **Cómo Agregar Datos a Firestore**

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: `epn-proyectos-38e79`
3. Ve a **Firestore Database**
4. Colección **`users`**
5. Haz clic en **"Agregar documento"**
6. Copia los datos del técnico
7. Haz clic en **"Guardar"**

### **Ejemplo: 3 Técnicos Recomendados**

**Técnico 1:**

- Nombre: Carlos García
- Rating: 4.8
- Servicios: 156
- Especialidades: Refrigerador, Lavadora, Microondas

**Técnico 2:**

- Nombre: María López
- Rating: 4.9
- Servicios: 203
- Especialidades: Aire Acondicionado, Horno, Secadora

**Técnico 3:**

- Nombre: Pedro Martínez
- Rating: 4.6
- Servicios: 89
- Especialidades: Microondas, Licuadora, Ventilador

---

## ✅ Checklist de Pruebas

### **Acceso como Invitado**

- [ ] Hago clic en "Continuar como Invitado"
- [ ] Llego al GuestDashboardScreen
- [ ] Veo 3 pestañas en la parte inferior

### **Pestaña Inicio**

- [ ] Veo banner de bienvenida
- [ ] Veo texto "Acceso limitado como invitado"
- [ ] Botones de Login/Registro funcionan

### **Pestaña Explorar**

- [ ] Carga técnicos desde Firestore
- [ ] Veo nombre, rating, servicios completados
- [ ] Veo especialidades en chips
- [ ] Botón "Ver Detalles" muestra SnackBar al hacer clic
- [ ] SnackBar tiene opción "Ir a Login"

### **Restricciones Funcionan**

- [ ] NO puedo solicitar servicios sin iniciar sesión
- [ ] NO puedo enviar mensajes a técnicos
- [ ] Los botones principales están deshabilitados

### **Navegación**

- [ ] "Continuar como Invitado" → GuestDashboard ✅
- [ ] "Crear Cuenta Ahora" → RegisterScreen ✅
- [ ] "Iniciar Sesión" → LoginScreen ✅
- [ ] "Registrarse" → RegisterScreen ✅

---

## 🔄 Flujo Completo de Prueba

```
1. Abre la app
   ↓
2. Ve la pantalla de Login
   ↓
3. Haz clic en "Continuar como Invitado"
   ↓
4. Llega a GuestDashboardScreen
   ↓
5. Navega por las 3 pestañas
   ↓
6. En "Explorar", ves técnicos desde Firestore
   ↓
7. Intentas hacer clic en "Ver Detalles"
   ↓
8. Ves mensaje: "Debes iniciar sesión para contactar técnicos"
   ↓
9. Haces clic en "Ir a Login"
   ↓
10. Vuelves a LoginScreen
   ↓
11. Ahora puedes hacer login con credenciales
   ↓
12. Llegas al DashboardScreen (autenticado)
   ↓
13. ÉXITO: Funciona correctamente ✅
```

---

## 🐛 Solución de Problemas

### **"El botón 'Continuar como Invitado' no aparece"**

- ✅ Solución: Verifica que estés en LoginScreen
- ✅ El botón está al final, puede estar debajo

### **"No veo técnicos en la pestaña Explorar"**

- ✅ Solución: Verifica que hayas agregado documentos a Firestore
- ✅ Verifica que los documentos tengan:
  - `role: "technician"`
  - `isAvailable: true`

### **"El SnackBar no aparece al hacer clic en 'Ver Detalles'"**

- ✅ Solución: El botón debe estar deshabilitado/desactivado
- ✅ Verifica que el método `onPressed` esté configurado

### **"Dice 'Contenido Restringido' sin mostrar técnicos"**

- ✅ Solución: Hay un error al cargar desde Firestore
- ✅ Revisa la consola de Flutter (flutter logs)

---

## 📊 Métricas de Éxito

✅ **ID-004-RR está completamente funcional cuando:**

1. ✅ Invitados pueden ver la pantalla de bienvenida
2. ✅ Invitados pueden ver técnicos disponibles desde Firestore
3. ✅ Invitados NO pueden hacer solicitudes de servicio
4. ✅ Hay CTAs claras para login/registro
5. ✅ La navegación entre pantallas funciona correctamente

---

## 🚀 Conclusión

**Para probar como invitado simplemente:**

1. Haz clic en **"Continuar como Invitado"** en la pantalla de Login
2. Explora las 3 pestañas del GuestDashboard
3. Intenta hacer acciones que requieren autenticación (verás que no puedes)
4. Regresa a Login y crea una cuenta o inicia sesión

¡Listo! Así pruebas completamente el requerimiento ID-004-RR.
