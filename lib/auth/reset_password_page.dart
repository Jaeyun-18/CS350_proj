import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'auth_visuals.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(_emailController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyAuthMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return AuthVisuals.inputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: AuthVisuals.muted, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AuthVisuals.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: AuthVisuals.cardDecoration,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthBrandMark(
                          title: 'WeBuyDivvy',
                          subtitle: 'Split grocery runs. Save more together.',
                          small: true,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Reset password',
                          style: AuthVisuals.titleStyle(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We will email a reset link to your KAIST address.',
                          style: AuthVisuals.subtitleStyle(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'KAIST EMAIL',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSendReset(),
                          decoration: _fieldDecoration(
                            labelText: 'Email',
                            hintText: 'name@kaist.ac.kr',
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: AuthService.instance.validateEmail,
                        ),
                        const SizedBox(height: 18),
                        AuthGradientButton(
                          label: 'Get New Password',
                          onPressed: _isLoading ? null : _handleSendReset,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 18),
                        const AuthDivider(label: 'or'),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: widget.onBackToLogin,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFD1FAE5),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: AuthVisuals.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Back to Login Page',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_sent)
                          Text(
                            'If sent, check your inbox and spam folder.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AuthVisuals.subtleText),
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
