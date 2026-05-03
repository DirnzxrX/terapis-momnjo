import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- TAMBAHAN IMPORT INI
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:therapist_momnjo/ui/widgets/hourglass_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Sesuai dokumen backend: pastikan di-trim agar spasi dari autocomplete tidak ikut terkirim
    String inputUser = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (inputUser.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan Password wajib diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    final response = await api.login(inputUser, password);

    // Pastikan widget masih aktif setelah proses await selesai
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == true) {
      // Ambil objek data dari response secara aman
      final data = response['data']; 
      
      String nama = '';
      String rating = '0.0';
      String reviewCount = '0';

      // Pastikan data adalah Map (JSON Object) yang valid
      if (data != null && data is Map) {
        nama = data['nama_lengkap']?.toString() ?? data['nama']?.toString() ?? data['name']?.toString() ?? '';
        rating = data['rating']?.toString() ?? '0.0';
        reviewCount = data['review_count']?.toString() ?? '0';
      }

      // Jika nama tetap kosong setelah dicek semua key, PAKSA gunakan input username
      if (nama.trim().isEmpty) {
        nama = inputUser;
      }

      // --- TAMBAHAN: Simpan Data ke SharedPreferences ---
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('rating', rating);
      await prefs.setString('review_count', reviewCount);
      
      // 🔥 Menyimpan nama agar terbaca di halaman Absensi 🔥
      await prefs.setString('user_name', nama);
      
      // Untuk mengecek di terminal/console apakah berhasil menyimpan
      debugPrint('=== [DEBUG] NAMA DISIMPAN SEBAGAI: $nama ===');
      // -------------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selamat datang, $nama!')),
      );
      // Rute tetap sesuai instruksi
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Login gagal. Silakan coba lagi.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.png', fit: BoxFit.cover),

          Positioned(
            top: 0,
            right: 0,
            child: Image.asset('assets/daun1.png', width: 160),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset('assets/daun2.png', width: 160),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/logo_momnjo.png', width: 120),
                        const SizedBox(height: 12),
                        const Text(
                          'Therapis Home Care',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  const Text(
                    'Selamat Datang!!!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk untuk melanjutkan',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 32),

                  const Text('Username',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Masukkan username',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text('Password',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('Ingat saya', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF48FB1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const HourglassLoading(size: 24, color: Colors.white)
                        : const Text('Masuk',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}