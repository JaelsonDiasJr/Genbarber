import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';

class BarberServicesScreen extends StatelessWidget {
  const BarberServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(backgroundColor: AppTheme.background, body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    final shopId = user.barbershopId ?? '';
    if (shopId.isEmpty) {
      return Scaffold(backgroundColor: AppTheme.background, body: const Center(child: Text('Barbearia não encontrada.')));
    }
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Catálogo', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('Serviços', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.8)),
              ]),
              GestureDetector(
                onTap: () => _showAddSheet(context, firestore, shopId),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ]),
          ),

          Expanded(child: StreamBuilder<List<ServiceModel>>(
            stream: firestore.streamServices(shopId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final services = snap.data ?? [];
              if (services.isEmpty) {
                return EmptyState(
                  icon: Icons.content_cut_outlined,
                  title: 'Nenhum serviço',
                  subtitle: 'Toque em + para adicionar seu primeiro serviço.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final svc = services[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.content_cut_rounded, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(svc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        Text('${svc.durationMinutes} min • R\$ ${svc.price.toInt()}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 18),
                        onPressed: () => _showEditSheet(context, firestore, svc),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Excluir serviço'),
                              content: Text('Excluir "${svc.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, minimumSize: const Size(0, 36)),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) await firestore.deleteService(svc.id);
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ]),
                  );
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showAddSheet(BuildContext context, FirestoreService firestore, String shopId) {
    _showServiceSheet(context, firestore, shopId, null);
  }

  void _showEditSheet(BuildContext context, FirestoreService firestore, ServiceModel svc) {
    _showServiceSheet(context, firestore, svc.barbershopId, svc);
  }

  void _showServiceSheet(BuildContext context, FirestoreService firestore, String shopId, ServiceModel? existing) {
    final nameCtrl     = TextEditingController(text: existing?.name ?? '');
    final priceCtrl    = TextEditingController(text: existing != null ? '${existing.price.toInt()}' : '');
    final durationCtrl = TextEditingController(text: existing != null ? '${existing.durationMinutes}' : '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(existing == null ? 'Novo serviço' : 'Editar serviço',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do serviço'),
                  validator: (v) => v!.isNotEmpty ? null : 'Obrigatório',
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                    validator: (v) => double.tryParse(v!) != null ? null : 'Inválido',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duração (min)'),
                    validator: (v) => int.tryParse(v!) != null ? null : 'Inválido',
                  )),
                ]),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setSt(() => saving = true);
                    final svc = ServiceModel(
                      id: existing?.id ?? '',
                      barbershopId: shopId,
                      name: nameCtrl.text.trim(),
                      price: double.parse(priceCtrl.text),
                      durationMinutes: int.parse(durationCtrl.text),
                    );
                    if (existing == null) {
                      await firestore.addService(svc);
                    } else {
                      await firestore.updateService(svc);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(existing == null ? 'Adicionar serviço' : 'Salvar alterações'),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
