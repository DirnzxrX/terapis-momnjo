import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFF48FB1);

  @override
  Widget build(BuildContext context) {
    // Scaffold digunakan di sini untuk mensimulasikan tampilan Drawer yang terbuka.
    // Pada implementasi asli, Anda cukup mengembalikan widget Drawer() saja, 
    // lalu memasukkannya ke properti `drawer: SideMenu()` pada Scaffold utama.
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5), // Latar belakang gelap/dim
      body: Row(
        children: [
          // 1. Area Side Menu (Drawer)
          Container(
            width: MediaQuery.of(context).size.width * 0.75, // Mengambil 75% lebar layar
            color: Colors.white,
            child: Column(
              children: [
                // Header Menu (Area Pink)
                _buildHeader(),
                
                // Daftar Menu Navigasi
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    children: [
                      _buildMenuItem(Icons.home_filled, 'Home', isSelected: true),
                      _buildMenuItem(Icons.calendar_today_outlined, 'Schedule'),
                      _buildMenuItem(Icons.person_outline, 'Activity'),
                      _buildMenuItem(Icons.monetization_on_outlined, 'Earnings'),
                      _buildMenuItem(Icons.chat_bubble_outline, 'Chat Admin'),
                      _buildMenuItem(Icons.assignment_turned_in_outlined, 'Absensi'),
                      _buildMenuItem(Icons.checklist_outlined, 'Equipment Checklist'),
                      _buildMenuItem(Icons.school_outlined, 'Learning Center'),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Divider(color: Color(0xFFEEEEEE), height: 1),
                      ),
                      
                      _buildMenuItem(Icons.settings_outlined, 'Pengaturan'),
                      _buildMenuItem(Icons.logout_outlined, 'Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Area Kosong di kanan (Bisa di-tap untuk menutup menu)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: primaryPink,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Profil
              const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), // Placeholder Rina
              ),
              // Ikon Notifikasi
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nama & ID Terapis
          const Text(
            'Rina Terapis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Terapis ID: TRP00128',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // Badge Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50), // Hijau
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ON DUTY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isSelected = false}) {
    // Jika item sedang dipilih (seperti 'Home'), warnanya menjadi pink
    final color = isSelected ? primaryPink : Colors.black87;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: color,
        ),
      ),
      onTap: () {
        // Logika navigasi ke menu terkait
      },
    );
  }
}