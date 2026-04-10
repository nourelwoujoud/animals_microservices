import 'package:flutter/material.dart';
import '../models/animal.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback onAdopt;

  const AnimalCard({
    super.key,
    required this.animal,
    required this.onAdopt,
  });

  Color _statusColor(bool available) =>
      available ? const Color(0xFF2E7D32) : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image placeholder ──────────────────────────────────────────
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E7D32).withOpacity(0.15),
                      const Color(0xFF81C784).withOpacity(0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    animal.typeEmoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(animal.isAvailable),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    animal.isAvailable ? 'Disponible' : 'Adopté',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // ── Content ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + gender
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        animal.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      animal.genderIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Breed · age
                Row(
                  children: [
                    _chip(context, animal.breed),
                    const SizedBox(width: 8),
                    _chip(context, animal.ageLabel),
                  ],
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  animal.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Adopt button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: animal.isAvailable ? onAdopt : null,
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: Text(
                      animal.isAvailable ? 'Adopter' : 'Déjà adopté',
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: animal.isAvailable
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}