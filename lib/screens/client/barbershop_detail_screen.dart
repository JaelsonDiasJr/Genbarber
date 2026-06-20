import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';

class BarbershopDetailScreen extends StatefulWidget {
  final BarbershopModel shop;
  const BarbershopDetailScreen({super.key, required this.shop});
  @override
  State<BarbershopDetailScreen> createState() => _BarbershopDetailScreenState();
}

class _BarbershopDetailScreenState extends State<BarbershopDetailScreen> {
  final _firestore = FirestoreService();
  ServiceModel? _selectedService;

  // Guarda a URL na inicialização para nunca perder referência durante rebuilds
  late final String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.shop.coverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: AppTheme.surface,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _coverUrl != null
                  ? Image.network(
                      _coverUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFD0D5DD)),
                    )
                  : Container(
                      color: const Color(0xFFD0D5DD),
                      child: const Icon(Icons.storefront_outlined, size: 64, color: AppTheme.textSecondary),
                    ),
            ),
          ),
        ],
        body: _DetailBody(
          shop: widget.shop,
          firestore: _firestore,
          selectedService: _selectedService,
          onServiceSelected: (svc) => setState(() => _selectedService = svc),
          onAgendar: () => _showBookingSheet(context),
        ),
      ),
      bottomNavigationBar: _selectedService == null
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => _showBookingSheet(context),
                  child: Text('Agendar ${_selectedService!.name}'),
                ),
              ),
            ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(shop: widget.shop, service: _selectedService!),
    );
  }
}

// ── Body separado para isolar rebuilds ─────────────────────────
class _DetailBody extends StatelessWidget {
  final BarbershopModel shop;
  final FirestoreService firestore;
  final ServiceModel? selectedService;
  final ValueChanged<ServiceModel?> onServiceSelected;
  final VoidCallback onAgendar;

