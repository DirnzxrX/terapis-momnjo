import 'package:flutter/material.dart';
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

  // SIMULASI DATA RIWAYAT LAPORAN
  final List<Map<String, dynamic>> _historyData = [
    {
      'customer_name': 'Sarah Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=43',
      'treatment_name': 'Postpartum Massage - 90 mins',
      'therapist_name': 'Rina Herlina',
      'is_home_visit': true,
      'is_at_branch': false,
      'date': '18 Apr 2026',
      'time': '14:00 - 15:30',
      'duration': '90 menit',
      'location': 'MomNJo Darmawangsa',
      'status': 'Submitted',
    },
    {
      'customer_name': 'Naria Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=44',
      'treatment_name': 'Postpartum - 90 mins',
      'therapist_name': 'Rina Herlina',
      'is_home_visit': true,
      'is_at_branch': true,
      'date': '18 Apr 2026',
      'time': '14:00 - 15:30',
      'duration': '90 menit',
      'location': 'Jl. Melati No.10 Bandung',
      'status': 'Submitted',
    },
  ];

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
              icon: Icon(Icons.search, color: textDarkBrown),
              onPressed: () {
                 _showInfoMessage(context, 'Fitur pencarian diaktifkan');
              },
            ),
            IconButton(
              icon: Icon(Icons.filter_alt_outlined, color: textDarkBrown),
              onPressed: () {
                 _showInfoMessage(context, 'Membuka menu filter...');
              },
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
                  decoration: InputDecoration(
                    hintText: 'Cari nama customer / treatment',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            // LIST KARTU RIWAYAT
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _historyData.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildHistoryCard(_historyData[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
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
                backgroundImage: NetworkImage(data['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['customer_name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown),
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
                    const Icon(Icons.check, size: 12, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      data['status'],
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
          Text(data['treatment_name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text('Therapist Name by ${data['therapist_name']}', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
          
          const SizedBox(height: 10),
          
          // BADGE LOKASI (Home Visit / At Branch)
          Row(
            children: [
              if (data['is_home_visit'])
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
              if (data['is_at_branch'])
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
                    Text('Date: ${data['date']}', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text('Duration: ${data['duration']}', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${data['time']}', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text('Branch / Address: ${data['location']}', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8))),
          
          const SizedBox(height: 16),
          
          // TOMBOL AKSI DIAKTIFKAN
          Row(
            children: [
              // Tombol View Report
              InkWell(
                onTap: () => _navigateToDetail(data), // NAVIGASI AKTIF
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: primaryPeach, borderRadius: BorderRadius.circular(8)),
                  child: const Text(' View Report ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const Spacer(),
              
              // Tombol panah Chevron
              IconButton(
                icon: Icon(Icons.chevron_right, color: textDarkBrown),
                onPressed: () => _navigateToDetail(data), // NAVIGASI AKTIF
              ),
            ],
          ),
        ],
      ),
    );
  }
}