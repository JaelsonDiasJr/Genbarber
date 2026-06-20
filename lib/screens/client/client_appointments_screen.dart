import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';

class ClientAppointmentsScreen extends StatefulWidget {
  const ClientAppointmentsScreen({super.key});
  @override
  State<ClientAppointmentsScreen> createState() =>
      _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen> {
  bool _upcoming = true;
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Agendamentos')),
      body: Column(children: [
        // Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              _tab('Próximos', true),
              _tab('Histórico', false),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
          stream: _firestore.streamClientAppointments(user.id),
          builder: (context, snap) {
            if (snap.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar agendamentos',
                subtitle: snap.error?.toString() ?? 'Tente novamente mais tarde.',
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }
            final all = snap.data ?? [];
            final now = DateTime.now();
            final filtered = _upcoming
                ? all
                    .where((a) =>
                        a.endDateTime.isAfter(now) &&
                        a.status != AppointmentStatus.cancelled)
                    .toList()
                : all
                    .where((a) =>
                        !a.endDateTime.isAfter(now) ||
                        a.status == AppointmentStatus.cancelled)
                    .toList();

            filtered.sort((a, b) => _upcoming
                ? a.dateTime.compareTo(b.dateTime)
                : b.dateTime.compareTo(a.dateTime));

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.calendar_today_outlined,
                title: _upcoming ? 'Sem agendamentos' : 'Sem histórico',
                subtitle: _upcoming
                    ? 'Agende em uma barbearia!'
                    : 'Seus atendimentos passados aparecerão aqui.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _AppointmentCard(
                  appointment: filtered[i],
                  firestore: _firestore,
                  showCancel: _upcoming),
            );
          },
        )),
      ]),
    );
  }

  Widget _tab(String label, bool isUpcoming) {
    final sel = _upcoming == isUpcoming;
    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _upcoming = isUpcoming),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppTheme.textSecondary)),
      ),
    ));
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final FirestoreService firestore;
  final bool showCancel;
  const _AppointmentCard({required this.appointment, required this.firestore, this.showCancel = true});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat("EEE, dd MMM", 'pt_BR').format(appointment.dateTime);
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: appointment.barbershopCoverUrl != null
                  ? Image.network(appointment.barbershopCoverUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder())
                  : _coverPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(appointment.barbershopName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis)),
                        StatusBadge(status: appointment.currentStatus),
                      ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.content_cut_rounded,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(appointment.serviceName,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  if (appointment.barbershopPhone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(appointment.barbershopPhone,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  if (appointment.barbershopAddress.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(appointment.barbershopAddress,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                ])),
          ]),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text('$dateStr  ·  $timeStr',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const Spacer(),
            Text(
                'R\$ ${appointment.servicePrice.toInt()} · ${appointment.serviceDurationMinutes} min',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ]),
        ),
        if (showCancel && (appointment.status == AppointmentStatus.pending ||
          appointment.status == AppointmentStatus.confirmed))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: OutlinedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Cancelar agendamento'),
                    content: const Text(
                        'Deseja realmente cancelar este agendamento?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Não')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            minimumSize: const Size(0, 36)),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true)
                  await firestore.cancelAppointment(appointment.id);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                backgroundColor: const Color(0xFFFFF3F3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Cancelar agendamento',
                        style: TextStyle(fontSize: 13)),
                  ]),
            ),
          ),

        // ── Review button for finished appointments ──
        if (appointment.currentStatus == AppointmentStatus.finished &&
            !appointment.reviewLeft)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ElevatedButton.icon(
              onPressed: () => _showReviewDialog(context),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Avaliar atendimento'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: const Color(0xFFFBBC04),
                foregroundColor: Colors.black87,
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        if (appointment.currentStatus == AppointmentStatus.finished &&
            appointment.reviewLeft)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Text('Avaliação enviada',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A))),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    double selectedRating = 5;
    final commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Como foi o atendimento?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('${appointment.barbershopName} · ${appointment.serviceName}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                // Stars
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedRating = starIndex.toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starIndex <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFBBC04),
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_ratingLabel(selectedRating),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Deixe um comentário (opcional)...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final review = ReviewModel(
                      id: '',
                      appointmentId: appointment.id,
                      clientId: appointment.clientId,
                      clientName: appointment.clientName,
                      barbershopId: appointment.barbershopId,
                      rating: selectedRating,
                      comment: commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    Navigator.pop(ctx);
                    await firestore.submitReview(review);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⭐ Avaliação enviada! Obrigado!'),
                          backgroundColor: Color(0xFF1A7A4A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Enviar avaliação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excelente! 🤩';
    if (r >= 4) return 'Muito bom! 😄';
    if (r >= 3) return 'Bom 🙂';
    if (r >= 2) return 'Regular 😐';
    return 'Ruim 😞';
  }

  Widget _coverPlaceholder() => Container(
      width: 52,
      height: 52,
      color: AppTheme.border,
      child: const Icon(Icons.storefront_outlined,
          color: AppTheme.textSecondary, size: 24));
}
