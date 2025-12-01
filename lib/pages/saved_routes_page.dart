import 'package:flutter/material.dart';

class SavedRoutesPage extends StatelessWidget {
  const SavedRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> savedRoutes = <String>[
      // Add or fetch real saved routes later
      'Home to Library',
      'Lab A to Cafeteria',
      'Reception to Room 204',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        title: const Text(
          'Saved Routes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: savedRoutes.isEmpty
          ? const Center(
              child: Text(
                'No saved routes yet',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedRoutes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final routeName = savedRoutes[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.05 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.1 * 255).round()),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.route,
                      color: const Color(0xFF2563eb),
                    ),
                    title: Text(
                      routeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                    onTap: () {
                      // Placeholder for route details/navigation
                    },
                  ),
                );
              },
            ),
    );
  }
}


