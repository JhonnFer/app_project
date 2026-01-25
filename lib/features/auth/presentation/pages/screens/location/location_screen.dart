//lib\features\auth\presentation\pages\screens\location\location_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../../../injection_container.dart';
import '../../../../domain/entities/user_entity.dart';
import 'package:app_project/features/auth/domain/usecases/save_location_usecase.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String userId;
  bool _isFromServiceRequest = false;

  LatLng selectedLocation = const LatLng(-0.180653, -78.467834); // Quito

  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController sectorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inicializamos los valores
    latController.text = selectedLocation.latitude.toString();
    lngController.text = selectedLocation.longitude.toString();
    sectorController.text = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Recibimos los argumentos desde Navigator
    final arguments = ModalRoute.of(context)!.settings.arguments;

    print('Location Screen - Argumentos recibidos: $arguments');

    if (arguments is UserEntity) {
      /// Si es un UserEntity directo, es del dashboard normal
      userId = arguments.uid;
      _isFromServiceRequest = false;
      print('Location Screen - Modo: Dashboard normal');
    } else if (arguments is Map<String, dynamic>) {
      // Si viene como un mapa, puede ser desde el formulario de solicitud
      _isFromServiceRequest = arguments['fromServiceRequest'] ?? false;
      final user = arguments['user'];
      userId = user?.uid ?? '';
      print(
          'Location Screen - Modo: Formulario de solicitud = $_isFromServiceRequest');
    }
  }

  Future<void> _saveLocation() async {
    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);
    var sector = sectorController.text.trim();

    print('=== GUARDANDO UBICACIÓN ===');
    print('latController: ${latController.text}');
    print('lngController: ${lngController.text}');
    print('sectorController inicial: $sector');

    if (lat == null || lng == null) {
      print('❌ Validación fallida: lat o lng null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de ubicación inválidos')),
      );
      return;
    }

    try {
      // Si el sector aún dice "Obteniendo dirección...", intentar obtenerla nuevamente
      if (sector.isEmpty || sector == 'Obteniendo dirección...') {
        print('⏳ Completando dirección...');
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            sector = [
              place.street,
              place.subLocality,
              place.locality,
              place.country,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            print('✅ Dirección obtenida: $sector');
          } else {
            sector = 'Ubicación: $lat, $lng';
            print('⚠️ Sin datos de lugar, usando coordenadas');
          }
        } catch (e) {
          print('⚠️ Error al obtener dirección: $e, usando coordenadas');
          sector = 'Ubicación: $lat, $lng';
        }
      }

      if (sector.isEmpty) {
        sector = 'Ubicación: $lat, $lng';
      }

      print('_isFromServiceRequest: $_isFromServiceRequest');

      // Si viene del formulario de solicitud, solo retornar los datos
      if (_isFromServiceRequest) {
        print('✅ Retornando datos al formulario de solicitud');
        final resultado = {
          'latitude': lat,
          'longitude': lng,
          'sector': sector,
        };
        print('Resultado que se retorna: $resultado');
        Navigator.pop(context, resultado);
        return;
      }

      // Si no, guardar en Firebase como normalmente
      print('⚙️ Guardando en Firebase...');
      await sl<SaveLocationUseCase>().call(
        userId: userId,
        latitude: lat,
        longitude: lng,
        sector: sector,
        accuracy: 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación guardada correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error al guardar ubicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar ubicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFromServiceRequest
              ? 'Seleccionar ubicación del servicio'
              : 'Mi ubicación',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Mapa'),
            Tab(icon: Icon(Icons.edit_location), text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          /// 🗺️ MAPA
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,
              onTap: (_, point) async {
                // 1️⃣ Actualizar posición y marcador
                setState(() {
                  selectedLocation = point;
                });

                // 2️⃣ Actualizar coordenadas
                latController.text = point.latitude.toString();
                lngController.text = point.longitude.toString();

                // 3️⃣ Feedback inmediato
                sectorController.text = 'Obteniendo dirección...';

                try {
                  final placemarks = await placemarkFromCoordinates(
                    point.latitude,
                    point.longitude,
                  );

                  if (placemarks.isNotEmpty) {
                    final place = placemarks.first;

                    sectorController.text = [
                      place.street,
                      place.subLocality,
                      place.locality,
                      place.country,
                    ].where((e) => e != null && e.isNotEmpty).join(', ');
                  } else {
                    sectorController.text =
                        'Ubicación: ${point.latitude}, ${point.longitude}';
                  }
                } catch (e) {
                  sectorController.text =
                      'Ubicación: ${point.latitude}, ${point.longitude}';
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_project',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// ✍️ MANUAL
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: latController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Latitud'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lngController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Longitud'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sectorController,
                  decoration:
                      const InputDecoration(labelText: 'Sector / Dirección'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveLocation,
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
      ),
    );
  }
}
