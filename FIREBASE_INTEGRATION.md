# Firebase Integration Guide

## Status: ✅ Firebase Data Integration Completed

This document outlines the Firebase integration changes made to consume real data instead of mocked/hardcoded data.

---

## Changes Made

### 1. Dashboard Screen (Real User Data)

**File**: `lib/features/auth/presentation/pages/screens/dashboard/dashboard_screen.dart`

#### Changes:

- ✅ Removed hardcoded `_currentUser = UserEntity.client()`
- ✅ Added `_loadUserData()` async method that:
  - Retrieves user from SessionManager singleton
  - Calls `GetUserServicesUseCase` to fetch services from Firestore
  - Updates UI with real user data and service statistics
- ✅ Modified `_buildHomeTab()` to display:
  - Real user name from SessionManager
  - Real service counts (inProgress, completed) from Firestore
  - Recent services list from Firebase `services` collection
- ✅ Added loading and error state handling

### 2. User Services UseCase (New)

**File**: `lib/features/auth/domain/usecases/get_user_services_usecase.dart`

#### What it does:

- Creates a UseCase layer for fetching user services
- Implements clean architecture pattern
- Accepts `GetUserServicesParams(uid: String)`
- Returns `Either<Failure, Map<String, dynamic>>`

### 3. Remote DataSource - getUserServices Method

**File**: `lib/features/auth/data/datasources/auth_service.dart`

#### Implementation:

```dart
Future<Map<String, dynamic>> getUserServices(String uid) async {
  final servicesSnapshot = await _firestore
      .collection('services')
      .where('clientId', isEqualTo: uid)
      .get();

  // Groups services by status
  // Returns: {inProgress: int, completed: int, recentServices: List}
}
```

### 4. Repository - getUserServices Method

**File**: `lib/features/auth/data/repositories/auth_repository_impl.dart`

#### Implementation:

- Calls RemoteDataSource `getUserServices()` method
- Wraps result in Either<Failure, Success> pattern
- Handles exceptions as ServerFailure

**File**: `lib/features/auth/domain/repositories/auth_repository.dart`

#### Added Interface:

```dart
Future<Either<Failure, Map<String, dynamic>>> getUserServices(String uid);
```

### 5. Nearby Technicians - Real Firebase Data

**File**: `lib/features/auth/presentation/pages/screens/dashboard/nearby_technicians_tab.dart`

#### Changes:

- ✅ Added `_fetchNearbyTechniciansFromFirebase()` method that:
  - Queries Firestore `users` collection
  - Filters by `role == 'technician'`
  - Converts documents to `TechnicianLocation` objects
  - Calculates distance from user location
  - Falls back gracefully on error
- ✅ Modified `_initializeData()` to call Firebase method instead of `_generateMockTechnicians()`
- ✅ Fallback mechanism: Uses mock data if Firebase query returns empty list

### 6. Dependency Injection

**File**: `lib/injection_container.dart`

#### Changes:

- ✅ Added import for `GetUserServicesUseCase`
- ✅ Registered UseCase: `sl.registerLazySingleton(() => GetUserServicesUseCase(repository: sl()));`

---

## Required Firestore Collections Structure

### Collection: `users`

**Purpose**: Store user profiles for all user types

**Expected fields**:

```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "profileImage": "string (URL)",
  "rating": "number",
  "role": "technician|client|guest",
  "createdAt": "timestamp",

  // For technicians only:
  "specialties": ["array of strings"],
  "isAvailable": "boolean",
  "address": "string",
  "latitude": "number",
  "longitude": "number",
  "completedServices": "number"
}
```

**Example document (Technician)**:

```json
{
  "uid": "tech_001",
  "name": "Carlos García",
  "email": "carlos@example.com",
  "phone": "+34600000001",
  "profileImage": "https://...",
  "rating": 4.8,
  "role": "technician",
  "createdAt": "2024-01-15T10:30:00Z",
  "specialties": ["Refrigerador", "Lavadora", "Microondas"],
  "isAvailable": true,
  "address": "Calle Principal 123",
  "latitude": 4.7115,
  "longitude": -74.0053,
  "completedServices": 156
}
```

### Collection: `services`

**Purpose**: Store service requests from clients

**Expected fields**:

```json
{
  "clientId": "string",
  "clientName": "string",
  "status": "pending|inProgress|completed|cancelled",
  "technicianId": "string",
  "technicianName": "string",
  "serviceType": "string",
  "rating": "number",
  "title": "string",
  "description": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "scheduledDate": "timestamp"
}
```

**Example document**:

