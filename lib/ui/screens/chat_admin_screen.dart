import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
// Sesuaikan path import ini dengan lokasi file api_service.dart di project Anda
import 'package:therapist_momnjo/data/api_service.dart'; 

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({Key? key}) : super(key: key);

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final Color primaryPink = const Color(0xFFE8647C);
  
  // Nomor cadangan (fallback) jika API gagal merespons
  final String _fallbackPhoneNumber = "+6281387297524"; 
  
  String? _dynamicAdminPhoneNumber;
  String _namaTerapis = "Terapis";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // --- INISIALISASI DATA AWAL ---
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _namaTerapis = prefs.getString('nama_lengkap') ?? "Terapis"; 
    });

    // Jalankan pengambilan kontak WA gerai secara dinamis
    await _fetchAdminPhoneNumber();
  }

  // --- AMBIL KONTAK WA GERAI LEWAT API SERVICE ---
  Future<void> _fetchAdminPhoneNumber() async {
    try {
      // 🔥 UI sekarang bersih! Tinggal panggil getGeraiWa() dari ApiService
      final response = await ApiService().getGeraiWa();

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _dynamicAdminPhoneNumber = response['data']['kontak_wa'];
        });
      } else {
        debugPrint('Gagal mendapatkan kontak WA dari server: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Terjadi kesalahan saat memanggil API: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIKA MEMBUKA APLIKASI WHATSAPP ---
  Future<void> _openWhatsApp(BuildContext context) async {
    // Pilih nomor dinamis jika ada, jika tidak, gunakan cadangan
    final String targetNumber = _dynamicAdminPhoneNumber ?? _fallbackPhoneNumber;
    
    final String message = "Halo Admin Mom n Jo, saya $_namaTerapis, ingin bertanya mengenai layanan dan jadwal kerja. Terima kasih!";
    
    // Hilangkan karakter '+' dan spasi agar URL wa.me valid
    final String cleanNumber = targetNumber.replaceAll('+', '').replaceAll(' ', '');
    final String url = "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}";
    
    final Uri uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka aplikasi WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuka WhatsApp. Pastikan aplikasi WhatsApp sudah terinstall.'),
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
                  // Tombol dengan Indikator Memuat Data
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _openWhatsApp(context),
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Icon(Icons.phone_android, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Memuat Nomor...' : 'Buka WhatsApp',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        disabledBackgroundColor: Colors.green.shade300,
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