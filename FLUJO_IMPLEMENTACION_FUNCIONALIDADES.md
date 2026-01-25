# 📋 Flujo de Implementación de Nuevas Funcionalidades

## Estructura General: 4 Capas

```
1. LÓGICA DE NEGOCIO (Domain Layer)
   ↓
2. LÓGICA DE APLICACIÓN (Service Layer)
   ↓
3. CONEXIÓN CON BD/API (Data Layer)
   ↓
4. UX/UI (Presentation Layer)
```

---

## PASO 1: LÓGICA DE NEGOCIO (Domain)

### Crear Entity (Modelo de dominio)

**Ubicación**: `lib/features/[feature]/domain/entities/`

```dart
// Ejemplo: rating_entity.dart
import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String technicianId;
  final String clientId;
  final double score; // 1-5
  final String comment;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.technicianId,
    required this.clientId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    technicianId,
    clientId,
    score,
    comment,
    createdAt,
  ];
}
```

### Crear UseCase (Casos de uso)

**Ubicación**: `lib/features/[feature]/domain/usecases/`

```dart
// Ejemplo: create_rating_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/rating_entity.dart';
import '../repositories/rating_repository.dart';

class CreateRatingUseCase implements UseCase<RatingEntity, CreateRatingParams> {
  final RatingRepository repository;

  CreateRatingUseCase(this.repository);

  @override
  Future<Either<Failure, RatingEntity>> call(CreateRatingParams params) async {
    return await repository.createRating(
      technicianId: params.technicianId,
      clientId: params.clientId,
      score: params.score,
      comment: params.comment,
    );
  }
}

class CreateRatingParams {
  final String technicianId;
  final String clientId;
  final double score;
  final String comment;

  CreateRatingParams({
    required this.technicianId,
    required this.clientId,
    required this.score,
    required this.comment,
  });
}
```

### Crear Repository (Interface)

**Ubicación**: `lib/features/[feature]/domain/repositories/`

```dart
// Ejemplo: rating_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, RatingEntity>> createRating({
    required String technicianId,
    required String clientId,
    required double score,
    required String comment,
  });

  Future<Either<Failure, List<RatingEntity>>> getTechnicianRatings(
    String technicianId,
  );

  Future<Either<Failure, void>> deleteRating(String ratingId);
}
```

---

## PASO 2: LÓGICA DE APLICACIÓN (Service Layer)

### Crear Model (Mapeable a JSON)

**Ubicación**: `lib/features/[feature]/data/models/`