```json
{
  "clientId": "user_001",
  "clientName": "Juan Pérez",
  "status": "inProgress",
  "technicianId": "tech_001",
  "technicianName": "Carlos García",
  "serviceType": "Reparación Refrigerador",
  "rating": 4.9,
  "title": "Refrigerador no enfría",
  "description": "El refrigerador dejó de enfriar correctamente",
  "createdAt": "2024-01-15T14:00:00Z",
  "updatedAt": "2024-01-15T14:30:00Z",
  "scheduledDate": "2024-01-16T09:00:00Z"
}
```

---

## Code Flow Diagram

### Dashboard User Services

```
1. DashboardScreen initializes (_loadUserData called in initState)
2. Retrieves current user from SessionManager.currentUser
3. Calls GetUserServicesUseCase(uid: user.uid)
4. UseCase calls AuthRepository.getUserServices(uid)
5. Repository calls AuthRemoteDataSource.getUserServices(uid)
6. DataSource queries Firestore:
   - Collection: 'services'
   - Where: clientId == uid
   - Groups by status (inProgress, completed)
   - Returns: Map with counts and recent services
7. Result flows back through Either pattern
8. DashboardScreen updates UI with setState()
```

### Nearby Technicians

```
1. NearbyTechniciansTab initializes (_initializeData called in initState)
2. Gets user's current location via LocationService
3. Calls _fetchNearbyTechniciansFromFirebase(userLocation)
4. Method queries Firestore:
   - Collection: 'users'
   - Where: role == 'technician'
   - Gets all documents
5. For each technician:
   - Creates LocationData object
   - Calculates distance from user location
   - Converts to TechnicianLocation
6. Returns sorted by distance
7. If empty, falls back to _generateMockTechnicians()
8. UI displays technician list
```

---

## Authentication Session

The application uses a persistent session system:

1. **Login/Register**:
   - User authenticates with Firebase Auth
   - User data fetched from Firestore
   - UserEntity created from Firestore data
   - Session saved locally to SharedPreferences via LocalDataSource

2. **Session Manager**:
   - Singleton pattern
   - Provides `currentUser` getter
   - Returns logged-in user at app startup (via SplashScreen)

3. **Data Flow**:
   - Session restored on app launch
   - Real user data used for Dashboard
   - Services fetched from Firestore on-demand
   - Technicians fetched from Firestore on-demand

---

## Testing Checklist

- [ ] Firestore collections exist with correct structure
- [ ] `users` collection has at least 2 technician documents
- [ ] `services` collection has documents with matching `clientId` values
- [ ] Firebase project ID matches: `epn-proyectos-38e79`
- [ ] Firestore security rules allow reads from authenticated users
- [ ] App compiles without errors
- [ ] Dashboard displays real user name (from SessionManager)
- [ ] Dashboard displays correct service counts
- [ ] Dashboard shows recent services from Firestore
- [ ] Nearby Technicians tab loads technicians from Firestore
- [ ] Technicians sorted by distance calculation
- [ ] Error handling works (mock fallback displays if needed)

---

## Known Limitations

1. **Location Data**:
   - Technician location fetched from Firestore fields (`latitude`, `longitude`)
   - Not using real-time location updates
   - Can be enhanced with Geolocator integration

2. **Search/Filtering**:
   - Currently fetching ALL technicians from Firestore
   - Can be optimized with Firestore geohashing or Cloud Functions
   - Consider pagination for performance

3. **Real-time Updates**:
   - Currently using `.get()` for one-time fetch
   - Can be upgraded to `.snapshots()` for real-time listeners

4. **Error Handling**:
   - Graceful fallback to mock data on Firestore errors
   - Consider user feedback for Firebase failures

---

## Firestore Queries Used

### 1. Get User Services

```dart
_firestore
    .collection('services')
    .where('clientId', isEqualTo: uid)
    .get()
```

### 2. Get All Technicians

```dart
_firestore
    .collection('users')
    .where('role', isEqualTo: 'technician')
    .get()
```

---

## Future Enhancements

1. **Real-time Technician Updates**:
   - Use `.snapshots()` stream instead of `.get()`
   - Update UI when technician availability changes

2. **Geolocation Optimization**:
   - Implement Firestore geohashing
   - Query only nearby technicians instead of all

3. **Service Pagination**:
   - Implement pagination for service history
   - Lazy load additional services on scroll

4. **Offline Support**:
   - Enable Firestore offline persistence
   - Show cached data while offline

5. **Search & Filtering**:
   - Add service type filtering
   - Add technician specialty filtering
   - Add rating/price filtering

---

## Support

For issues or questions:

1. Check Firebase Console Firestore tab for collection structure
2. Verify security rules in Firebase Console
3. Check Firebase Analytics for any errors
4. Review app logs for Firestore query failures

---

**Last Updated**: 2025-01-20
**Status**: ✅ Integration Complete - Testing Phase
