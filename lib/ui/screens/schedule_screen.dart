import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Tambahan untuk kDebugMode
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart'; 

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedTab = 'Home Service'; 
  
  final Color primaryPink = const Color(0xFFE8647C); 
  final Color textDarkBrown = const Color(0xFF4A332B); 
  final TextEditingController _searchController = TextEditingController();

  // --- STATE UNTUK API ---
  List<dynamic> _apiSchedules = []; 
  List<dynamic> _filteredSchedules = []; 
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSchedulesFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNGSI TARIK DATA API ---
  Future<void> _fetchSchedulesFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      
      // Memanggil API getActiveJobs()
      final response = await api.getActiveJobs(); 

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _apiSchedules = response['data'] ?? [];
            
            // 🔴 DEBUGGING BANTUAN: Cetak isi data ke terminal agar Anda bisa lihat langsung!
            if (kDebugMode) {
              print("=== 🛠️ CEK DATA DARI BACKEND ===");
              print("Jumlah Booking Masuk: ${_apiSchedules.length}");
              if (_apiSchedules.isNotEmpty) {
                print("Contoh Data 1: ${_apiSchedules.first}");
              }
              print("=================================");
            }

            _applyFilters(); 
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat jadwal dari server.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan internal. Pastikan internet Anda stabil.';
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNGSI FILTER LOKAL (SUDAH DIPERLONGGAR) ---
  void _applyFilters() {
    setState(() {
      _filteredSchedules = _apiSchedules.where((schedule) {
        
        // 1. FILTER STATUS TREATMENT (Bukan cuma status booking)
        // Cek apakah semua layanan di dalam transaksi ini sudah dikerjakan (is_done == true)
        final List<dynamic> treatments = schedule['treatments'] ?? [];
        if (treatments.isNotEmpty) {
          bool isAllTreatmentsDone = treatments.every((item) {
            return item is Map && item['is_done'] == true;
          });
          
          // Jika SEMUA treatment sudah selesai dikerjakan terapis, SEMBUNYIKAN dari tab Tugas.
          if (isAllTreatmentsDone) {
            return false; 
          }
        } else {
          // Jika array treatments kosong, baru kita cek status bookingnya (jaga-jaga)
          final String status = (schedule['status'] ?? schedule['booking_status'] ?? '').toString().toLowerCase().trim();
          if (['cancel', 'batal', 'canceled'].contains(status)) {
            return false; 
          }
        }

        // 2. FILTER TIPE LAYANAN (Home Service vs Onsite)
        String roomTypeStr = (schedule['room_type'] ?? schedule['type'] ?? schedule['kategori'] ?? '').toString().toLowerCase();
        
        // Jika backend mengirim 'home', 'kunjungan', atau kosong, anggap Home Service.
        bool isHome = roomTypeStr.contains('home') || roomTypeStr.contains('kunjungan') || roomTypeStr.isEmpty;
        bool matchesTab = _selectedTab == 'Home Service' ? isHome : !isHome;

        // 3. FILTER PENCARIAN (NAMA KLIEN / ID BOOKING)
        final query = _searchController.text.toLowerCase().trim();
        final name = (schedule['customer_name'] ?? schedule['nama_customer'] ?? '').toString().toLowerCase();
        final idBook = (schedule['id_booking'] ?? '').toString().toLowerCase();
        bool matchesSearch = query.isEmpty || name.contains(query) || idBook.contains(query);

        return matchesTab && matchesSearch;
      }).toList();

      // 4. SORTING: URUTKAN BERDASARKAN WAKTU TERBARU DI ATAS
      _filteredSchedules.sort((a, b) {
        DateTime timeA = DateTime.tryParse(a['start_time']?.toString() ?? a['jadwal']?.toString() ?? '') ?? DateTime(2000);
        DateTime timeB = DateTime.tryParse(b['start_time']?.toString() ?? b['jadwal']?.toString() ?? '') ?? DateTime(2000);
        return timeB.compareTo(timeA); 
      });
    });
  }

  // --- FUNGSI PEMBANTU FORMAT WAKTU ---
  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    try {
      DateTime dt = DateTime.parse(raw);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '--:--';
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
          automaticallyImplyLeading: false, 
          title: Text(
            'Tugas',
            style: TextStyle(color: textDarkBrown, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchSchedulesFromApi, // Pull-to-refresh
          color: primaryPink,
          child: Column(
            children: [
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomTabBar(), 
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                  ],
                ),
              ),
              
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIKA STATE RENDERER ---
  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryPink));
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSchedulesFromApi,
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    if (_filteredSchedules.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Tidak ada jadwal aktif untuk kategori ini.', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      itemCount: _filteredSchedules.length,
      itemBuilder: (context, index) {
        return _buildScheduleCard(_filteredSchedules[index]);
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // TAB 1: HOME SERVICE
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 'Home Service';
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTab == 'Home Service' ? primaryPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Home Service',
                  style: TextStyle(
                    color: _selectedTab == 'Home Service' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          // TAB 2: ONSITE
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 'Onsite';
                  _applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTab == 'Onsite' ? primaryPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Onsite',
                  style: TextStyle(
                    color: _selectedTab == 'Onsite' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _applyFilters(), 
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey.shade400),
            hintText: 'Cari nama customer / id',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<dynamic, dynamic> schedule) {
    String roomTypeStr = (schedule['room_type'] ?? schedule['type'] ?? schedule['kategori'] ?? '').toString().toLowerCase();
    bool isHomeService = roomTypeStr.contains('home') || roomTypeStr.contains('kunjungan') || roomTypeStr.isEmpty;
    
    
    final String formattedTime = _formatTime(schedule['start_time']?.toString() ?? schedule['jadwal']?.toString());
    
    final String idBooking = schedule['id_booking']?.toString() ?? '';
    final String customerName = schedule['customer_name']?.toString() ?? schedule['nama_customer']?.toString() ?? 'Klien Tanpa Nama';
    
    final String displayTitle = (idBooking.isNotEmpty && idBooking != '-') ? idBooking : customerName;
    
    final String roomType = schedule['room_type']?.toString() ?? '';
    final String gerai = schedule['gerai']?.toString() ?? '';
    
    String rawAlamat = [gerai, roomType].where((e) => e.isNotEmpty).join(' - ');
    if (rawAlamat.isEmpty) {
      rawAlamat = schedule['alamat']?.toString() ?? 'Menunggu konfirmasi lokasi';
    }

    return GestureDetector(
      onTap: () {
        final Map<String, dynamic> safeSchedule = Map<String, dynamic>.from(schedule);
        
        // ✅ Arahin sesuai Tipe
        String targetRoute = isHomeService ? '/booking_detail' : '/booking_detail_onsite';

        Navigator.pushNamed(context, targetRoute, arguments: safeSchedule).then((_) {
          _fetchSchedulesFromApi();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 65, 
                child: Text(
                  formattedTime,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown, letterSpacing: 0.5),
                ),
              ),
            ),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle, 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (customerName.isNotEmpty && displayTitle != customerName) ...[
                    const SizedBox(height: 4),
                    Text(
                      customerName,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 4),
                  
                  Text(
                    schedule['treatment_summary']?.toString() ?? schedule['layanan']?.toString() ?? 'Detail treatment tidak tersedia',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryPink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildServiceTypeBadge(isHomeService),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on, 
                        size: 16, 
                        color: primaryPink
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rawAlamat, 
                          style: TextStyle(
                            fontSize: 13, 
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Align(
              alignment: Alignment.center,
              child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeBadge(bool isHomeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Text(
        isHomeService ? 'Home Service 🏠' : 'Onsite 🏢',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}