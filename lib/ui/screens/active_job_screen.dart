import 'package:flutter/material.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({Key? key}) : super(key: key);

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryPink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Aktif',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Latar Belakang Pink Bagian Atas
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: primaryPink,
                  ),
                  
                  // Konten Utama
                  Column(
                    children: [
                      // 1. Header Info Pelanggan
                      _buildHeaderInfo(),
                      
                      const SizedBox(height: 16),
                      
                      // 2. Card Timer
                      _buildTimerCard(),
                      
                      const SizedBox(height: 24),
                      
                      // 3. Progress Treatment
                      _buildProgressSection(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 4. Tombol Aksi Bawah
          _buildBottomActions(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Dewi Lestari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mother Care Massage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.call_outlined, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Durasi Berjalan',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '00:25:18',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Sisa Estimasi',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '64:41',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Treatment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '2 dari 5 selesai',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          // List Progress
          _buildProgressItem('Konsultasi & Anamnesa', isDone: true),
          _buildProgressItem('Persiapan', isDone: true),
          _buildProgressItem('Massage Punggung', isDone: false),
          _buildProgressItem('Massage Kaki', isDone: false),
          _buildProgressItem('Relaksasi & Finishing', isDone: false),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, {required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? Colors.green : Colors.transparent,
              border: Border.all(
                color: isDone ? Colors.green : Colors.grey.shade400,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.check,
              size: 14,
              color: isDone ? Colors.white : Colors.transparent,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDone ? Colors.black87 : Colors.grey.shade700,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Pause
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pause, color: primaryPink, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Pause',
                    style: TextStyle(color: primaryPink, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Tombol Selesai Treatment
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Selesai Treatment',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}