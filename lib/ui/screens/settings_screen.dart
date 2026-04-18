import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFF48FB1); // Disamakan dengan home_screen.dart
  final Color textDark = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Mengikuti home_screen.dart
      extendBodyBehindAppBar: true, // Agar background gambar mencapai area AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      // Container dengan background disamakan dengan home_screen.dart
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 20),
                
                _buildSectionCard(
                  title: 'Akun & Keamanan',
                  children: [
                    _buildListTile(icon: Icons.person_outline, title: 'Edit Profil', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(icon: Icons.lock_outline, title: 'Email & Kata Sandi', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(icon: Icons.verified_user_outlined, title: 'Verifikasi Dua Langkah', onTap: () {}),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionCard(
                  title: 'Preferensi Aplikasi',
                  children: [
                    _buildListTile(icon: Icons.notifications_none, title: 'Notifikasi', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(icon: Icons.language, title: 'Bahasa', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.dark_mode_outlined, 
                      title: 'Tema Aplikasi', 
                      subtitle: 'Mode Terang/Gelap', 
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSectionCard(
                  title: 'Lainnya',
                  children: [
                    _buildListTile(icon: Icons.description_outlined, title: 'Syarat & Ketentuan', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(icon: Icons.privacy_tip_outlined, title: 'Kebijakan Privasi', onTap: () {}),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.delete_outline, 
                      title: 'Hapus Akun', 
                      textColor: Colors.red[700], 
                      iconColor: Colors.red[700], 
                      showTrailing: false, 
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryPink.withOpacity(0.15), // Efek transparan dari primaryPink
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), 
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rina Terapis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terapis ID: TRP00128',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
               title,
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: textDark,
               ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    Color? iconColor,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey.shade700,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: textColor ?? textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ) 
          : null,
      trailing: showTrailing 
          ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20) 
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }
}