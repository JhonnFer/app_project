import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/routes/app_router.dart';

class GuestDashboardScreen extends StatefulWidget {
  const GuestDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _availableTechnicians = [];
  bool _isLoadingTechnicians = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTechnicians();
  }

  Future<void> _loadAvailableTechnicians() async {
    setState(() => _isLoadingTechnicians = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .where('isAvailable', isEqualTo: true)
          .get();

      setState(() {
        _availableTechnicians = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] ?? 'Técnico',
                  'rating': doc['rating'] ?? 0.0,
                  'completedServices': doc['completedServices'] ?? 0,
                  'specialties': List<String>.from(doc['specialties'] ?? []),
                  'profileImage':
                      doc['profileImage'] ?? 'https://via.placeholder.com/150',
                })
            .toList();
      });
    } catch (e) {
      print('Error cargando técnicos: $e');
    } finally {
      setState(() => _isLoadingTechnicians = false);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        elevation: 0,
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
            icon: Icon(Icons.info_outlined),
            selectedIcon: Icon(Icons.info),
            label: 'Info',
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
        return _buildInfoTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Banner
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
                  'Bienvenido a TechServe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Acceso limitado como invitado. Registrate para acceder a todas las funcionalidades.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.register);
                    },
                    child: const Text('Crear Cuenta Ahora'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Services Overview
          Text(
            'Servicios Disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildServiceOverviewCard(
            icon: Icons.kitchen_outlined,
            title: 'Electrodomésticos',
            description:
                'Reparación de refrigeradores,\nllavadoras, microondas y más',
          ),
          const SizedBox(height: 12),
          _buildServiceOverviewCard(
            icon: Icons.people_outline,
            title: 'Técnicos Certificados',
            description: 'Profesionales calificados y\nverificados en tu área',
          ),
          const SizedBox(height: 12),
          _buildServiceOverviewCard(
            icon: Icons.security_outlined,
            title: 'Garantía de Calidad',
            description:
                'Garantía en reparaciones y\ncompromiso con el servicio',
          ),
          const SizedBox(height: 24),
          // CTA Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    if (_isLoadingTechnicians) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableTechnicians.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay técnicos disponibles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta más tarde',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Técnicos Disponibles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableTechnicians.length,
            itemBuilder: (context, index) {
              final tech = _availableTechnicians[index];
              return _buildTechnicianCard(tech);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Acceso Limitado',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Para solicitar servicios a técnicos, debes iniciar sesión o crear una cuenta.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Registrarse'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> tech) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey200,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tech['name'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${tech['rating']} (${tech['completedServices']} servicios)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((tech['specialties'] as List<String>).isNotEmpty)
              Wrap(
                spacing: 6,
                children: (tech['specialties'] as List<String>)
                    .take(3)
                    .map(
                      (service) => Chip(
                        label: Text(
                          service,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Debes iniciar sesión para contactar técnicos'),
                      action: SnackBarAction(
                        label: 'Ir a Login',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Ver Detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Sobre TechServe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'TechServe es una plataforma que conecta a clientes con técnicos certificados para servicios de reparación de electrodomésticos a domicilio.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Características',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('Técnicos verificados y calificados'),
          _buildFeatureItem('Servicio a domicilio en tu área'),
          _buildFeatureItem('Chat directo con el técnico'),
          _buildFeatureItem('Sistema de calificaciones'),
          _buildFeatureItem('Garantía en reparaciones'),
          const SizedBox(height: 24),
          Text(
            'Contacto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'soporte@techserve.com',
          ),
          _buildContactItem(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: '+34 900 123 456',
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOverviewCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(width: 16),
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
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
