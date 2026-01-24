import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../domain/usecases/register_usecase.dart';
import '../../../providers/session_provider.dart';

final sl = GetIt.instance;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  UserRole? _selectedRole;
  List<String> _selectedServices = [];
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    // Scroll al inicio cuando cambie de paso
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un rol')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final name = _fullNameController.text;
        final phone = _phoneController.text;
        final role = _selectedRole!.name;

        // Usar RegisterUseCase
        final result = await sl<RegisterUseCase>()(
          RegisterParams(
            email: email,
            password: password,
            name: name,
            role: role,
            phone: phone,
          ),
        );

        result.fold(
          // Error
          (failure) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          // Éxito
          (user) {
            if (mounted) {
              setState(() => _isLoading = false);
              // Guardar usuario en SessionManager para acceso rápido en memoria
              SessionManager().setCurrentUser(user);
              // Sesión ya se guarda en SharedPreferences en el repositorio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Registro exitoso!')),
              );
              // Navegar al dashboard después de registro exitoso
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 32),

                if (_currentStep == 0) ...[
                  _buildRoleSelectionStep(),
                ] else if (_currentStep == 1) ...[
                  _buildDataCollectionStep(),
                ] else if (_currentStep == 2) ...[
                  _buildServicesSelectionStep(),
                ],

                // Espacio adicional al final para asegurar scroll
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Rol'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep > 0 ? Colors.blue : Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepCircle(1, 'Datos'),
        if (_selectedRole == UserRole.technician) ...[
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 1 ? Colors.blue : Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          _buildStepCircle(2, 'Servicios'),
        ],
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecciona tu rol',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Elige el tipo de cuenta que necesitas',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 32),

        // Client Role
        _buildRoleCard(
          roleName: 'Cliente',
          description: 'Solicita servicios técnicos a domicilio',
          icon: Icons.person_outline,
          roleValue: UserRole.client,
        ),
        const SizedBox(height: 16),

        // Technician Role
        _buildRoleCard(
          roleName: 'Técnico',
          description: 'Ofrece servicios de reparación de electrodomésticos',
          icon: Icons.build_circle_outlined,
          roleValue: UserRole.technician,
        ),
        const SizedBox(height: 32),

        // Continue Button
        ElevatedButton(
          onPressed: _selectedRole != null ? () => _goToStep(1) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String roleName,
    required String description,
    required IconData icon,
    required UserRole roleValue,
  }) {
    final isSelected = _selectedRole == roleValue;
    return InkWell(
      onTap: () => setState(() => _selectedRole = roleValue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Widget _buildDataCollectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Completa tu perfil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        // Full Name
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            hintText: 'Juan Pérez García',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Ingresa tu nombre';
            if ((value?.length ?? 0) < 3) return 'Mínimo 3 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Ingresa tu email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Email inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            hintText: '+593 987654321',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Ingresa tu teléfono';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Ingresa una contraseña';
            if ((value?.length ?? 0) < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar contraseña',
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Confirma tu contraseña';
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),

        // Next/Register Button
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (_selectedRole == UserRole.technician) {
                      _goToStep(2);
                    } else {
                      _handleRegister();
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _selectedRole == UserRole.technician
                      ? 'Siguiente'
                      : 'Registrarse',
                ),
        ),
        const SizedBox(height: 16),

        // Back Button
        OutlinedButton(
          onPressed: () => _goToStep(0),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildServicesSelectionStep() {
    final services = [
      'Refrigeración',
      'Lavadoras',
      'Secadoras',
      'Cocinas',
      'Hornos',
      'Microondas',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecciona tus servicios',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        ...services.map((service) => CheckboxListTile(
              title: Text(service),
              value: _selectedServices.contains(service),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                });
              },
            )),

        const SizedBox(height: 32),

        // Complete Button
        ElevatedButton(
          onPressed:
              _selectedServices.isEmpty || _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Completar Registro'),
        ),
        const SizedBox(height: 16),

        // Back Button
        OutlinedButton(
          onPressed: () => _goToStep(1),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
