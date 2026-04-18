import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  String _namaTerapis = 'Terapis'; // Default awal
  int _bookingHariIni = 0;
  int _selesai = 0;
  Map<String, dynamic>? _nextBooking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- FUNGSI LOAD DATA DARI LOKAL & API ---
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // LOGIKA DETEKSI: Ambil nama dari storage
      String? namaSimpanan = prefs.getString('nama_lengkap');
      
      // Debugging untuk membantu Anda melihat apa yang salah di terminal
      debugPrint("🚨 NAMA DI STORAGE: $namaSimpanan");

      String namaTampil = 'adisurya'; // Fallback absolut sesuai mockup

      if (namaSimpanan != null && namaSimpanan.trim().isNotEmpty) {
        namaTampil = namaSimpanan;
      }
      
      final api = ApiService();
      final statsResponse = await api.getStats();
      
      int daily = 0;
      int completed = 0;
      if (statsResponse['success'] == true && statsResponse['data'] != null) {
        daily = statsResponse['data']['total_bookings'] ?? 0;
        completed = statsResponse['data']['completed_jobs'] ?? 0;
      }

      final jobsResponse = await api.getJobs(status: 'Open');
      Map<String, dynamic>? nextBook;
      
      if (jobsResponse['success'] == true && jobsResponse['data'] != null) {
        List jobs = jobsResponse['data'];
        if (jobs.isNotEmpty) {
          nextBook = jobs[0]; 
        }
      }

      if (mounted) {
        setState(() {
          _namaTerapis = namaTampil;
          _bookingHariIni = daily;
          _selesai = completed;
          _nextBooking = nextBook;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPink = Color(0xFFF48FB1);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'), 
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: primaryPink,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Profile
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 2. Card Status Kerja
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // 3. Ringkasan Hari Ini
                  const Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildSummarySection(),
                  const SizedBox(height: 24),

                  // 4. Booking Berikutnya
                  const Text(
                    'Booking Berikutnya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildNextBookingCard(context, primaryPink),
                  const SizedBox(height: 24),

                  // 5. Aksi Cepat
                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context), 
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pink.shade200, 
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat pagi,',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500), 
            ),
            // NAMA TERAPIS: Dipastikan tidak kosong
            Text(
              _namaTerapis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, size: 28, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Kerja', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Text('ON DUTY', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 12),
              const Text('08.00 - 17.00', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildSummaryCard(_isLoading ? '...' : _bookingHariIni.toString(), 'Booking Hari Ini', Colors.blue.shade300)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard(_isLoading ? '...' : _selesai.toString(), 'Selesai', Colors.green.shade400)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Rp 850.000', 'Pendapatan', const Color(0xFFD4AF37))),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNextBookingCard(BuildContext context, Color primaryColor) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const CircularProgressIndicator(),
      );
    }

    final jam = _nextBooking?['jam'] ?? '--:--';
    final namaKlien = _nextBooking?['customer_fullname'] ?? 'Klien';
    final deskripsi = _nextBooking?['deskripsi'] ?? 'Treatment Momnjo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(jam, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaKlien, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(deskripsi, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(child: Text('Lokasi tidak tersedia', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _nextBooking != null ? Navigator.pushNamed(context, '/booking_detail') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Row(
              children: [
                Text('Detail', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
      children: [
        _buildActionItem(Icons.history, 'Riwayat', Colors.red.shade400, onTap: () => Navigator.pushNamed(context, '/visit_report')),
        _buildActionItem(Icons.assignment_turned_in, 'Absensi', Colors.blue.shade400, onTap: () => Navigator.pushNamed(context, '/arrival_checkin')),
        _buildActionItem(Icons.chat_bubble_outline, 'Chat Admin', Colors.teal.shade400, onTap: () => Navigator.pushNamed(context, '/chat_admin')),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap, 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}