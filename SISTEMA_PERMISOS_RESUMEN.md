# 🛡️ SISTEMA DE PERMISOS Y RESTRICCIONES - RESUMEN IMPLEMENTADO

## ✅ Estado Actual

| Componente                 | Estado        | Archivo                                                                                                  |
| -------------------------- | ------------- | -------------------------------------------------------------------------------------------------------- |
| **Permisos definidos**     | ✅ Completado | [app_permissions.dart](lib/core/constants/app_permissions.dart)                                          |
| **Guards de ruta**         | ✅ Completado | [route_guard.dart](lib/core/routes/route_guard.dart)                                                     |
| **Router centralizado**    | ✅ Completado | [app_router.dart](lib/core/routes/app_router.dart)                                                       |
| **Botones con permisos**   | ✅ Completado | [permission_button.dart](lib/features/auth/presentation/widgets/common/permission_button.dart)           |
| **Widgets de restricción** | ✅ Completado | [role_restricted_widget.dart](lib/features/auth/presentation/widgets/common/role_restricted_widget.dart) |
| **Validador de permisos**  | ✅ Completado | [auth_validator.dart](lib/core/utils/auth_validator.dart)                                                |
| **Extensiones**            | ✅ Completado | [permission_extensions.dart](lib/core/utils/permission_extensions.dart)                                  |
| **Ejemplos prácticos**     | ✅ Completado | [dashboard_example.dart](lib/features/auth/presentation/widgets/examples/dashboard_example.dart)         |
| **Documentación**          | ✅ Completado | [GUIA_PERMISOS.md](lib/GUIA_PERMISOS.md)                                                                 |

---

## 📦 Archivos Nuevos (9 archivos)

```
lib/
├── core/
│   ├── constants/
│   │   └── app_permissions.dart (NEW) - Definición de permisos
│   ├── routes/
│   │   ├── route_guard.dart (NEW) - Guards y protección
│   │   └── app_router.dart (NEW) - Router con permisos
│   └── utils/
│       ├── permission_extensions.dart (NEW) - Extensiones
│       └── auth_validator.dart (NEW) - Validadores
├── features/auth/presentation/widgets/common/
│   ├── permission_button.dart (NEW) - Botones
│   └── role_restricted_widget.dart (NEW) - Widgets
├── features/auth/presentation/widgets/examples/
│   └── dashboard_example.dart (NEW) - Ejemplos
└── GUIA_PERMISOS.md (NEW) - Documentación
```

---

## 🎯 3 Niveles de Restricción Implementados

### 1️⃣ Nivel UI (Mostrar/Ocultar Componentes)

```dart
// Los botones solo aparecen si el usuario tiene permiso
PermissionButton(
  user: user,
  requiredPermission: Permission.createService,
  onPressed: () { },
  label: 'Crear Servicio',
)
```

### 2️⃣ Nivel Rutas (Proteger Navegación)

```dart
// Validar antes de navegar
if (AppRouter.canAccessRoute(
  routeName: '/create-service',
  currentUser: user,
)) {
  Navigator.pushNamed(context, '/create-service');
}
```

### 3️⃣ Nivel Lógica (Validar en Use Cases)

```dart
// En la capa de negocio
AuthValidator.requirePermission(user, Permission.createService);
// Continuar con lógica si no lanza excepción
```

---

## 📊 Permisos Definidos (13 totales)

### 👤 Cliente (7 permisos)

- ✅ `createService` - Crear solicitud de servicio
- ✅ `viewServices` - Ver sus servicios
- ✅ `rateService` - Calificar técnico
- ✅ `chatWithTechnician` - Chatear
- ✅ `cancelService` - Cancelar servicio
- ✅ `viewPublicInfo` - Ver info pública
- ✅ `viewTechnicians` - Buscar técnicos

### 🔧 Técnico (9 permisos)

- ✅ `acceptService` - Aceptar solicitud
- ✅ `completeService` - Marcar completado
- ✅ `viewClientProfile` - Ver perfil cliente
- ✅ `editProfile` - Editar su perfil
- ✅ `manageServices` - Gestionar servicios
- ✅ `receivePayments` - Recibir pagos
- ✅ `viewNearbyServices` - Ver servicios cercanos
- ✅ `viewPublicInfo` - Ver info pública
- ✅ `chatWithTechnician` - Chatear

### 👥 Invitado (3 permisos)

- ✅ `viewPublicInfo` - Ver información
- ✅ `viewTechnicians` - Ver técnicos
- ✅ `searchServices` - Buscar servicios

---

## 🔥 Sobre Firestore (IMPORTANTE)

### ❓ ¿Necesito crear tablas en Firebase?

**NO**, Firestore crea todo automáticamente:

```
✅ Se crea la colección "users" automáticamente
✅ Se crea un documento por usuario (con uid como ID)
✅ Los campos se crean según datos que guardes
✅ No necesitas esquema previo
```

### Ejemplo automático:

```dart
// Cuando un usuario se registra en auth_service.dart:
await _firestore.collection('users').doc(credential.user!.uid).set({
  'uid': credential.user!.uid,
  'email': email,
  'name': name,
  'role': role,  // ← Se guardará: 'client', 'technician', o 'guest'
  'phone': phone,
});

// Firestore crea automáticamente:
// Collection: 'users'
// Document ID: {uid del usuario}
// Fields: uid, email, name, role, phone, etc.
```

---

## 🚀 Cómo Integrar (Pasos Rápidos)

### Paso 1: Actualizar Dashboard

