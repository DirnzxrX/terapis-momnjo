import 'package:flutter/material.dart';
import 'package:therapist_momnjo/ui/screens/booking_detail_screen.dart';

// Import semua screen yang sudah dibuat
import 'package:therapist_momnjo/ui/screens/splash_screen.dart';
import 'package:therapist_momnjo/ui/screens/auth/login_screen.dart';
import 'package:therapist_momnjo/ui/screens/auth/register_screen.dart';
import 'package:therapist_momnjo/ui/screens/home_screen.dart';
import 'package:therapist_momnjo/ui/screens/schedule_screen.dart';
import 'package:therapist_momnjo/ui/screens/visit_report_screen.dart';
import 'package:therapist_momnjo/ui/screens/arrival_checkin_screen.dart';
import 'package:therapist_momnjo/ui/screens/chat_admin_screen.dart';
import 'package:therapist_momnjo/ui/screens/active_job_screen.dart';
import 'package:therapist_momnjo/ui/screens/earnings_screen.dart';
import 'package:therapist_momnjo/ui/screens/profile_screen.dart';
import 'package:therapist_momnjo/ui/screens/leave_management_screen.dart'; // Tambahkan import LeaveManagementScreen

void main() {
  // Memastikan binding Flutter sudah terinisialisasi
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
      
      // Pengaturan Tema Global Aplikasi
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFF48FB1), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF48FB1),
          primary: const Color(0xFFF48FB1),
          secondary: const Color(0xFFFFEBEE),
          surface: Colors.white,
        ),
        fontFamily: 'Poppins', 
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0, 
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87, 
            fontSize: 18, 
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), 

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF48FB1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Halaman pertama yang akan muncul saat app dibuka
      initialRoute: '/', 
      
      // Daftar rute aplikasi
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        
        // Rute Utama yang memegang Footer (Bottom Navigation)
        '/main': (context) => const MainWrapperScreen(), 

        // Rute ini tetap ada buat jaga-jaga, tapi secara default akan dipanggil di dalam MainWrapperScreen
        '/home': (context) => const HomeScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/active_job': (context) => const ActiveJobScreen(),

        // Rute Layar Penuh (tanpa footer)
        '/visit_report': (context) => const VisitReportScreen(),
        '/arrival_checkin': (context) => const ArrivalCheckinScreen(),
        '/chat_admin': (context) => const ChatAdminScreen(),
        '/booking_detail': (context) => const BookingDetailScreen(),
        '/earnings': (context) => const EarningsScreen(),
        '/profile': (context) => const ProfileScreen(), 
        '/leave_management': (context) => const LeaveManagementScreen(),// Tambahkan rute profile
      },

      // Fallback jika rute yang dituju tidak ditemukan
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }
}


// ============================================================================
// WIDGET BARU: Pembungkus untuk Bottom Navigation Bar (Footer)
// ============================================================================
class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({Key? key}) : super(key: key);

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  // 1. Variabel penentu tab aktif (default 0 = Home)
  int _selectedIndex = 0;

  // 2. Daftar halaman untuk tiap tab di footer
  // Pastikan urutannya sama persis dengan urutan tombol di bawah
  final List<Widget> _pages = [
    const HomeScreen(),      // Index 0
    const ScheduleScreen(),  // Index 1
    const ActiveJobScreen(), // Index 2
    const EarningsScreen(),  // Index 3
    const ProfileScreen(),   // Index 4 (Tambahkan halaman Profile)
  ];

  // 3. Fungsi yang jalan pas tombol footer ditekan
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman sesuai index yang dipilih
      body: _pages[_selectedIndex],
      
      // Bottom Navigation Bar (Footer)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed, // Biar labelnya nggak hilang-timbul
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // Panggil fungsinya di sini
          selectedItemColor: const Color(0xFFF48FB1), // Pink saat aktif
          unselectedItemColor: Colors.grey.shade400, // Abu-abu saat mati
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          
          items: const [
            // Tab 0: Home
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            // Tab 1: Jadwal
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Jadwal',
            ),
            // Tab 2: Activity / Job Aktif
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Aktivitas',
            ),
            // Tab 3: Earnings
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on_outlined),
              activeIcon: Icon(Icons.monetization_on),
              label: 'Earnings',
            ),
            // Tab 4: Profil
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}