import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/notification_service.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/session_provider.dart';

class TechnicianNotificationsTab extends StatefulWidget {
  const TechnicianNotificationsTab({Key? key}) : super(key: key);

  @override
  State<TechnicianNotificationsTab> createState() =>
      _TechnicianNotificationsTabState();
}

class _TechnicianNotificationsTabState
    extends State<TechnicianNotificationsTab> {
  final NotificationService _notificationService = NotificationService();
  late String _technicianId;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTechnicianId();
  }

  void _loadTechnicianId() {
    final session = SessionManager();
    _technicianId = session.currentUser?.uid ?? '';
    print('📲 Técnico ID: $_technicianId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevas Solicitudes'),
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _notificationService.getNotificationsForTechnician(_technicianId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          // Actualizar contador de no leídas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final unread = notifications.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !(data['isRead'] ?? false);
            }).length;

            if (unread != _unreadCount && mounted) {
              setState(() => _unreadCount = unread);
            }
          });

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin solicitudes nuevas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Las solicitudes de clientes aparecerán aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return _buildNotificationCard(
                context,
                notification.id,
                data,
                isRead,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    String notificationId,
    Map<String, dynamic> data,
    bool isRead,
  ) {
    final urgency = data['urgencyLevel'] ?? 'Media';
    final urgencyColor = urgency == 'Urgente'
        ? AppColors.warning
        : urgency == 'Alta'
            ? Colors.orange
            : AppColors.info;

    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo =
        createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Hace poco';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead
          ? AppColors.white
          : AppColors.primaryLight.withValues(alpha: 0.1),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: urgencyColor.withValues(alpha: 0.2),
          ),
          child: Icon(
            Icons.handyman_outlined,
            color: urgencyColor,
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Cliente: ${data['clientName'] ?? "Unknown"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Servicio: ${data['serviceType'] ?? ""}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              data['description'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    urgency,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Marcar como leída
          if (!isRead) {
            _notificationService.markNotificationAsRead(notificationId);
          }

          // Mostrar detalles de la solicitud
          _showRequestDetails(context, data, notificationId);
        },
        trailing: PopupMenuButton(
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              child: const Text('Ver detalles'),
              onTap: () {
                if (!isRead) {
                  _notificationService.markNotificationAsRead(notificationId);
                }
                _showRequestDetails(context, data, notificationId);
              },
            ),
            PopupMenuItem(
              child: const Text('Aceptar solicitud'),
              onTap: () {
                _acceptServiceRequest(context, data, notificationId);
              },
            ),
            PopupMenuItem(
              child: const Text('Rechazar'),
              onTap: () {
                _showRejectDialog(context, data, notificationId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(
      BuildContext context, Map<String, dynamic> data, String notificationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detalles de la Solicitud',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Cliente
                _buildDetailRow('Cliente', data['clientName'] ?? '-'),
                _buildDetailRow('Email', data['clientEmail'] ?? '-'),
                _buildDetailRow('Teléfono', data['clientPhone'] ?? '-'),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Solicitud
                _buildDetailRow('Servicio', data['serviceType'] ?? '-'),
                _buildDetailRow('Urgencia', data['urgencyLevel'] ?? '-'),
                _buildDetailRow('Dirección', data['address'] ?? '-'),

                // 💰 NUEVO: Mostrar precio propuesto
                if (data['proposedPrice'] != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Precio Propuesto:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${(data['proposedPrice'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                Text(
                  'Descripción:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['description'] ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 16),

                // Fecha preferida
                if (data['preferredDate'] != null)
                  _buildDetailRow(
                    'Fecha Preferida',
                    _formatDate(data['preferredDate']),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _acceptServiceRequest(context, data, notificationId);
                    },
                    child: const Text('Aceptar Solicitud'),
                  ),
                ),
                const SizedBox(height: 12),
                // 💰 NUEVO: Botón para contraoferta
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.attach_money),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCounterOfferDialog(context, data);
                    },
                    label: const Text('Enviar Contraoferta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRejectDialog(context, data, notificationId);
                    },
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 💰 ENVIAR CONTRAOFERTA
  void _showCounterOfferDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    final originalPrice = (data['proposedPrice'] ?? 0.0) as num;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('💰 Enviar Contraoferta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio Original: \$${originalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tu Precio',
                  hintText: 'Ej: 60000',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Razón de la Contraoferta',
                  hintText: 'Explica por qué propones este precio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isEmpty ||
                  reasonController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un precio válido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Cerrar diálogo de entrada
              if (!mounted) return;
              Navigator.pop(dialogContext);

              final session = SessionManager();
              final technician = session.currentUser;

              if (technician == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Usuario no encontrado'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Mostrar loading con context del widget principal
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Enviando contraoferta...'),
                    ],
                  ),
                ),
              );

              try {
                // Enviar contraoferta
                final success =
                    await _notificationService.sendPriceCounterOffer(
                  requestId: data['requestId'] ?? '',
                  senderId: technician.uid,
                  senderName: technician.name,
                  recipientId: data['uid'] ?? '',
                  recipientName: data['clientName'] ?? '',
                  proposedPrice: price,
                  originalPrice: originalPrice.toDouble(),
                  reason: reasonController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context); // Cerrar loading

                if (success) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Contraoferta enviada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Limpiar controllers
                  priceController.dispose();
                  reasonController.dispose();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Error al enviar contraoferta'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  /// 🎯 ACEPTAR SOLICITUD
  Future<void> _acceptServiceRequest(
    BuildContext context,
    Map<String, dynamic> data,
    String notificationId,
  ) async {
    try {
      final session = SessionManager();
      final technician = session.currentUser;

      if (technician == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no encontrado')),
        );
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Aceptando solicitud...'),
            ],
          ),
        ),
      );

      // Aceptar solicitud
      final success = await _notificationService.acceptServiceRequest(
        requestId: data['requestId'],
        technicianId: technician.uid,
        technicianName: technician.name,
        technicianEmail: technician.email,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud aceptada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al aceptar la solicitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ❌ RECHAZAR SOLICITUD
  void _showRejectDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String notificationId,
  ) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué deseas rechazar esta solicitud?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ingresa el motivo (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              Navigator.pop(dialogContext); // Cerrar diálogo

              final session = SessionManager();
              final technician = session.currentUser;

              if (technician == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Usuario no encontrado'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Mostrar loading con context del widget principal
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Rechazando solicitud...'),
                    ],
                  ),
                ),
              );

              try {
                // Rechazar
                final success = await _notificationService.rejectServiceRequest(
                  requestId: data['requestId'],
                  technicianId: technician.uid,
                  technicianName: technician.name,
                  rejectionReason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Sin especificar',
                );

                if (!mounted) return;
                Navigator.pop(context); // Cerrar loading

                if (success) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Solicitud rechazada'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  reasonController.dispose();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Error al rechazar la solicitud'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace poco';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }
}
