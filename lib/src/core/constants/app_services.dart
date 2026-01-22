class ApplianceService {
  final String id;
  final String name;
  final String description;
  final String icon;

  ApplianceService({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplianceService &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AppServices {
  static final List<ApplianceService> whiteLinerServices = [
    ApplianceService(
      id: 'lavadora',
      name: 'Lavadora',
      description: 'Reparación de lavadoras automáticas y semiautomáticas',
      icon: '🧺',
    ),
    ApplianceService(
      id: 'refrigerador',
      name: 'Refrigerador',
      description: 'Reparación y mantenimiento de refrigeradores y congeladores',
      icon: '❄️',
    ),
    ApplianceService(
      id: 'estufa',
      name: 'Estufa',
      description: 'Reparación de estufas eléctricas y a gas',
      icon: '🔥',
    ),
    ApplianceService(
      id: 'horno',
      name: 'Horno Microondas',
      description: 'Reparación de hornos microondas y convencionales',
      icon: '🍽️',
    ),
    ApplianceService(
      id: 'lavavajillas',
      name: 'Lavavajillas',
      description: 'Reparación de lavavajillas automáticas',
      icon: '🍴',
    ),
    ApplianceService(
      id: 'licuadora',
      name: 'Licuadora',
      description: 'Reparación de licuadoras y procesadores de alimentos',
      icon: '🥤',
    ),
    ApplianceService(
      id: 'secadora',
      name: 'Secadora',
      description: 'Reparación de secadoras de ropa',
      icon: '🌪️',
    ),
    ApplianceService(
      id: 'aire_acondicionado',
      name: 'Aire Acondicionado',
      description: 'Instalación y reparación de aire acondicionado',
      icon: '❄️',
    ),
    ApplianceService(
      id: 'calentador',
      name: 'Calentador de Agua',
      description: 'Reparación de calentadores eléctricos y a gas',
      icon: '🔥',
    ),
    ApplianceService(
      id: 'plancha',
      name: 'Plancha',
      description: 'Reparación de planchas eléctricas',
      icon: '👕',
    ),
  ];

  static ApplianceService getServiceById(String id) {
    return whiteLinerServices.firstWhere(
      (service) => service.id == id,
      orElse: () => ApplianceService(
        id: '',
        name: 'Desconocido',
        description: '',
        icon: '❓',
      ),
    );
  }
}
