import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_services.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/entities/user.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/role_selection_card.dart';
import '../../widgets/common/service_checklist_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  
  UserRole? _selectedRole;
  List<ApplianceService> _selectedServices = [];
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un rol')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Simulamos una llamada al servidor
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso!')),
          );
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicator
              Row(
                children: [
                  _buildStepIndicator(0, 'Rol'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0 ? AppColors.primary : AppColors.grey200,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  _buildStepIndicator(1, 'Datos'),
                  if (_selectedRole == UserRole.technician) ...[
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep > 1 ? AppColors.primary : AppColors.grey200,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    _buildStepIndicator(2, 'Servicios'),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              if (_currentStep == 0) ...[
                _buildRoleSelectionStep(),
              ] else if (_currentStep == 1) ...[
                _buildDataCollectionStep(),
              ] else if (_currentStep == 2) ...[
                _buildServicesSelectionStep(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.grey200,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.textSecondary,
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
            color: isActive ? AppColors.primary : AppColors.textSecondary,
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
          AppStrings.selectRole,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Elige el tipo de cuenta que necesitas',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        // Client Role
        RoleSelectionCard(
          roleName: AppStrings.clientRole,
          description: 'Solicita servicios técnicos a domicilio',
          icon: Icons.person_outline,
          isSelected: _selectedRole == UserRole.client,
          onTap: () {
            setState(() => _selectedRole = UserRole.client);
          },
        ),
        const SizedBox(height: 16),
        // Technician Role
        RoleSelectionCard(
          roleName: AppStrings.technicianRole,
          description: 'Ofrece servicios de reparación de electrodomésticos',
          icon: Icons.build_circle_outlined,
          isSelected: _selectedRole == UserRole.technician,
          onTap: () {
            setState(() => _selectedRole = UserRole.technician);
          },
        ),
        const SizedBox(height: 32),
        // Continue Button
        CustomButton(
          label: AppStrings.continueBtn,
          onPressed: _selectedRole != null
              ? () {
                  setState(() => _currentStep = 1);
                }
              : null,
          width: double.infinity,
        ),
      ],
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
        CustomTextField(
          label: AppStrings.fullName,
          hint: 'Juan Pérez García',
          controller: _fullNameController,
          prefixIcon: const Icon(Icons.person_outline),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppStrings.enterFullName;
            }
            if ((value?.length ?? 0) < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Email
        CustomTextField(
          label: AppStrings.email,
          hint: 'correo@ejemplo.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppStrings.enterEmail;
            }
            if (!RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                .hasMatch(value!)) {
              return AppStrings.invalidEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Phone
        CustomTextField(
          label: AppStrings.phone,
          hint: '+34 612 345 678',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppStrings.enterPhone;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Password
        CustomTextField(
          label: AppStrings.password,
          hint: '••••••••',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppStrings.enterPassword;
            }
            if ((value?.length ?? 0) < 6) {
              return AppStrings.passwordTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Confirm Password
        CustomTextField(
          label: AppStrings.confirmPassword,
          hint: '••••••••',
          controller: _confirmPasswordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppStrings.enterPassword;
            }
            if (value != _passwordController.text) {
              return AppStrings.passwordMismatch;
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        // Next/Register Button
        if (_selectedRole == UserRole.technician)
          CustomButton(
            label: 'Siguiente',
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() => _currentStep = 2);
              }
            },
            width: double.infinity,
          )
        else
          CustomButton(
            label: AppStrings.signUp,
            isLoading: _isLoading,
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _handleRegister();
                    }
                  },
            width: double.infinity,
          ),
        const SizedBox(height: 16),
        // Back Button
        OutlinedButton(
          onPressed: () {
            setState(() => _currentStep = 0);
          },
          child: const Text('Volver'),
        ),
        const SizedBox(height: 16),
        // Login Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.alreadyHaveAccount,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
                child: Text(
                  AppStrings.login,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ServiceChecklistWidget(
          selectedServices: _selectedServices,
          onServicesChanged: (services) {
            setState(() {
              _selectedServices = services;
            });
          },
        ),
        const SizedBox(height: 32),
        // Complete Registration Button
        CustomButton(
          label: 'Completar Registro',
          isLoading: _isLoading,
          onPressed: _selectedServices.isEmpty
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _handleRegister();
                  }
                },
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        // Back Button
        OutlinedButton(
          onPressed: () {
            setState(() => _currentStep = 1);
          },
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
