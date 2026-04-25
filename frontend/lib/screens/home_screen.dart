import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../services/api_service.dart';
import '../widgets/animal_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabController;

  // ── Animaux ─────────────────────────────────────────────────────────────────
  List<Animal> _animals  = [];
  List<Animal> _filtered = [];
  bool    _isLoadingAnimals = true;
  String? _animalsError;
  String  _searchQuery   = '';
  String  _selectedType  = 'Tous';
  final List<String> _types = ['Tous', 'Chien', 'Chat'];

  // ── Mes adoptions ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _myAdoptions     = [];
  bool    _isLoadingAdoptions = true;
  String? _adoptionsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadMyAdoptions();
      }
    });
    _loadAnimals();
    _loadMyAdoptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool _isDogOrCat(String type) {
    final t = type.toLowerCase();
    return t == 'dog' || t == 'cat' || t == 'chien' || t == 'chat';
  }

  /// Même mapping race → asset que AnimalCard
  String _imagePathForBreed(String breed, String type) {
    switch (breed.toLowerCase()) {
      case 'german shepherd': return 'assets/images/german_shepherd.jpg';
      case 'labrador':        return 'assets/images/labrador.jpg';
      case 'bulldog':         return 'assets/images/bulldog.jpg';
      case 'poodle':          return 'assets/images/poodle.jpg';
      case 'boxer':           return 'assets/images/boxer.jpg';
      case 'kokoni':          return 'assets/images/kokoni.jpg';
      case 'siamese':         return 'assets/images/siamese.jpg';
      case 'persian':         return 'assets/images/persian.jpg';
      case 'maine coon':      return 'assets/images/maine_coon.jpg';
      case 'bengal':          return 'assets/images/bengal.jpg';
      default:
        final t = type.toLowerCase();
        if (t == 'dog' || t == 'chien') return 'assets/images/labrador.jpg';
        return 'assets/images/persian.jpg';
    }
  }

  // ── Chargement ───────────────────────────────────────────────────────────────

  /// Redirige vers le login si le token est expiré
  void _handleTokenExpired() async {
    await ApiService.clearToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Session expirée, veuillez vous reconnecter.'),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
    );
  }

  Future<void> _loadAnimals() async {
    setState(() { _isLoadingAnimals = true; _animalsError = null; });
    try {
      final all = await ApiService.getAnimals();
      setState(() {
        _animals = all.where((a) => _isDogOrCat(a.type)).toList();
        _applyFilters();
        _isLoadingAnimals = false;
      });
    } catch (e) {
      if (e.toString().contains('TOKEN_EXPIRED')) { _handleTokenExpired(); return; }
      setState(() { _animalsError = e.toString().replaceFirst('Exception: ', ''); _isLoadingAnimals = false; });
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _animals.where((a) {
        final matchSearch = _searchQuery.isEmpty ||
            a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            a.breed.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchType = _selectedType == 'Tous' ||
            (_selectedType == 'Chien' && (a.type.toLowerCase() == 'dog' || a.type.toLowerCase() == 'chien')) ||
            (_selectedType == 'Chat'  && (a.type.toLowerCase() == 'cat' || a.type.toLowerCase() == 'chat'));
        return matchSearch && matchType;
      }).toList();
    });
  }

  Future<void> _loadMyAdoptions() async {
    setState(() { _isLoadingAdoptions = true; _adoptionsError = null; });
    try {
      final adoptions = await ApiService.getMyAdoptions();
      setState(() { _myAdoptions = adoptions; _isLoadingAdoptions = false; });
    } catch (e) {
      if (e.toString().contains('TOKEN_EXPIRED')) { _handleTokenExpired(); return; }
      setState(() { _adoptionsError = e.toString().replaceFirst('Exception: ', ''); _isLoadingAdoptions = false; });
    }
  }

  // ── Adopter ──────────────────────────────────────────────────────────────────

  Future<void> _adopt(Animal animal) async {
    final confirm = await _showConfirmDialog(
      title: "Confirmer l'adoption",
      content: 'Voulez-vous adopter ${animal.name} ?',
      confirmLabel: 'Adopter',
      confirmColor: const Color(0xFF2E7D32),
    );
    if (confirm != true) return;

    try {
      final result = await ApiService.adoptAnimal(animal.id);
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          final idx = _animals.indexWhere((a) => a.id == animal.id);
          if (idx != -1) {
            _animals[idx] = Animal(
              id: animal.id, name: animal.name, type: animal.type,
              breed: animal.breed, age: animal.age, gender: animal.gender,
              description: animal.description, status: 'adopted',
            );
            _applyFilters();
          }
        });
        _loadMyAdoptions();
        _showSnack('🎉 ${animal.name} est maintenant votre compagnon !', const Color(0xFF2E7D32));
      } else if (result['message'] == 'TOKEN_EXPIRED') {
        _handleTokenExpired();
      } else {
        _showSnack(result['message'] ?? "Erreur", Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur réseau : $e', Colors.red);
    }
  }

  // ── Annuler adoption ─────────────────────────────────────────────────────────

  Future<void> _cancelAdoption(Map<String, dynamic> adoption) async {
    final animalData = adoption['animal'] as Map<String, dynamic>?;
    final name      = animalData?['name'] ?? 'cet animal';
    final animalId  = adoption['animal_id'] as int;

    final confirm = await _showConfirmDialog(
      title: "Annuler l'adoption",
      content: 'Voulez-vous vraiment annuler l\'adoption de $name ?\nL\'animal redeviendra disponible.',
      confirmLabel: 'Annuler l\'adoption',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    try {
      final result = await ApiService.cancelAdoption(animalId);
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _myAdoptions.removeWhere((a) => a['animal_id'] == animalId);
        });
        setState(() {
          final idx = _animals.indexWhere((a) => a.id == animalId);
          if (idx != -1) {
            _animals[idx] = Animal(
              id: _animals[idx].id, name: _animals[idx].name, type: _animals[idx].type,
              breed: _animals[idx].breed, age: _animals[idx].age, gender: _animals[idx].gender,
              description: _animals[idx].description, status: 'available',
            );
            _applyFilters();
          }
        });
        _showSnack('✅ Adoption de $name annulée', Colors.orange.shade700);
      } else if (result['message'] == 'TOKEN_EXPIRED') {
        _handleTokenExpired();
      } else {
        _showSnack(result['message'] ?? "Erreur annulation", Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur réseau : $e', Colors.red);
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
    );
  }

  // ── Utilitaires UI ───────────────────────────────────────────────────────────

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Text('🐾', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('PetAdopt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { _loadAnimals(); _loadMyAdoptions(); }),
          IconButton(icon: const Icon(Icons.logout),  onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(icon: Icon(Icons.pets), text: 'Animaux'),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.favorite),
                if (_myAdoptions.isNotEmpty)
                  Positioned(
                    right: -6, top: -4,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: Center(child: Text('${_myAdoptions.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
              ]),
              text: 'Mes adoptions',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAnimalsTab(), _buildMyAdoptionsTab()],
      ),
    );
  }

  // ── Onglet Animaux ───────────────────────────────────────────────────────────

  Widget _buildAnimalsTab() {
    return Column(children: [
      Container(
        color: const Color(0xFF2E7D32),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(children: [
          TextField(
            onChanged: (v) { _searchQuery = v; _applyFilters(); },
            decoration: InputDecoration(
              hintText: 'Rechercher un animal...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _types.map((type) {
              final selected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _selectedType = type); _applyFilters(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white54,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: selected ? const Color(0xFF2E7D32) : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList()),
          ),
        ]),
      ),
      if (!_isLoadingAnimals && _animalsError == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            Text('${_filtered.length} animal${_filtered.length != 1 ? "aux" : ""} trouvé${_filtered.length != 1 ? "s" : ""}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ]),
        ),
      Expanded(
        child: _isLoadingAnimals
            ? const Center(child: CircularProgressIndicator())
            : _animalsError != null
                ? _buildError(_animalsError!, _loadAnimals)
                : _filtered.isEmpty
                    ? _buildEmpty('Aucun animal trouvé', 'Essayez de modifier vos filtres')
                    : RefreshIndicator(
                        onRefresh: _loadAnimals,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => AnimalCard(
                            animal: _filtered[i],
                            onAdopt: () => _adopt(_filtered[i]),
                          ),
                        ),
                      ),
      ),
    ]);
  }

  // ── Onglet Mes adoptions ─────────────────────────────────────────────────────

  Widget _buildMyAdoptionsTab() {
    if (_isLoadingAdoptions) return const Center(child: CircularProgressIndicator());
    if (_adoptionsError != null) return _buildError(_adoptionsError!, _loadMyAdoptions);
    if (_myAdoptions.isEmpty) {
      return _buildEmpty("Aucune adoption pour l'instant", "Adoptez un animal depuis l'onglet Animaux 🐾");
    }

    return RefreshIndicator(
      onRefresh: _loadMyAdoptions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _myAdoptions.length,
        itemBuilder: (_, i) => _buildAdoptionCard(_myAdoptions[i]),
      ),
    );
  }

  Widget _buildAdoptionCard(Map<String, dynamic> adoption) {
    final animalData  = adoption['animal'] as Map<String, dynamic>?;
    final name        = animalData?['name']        ?? 'Animal #${adoption['animal_id']}';
    final type        = animalData?['type']        ?? '';
    final breed       = animalData?['breed']       ?? '';
    final age         = animalData?['age'];
    final description = animalData?['description'] ?? '';

    final t = type.toLowerCase();

    // Emoji selon le type
    final String emoji = (t == 'dog' || t == 'chien')
        ? '🐕'
        : (t == 'cat' || t == 'chat')
            ? '🐈'
            : '🐾';

    // ── Même logique d'image que AnimalCard (asset local par race) ────────────
    final String imagePath = _imagePathForBreed(breed, type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70, height: 70,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8F5E9),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Adopté ✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              if (breed.isNotEmpty)
                Text(breed, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              if (age != null)
                Text('$age ${age == 1 ? "an" : "ans"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ])),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── Bouton Annuler l'adoption ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelAdoption(adoption),
              icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
              label: const Text("Annuler l'adoption",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Widgets utilitaires ───────────────────────────────────────────────────────

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('😕', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
      ]),
    ));
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔍', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ]),
    ));
  }
}