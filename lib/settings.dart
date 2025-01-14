// settings_page.dart
import 'package:flutter/material.dart';
import 'package:leo_app_01/policy.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // Define dark theme colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryTextColor = Colors.black;
  static const Color dangerColor = Color(0xFFCF6679);
  static const Color dividerColor = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile Settings',
            onTap: () => _navigateToPage(context, 'Profile Settings'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy Settings',
            onTap: () => _navigateToPage(context, 'Privacy Settings'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            onTap: () => _navigateToPage(context, 'Notification Settings'),
          ),

          const Divider(color: dividerColor),
          // Preferences Section
          _buildSectionHeader('Preferences'),
          _buildSettingTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _navigateToPage(context, 'Language Settings'),
          ),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            value: true,
            onChanged: (bool value) {
              // Implement location services toggle
            },
          ),

          const Divider(color: dividerColor),
          // Security Section
          _buildSectionHeader('Security'),
          _buildSettingTile(
            context,
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            onTap: () => _navigateToPage(context, '2FA Settings'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.block,
            title: 'Blocked Users',
            onTap: () => _navigateToPage(context, 'Blocked Users'),
          ),

          const Divider(color: dividerColor),
          // Legal Section
          _buildSectionHeader('Legal'),
          _buildSettingTile(
            context,
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () => _navigateToprivacy(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => _navigateToterms(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.copyright_outlined,
            title: 'Copyright Information',
            onTap: () => _navigateTocopyright(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.money_outlined,
            title: 'Refund Policy',
            onTap: () => _navigateTorefund(context),
          ),

          const Divider(color: dividerColor),
          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _navigateToPage(context, 'Help Center'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            onTap: () => _navigateToPage(context, 'Feedback'),
          ),

          const Divider(color: dividerColor),
          // Account Actions
          const SizedBox(height: 16),
          _buildDangerTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              // Implement logout functionality
            },
          ),
          _buildDangerTile(
            context,
            icon: Icons.delete_forever,
            title: 'Delete Account',
            onTap: () {
              // Implement delete account functionality
            },
            isDestructive: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
      )
          : null,
      trailing: const Icon(Icons.chevron_right, color: secondaryTextColor),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      inactiveThumbColor: secondaryTextColor,
      inactiveTrackColor: dividerColor,
    );
  }

  Widget _buildDangerTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? dangerColor : secondaryTextColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? dangerColor : secondaryTextColor,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToPage(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(title: title),
      ),
    );
  }

  _navigateToprivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyPolicyPage(),
      ),
    );
  }

  _navigateToterms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsAndConditionsPage(),
      ),
    );
  }

  _navigateTorefund(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefundPolicyPage(),
      ),
    );
  }

  _navigateTocopyright(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CopyrightPolicyPage(),
      ),
    );
  }
}

// detail_page.dart
class DetailPage extends StatelessWidget {
  final String title;

  const DetailPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsPage.backgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: SettingsPage.surfaceColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Content Goes Here',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}