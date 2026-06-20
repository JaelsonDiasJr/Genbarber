import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isClient = true;
  bool _obscure = true;
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _streetCtrl      = TextEditingController();
  final _neighborhoodCtrl= TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _stateCtrl       = TextEditingController();
  final _zipCtrl         = TextEditingController();
  final _shopLatCtrl     = TextEditingController();
  final _shopLngCtrl     = TextEditingController();
  final _passCtrl        = TextEditingController();
  File? _shopPhoto;
  // map removed from UI; keep address location only
  LatLng? _addressLocation;
  bool _isSearchingAddress = false;
  Timer? _addressSearchDebounce;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _streetCtrl.dispose(); _neighborhoodCtrl.dispose();
    _cityCtrl.dispose(); _stateCtrl.dispose(); _zipCtrl.dispose();
    _shopLatCtrl.dispose(); _shopLngCtrl.dispose();
    _passCtrl.dispose();
    _addressSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _pickShopPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _shopPhoto = File(picked.path);
    });
  }

  void _scheduleAddressSearch() {
    _addressSearchDebounce?.cancel();
    _addressSearchDebounce = Timer(const Duration(milliseconds: 800), _searchAddress);
  }

  Future<void> _searchAddress() async {
    final queryParts = [
      _streetCtrl.text.trim(),
      _neighborhoodCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _stateCtrl.text.trim(),
      _zipCtrl.text.trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (queryParts.isEmpty) return;
    final query = queryParts.join(', ');

    setState(() => _isSearchingAddress = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${Uri.encodeQueryComponent(query)}');
      final response = await http.get(url, headers: {
        'User-Agent': 'GenBarberApp/1.0 (https://genbarber.example)',
        'Accept': 'application/json',
      });
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) return;
      final item = data.first as Map<String, dynamic>;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lng = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lng == null) return;

      _addressLocation = LatLng(lat, lng);
      _shopLatCtrl.text = lat.toStringAsFixed(6);
      _shopLngCtrl.text = lng.toStringAsFixed(6);
      // map removed: keep resolved address in `_addressLocation`
    } catch (_) {
      // ignore errors silently
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),

              // Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [_toggleBtn('Cliente', true), _toggleBtn('Barbeiro', false)]),
              ),
              const SizedBox(height: 24),

              if (_isClient)
                const Text('Crie sua conta de cliente e agende em qualquer barbearia.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
              else
                const Text('Cadastre sua barbearia e gerencie agendamentos.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // Error
              if (auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFFCE8E6), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                ),

              _field(
                _isClient ? 'Nome completo' : 'Nome do estabelecimento',
                _nameCtrl,
                Icons.person_outline_rounded,
                validator: (v) => v!.length > 2 ? null : 'Nome muito curto',
              ),
              const SizedBox(height: 14),
              _field('Email', _emailCtrl, Icons.mail_outline_rounded,
                  type: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Email inválido'),
              const SizedBox(height: 14),
              _field('Telefone', _phoneCtrl, Icons.phone_outlined,
                  type: TextInputType.phone,
                  validator: (v) => v!.length > 8 ? null : 'Telefone inválido'),
              const SizedBox(height: 14),
              if (!_isClient)
                Column(children: [
                  InkWell(
                    onTap: _pickShopPhoto,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.photo_camera_back_outlined, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _shopPhoto == null
                                  ? 'Foto da barbearia (obrigatória)'
                                  : 'Foto da barbearia selecionada',
                              style: TextStyle(
                                color: _shopPhoto == null ? AppTheme.textSecondary : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (_shopPhoto != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_shopPhoto!, height: 140, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _field('Rua e número', _streetCtrl, Icons.location_city_outlined,
                      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Endereço obrigatório'),
                  const SizedBox(height: 14),
                  _field('Bairro', _neighborhoodCtrl, Icons.location_pin,
                      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Bairro obrigatório'),
                  const SizedBox(height: 14),
                  _field('Cidade', _cityCtrl, Icons.location_city,
                      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Cidade obrigatória'),
                  const SizedBox(height: 14),
                  _field('Estado (UF)', _stateCtrl, Icons.map_outlined),
                  const SizedBox(height: 14),
                  _field('CEP', _zipCtrl, Icons.local_post_office,
                      type: TextInputType.number),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      // mini map removed by request; placeholder (height 0)
                      height: 0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Use a localização atual para preencher as coordenadas e marcar a barbearia no mapa.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _captureShopLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Usar localização atual'),
                    ),
                  ),
                  const SizedBox(height: 14),
                ]),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Senha (mínimo 6 caracteres)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v!.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isClient ? 'Criar conta de cliente' : 'Cadastrar barbearia'),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isClientVal) {
    final selected = _isClient == isClientVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isClient = isClientVal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, IconData icon,
      {TextInputType? type, String? Function(String?)? validator, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _reverseGeocodeLocation(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
      final response = await http.get(url, headers: {
        'User-Agent': 'GenBarberApp/1.0 (https://genbarber.example)',
        'Accept': 'application/json',
      });
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return;

      if (mounted) {
        setState(() {
          _streetCtrl.text = '${address['road'] ?? ''} ${address['house_number'] ?? ''}'.trim();
          _neighborhoodCtrl.text = address['suburb'] ?? address['neighborhood'] ?? '';
          _cityCtrl.text = address['city'] ?? address['town'] ?? '';
          _stateCtrl.text = address['state'] ?? '';
          _zipCtrl.text = address['postcode'] ?? '';
        });
      }
    } catch (_) {
      // Ignore errors silently
    }
  }

  Future<void> _captureShopLocation() async {
    final position = await _resolveCurrentPosition();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível capturar a localização atual.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _shopLatCtrl.text = position.latitude.toStringAsFixed(6);
      _shopLngCtrl.text = position.longitude.toStringAsFixed(6);
      _addressLocation = LatLng(position.latitude, position.longitude);
    });

    // Reverse geocode to fill address fields
    await _reverseGeocodeLocation(position.latitude, position.longitude);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isClient && _shopPhoto == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione uma foto da barbearia.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final auth = context.read<AuthProvider>();

    final shopAddress = !_isClient ? [
      _streetCtrl.text.trim(),
      _neighborhoodCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _stateCtrl.text.trim(),
      _zipCtrl.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ') : null;

    // If there's no resolved address location yet, try searching it now
    if (!_isClient && _addressLocation == null) {
      await _searchAddress();
    }

    // Prefer the resolved address location; fall back to any hidden lat/lng values
    final shopLat = !_isClient
        ? (_addressLocation?.latitude ?? double.tryParse(_shopLatCtrl.text.trim()))
        : null;
    final shopLng = !_isClient
        ? (_addressLocation?.longitude ?? double.tryParse(_shopLngCtrl.text.trim()))
        : null;

    if (!_isClient && (shopLat == null || shopLng == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível localizar a barbearia. Verifique o endereço ou use a localização atual.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final success = await auth.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _isClient ? UserRole.client : UserRole.barber,
      shopAddress: shopAddress,
      shopLat: shopLat,
      shopLng: shopLng,
      shopCoverFile: _shopPhoto,
    );

    if (!success) return;

    if (!_isClient) {
      await auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cadastro concluído. Faça login para continuar.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
