import 'package:flutter/material.dart';

import 'auth_service.dart';

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
    final validation = AuthService.instance.validateNickname(_nicknameController.text);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation)),
      );
      return;
    }

    setState(() {
      _isCheckingNickname = true;
    });

    try {
      final available = await AuthService.instance
          .isDisplayNameAvailable(_nicknameController.text);
      if (!mounted) {
        return;
      }
      final checkedNickname = _nicknameController.text.trim();
      setState(() {
        _nicknameChecked = true;
        _nicknameAvailable = available;
        _checkedNickname = checkedNickname;
        _nicknameStatusMessage = available
            ? '사용 가능한 닉네임이에요.'
            : '이미 사용 중인 닉네임이에요.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthMessage(error))),
      );
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
        const SnackBar(content: Text('닉네임 중복확인을 먼저 완료해주세요.')),
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
        preferredLocation:
            AuthService.instance.sanitizePreferredLocation(_preferredLocation),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthMessage(error))),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FFF9), Color(0xFFE1F6E8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '회원가입',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '가입은 @kaist.ac.kr 이메일 인증이 완료되어야 마무리돼요.',
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: '이메일',
                              hintText: 'name@kaist.ac.kr',
                              border: OutlineInputBorder(),
                            ),
                            validator: AuthService.instance.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              labelText: '닉네임',
                              border: OutlineInputBorder(),
                            ),
                            validator: AuthService.instance.validateNickname,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nicknameStatusMessage ??
                                      '닉네임 중복확인을 진행해주세요.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _nicknameStatusMessage == null
                                            ? Colors.grey
                                            : _nicknameAvailable
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _isCheckingNickname
                                      ? null
                                      : _checkNicknameAvailability,
                                  child: _isCheckingNickname
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('중복확인'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: '비밀번호',
                              border: const OutlineInputBorder(),
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
                                ),
                              ),
                            ),
                            validator: AuthService.instance.validatePassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: '비밀번호 확인',
                              border: const OutlineInputBorder(),
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
                                ),
                              ),
                            ),
                            validator: (value) =>
                                AuthService.instance.validatePasswordConfirmation(
                              value,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _preferredLocation,
                            decoration: const InputDecoration(
                              labelText: '선호 위치 (선택)',
                              border: OutlineInputBorder(),
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
                          const SizedBox(height: 12),
                          const Text(
                            '선호 위치는 지금 선택하지 않아도 되고, 가입 후 마이페이지에서 바꿀 수 있어요.',
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('이메일 인증 후 가입'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: widget.onBackToLogin,
                            child: const Text('로그인으로 돌아가기'),
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
      ),
    );
  }
}
