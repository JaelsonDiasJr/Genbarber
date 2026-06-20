import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';

class BarberHomeScreen extends StatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  State<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends State<BarberHomeScreen>
    with WidgetsBindingObserver {
  late DateTime _today;
  late DateTime _dayStarted;
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = DateTime.now();
    _dayStarted = DateTime(_today.year, _today.month, _today.day);
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (today.isAfter(_dayStarted)) {
          setState(() {
            _today = now;
            _dayStarted = today;
          });
        }
        _startPeriodicRefresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _today = DateTime.now();
        _dayStarted = DateTime(_today.year, _today.month, _today.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
          backgroundColor: AppTheme.background,
          body: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    final shopId = user.barbershopId ?? '';
    if (shopId.isEmpty) {
      return Scaffold(
          backgroundColor: AppTheme.background,
          body: const Center(child: Text('Barbearia não encontrada.')));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<BarbershopModel?>(
          stream: _firestore.streamBarbershop(shopId),
          builder: (context, shopSnap) {
            final shop = shopSnap.data;
            return StreamBuilder<List<AppointmentModel>>(
              stream: _firestore.streamBarberAppointments(shopId, _today),
              builder: (context, aptSnap) {
                final apts = aptSnap.data ?? [];
                final confirmed = apts
                    .where((a) => a.status == AppointmentStatus.confirmed)
                    .toList();
                final revenue =
                    confirmed.fold(0.0, (sum, a) => sum + a.servicePrice);
                final upcoming = apts
                    .where((a) => a.dateTime.isAfter(_today))
                    .take(4)
                    .toList();

                return StreamBuilder<List<AppointmentModel>>(
                  stream: _firestore.streamMonthPendingAppointments(
                      shopId, _today),
                  builder: (context, pendingSnap) {
                    final pending = pendingSnap.data ?? [];

                    return CustomScrollView(slivers: [
                      // ── Header ──
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      const Text('Bem-vindo',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                      Text(shop?.name ?? 'Minha Barbearia',
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textPrimary,
                                              letterSpacing: -0.5)),
                                    ])),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primary,
                                  backgroundImage: user.photoUrl != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? const Icon(Icons.content_cut_rounded,
                                          color: Colors.white, size: 18)
                                      : null,
                                ),
                              ]),
                              const SizedBox(height: 20),

                              // ── Stats ──
                              Row(children: [
                                Expanded(
                                    child: StatCard(
                                        icon: Icons.calendar_today_rounded,
                                        value: '${apts.length}',
                                        label: 'Agendamentos hoje')),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: StatCard(
                                        icon: Icons.attach_money_rounded,
                                        value: 'R\$ ${revenue.toInt()}',
                                        label: 'Faturamento hoje',
                                        iconColor: AppColors.confirmed)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: StatCard(
                                        icon: Icons.people_outline_rounded,
                                        value: '${confirmed.length}',
                                        label: 'Clientes atendidos')),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: StatCard(
                                        icon: Icons.pending_outlined,
                                        value: '${pending.length}',
                                        label: 'Pendentes no mês',
                                        iconColor: AppColors.pending)),
                              ]),
                              const SizedBox(height: 28),
                            ]),
                      )),

                      // ── Seção: Pendências do mês ──
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Text('Aguardando confirmação',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.3)),
                                    Text(
                                        DateFormat("MMMM 'de' yyyy", 'pt_BR')
                                            .format(_today),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                  ])),
                              if (pending.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color:
                                          AppColors.pending.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Text('${pending.length}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pending)),
                                ),
                            ]),
                      )),

                      // Lista de pendências ou estado vazio
                      pending.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppTheme.border)),
                                child: const Row(children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      color: Color(0xFF16A34A), size: 22),
                                  SizedBox(width: 12),
                                  Text('Sem pendências este mês!',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                ]),
                              ),
                            ))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _PendingCard(
                                    apt: pending[i], firestore: _firestore),
                                childCount: pending.length,
                              ),
                            ),

                      // ── Seção: Próximos hoje ──
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: SectionHeader(
                            title: 'Próximos clientes hoje',
                            actionLabel: 'Ver agenda',
                            onAction: () {}),
                      )),

                      upcoming.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: EmptyState(
                                  icon: Icons.event_available_outlined,
                                  title: 'Sem agendamentos hoje',
                                  subtitle:
                                      'Os próximos clientes aparecerão aqui.'),
                            ))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final apt = upcoming[i];
                                  final timeStr =
                                      DateFormat('HH:mm').format(apt.dateTime);
                                  return Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppTheme.border)),
                                    child: Row(children: [
                                      Container(
                                        width: 50,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Center(
                                            child: Text(timeStr,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(apt.clientName,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.textPrimary)),
                                            Text(apt.serviceName,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme
                                                        .textSecondary)),
                                          ])),
                                      StatusBadge(status: apt.currentStatus),
                                      const SizedBox(width: 8),
                                      Text('R\$ ${apt.servicePrice.toInt()}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary)),
                                    ]),
                                  );
                                },
                                childCount: upcoming.length,
                              ),
                            ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ]);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

// ── Card de pendência com confirmação/recusa ───────────────────
class _PendingCard extends StatelessWidget {
  final AppointmentModel apt;
  final FirestoreService firestore;
  const _PendingCard({required this.apt, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("EEE, dd/MM", 'pt_BR').format(apt.dateTime);
    final timeStr = DateFormat('HH:mm').format(apt.dateTime);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pending.withOpacity(0.35)),
      ),
      child: Column(children: [
        // Faixa superior laranja
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.pending.withOpacity(0.08),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(Icons.schedule_rounded, size: 12, color: AppColors.pending),
            const SizedBox(width: 5),
            Text('Aguardando confirmação',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pending)),
            const Spacer(),
            Text('$dateStr  ·  $timeStr',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.pending)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.pending.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person_outline_rounded,
                  color: AppColors.pending, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(apt.clientName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                      '${apt.serviceName}  ·  R\$ ${apt.servicePrice.toInt()}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  if (apt.clientPhone.isNotEmpty)
                    Text(apt.clientPhone,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ])),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(
                child: ElevatedButton.icon(
              onPressed: () => firestore.updateAppointmentStatus(
                  apt.id, AppointmentStatus.confirmed),
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
                  apt.id, AppointmentStatus.cancelled),
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
      ]),
    );
  }
}
