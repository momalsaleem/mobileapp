import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
	const SettingsPage({super.key});

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
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
			body: ListView(
				padding: const EdgeInsets.all(16),
				children: [
					// Guide: Make all cards clickable for navigation or actions
					_settingsCard(
						icon: Icons.person,
						title: 'Account',
						subtitle: 'Manage your account settings',
						onTap: () {
							// TODO: Navigate to account settings
						},
					),
					_settingsCard(
						icon: Icons.lock,
						title: 'Privacy',
						subtitle: 'Privacy and security options',
						onTap: () {
							// TODO: Navigate to privacy settings
						},
					),
					_settingsCard(
						icon: Icons.notifications,
						title: 'Notifications',
						subtitle: 'Notification preferences',
						onTap: () {
							// TODO: Navigate to notification settings
						},
					),
					_settingsCard(
						icon: Icons.info,
						title: 'About',
						subtitle: 'App information',
						onTap: () {
							// TODO: Show about dialog
						},
					),
				],
			),
		);
	}

	Widget _settingsCard({
		required IconData icon,
		required String title,
		required String subtitle,
		required VoidCallback onTap,
	}) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(12),
			child: Container(
				margin: const EdgeInsets.only(bottom: 16),
				padding: const EdgeInsets.all(16),
				decoration: BoxDecoration(
					color: Colors.white.withOpacity(0.05),
					borderRadius: BorderRadius.circular(12),
				),
				child: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: const Color(0xFF2563eb).withOpacity(0.25),
								shape: BoxShape.circle,
							),
							child: Icon(icon, color: const Color(0xFF2563eb)),
						),
						const SizedBox(width: 16),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: const TextStyle(
											fontWeight: FontWeight.bold,
											fontSize: 18,
											color: Colors.white,
										),
									),
									const SizedBox(height: 4),
									Text(
										subtitle,
										style: TextStyle(
											fontSize: 14,
											color: Colors.white.withOpacity(0.6),
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
}
