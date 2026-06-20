import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Meu perfil')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    final initials = user.name.trim().isEmpty
        ? '?'
        : user.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Meu perfil')),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 8),
          // Avatar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
            child: Column(children: [
              Stack(children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))
                      : null,
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppTheme.surface, width: 2)),
                  child: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                )),
              ]),
              const SizedBox(height: 12),
              Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(user.email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              if (user.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, color: AppTheme.primary, size: 14),
                    SizedBox(width: 4),
                    Text('Cliente Premium', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 24),

          _Section(title: 'CONTA', items: [
            _MenuItem(
              icon: Icons.edit_outlined,
              title: 'Editar perfil',
              subtitle: 'Nome, foto, contato',
              onTap: () => _showEditProfileSheet(context, user),
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              title: 'Sair da conta',
              subtitle: 'Fazer logout',
              textColor: AppTheme.error,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sair da conta'),
                    content: const Text('Deseja realmente sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
          child: Column(children: items.asMap().entries.map((e) {
            return Column(children: [
              e.value,
              if (e.key < items.length - 1) const Divider(height: 1, color: AppTheme.border, indent: 52),
            ]);
          }).toList()),
        ),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: (textColor ?? AppTheme.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: textColor ?? AppTheme.primary, size: 18),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor ?? AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
    );
  }
}

void _showEditProfileSheet(BuildContext context, UserModel user) {
  final nameCtrl = TextEditingController(text: user.name);
  final phoneCtrl = TextEditingController(text: user.phone);
  bool saving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: user.email),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preencha nome e telefone.'),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setSt(() => saving = true);
                          final success = await context.read<AuthProvider>().updateProfile(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              );
                          setSt(() => saving = false);
                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Perfil atualizado com sucesso!'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else if (context.mounted) {
                            final message = context.read<AuthProvider>().errorMessage ?? 'Erro ao atualizar perfil.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Salvar alterações'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
