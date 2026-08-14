import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/cart_store.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

/// Clean, Simple, & Elegant Login Screen for Vela Agency POS.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  // Only this number is allowed to log in
  static const String _allowedNumber = '9344486055';

  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    setState(() => _isLoading = true);

    final enteredMobile = _mobileController.text.trim();
    CartStore.activeEmployee = enteredMobile;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Store Logo Icon Box
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Store Title & Subtitle
                        Text(
                          'Vela Agency'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to start billing'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: context.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Mobile Number Input Field
                        Text(
                          'Mobile Number'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (val) {
                            final digits = (val ?? '').trim();
                            if (digits.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (digits.length != 10) {
                              return 'Mobile number must be 10 digits';
                            }
                            if (digits != _allowedNumber) {
                              return 'Access denied. Unauthorized number.';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Enter 10-digit mobile number',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Button
                        PrimaryButton(
                          label: 'Login',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),

                        const SizedBox(height: 28),

                        // Footer Text
                        Text(
                          'Vela Agency POS · Grocery · Quality · Trust',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
