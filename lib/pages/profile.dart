import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: "Alex Doe");
  String _voiceId = "Female";
  String _language = "English";
  String _navMode = "Both";

  final List<String> savedLocations = ["Home", "Work", "Grocery", "Doctor"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("User Info"),
          _card(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voiceId,
                  decoration: const InputDecoration(labelText: "Voice ID"),
                  items: ["Male", "Female", "System"]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _voiceId = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle("Preferences"),
          _card(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration:
                      const InputDecoration(labelText: "Preferred Language"),
                  items: ["English", "Urdu", "Bilingual"]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
                const SizedBox(height: 20),
                const Text("Preferred Navigation Mode",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: ["Voice-only", "Haptic-only", "Both"]
                      .map((m) => _navMode == m)
                      .toList(),
                  onPressed: (index) {
                    setState(() {
                      _navMode = ["Voice-only", "Haptic-only", "Both"][index];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).colorScheme.primary,
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Voice-only")),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Haptic-only")),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Both")),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle("Saved Locations"),
          _card(
            child: Column(
              children: [
                for (var loc in savedLocations)
                  ListTile(
                    title: Text(loc),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit), onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.delete), onPressed: () {}),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: const Text("Add Location"),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0d1b2a),
        selectedItemColor: const Color(0xFF2563eb),
        unselectedItemColor: Colors.white60,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/');
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: "Saved Routes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// ✅ Helper methods placed inside the class
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      color: const Color(0xFF1a2233),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
