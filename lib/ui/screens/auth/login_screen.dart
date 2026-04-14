import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
// Nanti uncomment ini kalo udah bikin dummy navigasi
// import 'package:therapist_momnjo/ui/navigation/main_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller buat nangkep inputan user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State buat toggle password visibility sama checkbox
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    // Jangan lupa di-dispose biar ga memory leak Tuan!
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi dummy buat simulasi login
  void _handleLogin() {
    // Nanti di sini kita pasang logic nembak API dari temen lu
    debugPrint("Email: ${_emailController.text}");
    debugPrint("Password: ${_passwordController.text}");
    
    // Sementara, langsung pindah ke halaman utama aja
    /*
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()), // Asumsi lu udah bikin file ini
    );
    */
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulasi Login Berhasil, Tuan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pake Stack lagi biar background daunnya bisa ditumpuk di belakang form
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND GAMBAR (Sama kayak Splash)
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),

          // 2. ORNAMEN DAUN 
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

          // 3. KONTEN UTAMA DIBUNGKUS SCROLLVIEW
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Biar buttonnya melebar full
                children: [
                  const SizedBox(height: 20),
                  // --- BAGIAN LOGO & JUDUL ---
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/logo_momnjo.png', width: 120),
                        const SizedBox(height: 12),
                        const Text(
                          'Therapis Home Care',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),

                  // --- BAGIAN GREETING ---
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk untuk melanjutkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // --- FORM INPUT NOMOR HP / EMAIL ---
                  const Text(
                    'Nomor HP / Email',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nomor HP / email',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF48FB1), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- FORM INPUT PASSWORD ---
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Logic buat sembunyiin/tampilin password
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF48FB1), width: 1.5),
                      ),
                      // Icon mata di sebelah kanan
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- ROW INGAT SAYA & LUPA PASSWORD ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFFF48FB1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Ingat saya', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigasi ke Lupa Password
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF48FB1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- TOMBOL MASUK ---
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF48FB1), // Warna pink Momnjo
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Bikin tombolnya kapsul
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- DIVIDER ATAU ---
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('atau', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- TOMBOL MASUK DENGAN OTP ---
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigasi ke halaman OTP
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur OTP coming soon, Tuan!')),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFF48FB1), size: 20),
                    label: const Text(
                      'Masuk dengan OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF48FB1), // Tulisan pink
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFF48FB1), width: 1.5), // Garis pinggir pink
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- FOOTER HUBUNGI ADMIN ---
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Belum punya akun? ',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Daftar Sekarang',
                            style: const TextStyle(
                              color: Color(0xFFF48FB1),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/register');
                              },
                          ),
                        ],
                      ),
                    ),
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