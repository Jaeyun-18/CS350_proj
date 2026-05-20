import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main_page.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'reset_password_page.dart';
import 'signup_page.dart';
import 'verify_email_page.dart';

enum AuthFlowPage { login, signUp, resetPassword }

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const _AuthLoadingScaffold(
            message: 'Checking authentication...',
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const _LoggedOutFlow();
        }

        if (!AuthService.instance.isKaistEmail(user.email ?? '')) {
          return _RestrictedAccountView(email: user.email ?? 'Unknown email');
        }

        if (!user.emailVerified) {
          return VerifyEmailPage(user: user);
        }

        return MainPage(user: user);
      },
    );
  }
}

class _LoggedOutFlow extends StatefulWidget {
  const _LoggedOutFlow();

  @override
  State<_LoggedOutFlow> createState() => _LoggedOutFlowState();
}

class _LoggedOutFlowState extends State<_LoggedOutFlow> {
  AuthFlowPage _page = AuthFlowPage.login;

  @override
  Widget build(BuildContext context) {
    switch (_page) {
      case AuthFlowPage.login:
        return LoginPage(
          onSignUpRequested: () => setState(() {
            _page = AuthFlowPage.signUp;
          }),
          onForgotPasswordRequested: () => setState(() {
            _page = AuthFlowPage.resetPassword;
          }),
        );
      case AuthFlowPage.signUp:
        return SignupPage(
          onBackToLogin: () => setState(() {
            _page = AuthFlowPage.login;
          }),
        );
      case AuthFlowPage.resetPassword:
        return ResetPasswordPage(
          onBackToLogin: () => setState(() {
            _page = AuthFlowPage.login;
          }),
        );
    }
  }
}

class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FFF8), Color(0xFFE7F6EB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestrictedAccountView extends StatelessWidget {
  const _RestrictedAccountView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FFF8), Color(0xFFE7F6EB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_outline, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Account not allowed',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Only @kaist.ac.kr accounts can use this app.\n\nCurrent account: $email',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () async {
                            await AuthService.instance.signOut();
                          },
                          child: const Text('Log Out'),
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
