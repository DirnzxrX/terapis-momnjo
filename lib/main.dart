import 'package:flutter/material.dart';

// Import semua screen yang mau didaftarin rutenya di sini
import 'package:therapist_momnjo/ui/screens/splash_screen.dart';
import 'package:therapist_momnjo/ui/screens/auth/login_screen.dart';
import 'package:therapist_momnjo/ui/screens/auth/register_screen.dart';
// import 'package:therapist_momnjo/ui/navigation/main_nav.dart'; // Nanti kalo udah ada, uncomment

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MomnjoTherapistApp());
}

class MomnjoTherapistApp extends StatelessWidget {
  const MomnjoTherapistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momnjo Terapis',
      debugShowCheckedModeBanner: false, 
      
      theme: ThemeData(
        primaryColor: const Color(0xFFF48FB1), 
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFF48FB1),
          secondary: const Color(0xFFFFEBEE), 
        ),
        fontFamily: 'Poppins', 
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0, 
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87, 
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), 
      ),

      // --- INI DIA MAGIC-NYA: NAMED ROUTES ---
      // initialRoute itu ibarat titik start pertama kali app dibuka
      initialRoute: '/', 
      
      // Di sini lu daftarin semua "jalan" di aplikasi lu
      routes: {
        '/': (context) => const SplashScreen(), // Rute '/' default ke Splash
        '/login': (context) => const LoginScreen(), // Rute '/login' arahin ke LoginScreen
        '/register': (context) => const RegisterScreen(), // Rute '/register' arahin ke RegisterScreen
        
        // Nanti kalo halaman lain udah jadi, tinggal lu tambahin di mari:
        // '/main': (context) => const MainNavigation(),
        // '/active_job': (context) => const ActiveJobScreen(),
      },
    );
  }
}