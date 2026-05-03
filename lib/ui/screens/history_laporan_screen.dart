import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'detail_laporan_screen.dart'; // IMPORT HALAMAN DETAIL

class HistoryLaporanScreen extends StatefulWidget {
  const HistoryLaporanScreen({Key? key}) : super(key: key);

  @override
  State<HistoryLaporanScreen> createState() => _HistoryLaporanScreenState();
}

class _HistoryLaporanScreenState extends State<HistoryLaporanScreen> {
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);
  final Color goldBrown = const Color(0xFFB08D57);

  final TextEditingController _searchController = TextEditingController();

  // --- STATE UNTUK DATA API ---
  List<dynamic> _apiHistoryData = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNGSI MENGAMBIL DATA DARI BACKEND ---
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      // getHistoryList() akan memanggil get_all_jobs.php?status=closed
      final response = await api.getHistoryList(); 

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _apiHistoryData = response['data'] ?? [];
            _applySearch(); // Terapkan pencarian & sorting awal
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat riwayat laporan.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan jaringan. Silakan coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNGSI PENCARIAN & SORTING ---
  void _applySearch() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredData = _apiHistoryData.where((item) {
        final name = (item['customer_name'] ?? item['nama_customer'] ?? '').toString().toLowerCase();
        final treatment = (item['treatment_summary'] ?? item['layanan'] ?? '').toString().toLowerCase();
        final idBooking = (item['id_booking'] ?? '').toString().toLowerCase();
        
        return query.isEmpty || 
               name.contains(query) || 
               treatment.contains(query) || 
               idBooking.contains(query);
      }).toList();

      // Urutkan dari yang terbaru
      _filteredData.sort((a, b) {
        DateTime timeA = DateTime.tryParse(a['start_time']?.toString() ?? '') ?? DateTime(2000);
        DateTime timeB = DateTime.tryParse(b['start_time']?.toString() ?? '') ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });
    });
  }

  // --- HELPER UNTUK MENAMPILKAN PESAN (SNACKBAR) ---
  void _showInfoMessage(BuildContext context, String message) {
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

  // --- FUNGSI NAVIGASI KE DETAIL ---
  void _navigateToDetail(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporanScreen(reportData: data),
      ),
    );
  }

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
          title: Column(
            children: [
              Text(
                'Riwayat Laporan',
                style: TextStyle(
                  color: textDarkBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Laporan Kunjungan Selesai',
                style: TextStyle(
                  color: textDarkBrown.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textDarkBrown),
              onPressed: _fetchHistoryData,
            ),
          ],
        ),
        body: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama customer / treatment',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            // LIST KARTU RIWAYAT ATAU LOADING/ERROR STATE
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFECA898)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: textDarkBrown)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHistoryData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryPeach),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (_filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty 
                  ? 'Pencarian tidak ditemukan' 
                  : 'Belum ada riwayat kunjungan yang selesai.', 
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistoryData,
      color: primaryPeach,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _filteredData.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildHistoryCard(_filteredData[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<dynamic, dynamic> data) {
    // --- FORMAT DATA DARI API ---
    final String customerName = data['customer_name']?.toString() ?? data['nama_customer']?.toString() ?? 'Klien';
    final String treatmentName = data['treatment_summary']?.toString() ?? 'Treatment';
    final String therapistName = 'Anda'; // Biasanya nama Terapis yang sedang login
    
    // Konversi Waktu
    String dateStr = '-';
    String timeStr = '-';
    if (data['start_time'] != null) {
      try {
        DateTime dt = DateTime.parse(data['start_time'].toString());
        dateStr = DateFormat('dd MMM yyyy').format(dt);
        timeStr = DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }

    final String status = data['booking_status']?.toString() ?? 'Selesai';
    
    // Tipe & Lokasi
    String roomTypeStr = (data['room_type'] ?? data['type'] ?? '').toString().toLowerCase();
    bool isHomeVisit = roomTypeStr.contains('home') || roomTypeStr.contains('kunjungan') || roomTypeStr.isEmpty;
    bool isAtBranch = !isHomeVisit;
    
    final String gerai = data['gerai']?.toString() ?? '';
    String location = isHomeVisit 
        ? (data['alamat']?.toString() ?? 'Menunggu konfirmasi lokasi')
        : (gerai.isNotEmpty ? gerai : 'Cabang Momnjo');

    // Menghasilkan nomor avatar random berbasis nama agar cantik
    int avatarIndex = (customerName.length * 3) % 70;

    // Pastikan _navigateToDetail menerima tipe Map<String, dynamic>
    final Map<String, dynamic> safeData = Map<String, dynamic>.from(data);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Avatar, Nama, Badge Status
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=$avatarIndex'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // INFO TREATMENT
          Text('Treatment Name', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(treatmentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text('Therapist: $therapistName', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
          
          const SizedBox(height: 10),
          
          // BADGE LOKASI (Home Visit / At Branch)
          Row(
            children: [
              if (isHomeVisit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: primaryPeach.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined, size: 14, color: textDarkBrown),
                      const SizedBox(width: 4),
                      Text('Home Visit', style: TextStyle(fontSize: 11, color: textDarkBrown, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (isAtBranch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined, size: 14, color: textDarkBrown),
                      const SizedBox(width: 4),
                      Text('At Branch', style: TextStyle(fontSize: 11, color: textDarkBrown, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // GRID INFO WAKTU & LOKASI
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: $dateStr', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: $timeStr', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text('Branch / Address: $location', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8)), maxLines: 2, overflow: TextOverflow.ellipsis),
          
          const SizedBox(height: 16),
          
          // TOMBOL AKSI DIAKTIFKAN
          Row(
            children: [
              // Tombol View Report
              InkWell(
                onTap: () => _navigateToDetail(safeData), // NAVIGASI AKTIF
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: primaryPeach, borderRadius: BorderRadius.circular(8)),
                  child: const Text(' View Detail ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const Spacer(),
              
              // Tombol panah Chevron
              IconButton(
                icon: Icon(Icons.chevron_right, color: textDarkBrown),
                onPressed: () => _navigateToDetail(safeData), // NAVIGASI AKTIF
              ),
            ],
          ),
        ],
      ),
    );
  }
}