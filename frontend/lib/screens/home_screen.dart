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

class _HomeScreenState extends State<HomeScreen> {
  List<Animal> _animals = [];
  List<Animal> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedType = 'Tous';

  final List<String> _types = ['Tous', 'Chien', 'Chat', 'Lapin', 'Oiseau'];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final animals = await ApiService.getAnimals();
      setState(() {
        _animals = animals;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _animals.where((a) {
        final matchSearch = _searchQuery.isEmpty ||
            a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            a.breed.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchType = _selectedType == 'Tous' ||
            a.type.toLowerCase() ==
                _selectedType.toLowerCase().replaceAll('chien', 'dog').replaceAll('chat', 'cat').replaceAll('lapin', 'rabbit').replaceAll('oiseau', 'bird');
        return matchSearch && matchType;
      }).toList();
    });
  }

  Future<void> _adopt(Animal animal) async {
    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            const Text('Confirmer l\'adoption'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Voulez-vous adopter '),
              TextSpan(
                text: animal.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' ?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adopter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 10),
              Text('Traitement en cours...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final result = await ApiService.adoptAnimal(animal.id);
      if (!mounted) return;

      if (result['success'] == true) {
        // Update local status
        setState(() {
          final idx = _animals.indexWhere((a) => a.id == animal.id);
          if (idx != -1) {
            _animals[idx] = Animal(
              id: animal.id,
              name: animal.name,
              type: animal.type,
              breed: animal.breed,
              age: animal.age,
              gender: animal.gender,
              description: animal.description,
              status: 'adopted',
            );
            _applyFilters();
          }
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${animal.name} est maintenant votre compagnon !',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de l\'adoption'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('PetAdopt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnimals,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & filter bar ──────────────────────────────────────
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un animal...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((type) {
                      final selected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedType = type);
                            _applyFilters();
                          },
                          backgroundColor: Colors.white.withOpacity(0.3),
                          selectedColor: Colors.white,
                          checkmarkColor: const Color(0xFF2E7D32),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Animal count ─────────────────────────────────────────────
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} animal${_filtered.length != 1 ? 'aux' : ''} trouvé${_filtered.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
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
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAnimals,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text('Aucun animal trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Essayez de modifier vos filtres',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}