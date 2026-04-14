import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // State untuk Tab dan Filter
  String _selectedTab = 'Hari Ini';
  String _selectedFilter = 'Semua';

  final Color primaryPink = const Color(0xFFF48FB1);

  // Data dummy untuk list jadwal sesuai mockup
  final List<Map<String, dynamic>> _schedules = [
    {
      'time': '08.00',
      'name': 'Siti Aisyah',
      'service': 'Baby Spa',
      'address': 'Jl. Mawar No. 5, Bandung',
      'status': 'New',
    },
    {
      'time': '10.00',
      'name': 'Dewi Lestari',
      'service': 'Mother Care Massage',
      'address': 'Jl. Melati No. 10, Bandung',
      'status': 'Accepted',
    },
    {
      'time': '13.00',
      'name': 'Anita Putri',
      'service': 'Totok Payudara',
      'address': 'Perumahan Citra 2 Blok A8',
      'status': 'OTW',
    },
    {
      'time': '15.30',
      'name': 'Rizky Amelia',
      'service': 'Lulur Hamil',
      'address': 'Jl. Anggrek No. 12, Bandung',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Logika kembali, atau hapus jika ini adalah main tab di BottomNav
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Jadwal',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bagian Header (Tabs, Search, Filter) dengan background putih
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                _buildDateTabs(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
            ),
          ),
          
          // Bagian List Jadwal
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _schedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return _buildScheduleCard(schedule);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // 1. Tab Tanggal (Hari Ini, Besok, Mingguan)
  Widget _buildDateTabs() {
    final tabs = ['Hari Ini', 'Besok', 'Mingguan'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Bar Pencarian
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey),
            hintText: 'Cari nama customer',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // 3. Filter Status (Semua, New, Accepted, dll)
  Widget _buildFilterChips() {
    final filters = ['Semua', 'New', 'Accepted', 'OTW', 'Completed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPink : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryPink : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Card Item Jadwal
  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Waktu
          SizedBox(
            width: 50,
            child: Text(
              schedule['time'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Kolom Detail
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
                        schedule['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(schedule['status']),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  schedule['service'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule['address'],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk membuat Badge Status dengan warna yang sesuai
  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color bgColor;

    switch (status) {
      case 'New':
        textColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        break;
      case 'Accepted':
        textColor = Colors.purple.shade700;
        bgColor = Colors.purple.shade50;
        break;
      case 'OTW':
        textColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      case 'Completed':
        textColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
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
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}