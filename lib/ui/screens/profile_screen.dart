import 'package:flutter/material.dart';
// WAJIB DITAMBAHKAN: Import ApiService untuk menghapus sesi dari backend/lokal
import 'package:therapist_momnjo/data/api_service.dart';
import 'settings_screen.dart'; // Pastikan file ini ada di folder yang sama atau sesuaikan path-nya

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFE8647C); // Pink sesuai tema mockup baru

  // --- LOGIKA LOGOUT DITAMBAHKAN DI SINI ---
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin mengakhiri sesi dan keluar dari aplikasi?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. Tutup dialog
                Navigator.pop(dialogContext);
                
                // 2. Hapus sesi via ApiService
                await ApiService().logout();

                // 3. Hancurkan semua tumpukan layar dan lempar ke Login
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', // Pastikan rute ini terdaftar di main.dart
                    (Route<dynamic> route) => false, 
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          automaticallyImplyLeading: false, 
          title: const Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // 1. Header Profil
              _buildProfileHeader(),
              const SizedBox(height: 16),

              // 2. Info Detail
              _buildDetailInfo(),
              const SizedBox(height: 16),

              // 3. Menu List 
              _buildMenuList(context),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileHeader() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.pink.shade50,
            ),
            child: const CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), 
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rina Terapis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terapis ID: TRP00128',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          _buildInfoRow('Pengalaman', '3 Tahun'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey.shade200, height: 1),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          const SizedBox(height: 8), 
          
          _buildMenuItem(Icons.person_outline, 'Data Diri', () {}),
          _buildMenuDivider(),
          _buildMenuItem(Icons.description_outlined, 'Dokumen', () {}),
          _buildMenuDivider(),
          _buildMenuItem(Icons.menu_book_outlined, 'SOP & Panduan', () {}),
          _buildMenuDivider(),
          
          _buildMenuItem(Icons.settings_outlined, 'Pengaturan', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }),
          
          _buildMenuDivider(),
          _buildMenuItem(Icons.help_outline, 'Bantuan & Dukungan', () {}),
          _buildMenuDivider(),
          _buildMenuItem(Icons.info_outline, 'Tentang Aplikasi', () {}),
          _buildMenuDivider(),
          
          // TOMBOL KELUAR DITAMBAHKAN DI SINI
          _buildMenuItem(
            Icons.logout_outlined, 
            'Keluar', 
            () => _handleLogout(context),
            textColor: Colors.red.shade700, // Warna merah peringatan
            iconColor: Colors.red.shade700,
            showTrailing: false, // Hilangkan panah kanan
          ),
          
          const SizedBox(height: 8), 
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  // PERBAIKAN: Parameter opsional ditambahkan agar warna teks dan ikon bisa diubah
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? textColor, Color? iconColor, bool showTrailing = true}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true, 
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 22),
      title: Text(
        title,
        style: TextStyle( // Hapus kata 'const' di sini karena menggunakan variabel warna
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.black87,
        ),
      ),
      trailing: showTrailing ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20) : null,
      onTap: onTap, 
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }
}