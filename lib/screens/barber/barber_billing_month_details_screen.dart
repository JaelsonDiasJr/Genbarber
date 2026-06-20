import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';

class BarberBillingMonthDetailsScreen extends StatelessWidget {
  final String title;
  final List<AppointmentModel> items;
  const BarberBillingMonthDetailsScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      ),
      backgroundColor: AppTheme.background,
      body: items.isEmpty
          ? const Center(child: Text('Nenhum corte neste período.', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final apt = items[i];
                final dateStr = DateFormat('dd/MM/yyyy', 'pt_BR').format(apt.dateTime);
                final timeStr = DateFormat('HH:mm').format(apt.dateTime);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(apt.serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Text('${apt.clientName} · $dateStr  ·  $timeStr', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ])),
                    Text('R\$ ${apt.servicePrice.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ]),
                );
              },
            ),
    );
  }
}
