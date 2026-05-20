import 'package:flutter/material.dart';

import 'package:eco_wallet/features/auth/presentation/pages/login_page.dart';
import 'package:eco_wallet/features/auth/presentation/pages/register_page.dart';

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  var _showRegister = false;

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterPage(
        onBackToLogin: () => setState(() => _showRegister = false),
      );
    }
    return LoginPage(
      onCreateAccount: () => setState(() => _showRegister = true),
    );
  }
}
