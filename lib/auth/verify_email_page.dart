import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'auth_visuals.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.user});

  final User user;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
    });

    try {
      await AuthService.instance.resendVerificationEmail(widget.user);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = '인증 메일을 다시 보냈어요.';
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
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleCheckVerification() async {
    setState(() {
      _isChecking = true;
    });

    try {
      await widget.user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        return;
      }
      if (refreshedUser.emailVerified) {
        await AuthService.instance.markEmailVerified(refreshedUser);
        await AuthService.instance.ensureProfile(refreshedUser);
        if (!mounted) {
          return;
        }
        setState(() {
          _statusMessage = '인증이 완료됐어요. 잠시만 기다려주세요.';
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = '아직 인증이 확인되지 않았어요. 메일 링크를 눌렀는지 다시 확인해주세요.';
        });
      }
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
          _isChecking = false;
        });
      }
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthBrandMark(
                        title: 'WeBuyDivvy',
                        subtitle: 'Split grocery runs. Save more together.',
                        small: true,
                      ),
                      const SizedBox(height: 24),
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 56,
                        color: AuthVisuals.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이메일 인증이 필요해요',
                        textAlign: TextAlign.center,
                        style: AuthVisuals.titleStyle(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.user.email}로 보낸 인증 메일의 링크를 눌러주세요.\n인증이 끝나면 아래 버튼으로 확인할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: AuthVisuals.subtitleStyle(context),
                      ),
                      const SizedBox(height: 24),
                      AuthGradientButton(
                        label: '인증 완료 확인',
                        onPressed: _isChecking
                            ? null
                            : _handleCheckVerification,
                        isLoading: _isChecking,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isResending ? null : _handleResend,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AuthVisuals.cardBorder,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: AuthVisuals.text,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isResending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '인증 메일 다시 보내기',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          await AuthService.instance.signOut();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AuthVisuals.success,
                        ),
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AuthVisuals.subtleText),
                        ),
                      ],
                    ],
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
