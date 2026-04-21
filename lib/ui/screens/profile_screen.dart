import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:therapist_momnjo/ui/screens/sop_panduan_screen.dart';
import 'settings_screen.dart';
import 'data_diri_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryPink = const Color(0xFFE8647C); 

  // --- STATE VARIABLE UNTUK DATA DINAMIS ---
  String _therapistName = "Memuat...";
  String _therapistId = "-";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- FUNGSI MENGAMBIL DATA DARI SHARED PREFERENCES ---
  Future<void> _loadProfileData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Sesuaikan key string ini ('fullname' atau 'nama') dengan apa yang
      // teman backend Anda kirimkan saat proses login.
      String name = prefs.getString('fullname') ?? prefs.getString('nama') ?? 'Terapis Mom n Jo';
      String id = prefs.getString('username') ?? prefs.getString('id_terapis') ?? 'TRP-000';

      if (mounted) {
        setState(() {
          _therapistName = name;
          _therapistId = id;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _therapistName = "Terapis Mom n Jo";
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIKA LOGOUT ---
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
                Navigator.pop(dialogContext);
                await ApiService().logout();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
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
              // 1. Header Profil (Sekarang Dinamis)
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
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), // Avatar masih dummy, bisa diganti dinamis juga nantinya
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _therapistName, // <-- Data dinamis diterapkan di sini
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Terapis ID: $_therapistId', // <-- Data dinamis diterapkan di sini
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
                            text: '4.9 ', // Dummy rating
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: '(128 review)', // Dummy review count
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
          _buildInfoRow('Area Kerja', 'Bandung & Cimahi'), // Bisa dibuat dinamis juga nantinya
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
          
          _buildMenuItem(Icons.person_outline, 'Data Diri', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DataDiriScreen()),
            );
          }),
          _buildMenuDivider(),
          
          _buildMenuItem(Icons.menu_book_outlined, 'SOP & Panduan', () {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SopPanduanScreen()),);
          }),
          _buildMenuDivider(),
          
          _buildMenuItem(Icons.settings_outlined, 'Pengaturan', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }),
          _buildMenuDivider(),
          
          // TOMBOL KELUAR
          _buildMenuItem(
            Icons.logout_outlined, 
            'Keluar', 
            () => _handleLogout(context),
            textColor: Colors.red.shade700,
            iconColor: Colors.red.shade700,
            showTrailing: false, 
          ),
          
          const SizedBox(height: 8), 
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? textColor, Color? iconColor, bool showTrailing = true}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true, 
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 22),
      title: Text(
        title,
        style: TextStyle( 
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