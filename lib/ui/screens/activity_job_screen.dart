import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // --- WARNA DESAIN ---
  final Color primaryPeach = const Color(0xFFECA898);
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color badgeGreen = const Color(0xFFE8F5E9);
  final Color textGreen = const Color(0xFF4CAF50);
  
  // --- STATE UNTUK FILTER & API ---
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Dinilai', 'Belum Dinilai'];
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _apiActivities = [];
  List<dynamic> _filteredActivities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchActivitiesFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNGSI TARIK DATA API ---
  Future<void> _fetchActivitiesFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.getHistoryList();

      if (response['status'] == 'success' || response['success'] == true) {
        if (mounted) {
          setState(() {
            _apiActivities = response['data'] ?? [];
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat aktivitas dari server.';
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

  // --- FUNGSI FILTER LOKAL ---
  void _applyFilters() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(today.year, today.month, 1);

      _filteredActivities = _apiActivities.where((activity) {
        bool matchesTab = true;
        
        final rawDate = activity['date']?.toString() ?? activity['start_time']?.toString();
        DateTime? jobDate;
        if (rawDate != null && rawDate.isNotEmpty) {
          try {
            jobDate = DateTime.parse(rawDate);
          } catch (_) {}
        }
        
        final jobDay = jobDate != null ? DateTime(jobDate.year, jobDate.month, jobDate.day) : null;
        final hasRating = activity['rating'] != null && activity['rating'].toString().isNotEmpty;

        if (_selectedFilter == 'Hari Ini') {
          matchesTab = jobDay != null && jobDay.isAtSameMomentAs(today);
        } else if (_selectedFilter == 'Minggu Ini') {
          matchesTab = jobDay != null && (jobDay.isAtSameMomentAs(startOfWeek) || jobDay.isAfter(startOfWeek));
        } else if (_selectedFilter == 'Bulan Ini') {
          matchesTab = jobDay != null && (jobDay.isAtSameMomentAs(startOfMonth) || jobDay.isAfter(startOfMonth));
        } else if (_selectedFilter == 'Dinilai') {
          matchesTab = hasRating;
        } else if (_selectedFilter == 'Belum Dinilai') {
          matchesTab = !hasRating;
        }

        final query = _searchController.text.toLowerCase();
        final name = (activity['customer_name'] ?? '').toString().toLowerCase();
        final treatment = (activity['treatment_name'] ?? activity['treatment_summary'] ?? '').toString().toLowerCase();
        // Nambahin pencarian ID Booking juga biar sakti
        final idBooking = (activity['id_transaksi'] ?? activity['id_booking'] ?? '').toString().toLowerCase();
        
        bool matchesSearch = query.isEmpty || name.contains(query) || treatment.contains(query) || idBooking.contains(query);

        return matchesTab && matchesSearch;
      }).toList();
      
      _filteredActivities.sort((a, b) {
         String dateA = a['date']?.toString() ?? a['start_time']?.toString() ?? '2000-01-01';
         String dateB = b['date']?.toString() ?? b['start_time']?.toString() ?? '2000-01-01';
         return dateB.compareTo(dateA);
      });
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(raw);
      return DateFormat('dd MMMM yyyy').format(dt);
    } catch (e) { return raw; }
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat',
                style: TextStyle(color: textDarkBrown, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Pekerjaan Selesai',
                style: TextStyle(color: textDarkBrown.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // 1. SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Cari customer, treatment, atau ID',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),

            // 2. FILTER CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        _applyFilters();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? textDarkBrown : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? textDarkBrown : Colors.grey.shade300),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textDarkBrown,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 3. LIST KARTU AKTIVITAS
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchActivitiesFromApi,
                color: primaryPeach,
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryPeach));
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
                onPressed: _fetchActivitiesFromApi,
                style: ElevatedButton.styleFrom(backgroundColor: primaryPeach),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    if (_filteredActivities.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _filteredActivities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildActivityCard(_filteredActivities[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryPeach.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medical_services_outlined, size: 80, color: primaryPeach),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada aktivitas sesuai filter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDarkBrown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<dynamic, dynamic> data) {
    // AMBIL ID BOOKING / TRANSAKSI
    final String idBooking = data['id_transaksi']?.toString() ?? data['id_booking']?.toString() ?? '-';
    
    final String customerName = data['customer_name']?.toString() ?? 'Klien Tanpa Nama';
    final String treatmentName = data['treatment_name']?.toString() ?? data['treatment_summary']?.toString() ?? 'Treatment';
    
    final String serviceType = data['service_type']?.toString() ?? data['room_type']?.toString() ?? 'Onsite';
    final bool isHomeService = serviceType.toLowerCase().contains('home');
    final String typeText = isHomeService ? 'Home Service' : 'Onsite';

    final String dateText = _formatDate(data['date']?.toString() ?? data['start_time']?.toString());
    final String startTime = data['time']?.toString() ?? '--:--';
    
    final String status = data['status']?.toString() ?? 'Completed';
    final String qty = data['qty']?.toString() ?? '1';

    final String avatarUrl = data['customer_avatar'] ?? data['avatar'] ?? data['foto'] ?? 'https://i.pravatar.cc/150?img=43';
    final String? rating = data['rating']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 INI DIA TAMBAHAN ID BOOKING-NYA TUAN!
                    Text(
                      'ID: $idBooking',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryPeach),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treatmentName,
                      style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryPeach.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeText,
                        style: TextStyle(color: textDarkBrown, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: textGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rating != null && rating.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textDarkBrown),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),
          
          Text(
            dateText,
            style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: textDarkBrown.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                'Mulai: $startTime',
                style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.shopping_bag_outlined, size: 14, color: textDarkBrown.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                'Qty: $qty',
                style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          
          InkWell(
            onTap: () {
              final Map<String, dynamic> safeData = Map<String, dynamic>.from(data);
              Navigator.pushNamed(context, '/activity_detail', arguments: safeData);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lihat Detail Rating & Laporan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkBrown),
                  ),
                  Icon(Icons.chevron_right, color: textDarkBrown, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}