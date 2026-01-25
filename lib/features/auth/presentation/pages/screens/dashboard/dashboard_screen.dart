import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/routes/app_router.dart';
import '../../../../data/datasources/notification_service.dart';
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
                if (_currentUser == null) return;

                Navigator.of(context).pushNamed(
                  AppRoutes.serviceRequest,
                  arguments: _currentUser,
                );
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
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            '💰 Negociaciones de Precios',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Solicitudes organizadas por estado',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // 📋 PENDIENTES (Amarillo/Azul)
          _buildNegotiationSection(
            title: '⏳ Negociaciones Pendientes',
            subtitle: 'En espera de aceptar o rechazar',
            icon: Icons.schedule,
            color: Colors.blue,
            status: 'pending',
          ),
          const SizedBox(height: 16),

          // ✅ ACEPTADAS (Verde)
          _buildNegotiationSection(
            title: '✅ Negociaciones Aceptadas',
            subtitle: 'Acuerdos completados',
            icon: Icons.check_circle,
            color: Colors.green,
            status: 'accepted',
          ),
          const SizedBox(height: 16),

          // ❌ RECHAZADAS (Rojo)
          _buildNegotiationSection(
            title: '❌ Negociaciones Rechazadas',
            subtitle: 'Propuestas descartadas',
            icon: Icons.cancel,
            color: Colors.red,
            status: 'rejected',
          ),
        ],
      ),
    );
  }

  /// Constructor para cada sección de negociaciones
  Widget _buildNegotiationSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('price_negotiations')
          .where('recipientId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        // Filtrar por estado
        final negotiations = snapshot.data?.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .where((data) => (data['status'] ?? '') == status)
                .toList() ??
            [];

        if (negotiations.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Sin negociaciones en este estado',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${negotiations.length}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...negotiations.map((negotiation) {
                  return _buildNegotiationCard(negotiation, status);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tarjeta individual de negociación
  Widget _buildNegotiationCard(
      Map<String, dynamic> negotiation, String currentStatus) {
    final originalPrice = (negotiation['originalPrice'] ?? 0.0) as num;
    final proposedPrice = (negotiation['proposedPrice'] ?? 0.0) as num;
    final senderName = negotiation['senderName'] ?? 'Técnico';
    final reason = negotiation['reason'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (currentStatus == 'pending')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pendiente',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (currentStatus == 'accepted')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aceptada',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Rechazada',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio original',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${originalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey[400]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Contraoferta',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${proposedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Razón: $reason',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (currentStatus == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectNegotiation(negotiation),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _acceptNegotiation(negotiation),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Aceptar negociación
  Future<void> _acceptNegotiation(Map<String, dynamic> negotiation) async {
    final negotiationId = negotiation['id'] ?? '';
    final requestId = negotiation['requestId'] ?? '';
    final agreedPrice = (negotiation['proposedPrice'] ?? 0.0).toDouble();

    if (negotiationId.isEmpty || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Datos incompletos')),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Aceptando...'),
          ],
        ),
      ),
    );

    try {
      final success = await NotificationService().acceptPriceCounterOffer(
        negotiationId: negotiationId,
        requestId: requestId,
        acceptedByUserId: _currentUser!.uid,
        agreedPrice: agreedPrice,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta aceptada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al aceptar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading en caso de error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Rechazar negociación
  Future<void> _rejectNegotiation(Map<String, dynamic> negotiation) async {
    final negotiationId = negotiation['id'] ?? '';
    final requestId = negotiation['requestId'] ?? '';

    if (negotiationId.isEmpty || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Datos incompletos')),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Rechazando...'),
          ],
        ),
      ),
    );

    try {
      final success = await NotificationService().rejectPriceCounterOffer(
        negotiationId: negotiationId,
        requestId: requestId,
        rejectedByUserId: _currentUser!.uid,
        rejectionReason: 'Rechazado por el cliente',
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Contraoferta rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al rechazar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading en caso de error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar negociaciones en un BottomSheet (antiguo - mantener para compatibilidad)
  void _showNegotiationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('💰 Negociaciones Activas'),
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('price_negotiations')
                  .where('recipientId', isEqualTo: _currentUser!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay negociaciones pendientes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar por estado pending
                final pendingNegotiations = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? '') == 'pending';
                }).toList();

                if (pendingNegotiations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay negociaciones pendientes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: pendingNegotiations.length,
                  itemBuilder: (context, index) {
                    final negotiation = pendingNegotiations[index].data()
                        as Map<String, dynamic>;
                    final negotiationId = pendingNegotiations[index].id;

                    return NegotiationCard(
                      negotiationId: negotiationId,
                      negotiationData: negotiation,
                      currentUser: _currentUser!,
                      onRefresh: () => Navigator.pop(context),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar solicitudes pendientes
  void _showPendingRequestsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('📋 Solicitudes Pendientes'),
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('service_requests')
                  .where('uid', isEqualTo: _currentUser!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes solicitudes aún',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar solicitudes en estado "proposed" (sin negociación)
                final proposedRequests = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['priceStatus'] ?? 'proposed') == 'proposed';
                }).toList();

                if (proposedRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Todas tus solicitudes están en negociación',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: proposedRequests.length,
                  itemBuilder: (context, index) {
                    final request =
                        proposedRequests[index].data() as Map<String, dynamic>;
                    final requestId = proposedRequests[index].id;

                    return ServiceRequestCard(
                      requestId: requestId,
                      requestData: request,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar acuerdos completados
  void _showCompletedAgreementsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('✅ Acuerdos Completados'),
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('service_requests')
                  .where('uid', isEqualTo: _currentUser!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay acuerdos completados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar acuerdos completados
                final agreedRequests = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['priceStatus'] ?? '') == 'agreed';
                }).toList();

                if (agreedRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay acuerdos completados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: agreedRequests.length,
                  itemBuilder: (context, index) {
                    final request =
                        agreedRequests[index].data() as Map<String, dynamic>;

                    return AgreementCard(
                      requestData: request,
                    );
                  },
                );
              },
            ),
          ),
        ),
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

