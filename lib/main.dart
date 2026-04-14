import 'package:flutter/material.dart';

// TODO: Nanti di-uncomment kalo file-filenya udah lu bikin ya Tuan
// import 'core/theme.dart';
// import 'ui/navigation/main_nav.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  // Kalau nanti lu pake Firebase atau Provider, inisialisasinya di sini sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MomnjoTherapistApp());
}

class MomnjoTherapistApp extends StatelessWidget {
  const MomnjoTherapistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momnjo Terapis',
      debugShowCheckedModeBanner: false, // Biar pita debug di pojok kanan atas ilang
      
      // Setup tema global di sini biar gampang
      theme: ThemeData(
        // Pake warna pink khas Momnjo
        primaryColor: const Color(0xFFF48FB1), 
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFF48FB1),
          secondary: const Color(0xFFFFEBEE), // Peach color
        ),
        // Biasanya desain kayak gini pake font Poppins atau Montserrat
        fontFamily: 'Poppins', 
        
        // Setup Appbar default biar putih, rapi, elegan
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0, // Bikin flat nggak ada bayangan
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87, 
            fontSize: 18, 
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Background app sedikit abu-abu muda biar adem
      ),

      // Udah diganti jadi SplashScreen ya Tuan!
      home: const SplashScreen(), 
    );
  }
}