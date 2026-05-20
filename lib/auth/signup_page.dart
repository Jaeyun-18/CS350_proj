import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'auth_visuals.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _preferredLocation = AuthService.preferredLocations.first;
  bool _isLoading = false;
  bool _isCheckingNickname = false;
  bool _nicknameChecked = false;
  bool _nicknameAvailable = false;
  String? _checkedNickname;
  String? _nicknameStatusMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_handleNicknameChanged);
  }

  void _handleNicknameChanged() {
    final currentNickname = _nicknameController.text.trim();
    if (_checkedNickname == currentNickname) {
      return;
    }

    if (!_nicknameChecked && _checkedNickname == null) {
      return;
    }

    setState(() {
      _nicknameChecked = false;
      _nicknameAvailable = false;
      _checkedNickname = null;
      _nicknameStatusMessage = null;
    });
  }

  Future<void> _checkNicknameAvailability() async {
    final validation = AuthService.instance.validateNickname(
      _nicknameController.text,
    );
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    setState(() {
      _isCheckingNickname = true;
    });

    try {
      final available = await AuthService.instance.isDisplayNameAvailable(
        _nicknameController.text,
      );
      if (!mounted) {
        return;
      }
      final checkedNickname = _nicknameController.text.trim();
      setState(() {
        _nicknameChecked = true;
        _nicknameAvailable = available;
        _checkedNickname = checkedNickname;
        _nicknameStatusMessage = available
            ? 'Nickname is available.'
            : 'This nickname is already taken.';
      });
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
          _isCheckingNickname = false;
        });
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentNickname = _nicknameController.text.trim();
    if (!_nicknameChecked ||
        !_nicknameAvailable ||
        _checkedNickname != currentNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check nickname availability first.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signUpWithEmail(
        email: _emailController.text,
        displayName: currentNickname,
        password: _passwordController.text,
        preferredLocation: AuthService.instance.sanitizePreferredLocation(
          _preferredLocation,
        ),
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
    _nicknameController.removeListener(_handleNicknameChanged);
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _signupFieldDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return AuthVisuals.inputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: Icon(icon, color: AuthVisuals.muted, size: 20),
      suffixIcon: suffixIcon,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        _SignupHeader(onBack: widget.onBackToLogin),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: AuthVisuals.titleStyle(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign-up completes after you click the verification link sent to your @kaist.ac.kr email.',
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
                          textInputAction: TextInputAction.next,
                          decoration: _signupFieldDecoration(
                            labelText: 'Email',
                            hintText: 'name@kaist.ac.kr',
                            icon: Icons.mail_outline_rounded,
                            helperText:
                                'A verification link will be sent after sign-up.',
                          ),
                          validator: AuthService.instance.validateEmail,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'NICKNAME',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nicknameController,
                          textInputAction: TextInputAction.next,
                          decoration: _signupFieldDecoration(
                            labelText: 'Nickname',
                            hintText: 'Enter the nickname you want to use',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: AuthService.instance.validateNickname,
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 380;
                            final message = Text(
                              _nicknameStatusMessage ??
                                  'Please check nickname availability.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _nicknameStatusMessage == null
                                        ? AuthVisuals.muted
                                        : _nicknameAvailable
                                        ? AuthVisuals.success
                                        : Colors.redAccent,
                                    height: 1.35,
                                  ),
                            );
                            final button = SizedBox(
                              height: 48,
                              width: isCompact ? double.infinity : null,
                              child: OutlinedButton(
                                onPressed: _isCheckingNickname
                                    ? null
                                    : _checkNicknameAvailability,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AuthVisuals.cardBorder,
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  foregroundColor: AuthVisuals.text,
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                ),
                                child: _isCheckingNickname
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AuthVisuals.success,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Check',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  message,
                                  const SizedBox(height: 10),
                                  button,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: message),
                                const SizedBox(width: 12),
                                button,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'PASSWORD',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _signupFieldDecoration(
                            labelText: 'Password',
                            hintText: 'At least 8 characters',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AuthVisuals.muted,
                              ),
                            ),
                          ),
                          validator: AuthService.instance.validatePassword,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'CONFIRM PASSWORD',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.next,
                          decoration: _signupFieldDecoration(
                            labelText: 'Confirm password',
                            hintText: 'Enter your password again',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AuthVisuals.muted,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              AuthService.instance.validatePasswordConfirmation(
                                value,
                                _passwordController.text,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'MY LOCATION',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _preferredLocation,
                          decoration: _signupFieldDecoration(
                            labelText: 'Preferred location (optional)',
                            hintText: 'You can choose later',
                            icon: Icons.location_on_outlined,
                          ),
                          items: AuthService.preferredLocations
                              .map(
                                (location) => DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _preferredLocation = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You can change your preferred location later in My Page.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AuthVisuals.muted,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 24),
                        AuthGradientButton(
                          label: 'Sign up & verify email',
                          onPressed: _isLoading ? null : _handleSignup,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: widget.onBackToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: AuthVisuals.success,
                            ),
                            child: const Text(
                              'Back to Log In',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
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

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuthVisuals.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AuthVisuals.success,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AuthVisuals.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join WeBuyDivvy with your KAIST email',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AuthVisuals.label,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