```dart
// Ejemplo: rating_model.dart
import '../../domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required String id,
    required String technicianId,
    required String clientId,
    required double score,
    required String comment,
    required DateTime createdAt,
  }) : super(
    id: id,
    technicianId: technicianId,
    clientId: clientId,
    score: score,
    comment: comment,
    createdAt: createdAt,
  );

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      technicianId: json['technicianId'] ?? '',
      clientId: json['clientId'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  factory RatingModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return RatingModel(
      id: docId,
      technicianId: data['technicianId'] ?? '',
      clientId: data['clientId'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicianId': technicianId,
      'clientId': clientId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

### Crear Repository Implementation

**Ubicación**: `lib/features/[feature]/data/repositories/`

```dart
// Ejemplo: rating_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';
import '../../../../core/error/failures.dart';
import '../datasources/rating_remote_datasource.dart';
import '../models/rating_model.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;

  RatingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RatingEntity>> createRating({
    required String technicianId,
    required String clientId,
    required double score,
    required String comment,
  }) async {
    try {
      final result = await remoteDataSource.createRating(
        technicianId: technicianId,
        clientId: clientId,
        score: score,
        comment: comment,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getTechnicianRatings(
    String technicianId,
  ) async {
    try {
      final result = await remoteDataSource.getTechnicianRatings(technicianId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRating(String ratingId) async {
    try {
      await remoteDataSource.deleteRating(ratingId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

### Crear Data Source (Interface + Implementation)

**Ubicación**: `lib/features/[feature]/data/datasources/`

```dart
// Ejemplo: rating_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

abstract class RatingRemoteDataSource {
  Future<RatingModel> createRating({
    required String technicianId,
    required String clientId,
    required double score,
    required String comment,
  });

  Future<List<RatingModel>> getTechnicianRatings(String technicianId);
  Future<void> deleteRating(String ratingId);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final FirebaseFirestore firestore;

  RatingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<RatingModel> createRating({
    required String technicianId,
    required String clientId,
    required double score,
    required String comment,
  }) async {
    final docRef = await firestore.collection('ratings').add({
      'technicianId': technicianId,
      'clientId': clientId,
      'score': score,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return RatingModel(
      id: docRef.id,
      technicianId: technicianId,
      clientId: clientId,
      score: score,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<RatingModel>> getTechnicianRatings(String technicianId) async {
    final snapshot = await firestore
        .collection('ratings')
        .where('technicianId', isEqualTo: technicianId)
        .get();

    return snapshot.docs
        .map((doc) => RatingModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> deleteRating(String ratingId) async {
    await firestore.collection('ratings').doc(ratingId).delete();
  }
}
```

---

## PASO 3: CONEXIÓN CON BD/API

### En `lib/injection_container.dart`

```dart
// Registrar datasources, repositories y usecases
void setupRatingDependencies() {
  // Data sources
  sl.registerSingleton<RatingRemoteDataSource>(
    RatingRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerSingleton<RatingRepository>(
    RatingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerSingleton<CreateRatingUseCase>(
    CreateRatingUseCase(sl()),
  );
  sl.registerSingleton<GetTechnicianRatingsUseCase>(
    GetTechnicianRatingsUseCase(sl()),
  );
}
```

### Llamar en `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupRatingDependencies(); // ← Agregar esta línea

  runApp(const MyApp());
}
```

---

## PASO 4: UX/UI (Presentation Layer)

### Crear Screen

**Ubicación**: `lib/features/[feature]/presentation/pages/`

```dart
// Ejemplo: technician_ratings_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../domain/usecases/get_technician_ratings_usecase.dart';
import '../../domain/usecases/create_rating_usecase.dart';

final sl = GetIt.instance;

class TechnicianRatingsScreen extends StatefulWidget {
  final String technicianId;

  const TechnicianRatingsScreen({
    Key? key,
    required this.technicianId,
  }) : super(key: key);

  @override
  State<TechnicianRatingsScreen> createState() =>
      _TechnicianRatingsScreenState();
}

class _TechnicianRatingsScreenState extends State<TechnicianRatingsScreen> {
  late final GetTechnicianRatingsUseCase _getRatingsUseCase;
  late final CreateRatingUseCase _createRatingUseCase;

  @override
  void initState() {
    super.initState();
    _getRatingsUseCase = sl<GetTechnicianRatingsUseCase>();
    _createRatingUseCase = sl<CreateRatingUseCase>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: FutureBuilder(
        future: _getRatingsUseCase(widget.technicianId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ratings = snapshot.data ?? [];

          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildRatingCard(rating);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRatingDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRatingCard(RatingEntity rating) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${rating.score}/5',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rating.comment),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${rating.clientId}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    final scoreController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Calificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Puntuación (1-5)',
              ),
            ),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = double.tryParse(scoreController.text) ?? 0;
              final params = CreateRatingParams(
                technicianId: widget.technicianId,
                clientId: 'current_user_id',
                score: score,
                comment: commentController.text,
              );

              final result = await _createRatingUseCase(params);
              result.fold(
                (failure) => print('Error: $failure'),
                (rating) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calificación agregada'),
                    ),
                  );
                  setState(() {}); // Refrescar
                },
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
```

### Crear Widgets Reutilizables

**Ubicación**: `lib/features/[feature]/presentation/widgets/`

```dart
// Ejemplo: star_rating_widget.dart
import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final Function(double) onRatingChanged;
  final double initialRating;

  const StarRatingWidget({
    Key? key,
    required this.onRatingChanged,
    this.initialRating = 0,
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () {
            setState(() => _rating = index + 1.0);
            widget.onRatingChanged(_rating);
          },
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}
```

---

## RESUMEN: CHECKLIST POR FUNCIONALIDAD

```
☐ PASO 1: DOMAIN (Lógica de Negocio)
  ☐ Crear Entity
  ☐ Crear UseCase(s)
  ☐ Crear Repository (Interface)

☐ PASO 2: DATA (Lógica de Aplicación)
  ☐ Crear Model (extends Entity)
  ☐ Crear Repository Implementation
  ☐ Crear DataSource (interface + impl)

☐ PASO 3: INYECCIÓN DE DEPENDENCIAS
  ☐ Registrar DataSource
  ☐ Registrar Repository
  ☐ Registrar UseCase(s)
  ☐ Llamar setup en main.dart

☐ PASO 4: PRESENTATION (UI)
  ☐ Crear Screen(s)
  ☐ Crear Widget(s) reutilizables
  ☐ Conectar con UseCases
  ☐ Agregar rutas en AppRouter
```

---

## EJEMPLO RÁPIDO: Agregar Feature "HISTORIAL DE SERVICIOS"

### 1️⃣ Domain

```
service_history/
  domain/
    entities/
      - service_history_entity.dart
    repositories/
      - service_history_repository.dart
    usecases/
      - get_service_history_usecase.dart
```

### 2️⃣ Data

```
service_history/
  data/
    models/
      - service_history_model.dart
    repositories/
      - service_history_repository_impl.dart
    datasources/
      - service_history_remote_datasource.dart
```

### 3️⃣ Setup en injection_container.dart

```dart
sl.registerSingleton(ServiceHistoryRemoteDataSourceImpl(sl()));
sl.registerSingleton(ServiceHistoryRepositoryImpl(sl()));
sl.registerSingleton(GetServiceHistoryUseCase(sl()));
```

### 4️⃣ Presentation

```
service_history/
  presentation/
    pages/
      - service_history_screen.dart
    widgets/
      - service_history_card.dart
```

---

## FLUJO DE DESARROLLO RECOMENDADO

1. **Empezar por Domain** → Define qué quieres lograr
2. **Implementar Data** → Define cómo obtener los datos
3. **Inyectar Dependencias** → Conecta todo
4. **Crear UI** → Presenta los datos

**Ventajas:**

- ✅ Código testeable (domain/data sin UI)
- ✅ Fácil de mantener (cambios en BD sin afectar UI)
- ✅ Reutilizable (mismo UseCase en múltiples screens)
- ✅ Clean Architecture
