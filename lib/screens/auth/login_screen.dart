import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 56),

              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),

              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Gen', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1)),
                TextSpan(text: 'Barber', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: AppTheme.primary, letterSpacing: -1)),
              ])),
              const SizedBox(height: 6),
              const Text('Bem-vindo de volta. Entre na sua conta.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // Erro
              if (auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFFCE8E6), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                ),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => auth.clearError(),
                decoration: const InputDecoration(
                  hintText: 'seu@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.textSecondary, size: 20),
                ),
                validator: (v) => (v != null && v.contains('@')) ? null : 'Email inválido',
              ),
              const SizedBox(height: 14),

              // Senha
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                onChanged: (_) => auth.clearError(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v != null && v.length >= 6) ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showPasswordReset(context),
                  child: const Text('Esqueci a senha', style: TextStyle(color: AppTheme.primary, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              // Botão entrar
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 32),

              // Cadastro
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Não tem uma conta? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Cadastre-se',
                    style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().loginWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  void _showPasswordReset(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar senha', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Digite seu email e enviaremos um link de recuperação.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'seu@email.com'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38)),
            onPressed: () async {
              if (ctrl.text.contains('@')) {
                await context.read<AuthProvider>().sendPasswordReset(ctrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Email de recuperação enviado!'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
