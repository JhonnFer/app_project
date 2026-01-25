import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_services.dart';
import '../../../../../../core/routes/app_router.dart';
import '../../../../../../core/services/notification_service.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/session_provider.dart';
import 'nearby_technicians_tab.dart';

final sl = GetIt.instance;

class ServiceRequestFormScreen extends StatefulWidget {
  final UserEntity? user;

  const ServiceRequestFormScreen({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  State<ServiceRequestFormScreen> createState() =>
      _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  ApplianceService? _selectedService;
  String? _selectedUrgency;
  bool _isLoading = false;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  double? _latitude;
  double? _longitude;
  String? _selectedSector;

  // 🆕 Variables para técnicos
  List<Map<String, dynamic>> _selectedTechnicians = [];

  final List<String> _urgencyLevels = ['Baja', 'Media', 'Alta', 'Urgente'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedUrgency = 'Media';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _preferredDate) {
      setState(() {
        _preferredDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _preferredTime) {
      setState(() {
        _preferredTime = picked;
      });
    }
  }

  Future<void> _selectLocationFromMap() async {
    if (widget.user == null) return;

    // Pasar un mapa indicando que viene del formulario de solicitud
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.location,
      arguments: {
        'user': widget.user,
        'fromServiceRequest': true,
      },
    ) as Map<String, dynamic>?;

    print('Resultado del mapa: $result');

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
        _selectedSector = result['sector'] as String?;

        // Actualizar el campo de dirección con los datos capturados
        if (_selectedSector != null &&
            _selectedSector!.isNotEmpty &&
            _selectedSector != 'Obteniendo dirección...') {
          _addressController.text = _selectedSector!;
          print('✅ Dirección completa: ${_addressController.text}');
        } else if (_latitude != null && _longitude != null) {
          _addressController.text = 'Ubicación: $_latitude, $_longitude';
          print('📍 Usando coordenadas: ${_addressController.text}');
        }
      });

      // 🆕 Cargar técnicos cercanos después de seleccionar ubicación
      if (_latitude != null && _longitude != null) {
        await _showTechnicianMapSelector();
      }
    } else {
      print('❌ No se recibieron datos del mapa');
    }
  }

  /// 🆕 Abrir mapa para seleccionar técnicos
  Future<void> _showTechnicianMapSelector() async {
  if (!mounted) return;

  final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: const NearbyTechniciansTab(
        allowSelection: true,
        maxSelection: 2,
      ),
    ),
  );

  if (result != null && mounted) {
    setState(() {
      _selectedTechnicians = result;
    });
    print('✅ Técnicos actualizados en el estado');
  }
}

  Future<void> _submitForm() async {
    print('=== INICIANDO ENVÍO DE FORMULARIO ===');

    // Validar cada campo manualmente para ver cuál falla
    print('🔍 Validando campos del formulario...');
    print('  - Servicio: ${_selectedService?.name ?? "NO SELECCIONADO"}');
    print('  - Descripción: "${_descriptionController.text}"');
    print('  - Dirección: "${_addressController.text}"');
    print('  - Teléfono: "${_phoneController.text}"');
    print('  - Fecha: $_preferredDate');
    print('  - Hora: $_preferredTime');

    if (!_formKey.currentState!.validate()) {
      print('❌ Validación del formulario falló');
      print('💡 Verifica que todos los campos estén llenos:');
      print('   - Descripción debe tener al menos 10 caracteres');
      print('   - Dirección no debe estar vacía');
      print('   - Teléfono debe ser válido');
      return;
    }

    if (_selectedService == null) {
      print('❌ Servicio no seleccionado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un servicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_preferredDate == null) {
      print('❌ Fecha no seleccionada');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha preferida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_preferredTime == null) {
      print('❌ Hora no seleccionada');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una hora preferida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Todas las validaciones pasaron');
    setState(() => _isLoading = true);

    try {
      print('⏳ Obteniendo usuario...');
      // Obtener usuario actual de la sesión
      final session = SessionManager();
      UserEntity? currentUser = session.currentUser ?? widget.user;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      print('✅ Usuario: ${currentUser.name} (${currentUser.uid})');

      // Preparar datetime preferido
      final preferredDateTime = DateTime(
        _preferredDate!.year,
        _preferredDate!.month,
        _preferredDate!.day,
        _preferredTime!.hour,
        _preferredTime!.minute,
      );

      print('✅ Fecha y hora: $preferredDateTime');
      

      // Crear documento de solicitud en Firebase
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final serviceRequest = {
        'uid': currentUser.uid,
        'clientName': currentUser.name,
        'clientEmail': currentUser.email,
        'clientPhone': _phoneController.text.trim(),
        'serviceType': _selectedService!.id,
        'serviceName': _selectedService!.name,
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'sector': _selectedSector,
        'latitude': _latitude,
        'longitude': _longitude,
        'urgencyLevel': _selectedUrgency ?? 'Media',
        'preferredDate': preferredDateTime,
        'status':
            'pending', // pending, assigned, in_progress, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'technician': null, // Será asignado después
        'estimatedCost': null,
        'notes': '',
      };

      print('📦 Datos de solicitud preparados:');
      print('  - Servicio: ${_selectedService!.name}');
      print('  - Dirección: ${_addressController.text.trim()}');
      print('  - Teléfono: ${_phoneController.text.trim()}');
      print('  - Urgencia: ${_selectedUrgency ?? "Media"}');

      // Guardar en Firestore
      print('⏳ Guardando en Firestore...');
      final docRef =
          await _firestore.collection('service_requests').add(serviceRequest);
      final requestId = docRef.id;

      print('✅ Solicitud guardada en Firestore: $requestId');

      // 🆕 Validar que hay técnicos seleccionados
      if (_selectedTechnicians.isEmpty) {
        print('⚠️ No hay técnicos seleccionados');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona al menos un técnico del mapa'),
            backgroundColor: Colors.orange,
          ),
        );

        // Borrar la solicitud que se acaba de crear
        await _firestore.collection('service_requests').doc(requestId).delete();
        return;
      }

      // 📲 Notificar solo los técnicos seleccionados
      print('📲 Notificando ${_selectedTechnicians.length} técnicos seleccionados...');
      final notificationService = NotificationService();
      
      final selectedIds = _selectedTechnicians
          .map((t) => t['id'] as String)
          .toList();
      
      final techniciansNotified =
          await notificationService.notifySelectedTechnicians(
        requestId: requestId,
        selectedTechnicianIds: selectedIds,
        clientName: currentUser.name,
        clientEmail: currentUser.email,
        clientPhone: _phoneController.text.trim(),
        serviceType: _selectedService!.name,
        description: _descriptionController.text.trim(),
        urgencyLevel: _selectedUrgency ?? 'Media',
        latitude: _latitude ?? 0,
        longitude: _longitude ?? 0,
        address: _addressController.text.trim(),
        preferredDate: preferredDateTime,
      );

      print('✅ Técnicos notificados: $techniciansNotified');

      // Éxito
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud enviada a $techniciansNotified técnicos'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('✅ Mensaje de éxito mostrado');

      // Navegar de vuelta al dashboard después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      print('✅ Navegando de vuelta...');
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ ERROR: $e');
      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      print('🏁 Finalizando...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Servicio Técnico'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seleccionar Servicio
              Text(
                'Tipo de Servicio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ApplianceService>(
                value: _selectedService,
                items: AppServices.whiteLinerServices.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text('${service.icon} ${service.name}'),
                  );
                }).toList(),
                onChanged: (service) {
                  setState(() => _selectedService = service);
                },
                decoration: InputDecoration(
                  hintText: 'Selecciona un servicio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor selecciona un servicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Descripción del Problema
              Text(
                'Descripción del Problema',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe el problema que estás experimentando',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La descripción es requerida';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Dirección
              Text(
                'Dirección de Atención',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectLocationFromMap,
                child: TextFormField(
                  controller: _addressController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Toca para seleccionar ubicación en el mapa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: const Icon(Icons.map_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona la ubicación';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Teléfono
              Text(
                'Teléfono de Contacto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+57 3XX XXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  // Validación básica de teléfono
                  if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                    return 'Por favor ingresa un teléfono válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Nivel de Urgencia
              Text(
                'Nivel de Urgencia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUrgency,
                items: _urgencyLevels.map((level) {
                  Color color;
                  IconData icon;

                  switch (level) {
                    case 'Baja':
                      color = Colors.blue;
                      icon = Icons.trending_down;
                      break;
                    case 'Media':
                      color = Colors.orange;
                      icon = Icons.trending_flat;
                      break;
                    case 'Alta':
                      color = Colors.red;
                      icon = Icons.trending_up;
                      break;
                    case 'Urgente':
                      color = Colors.red;
                      icon = Icons.priority_high;
                      break;
                    default:
                      color = Colors.grey;
                      icon = Icons.help;
                  }

                  return DropdownMenuItem(
                    value: level,
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(level),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUrgency = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
              ),
              const SizedBox(height: 20),

              // Fecha Preferida
              Text(
                'Fecha Preferida',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.grey100,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 12),
                      Text(
                        _preferredDate == null
                            ? 'Selecciona una fecha'
                            : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hora Preferida
              Text(
                'Hora Preferida',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.grey100,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 12),
                      Text(
                        _preferredTime == null
                            ? 'Selecciona una hora'
                            : '${_preferredTime!.hour.toString().padLeft(2, '0')}:${_preferredTime!.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🆕 SELECCIONAR TÉCNICOS - Botón para abrir mapa
              Text(
                'Técnicos Cercanos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _addressController.text.isEmpty
                    ? null
                    : _showTechnicianMapSelector,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _addressController.text.isEmpty
                          ? AppColors.grey300
                          : AppColors.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _addressController.text.isEmpty
                        ? AppColors.grey100
                        : AppColors.primary.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 40,
                        color: _addressController.text.isEmpty
                            ? Colors.grey
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedTechnicians.isEmpty
                            ? 'Ver técnicos disponibles en el mapa'
                            : 'Cambiar técnicos seleccionados',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _addressController.text.isEmpty
                                  ? Colors.grey
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedTechnicians.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedTechnicians.map((tech) {
                            return Chip(
                              label: Text(tech['name'] ?? 'Técnico'),
                              onDeleted: () {
                                setState(() {
                                  _selectedTechnicians.removeWhere(
                                    (t) => t['id'] == tech['id'],
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Enviar Solicitud'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 
