import 'package:flutter/material.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/widgets/shared_widgets.dart';
import 'package:genbarber/screens/client/barbershop_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestore = FirestoreService();
  final _searchCtrl = TextEditingController();
  List<BarbershopModel> _allShops = [];
  List<BarbershopModel> _filteredShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filterShops);
    _loadShops();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filterShops);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    final shops = await _firestore.streamAllBarbershops().first;
    if (mounted) {
      setState(() {
        _allShops = shops;
        _filteredShops = []; // Start with empty list until user types
        _isLoading = false;
      });
    }
  }

  void _filterShops() {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredShops = []);
      return;
    }
    setState(() {
      _filteredShops = _allShops.where((shop) {
        final nameMatch = shop.name.toLowerCase().contains(query);
        final subtitleMatch = shop.subtitle.toLowerCase().contains(query);
        final addressMatch = shop.address.toLowerCase().contains(query);
        return nameMatch || subtitleMatch || addressMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: AppTheme.border,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar por nome ou endereço...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              onPressed: () => _searchCtrl.clear(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_searchCtrl.text.isEmpty) {
      return EmptyState(
        icon: Icons.search,
        title: 'Buscar barbearia',
        subtitle: 'Encontre estabelecimentos pelo nome ou endereço.',
      );
    }

    if (_filteredShops.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Nenhum resultado',
        subtitle: 'Não encontramos barbearias para "${_searchCtrl.text}".',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredShops.length,
      itemBuilder: (context, i) {
        final shop = _filteredShops[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BarbershopCard(
            shop: shop,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BarbershopDetailScreen(shop: shop))),
          ),
        );
      },
    );
  }
}