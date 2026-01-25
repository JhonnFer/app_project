import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../providers/session_provider.dart';
import '../../../../../../../core/constants/app_colors.dart';

class TechnicianNotificationsTab extends StatefulWidget {
  const TechnicianNotificationsTab({Key? key}) : super(key: key);

  @override
  State<TechnicianNotificationsTab> createState() =>
      _TechnicianNotificationsTabState();
}

class _TechnicianNotificationsTabState
    extends State<TechnicianNotificationsTab> {
  UserEntity? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final session = SessionManager();
    UserEntity? user = session.currentUser;

    if (user == null) {
      user = await session.checkSession();
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_currentUser == null)
      return Center(
        child: Text('No hay usuario',
            style: TextStyle(color: AppColors.textSecondary)),
      );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 226, 228, 234),
          title: const Text('Notificaciones'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '⏳ Pendientes'),
              Tab(text: '✅ Aceptadas'),
              Tab(text: '❌ Rechazadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsStream('service_requests', 'pending'),
            _buildRequestsStream('service_assignments', 'accepted', 'technicianId'),
            _buildRequestsStream('service_requests', 'rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsStream(String collection, String status, [String technicianField = 'selectedTechnicianIds']) {
    final query = (collection == 'service_assignments')
        ? FirebaseFirestore.instance
            .collection(collection)
            .where(technicianField, isEqualTo: _currentUser!.uid)
            .orderBy('acceptedAt', descending: true)
        : FirebaseFirestore.instance
            .collection(collection)
            .where(technicianField, arrayContains: _currentUser!.uid)
            .where('status', isEqualTo: status)
            .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return Center(
            child: Text('No hay solicitudes $status',
                style: TextStyle(color: AppColors.textSecondary)),
          );

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildRequestTile(data, status);
          },
        );
      },
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> data, String status) {
    Color chipColor;
    String chipText;

    switch (status) {
      case 'accepted':
        chipColor = AppColors.success;
        chipText = 'Aceptada';
        break;
      case 'rejected':
        chipColor = AppColors.error;
        chipText = 'Rechazada';
        break;
      default:
        chipColor = AppColors.warning;
        chipText = 'Pendiente';
    }

    return Card(
      color: AppColors.grey50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          data['clientName'] ?? data['technicianName'] ?? 'Solicitud',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          data['description'] ?? data['reason'] ?? '',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Chip(
          label: Text(
            chipText,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: chipColor,
        ),
      ),
    );
  }
}
