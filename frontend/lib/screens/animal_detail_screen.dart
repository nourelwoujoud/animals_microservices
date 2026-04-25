import 'package:flutter/material.dart';
import '../models/animal.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;
  final VoidCallback onAdopt;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
    required this.onAdopt,
  });

  // ── Même mapping que AnimalCard ──────────────────────────────────────────
  String get _imagePath {
    switch (animal.breed.toLowerCase()) {
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
        final t = animal.type.toLowerCase();
        if (t == 'dog' || t == 'chien') return 'assets/images/labrador.jpg';
        return 'assets/images/persian.jpg';
    }
  }

  Color get _statusColor =>
      animal.isAvailable ? const Color(0xFF2E7D32) : Colors.grey.shade600;

  // ── Ouvre la photo en plein écran avec zoom ──────────────────────────────
  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenPhoto(
          imagePath: _imagePath,
          animalName: animal.name,
          typeEmoji: animal.typeEmoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec grande photo cliquable ───────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openFullscreen(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo principale
                    Image.asset(
                      _imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8F5E9),
                        child: Center(
                          child: Text(animal.typeEmoji,
                              style: const TextStyle(fontSize: 80)),
                        ),
                      ),
                    ),

                    // Dégradé bas pour lisibilité
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Icône loupe — indique que c'est cliquable
                    Positioned(
                      bottom: 14, right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.white, size: 22),
                      ),
                    ),

                    // Badge statut
                    Positioned(
                      top: 12, right: 12,
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2))],
                          ),
                          child: Text(
                            animal.isAvailable ? 'Disponible' : 'Adopté',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Infos animal ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + genre
                  Row(children: [
                    Expanded(
                      child: Text(
                        animal.name,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(animal.genderIcon,
                        style: const TextStyle(fontSize: 26)),
                  ]),
                  const SizedBox(height: 10),

                  // Chips
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _chip(animal.breed),
                    _chip(animal.ageLabel),
                    _chip(animal.type),
                  ]),
                  const SizedBox(height: 24),

                  // Description
                  const Text('À propos',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    animal.description,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black54, height: 1.6),
                  ),
                  const SizedBox(height: 30),

                  // Bouton Adopter
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: animal.isAvailable
                          ? () {
                              onAdopt();
                              Navigator.pop(context);
                            }
                          : null,
                      icon: Icon(
                        animal.isAvailable
                            ? Icons.favorite_border
                            : Icons.favorite,
                        size: 20,
                      ),
                      label: Text(
                        animal.isAvailable ? 'Adopter' : 'Déjà adopté',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: animal.isAvailable
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Plein écran avec zoom ─────────────────────────────────────────────────────
class _FullscreenPhoto extends StatelessWidget {
  final String imagePath;
  final String animalName;
  final String typeEmoji;

  const _FullscreenPhoto({
    required this.imagePath,
    required this.animalName,
    required this.typeEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(animalName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Text(typeEmoji,
                  style: const TextStyle(fontSize: 100)),
            ),
          ),
        ),
      ),
    );
  }
}