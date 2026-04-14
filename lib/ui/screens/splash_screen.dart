import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Logika buat pindah halaman otomatis setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      // Uncomment kode di bawah ini kalo file Login-nya udah lu bikin ya Tuan!
      /*
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      */
      debugPrint("Pindah ke halaman Login...");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pake Stack biar gampang numpuk background gambar, daun, sama konten tengah
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND GAMBAR
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),

          // 2. ORNAMEN DAUN
          // Daun atas kanan
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/daun1.png',
              width: 180, // Ukurannya bisa lu sesuaiin lagi kalo kurang pas
            ),
          ),
          // Daun bawah kiri
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              'assets/daun2.png',
              width: 180, // Ukurannya bisa lu sesuaiin lagi kalo kurang pas
            ),
          ),

          // 3. KONTEN UTAMA DI TENGAH
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // LOGO MOM N JO DARI ASSET
              Image.asset(
                'assets/logo_momnjo.png',
                width: 150, 
              ),
              const SizedBox(height: 16),

              // TEKS SUBTITLE
              const Text(
                'Therapis Home Care',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87, // Sesuaiin warnanya kalo dirasa kurang gelap
                ),
              ),

              const Spacer(flex: 1),

              // ICON LOVE DI DALAM LINGKARAN
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), // Background lingkaran love
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFF48FB1), // Warna love pink
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),

              // QUOTE TEXT
              Text(
                'Melayani dengan Kasih,\nProfesional dengan Hati',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // LOADING DOTS DARI ASSET
              Image.asset(
                'assets/titik.png',
                width: 70, // Bisa digedein/dikecilin sesuai selera Tuan
              ),
              const SizedBox(height: 40), // Jarak aman dari bawah layar
            ],
          ),
        ],
      ),
    );
  }
}
