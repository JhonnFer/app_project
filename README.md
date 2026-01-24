# 🔥 Configuración de Firebase en Proyecto Flutter

Este documento describe **paso a paso** cómo se configuró Firebase en el proyecto Flutter, incluyendo la **instalación de dependencias**, **configuración de plataformas** y **buenas prácticas con Arquitectura Clean**.

---

## 📌 Requisitos Previos

Antes de iniciar, asegúrese de contar con:

* Flutter SDK instalado
* Dart SDK
* Android Studio o VS Code
* Cuenta activa de Google
* Proyecto Flutter creado

```bash
flutter create nombre_app
```

---

## 1️⃣ Crear Proyecto en Firebase Console

1. Acceder a [https://console.firebase.google.com](https://console.firebase.google.com)
2. Seleccionar **Agregar proyecto**
3. Asignar un nombre al proyecto
4. Google Analytics (opcional)
5. Finalizar creación

---

## 2️⃣ Registrar Aplicación Android

1. Dentro del proyecto Firebase, seleccionar **Agregar app → Android**
2. Ingresar el **Application ID** (ubicado en `android/app/build.gradle`)

```gradle
applicationId "com.example.nombre_app"
```

3. Descargar el archivo:

```
google-services.json
```

4. Colocarlo en:

```
android/app/google-services.json
```

---

## 3️⃣ Registrar Aplicación iOS (Opcional)

1. Agregar app → iOS
2. Ingresar Bundle ID
3. Descargar:

```
GoogleService-Info.plist
```

4. Colocarlo en:

```
ios/Runner/
```

---

## 4️⃣ Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Agregar el path si es necesario:

### Windows

```powershell
setx PATH "%PATH%;%USERPROFILE%\\AppData\\Local\\Pub\\Cache\\bin"
```

### Linux / macOS

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

---

## 5️⃣ Configurar Firebase Automáticamente

Desde la raíz del proyecto:

```bash
flutterfire configure
```

Este proceso genera automáticamente:

```
lib/firebase_options.dart
```

---

## 6️⃣ Instalar Dependencias Firebase

Editar `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
```

Instalar dependencias:

```bash
flutter pub get
```

---

## 7️⃣ Configuración Android (Gradle)

### 📍 android/build.gradle

```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
  }
}
```

### 📍 android/app/build.gradle

```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 8️⃣ Inicializar Firebase en Flutter

### 📍 lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

---

## 9️⃣ Configurar Autenticación en Firebase

1. Firebase Console → Authentication
2. Métodos de inicio de sesión
3. Habilitar:

   * Email / Password
   * Google (opcional)

---

## 🔐 Dependencias Utilizadas

| Dependencia     | Función                  |
| --------------- | ------------------------ |
| firebase_core   | Inicializa Firebase      |
| firebase_auth   | Autenticación            |
| flutterfire_cli | Configuración automática |

---

## 🧪 Prueba de Conexión

```dart
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;

Future<void> login() async {
  await auth.signInWithEmailAndPassword(
    email: 'test@test.com',
    password: '123456',
  );
}
```

---

## 🧱 Integración con Arquitectura Clean

### 📂 Estructura Recomendada

```
lib/
 └── features/
     └── auth/
         ├── domain/
         │   ├── entities/
         │   ├── repositories/
         │   └── usecases/
         ├── data/
         │   ├── datasources/
         │   ├── models/
         │   └── repositories/
         └── presentation/
```

### Buenas Prácticas

* Firebase solo en **data layer**
* UI no accede directamente a Firebase
* Lógica encapsulada en **UseCases**

---

## ⚠️ Errores Comunes

| Error                             | Solución              |
| --------------------------------- | --------------------- |
| No matching client found          | Revisar applicationId |
| Firebase not initialized          | Revisar main.dart     |
| google-services.json no detectado | Verificar ruta        |

---

## ✅ Resultado Final

✔ Firebase correctamente configurado
✔ Autenticación funcional
✔ Arquitectura limpia y escalable
✔ Proyecto listo para producción

---

## 📌 Recomendaciones

* No subir `google-services.json` a repositorios públicos
* Usar variables de entorno para producción
* Separar lógica de autenticación por casos de uso

---

✍️ **Documentación técnica – Proyecto Flutter con Firebase**
