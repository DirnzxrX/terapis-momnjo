import 'package:flutter/material.dart';

class BantuanDukunganScreen extends StatelessWidget {
  const BantuanDukunganScreen({Key? key}) : super(key: key);

  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPink = const Color(0xFFE8647C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/baground2.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDarkBrown),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Bantuan & Dukungan',
            style: TextStyle(
              color: textDarkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Hubungi Kami'),
              const SizedBox(height: 12),
              _buildContactCard(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: 'Chat WhatsApp Admin',
                subtitle: '+62 812-3456-7890',
                onTap: () {
                  _showSnackbar(context, 'Membuka WhatsApp Admin...');
                },
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@momnjo.com',
                onTap: () {
                  _showSnackbar(context, 'Membuka aplikasi Email...');
                },
              ),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Pertanyaan Populer (FAQ)'),
              const SizedBox(height: 12),
              _buildFaqCard(
                'Bagaimana cara mengubah jadwal kunjungan?', 
                'Anda dapat mengubah jadwal kunjungan melalui menu Jadwal, pilih jadwal yang ingin diubah, lalu tekan tombol "Reschedule". Pengubahan maksimal dilakukan 24 jam sebelum waktu kunjungan.'
              ),
              const SizedBox(height: 12),
              _buildFaqCard(
                'Apa yang harus dilakukan jika saya sakit mendadak?', 
                'Silakan ajukan Cuti Sakit melalui menu Manajemen Cuti di aplikasi dan lampirkan foto surat keterangan dokter. Segera hubungi Admin Pusat agar jadwal Anda hari ini dapat dialihkan ke terapis lain.'
              ),
              const SizedBox(height: 12),
              _buildFaqCard(
                'Bagaimana sistem perhitungan insentif bulanan?', 
                'Insentif dihitung berdasarkan akumulasi jumlah treatment yang Anda selesaikan dan skor rating dari pelanggan. Detail transparansinya dapat Anda lihat setiap bulan pada menu Slip Gaji.'
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: textDarkBrown,
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context, 
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryPink.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryPink),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDarkBrown)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqCard(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown),
        ),
        iconColor: primaryPink,
        collapsedIconColor: Colors.grey.shade400,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}