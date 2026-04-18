import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedTab = 'Hari Ini';
  String _selectedFilter = 'Semua'; 

  final Color primaryPink = const Color(0xFFE8647C); 
  final TextEditingController _searchController = TextEditingController();

  // --- DATA DUMMY HARDCODED ---
  final List<Map<String, dynamic>> _dummySchedules = [
    {
      'jam': '08.00',
      'customer_fullname': 'Siti Aisyah',
      'deskripsi': 'Baby Spa',
      'alamat': 'Jl. Mawar No. 5, Bandung',
      'status': 'New',
      'service_type': 'home_service',
    },
    {
      'jam': '10.00',
      'customer_fullname': 'Dewi Lestari',
      'deskripsi': 'Mother Care Massage',
      'alamat': 'MomNJO Clinic Bandung',
      'status': 'Accepted',
      'service_type': 'on_site',
    },
    {
      'jam': '13.00',
      'customer_fullname': 'Anita Putri',
      'deskripsi': 'Totok Payudara',
      'alamat': 'Perumahan Citra 2 Blok A8, Bandung',
      'status': 'OTW',
      'service_type': 'home_service',
    },
    {
      'jam': '15.30',
      'customer_fullname': 'Rizky Amelia',
      'deskripsi': 'Lulur Hamil',
      'alamat': 'MomNJO Clinic Bandung',
      'status': 'Completed',
      'service_type': 'on_site',
    },
  ];

  List<Map<String, dynamic>> _filteredSchedules = [];

  @override
  void initState() {
    super.initState();
    _filteredSchedules = List.from(_dummySchedules);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredSchedules = _dummySchedules.where((schedule) {
        final status = schedule['status'] ?? '';
        bool passStatus = (_selectedFilter == 'Semua') || 
                          (status.toString().toLowerCase() == _selectedFilter.toLowerCase());

        final query = _searchController.text.toLowerCase();
        final name = (schedule['customer_fullname'] ?? '').toString().toLowerCase();
        bool passSearch = query.isEmpty || name.contains(query);

        return passStatus && passSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // MEMBUNGKUS SCAFFOLD DENGAN GAMBAR BACKGROUND DARI ASSETS
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        // WAJIB TRANSPARAN AGAR GAMBAR BACKGROUND DI BELAKANGNYA TERLIHAT
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Dibuat transparan agar menyatu dengan background
          elevation: 0,
          automaticallyImplyLeading: false, // Ini krusial: Mematikan auto-back button bawaan Flutter
          title: const Text(
            'Jadwal',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateTabs(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(), 
                ],
              ),
            ),
            
            Expanded(
              child: _filteredSchedules.isEmpty
                  ? Center(
                      child: Text('Tidak ada jadwal.', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredSchedules.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildScheduleCard(_filteredSchedules[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateTabs() {
    final tabs = ['Hari Ini', 'Besok', 'Mingguan'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: tabs.map((tab) {
              final isSelected = _selectedTab == tab;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() => _selectedTab = tab);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryPink : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
          decoration: const InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey),
            hintText: 'Cari nama customer',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'New', 'Completed']; 
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0), 
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() => _selectedFilter = filter);
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryPink : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? primaryPink : Colors.grey.shade200),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final String serviceType = schedule['service_type'] ?? 'home_service';
    final bool isHomeService = serviceType == 'home_service';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/booking_detail', arguments: schedule);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(
                      schedule['jam'] ?? '--:--',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                schedule['customer_fullname'] ?? 'Klien',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            _buildStatusBadge(schedule['status'] ?? 'Unknown'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              schedule['deskripsi'] ?? '-',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                            ),
                            _buildServiceTypeBadge(isHomeService),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isHomeService ? Icons.location_on : Icons.business, 
                              size: 14, 
                              color: isHomeService ? primaryPink : Colors.grey.shade600
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                schedule['alamat'] ?? '-', 
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
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeBadge(bool isHomeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHomeService ? primaryPink.withOpacity(0.9) : const Color(0xFFF5E6D3), 
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isHomeService ? 'Home Service 🏠' : 'On Site 🏥',
        style: TextStyle(
          color: isHomeService ? Colors.white : Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.toLowerCase() == 'accepted' || status.toLowerCase() == 'otw') {
      return const SizedBox.shrink(); 
    }

    Color textColor;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'new':
        textColor = const Color(0xFF1976D2);
        bgColor = const Color(0xFFE3F2FD);
        break;
      case 'accepted':
        textColor = const Color(0xFF7B1FA2);
        bgColor = const Color(0xFFF3E5F5);
        break;
      case 'otw':
        textColor = const Color(0xFFE65100);
        bgColor = const Color(0xFFFFF3E0);
        break;
      case 'completed':
        textColor = const Color(0xFF388E3C);
        bgColor = const Color(0xFFE8F5E9);
        break;
      default:
        textColor = Colors.grey.shade700;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}