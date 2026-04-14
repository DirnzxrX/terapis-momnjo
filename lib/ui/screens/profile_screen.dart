import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFF48FB1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. Header Profil
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // 2. Info Detail (Area, Pengalaman, Spesialisasi)
            _buildDetailInfo(),
            const SizedBox(height: 24),

            // 3. Menu List
            _buildMenuList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), // Placeholder foto Rina
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rina Terapis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terapis ID: TRP00128',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: '4.9 ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: '(128 review)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
        children: [
          _buildInfoRow('Area Kerja', 'Bandung & Cimahi'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          _buildInfoRow('Pengalaman', '3 Tahun'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          _buildInfoRow('Spesialisasi', 'Mother Care, Baby Spa'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, 'Data Diri'),
          _buildMenuDivider(),
          _buildMenuItem(Icons.description_outlined, 'Dokumen'),
          _buildMenuDivider(),
          _buildMenuItem(Icons.menu_book_outlined, 'SOP & Panduan'),
          _buildMenuDivider(),
          _buildMenuItem(Icons.settings_outlined, 'Pengaturan'),
          _buildMenuDivider(),
          _buildMenuItem(Icons.help_outline, 'Bantuan & Dukungan'),
          _buildMenuDivider(),
          _buildMenuItem(Icons.info_outline, 'Tentang Aplikasi'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.black87, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
      onTap: () {
        // Logika navigasi ke masing-class pengaturan
      },
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }
}