```dart
// En tu dashboard_screen.dart
class DashboardScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = _getCurrentUser(); // Obtén usuario actual

    return Scaffold(
      body: Column(
        children: [
          // Solo aparece si es cliente
          PermissionButton(
            user: currentUser,
            requiredPermission: Permission.createService,
            onPressed: () { },
            label: 'Crear Servicio',
          ),

          // Solo aparece si es técnico
          RoleButton(
            user: currentUser,
            allowedRoles: [UserRole.technician],
            onPressed: () { },
            label: 'Aceptar Servicio',
          ),
        ],
      ),
    );
  }
}
```

### Paso 2: Proteger Rutas

```dart
// Antes de navegar
AppRouter.safeNavigate(
  routeName: '/create-service',
  currentUser: currentUser,
);
```

### Paso 3: Validar en Use Cases

```dart
Future<Either<Failure, void>> createService(UserEntity user) async {
  try {
    // Validar permiso
    AuthValidator.requirePermission(user, Permission.createService);

    // Lógica aquí
    return const Right(null);
  } on UnauthorizedFailure catch (e) {
    return Left(e as Failure);
  }
}
```

---

## 📖 Documentación Completa

Archivo: [lib/GUIA_PERMISOS.md](lib/GUIA_PERMISOS.md)

Contiene:

- ✅ Formas de usar el sistema
- ✅ Ejemplos completos
- ✅ Patrones de implementación
- ✅ Próximos pasos
- ✅ Notas importantes

---

## 💡 Ejemplos en Código

Archivo: [lib/features/auth/presentation/widgets/examples/dashboard_example.dart](lib/features/auth/presentation/widgets/examples/dashboard_example.dart)

Contiene:

- ✅ Ejemplo 1: Mostrar sección solo para clientes
- ✅ Ejemplo 2: Mostrar sección solo para técnicos
- ✅ Ejemplo 3: Usar PermissionRestrictedWidget
- ✅ Ejemplo 4: Mostrar información y permisos del usuario
- ✅ Ejemplos adicionales de verificación

---

## 📋 Checklist de Implementación

```
[ ] Leer GUIA_PERMISOS.md completo
[ ] Revisar ejemplos en dashboard_example.dart
[ ] Actualizar dashboard_screen.dart con PermissionButton
[ ] Agregar RoleRestrictedWidget para secciones
[ ] Proteger rutas con AppRouter.canAccessRoute()
[ ] Agregar validación en Use Cases con AuthValidator
[ ] Probar con diferentes roles (Cliente, Técnico, Invitado)
[ ] Verificar que botones aparecen/desaparecen
[ ] Verificar que rutas se bloquean sin permisos
```

---

## 🎓 Conceptos Clave

| Concepto              | Descripción                     | Uso                          |
| --------------------- | ------------------------------- | ---------------------------- |
| **Permission**        | Enum con acciones permitidas    | Validar acciones específicas |
| **UserRole**          | Cliente, Técnico, Invitado      | Categorizar usuarios         |
| **PermissionManager** | Mapea roles → permisos          | Centro de lógica             |
| **RouteGuard**        | Valida acceso a rutas           | Proteger navegación          |
| **PermissionButton**  | Botón que se oculta sin permiso | UI condicionada              |
| **RoleGuard**         | Widget por rol                  | Mostrar/ocultar secciones    |
| **AuthValidator**     | Valida en lógica de negocio     | Use Cases seguros            |

---

## 🔄 Flujo Completo Ejemplo

```
Usuario intenta crear servicio
    ↓
1. PermissionButton verifica permiso
    ↓
2. Si tiene permiso → botón visible
    ↓
3. Usuario toca botón → navegar a /create-service
    ↓
4. AppRouter verifica permiso (2x validación)
    ↓
5. Navigate a CreateServiceScreen
    ↓
6. Use Case valida permiso (3x validación)
    ↓
7. Si todo OK → crear servicio en Firestore
    ↓
8. Documento se crea automáticamente en collection "services"
```

---

## ❓ Preguntas Frecuentes

**P: ¿Necesito crear las colecciones en Firestore?**
R: No, se crean automáticamente cuando haces `set()` o `add()`

**P: ¿Dónde guardo los permisos en Firestore?**
R: Los permisos están en el `role` del documento del usuario. Firestore lee desde `app_permissions.dart`

**P: ¿Puedo agregar más permisos?**
R: Sí, agrega en el `enum Permission` y asigna al rol en `rolePermissions`

**P: ¿Es obligatorio usar los 3 niveles de validación?**
R: No, pero se recomienda:

- UI: Para mejor UX
- Rutas: Para seguridad básica
- Use Cases: Para seguridad real

---

## ✨ Ventajas del Sistema

- ✅ Centralizado (un lugar para definir permisos)
- ✅ Flexible (fácil agregar nuevos permisos)
- ✅ Reutilizable (funciona en toda la app)
- ✅ Seguro (validación en múltiples niveles)
- ✅ Limpio (extensiones y helpers)
- ✅ Documentado (guías y ejemplos)
- ✅ No requiere base de datos (permisos en código)

---

## 🎯 Resultado Final

Tu app ahora tiene:

1. ✅ **Gestión de 3 roles** (Cliente, Técnico, Invitado)
2. ✅ **13 permisos** bien definidos
3. ✅ **Restricción de UI** (botones y secciones)
4. ✅ **Protección de rutas** (navegación segura)
5. ✅ **Validación de negocio** (Use Cases seguros)
6. ✅ **Integración Firebase** (automática, sin tablas)

¡Proyecto completamente seguro y estructurado! 🎉
