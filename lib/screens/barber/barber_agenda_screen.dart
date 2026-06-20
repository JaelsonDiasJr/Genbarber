import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';

class BarberAgendaScreen extends StatefulWidget {
  const BarberAgendaScreen({super.key});
  @override
  State<BarberAgendaScreen> createState() => _BarberAgendaScreenState();
}

class _BarberAgendaScreenState extends State<BarberAgendaScreen> {
  final _firestore = FirestoreService();
  late DateTime _selectedDate;
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _calendarMonth = DateTime(today.year, today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    final shopId = user.barbershopId ?? '';
    if (shopId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Barbearia não encontrada.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header + Calendário ──
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Hoje, ${DateFormat("dd MMM", 'pt_BR').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Text(
                'Agenda',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.8),
              ),
              const SizedBox(height: 16),
              _buildCalendar(shopId),
            ]),
          ),

          // ── Data selecionada label ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(_selectedDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),

          // ── Lista de agendamentos ──
          Expanded(child: StreamBuilder<List<AppointmentModel>>(
            stream: _firestore.streamBarberAppointments(shopId, _selectedDate),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Erro ao carregar agendamentos: ${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
                );
              }
              final apts = snap.data ?? [];
              if (apts.isEmpty) {
                return EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Sem agendamentos',
                  subtitle: 'Nenhum agendamento para este dia.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: apts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _AgendaCard(appointment: apts[i], firestore: _firestore),
              );
            },
          )),
        ]),
      ),
    );
  }

  Widget _buildCalendar(String shopId) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final firstDay = _calendarMonth;
    final daysInMonth = DateUtils.getDaysInMonth(firstDay.year, firstDay.month);
    final startWeekday = firstDay.weekday % 7; // 0=Dom
    final weekLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Column(children: [
      // Navegação mês
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          onPressed: () => setState(() {
            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
          }),
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          DateFormat("MMMM yyyy", 'pt_BR').format(_calendarMonth),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        IconButton(
          onPressed: () => setState(() {
            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
          }),
          icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
      const SizedBox(height: 8),

      // Cabeçalho dias da semana
      Row(children: weekLabels.map((l) => Expanded(
        child: Center(child: Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
      )).toList()),
      const SizedBox(height: 6),

      // Grade de dias — com indicador de agendamentos via StreamBuilder
      StreamBuilder<List<AppointmentModel>>(
        stream: _firestore.streamBarberAppointmentsForMonth(shopId, _calendarMonth),
        builder: (context, monthSnap) {
          final monthApts = monthSnap.data ?? [];

          // Agrupa os dias que têm agendamentos
          final daysWithApts = <int>{};
          for (final apt in monthApts) {
            if (apt.status == AppointmentStatus.pending ||
                apt.status == AppointmentStatus.confirmed ||
                apt.status == AppointmentStatus.inProgress) {
              if (apt.dateTime.year == _calendarMonth.year &&
                  apt.dateTime.month == _calendarMonth.month) {
                daysWithApts.add(apt.dateTime.day);
              }
            }
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                                 date.month == _selectedDate.month &&
                                 date.day == _selectedDate.day;
              final isToday = date.year == todayNorm.year &&
                              date.month == todayNorm.month &&
                              date.day == todayNorm.day;
              final hasApts = daysWithApts.contains(day);

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                }),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : isToday
                                ? AppTheme.primary.withOpacity(0.12)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      )),
                    ),
                    // Indicador de agendamentos
                    if (hasApts && !isSelected)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ]);
  }
}

class _AgendaCard extends StatelessWidget {
  final AppointmentModel appointment;
  final FirestoreService firestore;
  const _AgendaCard({required this.appointment, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);
    final rawStatus = appointment.status;
    final computed = appointment.currentStatus;
    final isPending = rawStatus == AppointmentStatus.pending;
    final isInProgress = computed == AppointmentStatus.inProgress;
    final isFinished = rawStatus == AppointmentStatus.finished;

    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isInProgress
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.border)),
      child: Column(children: [
        if (isInProgress)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radio_button_checked, size: 10, color: AppTheme.primary),
                SizedBox(width: 6),
                Text('Em andamento',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$timeStr — ${appointment.clientName}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              if (appointment.clientPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(appointment.clientPhone,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              const SizedBox(height: 4),
              Text(appointment.serviceName,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(
                  'R\$ ${appointment.servicePrice.toInt()} · ${appointment.serviceDurationMinutes} min',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ])),
            StatusBadge(status: computed),
          ]),
        ),

        // ── Pending: Confirm / Refuse ──
        if (isPending)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () => firestore.updateAppointmentStatus(
                    appointment.id, AppointmentStatus.confirmed),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Confirmar'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    textStyle: const TextStyle(fontSize: 13)),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () => firestore.updateAppointmentStatus(
                    appointment.id, AppointmentStatus.cancelled),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Recusar'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                    textStyle: const TextStyle(fontSize: 13)),
              )),
            ]),
          ),

        // ── In Progress: Finish button ──
        if (isInProgress && !isFinished && !isPending)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ElevatedButton.icon(
              onPressed: () => _confirmFinish(context),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Finalizar Corte'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: const Color(0xFF1A7A4A),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finalizar atendimento?'),
        content: Text('Confirmar que o corte de ${appointment.clientName} foi concluído?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7A4A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await firestore.finishAppointment(appointment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Atendimento finalizado!'),
            backgroundColor: Color(0xFF1A7A4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
