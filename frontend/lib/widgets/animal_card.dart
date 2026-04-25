import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../screens/animal_detail_screen.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onAdopt;

  const AnimalCard({
    super.key,
    required this.animal,
    required this.onAdopt,
  });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnimalDetailScreen(
            animal: animal,
            onAdopt: onAdopt,
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Image.asset(
                      _imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 200,
                        color: const Color(0xFFE8F5E9),
                        child: Center(
                          child: Text(animal.typeEmoji,
                              style: const TextStyle(fontSize: 72)),
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge statut
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // Icône zoom bas gauche
                Positioned(
                  bottom: 10, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text('Agrandir',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Contenu ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(animal.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Text(animal.genderIcon,
                        style: const TextStyle(fontSize: 20)),
                  ]),
                  const SizedBox(height: 8),

                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _chip(animal.breed),
                    _chip(animal.ageLabel),
                  ]),
                  const SizedBox(height: 10),

                  Text(
                    animal.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: animal.isAvailable ? onAdopt : null,
                      icon: Icon(
                        animal.isAvailable
                            ? Icons.favorite_border
                            : Icons.favorite,
                        size: 18,
                      ),
                      label: Text(
                        animal.isAvailable ? 'Adopter' : 'Déjà adopté',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: animal.isAvailable
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600)),
    );
  }
}