import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _dailyRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Signed in with Ecoenzyme';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'E';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFD9F1DA),
                    child: Text(
                      initial,
                      style: textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your account', style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(email, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('PREFERENCES', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),
                  title: const Text('Daily eco reminders'),
                  subtitle: const Text('A gentle nudge for your daily goals'),
                  value: _dailyRemindersEnabled,
                  onChanged: (value) {
                    setState(() => _dailyRemindersEnabled = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(Icons.eco_outlined),
                  title: Text('About Ecoenzyme'),
                  subtitle: Text('Small steps for a healthier planet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('ACCOUNT', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB5473A)),
              title: const Text('Sign out'),
              onTap: () => _confirmSignOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in to continue your progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !context.mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sign out: ${error.message}')),
        );
      }
    }
  }
}
