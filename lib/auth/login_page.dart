import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'auth_visuals.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSignUpRequested,
    required this.onForgotPasswordRequested,
  });

  final VoidCallback onSignUpRequested;
  final VoidCallback onForgotPasswordRequested;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
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
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _loginFieldDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return AuthVisuals.inputDecoration(
      labelText: labelText,
      hintText: hintText,
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
                        const _LoginHeader(),
                        const SizedBox(height: 28),
                        Text('로그인', style: AuthVisuals.titleStyle(context)),
                        const SizedBox(height: 8),
                        Text(
                          '이메일 인증이 완료된 KAIST 계정으로만 들어올 수 있어요.',
                          style: AuthVisuals.subtitleStyle(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'EMAIL',
                          style: AuthVisuals.sectionLabelStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _loginFieldDecoration(
                            labelText: '이메일',
                            hintText: 'name@kaist.ac.kr',
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: AuthService.instance.validateEmail,
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
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: _loginFieldDecoration(
                            labelText: '비밀번호',
                            hintText: '비밀번호를 입력하세요',
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
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: widget.onForgotPasswordRequested,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AuthGradientButton(
                          label: 'Log In',
                          onPressed: _isLoading ? null : _handleLogin,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 22),
                        const AuthDivider(label: 'or'),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 340;
                            final prompt = Text(
                              'New to WeBuyDivvy?',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AuthVisuals.label),
                              textAlign: TextAlign.center,
                            );
                            final action = TextButton(
                              onPressed: widget.onSignUpRequested,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: AuthVisuals.success,
                              ),
                              child: const Text(
                                'Create account →',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            );

                            if (isCompact) {
                              return Column(children: [prompt, action]);
                            }

                            return Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 2,
                              children: [prompt, action],
                            );
                          },
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AuthVisuals.primaryGradient,
          ),
          child: const Stack(
            children: [
              Positioned(left: 11, top: 11, child: _BrandDot(size: 7)),
              Positioned(right: 11, bottom: 11, child: _BrandDot(size: 7)),
              Positioned(
                left: 11,
                top: 10,
                right: 10,
                bottom: 10,
                child: _BrandSlash(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WeBuyDivvy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AuthVisuals.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Split grocery runs. Save more together.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AuthVisuals.subtleText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandDot extends StatelessWidget {
  const _BrandDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}

class _BrandSlash extends StatelessWidget {
  const _BrandSlash();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BrandSlashPainter());
  }
}

class _BrandSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.92),
      Offset(size.width * 0.95, size.height * 0.08),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
