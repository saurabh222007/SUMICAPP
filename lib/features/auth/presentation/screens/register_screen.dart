import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../../shared/widgets/glass_container.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service & Privacy Policy.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API Network Latency
    await Future.delayed(const Duration(milliseconds: 1200));

    // Save token to secure storage to bypass route redirect checks
    const secureStorage = SecureStorageService();
    await secureStorage.write(SecureStorageKeys.accessToken, 'mock_access_token');
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5C8A).withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo Image
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida/AP1WRLsh1ql0UKdrm4ZMQdiQW6ddmuaIhoRRP-bJsKPmzY4Gkls1wpIdYUKyCBmkcV6qykFEv8lQchteglL8gKMxA6bu7YEWngGoKuumQql0UsXHBSPpI1UEbU1d0DrGpqwl4zk6qFRGqhISxXl8x9mjTt3hGHVWV_A3pKvd1DubpsTzMQheAvGAca5YHA6cVePD4aDtDrf277lgTTaTK2HAjxgA_z_lFM4hsXK6qm23L0eL17xCpGr3LV9tOBM',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 22.0,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Full Name input
                    TextFormField(
                      controller: _nameController,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                        floatingLabelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFF0D0D12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.darkOutline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Address input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                        floatingLabelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFF0D0D12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.darkOutline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                        floatingLabelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFF0D0D12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.darkOnSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.darkOutline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password input
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                        floatingLabelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFF0D0D12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.darkOutline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // Terms of service check
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          activeColor: AppColors.primary,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setState(() => _acceptTerms = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.darkOnSurfaceVariant,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Action Button (Gradient)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFFF5C8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Create Account',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Separator
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.darkOutline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'or sign up with',
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFFA0A0AD),
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.darkOutline)),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Social buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google
                        _SocialButton(
                          onTap: () {},
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDLTOHldrUGtOzRwDq6SLdlfFRhDNa5jw3dCTzJc6P3IWVOT5UDLO7njmxdgwskhaPLRo6eY1MdPUr7DTh3Vqbs-mkiMATzFDoyTaQn0ZkESTNOjwEozN4JvUx8ayD2P125y_C3uSVQ3q6irSHcQmQZ6F_D2mz5jCKSbAoSOeA-lFxux_VWNlgbFrcvrxS6a8NZfdUifbxAv0ez4tXI8I8gJciRusuQmqQRfGkKBke6RNR-Q90toR9g_31df_Ml2YymvanwkoXRarU',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Apple
                        _SocialButton(
                          onTap: () {},
                          child: const Icon(Icons.apple, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 24),
                        // Facebook
                        _SocialButton(
                          onTap: () {},
                          child: const Icon(Icons.facebook, color: Colors.white, size: 26),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // Switch to login
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFA0A0AD)),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: AppTypography.titleMedium.copyWith(
                                  color: const Color(0xFFFF5C8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 28.0,
        width: 56,
        height: 56,
        backgroundColor: Colors.white.withOpacity(0.05),
        child: Center(child: child),
      ),
    );
  }
}
