import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/routes/app_router.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../domain/usecases/get_user_services_usecase.dart';
import '../../../../presentation/providers/session_provider.dart';
import 'nearby_technicians_tab.dart';

final sl = GetIt.instance;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  UserEntity? _currentUser;
  bool _isLoading = true;
  Map<String, dynamic>? _userServices;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Obtener usuario de la sesión (singleton)
      final session = SessionManager();
      UserEntity? user = session.currentUser;

      // Si no está en memoria, cargar desde SharedPreferences
      if (user == null) {
        user = await session.checkSession();
      }

      if (user != null) {
        setState(() => _currentUser = user);

        // Cargar servicios del usuario
        final result = await sl<GetUserServicesUseCase>()(
          GetUserServicesParams(uid: user.uid),
        );

        result.fold(
          (failure) => print('Error cargando servicios: $failure'),
          (services) => setState(() => _userServices = services),
        );
      } else {
        print('No hay usuario autenticado');
      }
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {
              if (_currentUser == null) return;

              Navigator.of(context).pushNamed(
                AppRoutes.location,
                arguments: _currentUser, // 👈 PASAMOS EL USER
              );
            },
            tooltip: 'Mi Ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Técnicos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildExploreTab();
      case 2:
        return const NearbyTechniciansTab();
      case 3:
        return _buildChatTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null) {
      return const Center(child: Text('Error al cargar datos del usuario'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.welcomeBack},',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick Stats
          Text(
            AppStrings.activeServices,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_outlined,
                  title: 'En Progreso',
                  value: '${_userServices?['inProgress'] ?? 0}',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outlined,
                  title: 'Completados',
                  value: '${_userServices?['completed'] ?? 0}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Services
          Text(
            'Servicios Recientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Servicios recientes de Firebase
          if (_userServices != null &&
              (_userServices!['recentServices'] as List).isNotEmpty)
            ...((_userServices!['recentServices'] as List).map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildServiceCard(
                  title: service['title'] as String,
                  technician: service['technician'] as String,
                  status: service['status'] as String == 'completed'
                      ? 'Completado'
                      : 'En Progreso',
                  rating: service['rating'] as double? ?? 0.0,
                ),
              );
            }).toList())
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Text(
                  'No hay servicios registrados',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Browse Services Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to browse services
              },
              icon: const Icon(Icons.add),
              label: const Text('Solicitar Nuevo Servicio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_outlined,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.browseServices,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Explora los servicios disponibles\ny contrata un técnico',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin conversaciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus chats\ncon técnicos y clientes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'Usuario',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.role.name.toUpperCase() ?? 'GUEST',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          // Profile Info
          _buildProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: _currentUser?.email ?? 'No registrado',
          ),
          const SizedBox(height: 12),
          _buildProfileInfoTile(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: _currentUser?.phone ?? 'No registrado',
          ),
          const SizedBox(height: 24),
          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text(AppStrings.settings),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout_outlined),
              label: const Text(AppStrings.logout),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String technician,
    required String status,
    required double rating,
  }) {
    final isCompleted = status == 'Completado';
    final statusColor = isCompleted ? AppColors.success : AppColors.info;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Con: $technician',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$rating',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