/// 💰 Widget para mostrar tarjeta de negociación
class NegotiationCard extends StatefulWidget {
  final String negotiationId;
  final Map<String, dynamic> negotiationData;
  final UserEntity currentUser;
  final VoidCallback onRefresh;

  const NegotiationCard({
    Key? key,
    required this.negotiationId,
    required this.negotiationData,
    required this.currentUser,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<NegotiationCard> createState() => _NegotiationCardState();
}

class _NegotiationCardState extends State<NegotiationCard> {
  @override
  Widget build(BuildContext context) {
    final proposedPrice = widget.negotiationData['proposedPrice'] ?? 0.0;
    final originalPrice = widget.negotiationData['originalPrice'] ?? 0.0;
    final senderName =
        widget.negotiationData['senderName'] ?? 'Usuario desconocido';
    final reason = widget.negotiationData['reason'] ?? '';
    final priceDifference = proposedPrice - originalPrice;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          priceDifference < 0 ? Icons.trending_down : Icons.trending_up,
          color: priceDifference < 0 ? Colors.red : Colors.green,
        ),
        title: Text('Contraoferta de $senderName'),
        subtitle: Text(
          '\$${originalPrice.toStringAsFixed(0)} → \$${proposedPrice.toStringAsFixed(0)}',
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PriceNegotiationDetailScreen(
                  negotiationId: widget.negotiationId,
                  negotiationData: widget.negotiationData,
                  currentUser: widget.currentUser,
                  onRefresh: widget.onRefresh,
                ),
              ),
            );
          },
          child: const Text('Ver'),
        ),
      ),
    );
  }
}

/// 📋 Widget para mostrar tarjeta de solicitud
class ServiceRequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const ServiceRequestCard({
    Key? key,
    required this.requestId,
    required this.requestData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceName = requestData['serviceName'] ?? 'Servicio desconocido';
    final price = requestData['proposedPrice'] ?? 0.0;
    final description = requestData['description'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.assignment_outlined,
          color: AppColors.primary,
        ),
        title: Text(serviceName),
        subtitle: Text('\$${price.toStringAsFixed(0)}'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            // Aquí puedes navegar a los detalles de la solicitud
          },
        ),
      ),
    );
  }
}

/// ✅ Widget para mostrar tarjeta de acuerdo
class AgreementCard extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const AgreementCard({
    Key? key,
    required this.requestData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceName = requestData['serviceName'] ?? 'Servicio desconocido';
    final agreedPrice = requestData['agreedPrice'] ?? 0.0;
    final technicianName = requestData['technicianName'] ?? 'Técnico asignado';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
        title: Text(serviceName),
        subtitle: Text('Técnico: $technicianName'),
        trailing: Text(
          '\$${agreedPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

/// 💬 Pantalla de detalles de negociación
class PriceNegotiationDetailScreen extends StatefulWidget {
  final String negotiationId;
  final Map<String, dynamic> negotiationData;
  final UserEntity currentUser;
  final VoidCallback onRefresh;

  const PriceNegotiationDetailScreen({
    Key? key,
    required this.negotiationId,
    required this.negotiationData,
    required this.currentUser,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PriceNegotiationDetailScreen> createState() =>
      _PriceNegotiationDetailScreenState();
}

class _PriceNegotiationDetailScreenState
    extends State<PriceNegotiationDetailScreen> {
  late TextEditingController _counterOfferController;
  late TextEditingController _reasonController;
  late TextEditingController _rejectionReasonController;
  final _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _counterOfferController = TextEditingController();
    _reasonController = TextEditingController();
    _rejectionReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _counterOfferController.dispose();
    _reasonController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _acceptOffer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Aceptando contraoferta...'),
          ],
        ),
      ),
    );

    try {
      final success = await _notificationService.acceptPriceCounterOffer(
        negotiationId: widget.negotiationId,
        requestId: widget.negotiationData['requestId'],
        acceptedByUserId: widget.currentUser.uid,
        agreedPrice: widget.negotiationData['proposedPrice'],
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta aceptada'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectOffer() async {
    if (_rejectionReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una razón')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Rechazando contraoferta...'),
          ],
        ),
      ),
    );

    try {
      final success = await _notificationService.rejectPriceCounterOffer(
        negotiationId: widget.negotiationId,
        requestId: widget.negotiationData['requestId'],
        rejectedByUserId: widget.currentUser.uid,
        rejectionReason: _rejectionReasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposedPrice = widget.negotiationData['proposedPrice'] ?? 0.0;
    final originalPrice = widget.negotiationData['originalPrice'] ?? 0.0;
    final reason = widget.negotiationData['reason'] ?? '';
    final senderName = widget.negotiationData['senderName'] ?? '';
    final priceDifference = proposedPrice - originalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Negociación de Precio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la contraoferta
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contraoferta de $senderName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Precio Original:'),
                        Text(
                          '\$${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Contraoferta:'),
                        Text(
                          '\$${proposedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                priceDifference < 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Razón: $reason',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Opciones de respuesta
            Text(
              'Tu Respuesta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _showRejectDialog(),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _acceptOffer,
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Contraoferta'),
        content: TextField(
          controller: _rejectionReasonController,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'Razón del rechazo...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed:
                _rejectionReasonController.text.isEmpty ? null : _rejectOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}
