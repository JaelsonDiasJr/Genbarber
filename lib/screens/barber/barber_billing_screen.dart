import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'barber_billing_month_details_screen.dart';

class BarberBillingScreen extends StatefulWidget {
  const BarberBillingScreen({super.key});
  @override
  State<BarberBillingScreen> createState() => _BarberBillingScreenState();
}

class _BarberBillingScreenState extends State<BarberBillingScreen> {
  bool _isMonth = true;
  // Cache to avoid flicker when stream briefly emits empty list
  double _cachedMonthTotal = 0.0;
  int _cachedMonthCount = 0;
  double _cachedYearTotal = 0.0;
  int _cachedYearCount = 0;
  // Cache for chart and detail data
  Map<String, double> _cachedChartData = {};
  List<String> _cachedChartLabels = [];
  Map<String, double> _cachedDetailTotalsMonth = {};
  Map<String, double> _cachedDetailTotalsYear = {};
  Map<String, List<AppointmentModel>> _cachedDetailItemsMonth = {};
  Map<String, List<AppointmentModel>> _cachedDetailItemsYear = {};

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
        child: StreamBuilder<List<AppointmentModel>>(
          stream: firestore.streamAllBarberAppointments(shopId),
          builder: (context, snap) {
            final all = snap.data ?? [];
            final confirmed = all.where((a) => a.status == AppointmentStatus.confirmed).toList();

            final now = DateTime.now();

            // Month totals and counts
            final thisMonth = confirmed.where((a) => a.dateTime.year == now.year && a.dateTime.month == now.month).toList();
            final lastMonth = confirmed.where((a) {
              final lm = DateTime(now.year, now.month - 1);
              return a.dateTime.year == lm.year && a.dateTime.month == lm.month;
            }).toList();
            final thisMonthTotal = thisMonth.fold(0.0, (s, a) => s + a.servicePrice);
            final lastMonthTotal = lastMonth.fold(0.0, (s, a) => s + a.servicePrice);
            final growthMonth = lastMonthTotal > 0 ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100) : 0.0;

            // Year totals and counts
            final thisYear = confirmed.where((a) => a.dateTime.year == now.year).toList();
            final lastYear = confirmed.where((a) => a.dateTime.year == now.year - 1).toList();
            final thisYearTotal = thisYear.fold(0.0, (s, a) => s + a.servicePrice);
            final lastYearTotal = lastYear.fold(0.0, (s, a) => s + a.servicePrice);
            final growthYear = lastYearTotal > 0 ? ((thisYearTotal - lastYearTotal) / lastYearTotal * 100) : 0.0;

            // Choose growth based on current toggle
            final growth = _isMonth ? growthMonth : growthYear;

            // Update caches only when we have confirmed items (avoid replacing cached non-zero with empty)
            if (thisMonth.isNotEmpty) {
              _cachedMonthTotal = thisMonthTotal;
              _cachedMonthCount = thisMonth.length;
            }
            if (thisYear.isNotEmpty) {
              _cachedYearTotal = thisYearTotal;
              _cachedYearCount = thisYear.length;
            }

            // Use cached values as fallback to prevent flicker
            final displayMonthTotal = thisMonth.isNotEmpty ? thisMonthTotal : _cachedMonthTotal;
            final displayMonthCount = thisMonth.isNotEmpty ? thisMonth.length : _cachedMonthCount;
            final displayYearTotal = thisYear.isNotEmpty ? thisYearTotal : _cachedYearTotal;
            final displayYearCount = thisYear.isNotEmpty ? thisYear.length : _cachedYearCount;

            // Summary value and label adapt to month/year and include count of confirmed cuts
            final summaryValue = _isMonth
                ? 'R\$ ${_fmt(displayMonthTotal)} · ${displayMonthCount} cortes'
                : 'R\$ ${_fmt(displayYearTotal)} · ${displayYearCount} cortes';
            final summaryLabel = _isMonth
                ? DateFormat('MMMM / yyyy', 'pt_BR').format(now)
                : now.year.toString();

            // Chart and detail data adapt to Month/Year toggle
            Map<String, double> chartData = {};
            List<String> chartLabels = [];

            if (_isMonth) {
              // Chart: months of current year
              final yearConfirmed = confirmed.where((a) => a.dateTime.year == now.year).toList();
              for (final apt in yearConfirmed) {
                final key = '${apt.dateTime.year}-${apt.dateTime.month.toString().padLeft(2, '0')}';
                chartData[key] = (chartData[key] ?? 0) + apt.servicePrice;
              }
              // labels: Jan..Dec for current year
              chartLabels = List.generate(12, (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}');

            } else {
              // Chart: totals per year (last 5 years incl. current)
              for (final apt in confirmed) {
                final key = apt.dateTime.year.toString();
                chartData[key] = (chartData[key] ?? 0) + apt.servicePrice;
              }
              final startYear = now.year - 4;
              chartLabels = List.generate(5, (i) => (startYear + i).toString());
            }

            // Detail totals: per month/year label or per year
            final Map<String, double> detailTotals = {};
            final Map<String, List<AppointmentModel>> detailItems = {};
            if (_isMonth) {
              for (final apt in confirmed) {
                final key = DateFormat('MMM / yyyy', 'pt_BR').format(apt.dateTime);
                detailTotals[key] = (detailTotals[key] ?? 0) + apt.servicePrice;
                detailItems[key] = (detailItems[key] ?? [])..add(apt);
              }
            } else {
              for (final apt in confirmed) {
                final key = apt.dateTime.year.toString();
                detailTotals[key] = (detailTotals[key] ?? 0) + apt.servicePrice;
                detailItems[key] = (detailItems[key] ?? [])..add(apt);
              }
            }

            // Update caches for chart and detail only when non-empty
            if (chartData.isNotEmpty) {
              _cachedChartData = Map<String, double>.from(chartData);
              _cachedChartLabels = List<String>.from(chartLabels);
            }
            if (detailTotals.isNotEmpty) {
              if (_isMonth) {
                _cachedDetailTotalsMonth = Map<String, double>.from(detailTotals);
                _cachedDetailItemsMonth = detailItems.map((k, v) => MapEntry(k, List<AppointmentModel>.from(v)));
              } else {
                _cachedDetailTotalsYear = Map<String, double>.from(detailTotals);
                _cachedDetailItemsYear = detailItems.map((k, v) => MapEntry(k, List<AppointmentModel>.from(v)));
              }
            }

            // Use cached values when current data is empty to avoid flicker
            final displayChartData = chartData.isNotEmpty ? chartData : _cachedChartData;
            final displayChartLabels = chartLabels.isNotEmpty ? chartLabels : _cachedChartLabels;
            final displayDetailTotals = detailTotals.isNotEmpty
                ? detailTotals
                : (_isMonth ? _cachedDetailTotalsMonth : _cachedDetailTotalsYear);
            final displayDetailItems = detailItems.isNotEmpty
              ? detailItems
              : (_isMonth ? _cachedDetailItemsMonth : _cachedDetailItemsYear);

            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Resumo financeiro', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const Text('Faturamento', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.8)),
                  const SizedBox(height: 20),

                  // Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [_tab('Mês', true), _tab('Ano', false)]),
                  ),
                  const SizedBox(height: 20),

                  // Summary cards
                  Row(children: [
                    Expanded(child: _SummaryCard(
                      icon: Icons.attach_money_rounded,
                      iconColor: AppTheme.primary,
                      value: summaryValue,
                      label: summaryLabel,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: growth >= 0 ? AppTheme.success : AppTheme.error,
                      value: '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(0)}%',
                      label: 'vs período anterior',
                      valueColor: growth >= 0 ? AppTheme.success : AppTheme.error,
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // Chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                        Text('Evolução mensal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 18),
                      ]),
                      const SizedBox(height: 20),
                      _BarChart(data: displayChartData, labels: displayChartLabels, isMonth: _isMonth),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  const Text('Detalhamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                ]),
              )),

              displayDetailTotals.isEmpty
                  ? const SliverToBoxAdapter(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Nenhum faturamento ainda.', style: TextStyle(color: AppTheme.textSecondary))),
                    ))
                  : SliverList(delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final key = displayDetailTotals.keys.toList().reversed.toList()[i];
                        final val = displayDetailTotals[key]!;
                        return InkWell(
                          onTap: () {
                            final items = displayDetailItems[key] ?? [];
                            if (items.isEmpty) return;
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => BarberBillingMonthDetailsScreen(title: key, items: items)));
                          },
                          child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(key, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                            Text('R\$ ${_fmt(val)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          ]),
                          ),
                        );
                      },
                      childCount: displayDetailTotals.length,
                    )),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ]);
          },
        ),
      ),
    );
  }

  Widget _tab(String label, bool isMonthVal) {
    final sel = _isMonth == isMonthVal;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _isMonth = isMonthVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textSecondary)),
      ),
    ));
  }

  String _fmt(double v) {
    if (v >= 1000) return NumberFormat('#,##0', 'pt_BR').format(v);
    return v.toInt().toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;
  const _SummaryCard({required this.icon, required this.iconColor, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor ?? AppTheme.textPrimary, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, double> data;
  final List<String> labels;
  final bool isMonth;
  const _BarChart({required this.data, required this.labels, required this.isMonth});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxVal = data.values.isEmpty ? 1.0 : data.values.reduce((a, b) => a > b ? a : b);

    if (isMonth) {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return Column(children: [
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (i) {
              final key = labels.length > i ? labels[i] : '${now.year}-${(i + 1).toString().padLeft(2, '0')}';
              final val = data[key] ?? 0;
              final ratio = maxVal > 0 ? val / maxVal : 0.0;
              final isCurrentMonth = (i + 1) == now.month;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: (80 * ratio).clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      color: isCurrentMonth ? AppTheme.primary : AppTheme.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]),
              ));
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: months.map((m) => Expanded(
          child: Text(m, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        )).toList()),
      ]);
    }

    // Year mode: labels contain year strings
    return Column(children: [
      SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (i) {
            final key = labels[i];
            final val = data[key] ?? 0;
            final ratio = maxVal > 0 ? val / maxVal : 0.0;
            final isCurrentYear = key == now.year.toString();
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: (80 * ratio).clamp(4.0, 80.0),
                  decoration: BoxDecoration(
                    color: isCurrentYear ? AppTheme.primary : AppTheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]),
            ));
          }),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: labels.map((l) => Expanded(
        child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      )).toList()),
    ]);
  }
}
