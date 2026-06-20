import 'package:flutter/material.dart';
import 'package:genbarber/widgets/shared_widgets.dart';
import 'package:genbarber/screens/barber/barber_home_screen.dart';
import 'package:genbarber/screens/barber/barber_agenda_screen.dart';
import 'package:genbarber/screens/barber/barber_services_screen.dart';
import 'package:genbarber/screens/barber/barber_billing_screen.dart';
import 'package:genbarber/screens/barber/barber_profile_screen.dart';

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});
  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  int _index = 0;
  Key _billingKey = UniqueKey();
  late List<Widget> _screens;
  final _navItems = const [
    NavItem(icon: Icons.grid_view_outlined,     activeIcon: Icons.grid_view_rounded,      label: 'Início'),
    NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Agenda'),
    NavItem(icon: Icons.content_cut_outlined,   activeIcon: Icons.content_cut_rounded,    label: 'Serviços'),
    NavItem(icon: Icons.attach_money_outlined,  activeIcon: Icons.attach_money_rounded,   label: 'Faturamento'),
    NavItem(icon: Icons.settings_outlined,      activeIcon: Icons.settings_rounded,       label: 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const BarberHomeScreen(),
      const BarberAgendaScreen(),
      const BarberServicesScreen(),
      BarberBillingScreen(key: _billingKey),
      const BarberProfileScreen(),
    ];
  }

  void _onNavTap(int index) {
    if (index == _index && index == 3) {
      setState(() {
        _billingKey = UniqueKey();
        _screens[3] = BarberBillingScreen(key: _billingKey);
      });
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, items: _navItems, onTap: _onNavTap),
    );
  }
}
