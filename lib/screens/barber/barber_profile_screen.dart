import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';

class BarberProfileScreen extends StatelessWidget {
  const BarberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
          backgroundColor: AppTheme.background,
          body: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    final firestore = FirestoreService();
    final shopIdFuture = (user.barbershopId?.trim().isNotEmpty == true)
        ? Future.value(user.barbershopId!.trim())
        : firestore.getBarbershopIdByOwner(user.id);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: shopIdFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final resolvedShopId = snap.data;
            if (resolvedShopId == null || resolvedShopId.isEmpty) {
              return const Center(child: Text('Barbearia não encontrada.'));
            }

            return StreamBuilder<BarbershopModel?>(
              stream: firestore.streamBarbershop(resolvedShopId),
              builder: (context, shopSnap) {
                final shop = shopSnap.data;
                if (shopSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary));
                }
                if (shop == null) {
                  return const Center(child: Text('Barbearia não encontrada.'));
                }
                return _ProfileBody(
                    shop: shop, firestore: firestore, user: user);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final BarbershopModel shop;
  final FirestoreService firestore;
  final UserModel user;
  const _ProfileBody(
      {required this.shop, required this.firestore, required this.user});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return LoadingOverlay(
      isLoading: _isUploading,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estabelecimento',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(shop.name,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.8)),
            ]),
          ),

          // Cover photo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShopCoverImage(
              imageUrl:
                  shop.coverUrl != null && shop.coverUrl!.trim().isNotEmpty
                      ? shop.coverUrl
                      : null,
              height: 160,
              borderRadius: BorderRadius.circular(16),
              overlayChild: Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _pickCover(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 16, color: AppTheme.textPrimary),
                        SizedBox(width: 4),
                        Text('Editar foto',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _pickCover(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Alterar foto da barbearia'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              // Name/subtitle
              GestureDetector(
                onTap: () => _editInfoSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(shop.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          Text(shop.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ])),
                    const Icon(Icons.edit_outlined,
                        color: AppTheme.textSecondary, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Endereço',
                  value: shop.address.isEmpty ? 'Não informado' : shop.address),
              const SizedBox(height: 10),
              InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: shop.phone.isEmpty ? 'Não informado' : shop.phone),
              const SizedBox(height: 20),

              // Hours header
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Horário de funcionamento',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                TextButton.icon(
                  onPressed: () => _editHoursSheet(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ]),
              const SizedBox(height: 12),

              // Hours list
              Container(
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border)),
                child: Column(children: () {
                  final hourKeys = shop.hours.keys.toList();
                  if (hourKeys.isEmpty) {
                    return [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text('Horário não informado',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textSecondary)),
                      ),
                    ];
                  }
                  return hourKeys.map((key) {
                    final isLast = key == hourKeys.last;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(key,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary)),
                              Text(shop.hours[key] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary)),
                            ]),
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: AppTheme.border),
                    ]);
                  }).toList();
                }()),
              ),
              const SizedBox(height: 20),

              // Sign out
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sair da conta'),
                      content: const Text('Deseja realmente sair?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              minimumSize: const Size(0, 36)),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().signOut();
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  backgroundColor: const Color(0xFFFFF3F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sair da conta'),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context) async {
    final picker = ImagePicker();

    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir a galeria. '
              'Verifique as permissões do app nas configurações do celular.\n'
              'Detalhe: $e',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      return;
    }

    if (picked == null) return; // usuário cancelou

    final imageFile = File(picked.path);
    if (!imageFile.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo de imagem não encontrado.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final url = await widget.firestore
          .uploadBarbershopCover(widget.shop.id, imageFile);

      if (context.mounted) {
        if (url != null && url.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto da barbearia atualizada com sucesso!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upload concluído, mas não foi possível obter a URL da imagem. '
                'Verifique as regras do Firebase Storage.',
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Mensagem mais clara para erros comuns do Firebase Storage
        final msg = e.toString();
        String friendlyMessage;
        if (msg.contains('unauthorized') || msg.contains('permission-denied') || msg.contains('403')) {
          friendlyMessage =
              'Sem permissão para enviar a imagem. Verifique as regras do Firebase Storage no console do Firebase.';
        } else if (msg.contains('network') || msg.contains('connection')) {
          friendlyMessage = 'Sem conexão com a internet. Tente novamente.';
        } else {
          friendlyMessage = 'Erro ao enviar foto: $msg';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _editInfoSheet(BuildContext context) {
    final shop = widget.shop;
    final firestore = widget.firestore;
    final nameCtrl = TextEditingController(text: shop.name);
    final subCtrl = TextEditingController(text: shop.subtitle);
    final addressCtrl = TextEditingController(text: shop.address);
    final phoneCtrl = TextEditingController(text: shop.phone);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editar informações',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nome da barbearia')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: subCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Descrição curta')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Endereço completo')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: 'Telefone')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSt(() => saving = true);
                              final updated = BarbershopModel(
                                id: shop.id,
                                ownerId: shop.ownerId,
                                name: nameCtrl.text.trim(),
                                subtitle: subCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                rating: shop.rating,
                                ratingCount: shop.ratingCount,
                                coverUrl: shop.coverUrl,
                                lat: shop.lat,
                                lng: shop.lng,
                                hours: shop.hours,
                              );
                              await firestore.updateBarbershop(updated);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar alterações'),
                    ),
                    const SizedBox(height: 8),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  void _editHoursSheet(BuildContext context) {
    final shop = widget.shop;
    final hourKeys = shop.hours.keys.toList();
    final controllers = hourKeys
        .map((key) => TextEditingController(text: shop.hours[key] ?? ''))
        .toList();
    final closed = hourKeys
        .map((key) =>
            (shop.hours[key]?.toLowerCase().contains('fechado') ?? false))
        .toList();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Editar horários',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  ...List.generate(hourKeys.length, (index) {
                    final key = hourKeys[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(key,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                              Row(children: [
                                const Text('Fechado',
                                    style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 8),
                                Switch(
                                  value: closed[index],
                                  activeColor: AppTheme.primary,
                                  onChanged: (value) {
                                    setSt(() {
                                      closed[index] = value;
                                      if (value) {
                                        controllers[index].text = '';
                                      }
                                    });
                                  },
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: controllers[index],
                            readOnly: closed[index],
                            decoration: InputDecoration(
                              labelText: closed[index] ? 'Fechado' : 'Horário',
                              hintText:
                                  closed[index] ? null : 'Ex: 09:00 – 19:00',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSt(() => saving = true);
                            final updatedHours = <String, String>{};
                            for (var i = 0; i < hourKeys.length; i++) {
                              updatedHours[hourKeys[i]] = closed[i]
                                  ? 'Fechado'
                                  : controllers[i].text.trim();
                            }
                            final updated = BarbershopModel(
                              id: shop.id,
                              ownerId: shop.ownerId,
                              name: shop.name,
                              subtitle: shop.subtitle,
                              address: shop.address,
                              phone: shop.phone,
                              rating: shop.rating,
                              ratingCount: shop.ratingCount,
                              coverUrl: shop.coverUrl,
                              lat: shop.lat,
                              lng: shop.lng,
                              hours: updatedHours,
                            );
                            await widget.firestore.updateBarbershop(updated);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar alterações'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
