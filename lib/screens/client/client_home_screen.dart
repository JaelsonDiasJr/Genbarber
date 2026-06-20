import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';
import 'package:genbarber/screens/client/barbershop_detail_screen.dart';
import 'package:genbarber/screens/client/search_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});
  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _firestore = FirestoreService();
  final _mapController = MapController();
  Position? _position;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _moveMapToPosition(Position pos) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      } catch (_) {}
    });
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (!mounted || pos == null) return;
      setState(() => _position = pos);
      _moveMapToPosition(pos);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.name.split(' ').first ?? 'Olá';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<List<BarbershopModel>>(
          stream: _firestore.streamAllBarbershops(),
          builder: (context, snap) {
            final shops = snap.data ?? [];
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: AppTheme.primary.withOpacity(0.12),
                        backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                        child: user?.photoUrl == null
                            ? Text(firstName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Bem-vindo', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('Olá, $firstName! 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                      ]),
                    ]),
                    const SizedBox(height: 20),
                    // Search
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                        child: const Row(children: [
                          SizedBox(width: 14),
                          Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                          SizedBox(width: 10),
                          Text('Buscar barbearias ou serviços', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ]),
                      ),
                    ),
                  ]),
                )),

                // Map section header
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: SectionHeader(title: 'Barbearias próximas', actionLabel: 'Expandir', onAction: () {}),
                )),

                // Real Map
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _position != null
                              ? LatLng(_position!.latitude, _position!.longitude)
                              : const LatLng(-23.5505, -46.6333),
                          zoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.genbarber.app',
                          ),
                          MarkerLayer(markers: [
                            // User location
                            if (_position != null)
                              Marker(
                                point: LatLng(_position!.latitude, _position!.longitude),
                                width: 24, height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            // Barbershop markers
                            ...shops.map((shop) => Marker(
                              point: LatLng(shop.lat, shop.lng),
                              width: 36, height: 36,
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BarbershopDetailScreen(shop: shop))),
                                child: Container(
                                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8),
                                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]),
                                  child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                )),

                // Location label
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _position != null ? 'Sua localização' : 'São Paulo, SP',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text('${shops.length} barbearias próximas', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                )),

                // Barbershops section
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: SectionHeader(title: 'Estabelecimentos em destaque', actionLabel: 'Ver tudo', onAction: () {}),
                )),

                // Barbershop list
                snap.connectionState == ConnectionState.waiting
                    ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primary))))
                    : shops.isEmpty
                        ? SliverToBoxAdapter(child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: EmptyState(
                              icon: Icons.storefront_outlined,
                              title: 'Nenhuma barbearia cadastrada',
                              subtitle: 'As barbearias aparecerão aqui quando estiverem disponíveis.',
                            ),
                          ))
                        : SliverList(delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: BarbershopCard(
                                shop: shops[i],
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BarbershopDetailScreen(shop: shops[i]))),
                              ),
                            ),
                            childCount: shops.length,
                          )),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }
}