  const _DetailBody({
    required this.shop,
    required this.firestore,
    required this.selectedService,
    required this.onServiceSelected,
    required this.onAgendar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info da barbearia
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shop.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(shop.subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ]),
              ),
              if (shop.rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBC04), size: 16),
                    const SizedBox(width: 4),
                    Text(shop.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
            ]),
            const SizedBox(height: 16),
            if (shop.address.isNotEmpty) _InfoRow(Icons.location_on_outlined, shop.address),
            if (shop.phone.isNotEmpty) ...[const SizedBox(height: 8), _InfoRow(Icons.phone_outlined, shop.phone)],
          ]),
        ),

        // Horários
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Horário de funcionamento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border)),
              child: Column(
                children: shop.hours.entries.map((e) {
                  final isLast = e.key == shop.hours.keys.last;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.key, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                        Text(e.value, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      ]),
                    ),
                    if (!isLast) const Divider(height: 1, color: AppTheme.border),
                  ]);
                }).toList(),
              ),
            ),
          ]),
        ),

        // Serviços
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Serviços disponíveis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ),

        StreamBuilder<List<ServiceModel>>(
          stream: firestore.streamServices(shop.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primary)));
            }
            final services = snap.data ?? [];
            if (services.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum serviço cadastrado ainda.',
                    style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
              );
            }
            return Column(
              children: services.map((svc) {
                final selected = selectedService?.id == svc.id;
                return GestureDetector(
                  onTap: () => onServiceSelected(selected ? null : svc),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withOpacity(0.06) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.content_cut_rounded,
                            color: selected ? Colors.white : AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(svc.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          Text('${svc.durationMinutes} min',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ]),
                      ),
                      Text('R\$ ${svc.price.toInt()}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 100),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      ]);
}

// ─── Booking Sheet ────────────────────────────────────────────
class _BookingSheet extends StatefulWidget {
  final BarbershopModel shop;
  final ServiceModel service;
  const _BookingSheet({required this.shop, required this.service});
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _firestore = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  int _selectedTime = -1;
  bool _loading = false;
  late DateTime _calendarMonth;

  final _times = ['09:00','09:30','10:00','10:30','11:00','11:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _calendarMonth = DateTime(today.year, today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Escolha data e hora',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.content_cut_rounded, color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Text(widget.service.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text('R\$ ${widget.service.price.toInt()} · ${widget.service.durationMinutes}min',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCalendar(),
              const SizedBox(height: 20),
              Text(
                DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(_selectedDate),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<AppointmentModel>>(
                stream: _firestore.streamBarberAppointments(widget.shop.id, _selectedDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: Padding(padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: AppTheme.primary)));
                  }
                  final appointments = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, childAspectRatio: 2.4, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: _times.length,
                    itemBuilder: (context, i) {
                      final sel = _selectedTime == i;
                      final parts = _times[i].split(':');
                      final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
                          int.parse(parts[0]), int.parse(parts[1]));
                      final isPast = dt.isBefore(DateTime.now());
                      final isBooked = appointments.any((apt) {
                        final valid = apt.status == AppointmentStatus.pending ||
                            apt.status == AppointmentStatus.confirmed ||
                            apt.status == AppointmentStatus.inProgress;
                        if (!valid) return false;
                        return apt.dateTime.year == dt.year &&
                            apt.dateTime.month == dt.month &&
                            apt.dateTime.day == dt.day &&
                            apt.dateTime.hour == dt.hour &&
                            apt.dateTime.minute == dt.minute;
                      });
                      final disabled = isPast || isBooked;
                      return GestureDetector(
                        onTap: disabled ? null : () => setState(() => _selectedTime = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: disabled ? AppTheme.border : sel ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: disabled ? AppTheme.border : sel ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Center(
                            child: Text(_times[i],
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500,
                                    color: disabled ? AppTheme.textSecondary : sel ? Colors.white : AppTheme.textPrimary)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _selectedTime >= 0 && !_loading ? _confirm : null,
              style: ElevatedButton.styleFrom(disabledBackgroundColor: AppTheme.border),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar agendamento'),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCalendar() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    final startWeekday = _calendarMonth.weekday % 7;
    final weekLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          onPressed: () => setState(() {
            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
          }),
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        Text(DateFormat("MMMM yyyy", 'pt_BR').format(_calendarMonth),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        IconButton(
          onPressed: () => setState(() {
            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
          }),
          icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: weekLabels.map((l) => Expanded(
        child: Center(child: Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
      )).toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 1, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: startWeekday + daysInMonth,
        itemBuilder: (context, index) {
          if (index < startWeekday) return const SizedBox.shrink();
          final day = index - startWeekday + 1;
          final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
          final isPast = date.isBefore(todayNorm);
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month && date.day == _selectedDate.day;
          final isToday = date.year == todayNorm.year &&
              date.month == todayNorm.month && date.day == todayNorm.day;

          return GestureDetector(
            onTap: isPast ? null : () => setState(() { _selectedDate = date; _selectedTime = -1; }),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : isToday ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('$day', style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? Colors.white : isPast ? AppTheme.textSecondary.withOpacity(0.4) : AppTheme.textPrimary,
              ))),
            ),
          );
        },
      ),
    ]);
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final parts = _times[_selectedTime].split(':');
      final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          int.parse(parts[0]), int.parse(parts[1]));

      await _firestore.createAppointment(AppointmentModel(
        id: const Uuid().v4(),
        clientId: user.id,
        clientName: user.name,
        clientEmail: user.email,
        clientPhone: user.phone,
        barbershopId: widget.shop.id,
        barbershopName: widget.shop.name,
        barbershopAddress: widget.shop.address,
        barbershopPhone: widget.shop.phone,
        serviceId: widget.service.id,
        serviceName: widget.service.name,
        servicePrice: widget.service.price,
        serviceDurationMinutes: widget.service.durationMinutes,
        dateTime: dt,
        status: AppointmentStatus.pending,
        barbershopCoverUrl: widget.shop.coverUrl,
      ));

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento enviado! Aguardando confirmação.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao agendar. Tente novamente.'), backgroundColor: AppTheme.error),
      );
    }
  }
}
