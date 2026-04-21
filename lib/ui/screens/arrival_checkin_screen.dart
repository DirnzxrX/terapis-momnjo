import 'package:flutter/material.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart';

class ArrivalCheckinScreen extends StatefulWidget {
  const ArrivalCheckinScreen({Key? key}) : super(key: key);

  @override
  State<ArrivalCheckinScreen> createState() => _ArrivalCheckinScreenState();
}

class _ArrivalCheckinScreenState extends State<ArrivalCheckinScreen> {
  final Color primaryPink = const Color(0xFFE8647C);
  final Color textDarkBrown = const Color(0xFF4A332B);

  List<dynamic> _activeJobs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // STATE UNTUK TAB
  String _selectedTab = 'Home Service'; 
  String _searchQuery = ''; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchActiveJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // PERBAIKAN: Parameter status dihapus karena getJobs() sudah otomatis mengambil active jobs (Open)
    final result = await ApiService().getJobs();

    if (mounted) {
      if (result['success'] == true) {
        List<dynamic> apiData = result['data'] ?? [];
        setState(() {
          _activeJobs = apiData; 
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    }
  }

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
          image: AssetImage('assets/baground2.jpeg'),
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
            'Jadwal',
            style: TextStyle(color: textDarkBrown, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchActiveJobs,
          color: primaryPink,
          child: Column(
            children: [
              const SizedBox(height: 10),
              // MEMANGGIL WIDGET TAB DI SINI
              _buildCustomTabBar(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari nama customer',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET UNTUK 2 TAB (HOME SERVICE & ONSITE)
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // TAB 1: HOME SERVICE
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'Home Service'),
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
              onTap: () => setState(() => _selectedTab = 'Onsite'),
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

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryPink));
    }

    if (_errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                TextButton(onPressed: _fetchActiveJobs, child: const Text('Coba Lagi')),
              ],
            ),
          ),
        ),
      );
    }

    // LOGIKA FILTER BERDASARKAN TAB DAN PENCARIAN
    List<dynamic> filteredJobs = _activeJobs.where((job) {
      bool isHome = job['room_type']?.toString().toLowerCase().contains('home') ?? false;
      
      // Jika tab Home Service terpilih, tampilkan yang isHome == true.
      // Jika tab Onsite terpilih, tampilkan yang isHome == false.
      bool matchesTab = _selectedTab == 'Home Service' ? isHome : !isHome;

      String custName = (job['customer_name'] ?? '').toString().toLowerCase();
      bool matchesSearch = custName.contains(_searchQuery);

      return matchesTab && matchesSearch;
    }).toList();

    if (filteredJobs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(filteredJobs[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tidak ada jadwal $_selectedTab',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown),
              ),
              const SizedBox(height: 8),
              Text('Tarik ke bawah untuk memuat ulang', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data) {
    bool isHomeService = data['room_type']?.toString().toLowerCase().contains('home') ?? false;
    String jamTampil = data['start_time'] != null ? _formatTime(data['start_time']) : '--:--';
    
    String namaKlien = data['customer_name']?.toString() ?? 'Klien Tanpa Nama';

    return GestureDetector(
      onTap: () {
        // PERBAIKAN: .then ditambahkan agar daftar me-refresh secara otomatis
        // ketika user menyelesaikan job dan kembali ke halaman ini.
        if (isHomeService) {
          Navigator.pushNamed(context, '/booking_detail', arguments: data).then((_) {
            _fetchActiveJobs();
          });
        } else {
          Navigator.pushNamed(context, '/booking_detail_onsite', arguments: data).then((_) {
            _fetchActiveJobs();
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 60,
                child: Text(
                  jamTampil,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown, letterSpacing: 1.2),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaKlien,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['treatment_summary'] ?? 'Detail treatment tidak tersedia',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryPink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Text(
                          isHomeService ? 'Home Service 🏠' : 'Onsite 🏢',
                          style: TextStyle(color: textDarkBrown, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 16, color: primaryPink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data['gerai'] ?? data['alamat'] ?? '-',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.center,
              child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}