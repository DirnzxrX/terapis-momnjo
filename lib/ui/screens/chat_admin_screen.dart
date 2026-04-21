import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Pastikan sudah menambahkan url_launcher di pubspec.yaml

class ChatAdminScreen extends StatelessWidget {
  const ChatAdminScreen({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFE8647C);
  final String adminPhoneNumber = "+6281387297524"; // Ganti dengan nomor admin Mom n Jo

  // --- FUNGSI UNTUK MEMBUKA WHATSAPP ---
  Future<void> _openWhatsApp(BuildContext context) async {
    final String message = "Halo Admin Mom n Jo, saya Rina (Terapis), ingin bertanya mengenai layanan dan jadwal kerja. Terima kasih!";
    final String url = "https://wa.me/${adminPhoneNumber.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(message)}";
    
    final Uri uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka WhatsApp';
      }
    } catch (e) {
      // Jika gagal membuka aplikasi WA (misal: tidak terinstall), munculkan pesan
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuka WhatsApp. Pastikan aplikasi WhatsApp terinstall.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Chat Admin',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon WhatsApp atau Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_outlined, color: Colors.green.shade600, size: 50),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hubungi Admin via WhatsApp',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Anda akan dialihkan ke aplikasi WhatsApp untuk berkomunikasi langsung dengan admin pusat Mom n Jo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Tombol Utama
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(context),
                      icon: const Icon(Icons.phone_android, color: Colors.white),
                      label: const Text(
                        'Buka WhatsApp',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jam Operasional: 08:00 - 20:00 WIB',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}