import 'package:flutter/material.dart';

class DataDiriScreen extends StatelessWidget {
  const DataDiriScreen({Key? key}) : super(key: key);

  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);

  @override
  Widget build(BuildContext context) {
    // Membungkus Scaffold dengan Container untuk Background Image
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/baground2.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar gambar terlihat
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDarkBrown),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Data Diri',
            style: TextStyle(
              color: textDarkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              _buildProfilePicture(),
              const SizedBox(height: 24),
              
              // Kartu Informasi Pribadi
              _buildInfoSection(
                title: 'Informasi Pribadi',
                items: [
                  _buildInfoItem(Icons.person_outline, 'Nama Lengkap', 'Rina Terapis'),
                  _buildInfoItem(Icons.phone_outlined, 'Nomor Telepon', '+62 812 3456 7890'),
                  _buildInfoItem(Icons.email_outlined, 'Email', 'rina.terapis@momnjo.com'),
                  _buildInfoItem(Icons.calendar_today_outlined, 'Tanggal Lahir', '12 Agustus 1995'),
                  _buildInfoItem(Icons.female_outlined, 'Jenis Kelamin', 'Perempuan'),
                  _buildInfoItem(Icons.location_on_outlined, 'Alamat', 'Jl. Melati No. 10, Bandung'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Kartu Informasi Pekerjaan
              _buildInfoSection(
                title: 'Informasi Pekerjaan',
                items: [
                  _buildInfoItem(Icons.badge_outlined, 'ID Terapis', 'TRP00128'),
                  _buildInfoItem(Icons.map_outlined, 'Area Kerja', 'Bandung & Cimahi'),
                  _buildInfoItem(Icons.work_outline, 'Pengalaman', '3 Tahun'),
                  _buildInfoItem(Icons.spa_outlined, 'Spesialisasi', 'Mother Care, Baby Spa'),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Komponen Foto Profil + Ikon Kamera
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPeach,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Komponen Card Pembungkus List Informasi
  Widget _buildInfoSection({required String title, required List<Widget> items}) {
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDarkBrown,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Komponen Baris Informasi (Icon + Label + Value)
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}