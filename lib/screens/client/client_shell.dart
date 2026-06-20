import 'package:flutter/material.dart';
import 'package:genbarber/widgets/shared_widgets.dart';
import 'package:genbarber/screens/client/client_home_screen.dart';
import 'package:genbarber/screens/client/client_appointments_screen.dart';
import 'package:genbarber/screens/client/client_profile_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  final _screens = const [ClientHomeScreen(), ClientAppointmentsScreen(), ClientProfileScreen()];
  final _navItems = const [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Início'),
    NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Agenda'),
    NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, items: _navItems, onTap: (i) => setState(() => _index = i)),
    );
  }
}
