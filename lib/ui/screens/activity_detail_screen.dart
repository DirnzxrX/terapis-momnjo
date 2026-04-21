import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({Key? key}) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  // --- WARNA DESAIN SESUAI MOCKUP ---
  final Color primaryPeach = const Color(0xFFECA898); // Warna header solid
  final Color textDarkBrown = const Color(0xFF4A332B); // Warna teks
  final Color bgBaseColor = const Color(0xFFFDF6F5); // Warna latar belakang krem terang

  Map<String, dynamic>? _activityData;
  bool _isInitialized = false;

  // State untuk Bagian 5 (Rating dari Terapis)
  int _therapistRating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _notesController = TextEditingController();

  final List<String> _ratingTags = [
    'Ramah', 'Tepat Waktu', 'Kooperatif', 
    'Sulit', 'Lingkungan Bersih', 'Responsif'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _activityData = args;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitRating() {
    if (_therapistRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap berikan rating (bintang) terlebih dahulu.')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating berhasil dikirim!')),
    );

    setState(() {
      _activityData?['is_rated_by_therapist'] = true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // Data fallback jika dibuka tanpa argumen
    final data = _activityData ?? {
      'customer_name': 'Sarah Johnson',
      'treatment_name': 'Postpartum Massage - 90 mins',
      'type': 'Home Visit',
      'date': '26 Oktober 2026',
      'start_time': '14:00',
      'end_time': '15:30',
      'duration': '90 mnt',
      'avatar': 'https://i.pravatar.cc/150?img=43',
      'customer_rating': 4.0,
      'customer_feedback': 'Customer sangat terbantu dengan pijatan yang diberikan dan komplain terselesaikan dengan baik.',
    };

    // PERBAIKAN ARSITEKTUR UI: 
    // Membuang Container Background Image. Halaman detail WAJIB menggunakan solid color 
    // agar tulisan padat tetap terbaca dengan nyaman.
    return Scaffold(
      backgroundColor: bgBaseColor, // Latar belakang krem terang sesuai mockup
      appBar: AppBar(
        backgroundColor: primaryPeach, // Header peach solid sesuai mockup
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDarkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Aktivitas',
          style: TextStyle(color: textDarkBrown, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Menambah padding atas
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection1CustomerInfo(data),
              const SizedBox(height: 16),
              _buildSection2TreatmentInfo(data),
              const SizedBox(height: 16),
              _buildSection3TimeInfo(data),
              const SizedBox(height: 16),
              _buildSection4CustomerRating(data),
              const SizedBox(height: 16),
              
              if (data['is_rated_by_therapist'] != true)
                _buildSection5TherapistRatesCustomer(),
                
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildBaseCard({required String titleNumber, required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Kartu warna putih solid agar menonjol dari latar belakang krem
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, // Sedikit diperbesar agar nomor lebih jelas
                height: 24,
                decoration: BoxDecoration(color: textDarkBrown, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(titleNumber, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textDarkBrown)),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  // 1. Informasi Pelanggan
  Widget _buildSection1CustomerInfo(Map<String, dynamic> data) {
    return _buildBaseCard(
      titleNumber: '1',
      title: 'Informasi Pelanggan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, backgroundImage: NetworkImage(data['avatar'] ?? 'https://i.pravatar.cc/150')),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['customer_name'] ?? '-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
                  const SizedBox(height: 2),
                  Text('ID: 1234454667', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor Pelanggan', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('105187700', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor Telepon', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('+122 3452 7899', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tipe Layanan:', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Text(data['type'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Alamat:', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Text('131 Place Rive, Marilira 70081', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 2. Informasi Treatment
  Widget _buildSection2TreatmentInfo(Map<String, dynamic> data) {
    return _buildBaseCard(
      titleNumber: '2',
      title: 'Informasi Treatment',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: textDarkBrown),
              children: [
                const TextSpan(text: 'Nama Treatment: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: data['treatment_name'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: textDarkBrown),
              children: [
                const TextSpan(text: 'Nama Terapis: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: 'Maria Chen'), // Simulasi
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Catatan / Keluhan Pelanggan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text(
            'Catatan pelanggan dan keluhan untuk permintaan tambahan koordinasi.',
            style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8)),
          ),
          const SizedBox(height: 12),
          Text('Permintaan Tambahan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text('-', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8))),
        ],
      ),
    );
  }

  // 3. Informasi Waktu
  Widget _buildSection3TimeInfo(Map<String, dynamic> data) {
    return _buildBaseCard(
      titleNumber: '3',
      title: 'Informasi Waktu',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: Icon(Icons.schedule, color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(height: 4),
              Text(data['start_time'] ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkBrown)),
            ],
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2)),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.hourglass_bottom, color: Colors.red.shade300, size: 20),
              ),
              const SizedBox(height: 4),
              Text(data['end_time'] ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkBrown)),
            ],
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2)),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: Icon(Icons.timer_outlined, color: Colors.orange.shade400, size: 20),
              ),
              const SizedBox(height: 4),
              Text('Total: ${data['duration'] ?? '-'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textDarkBrown)),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Penilaian Pelanggan
  Widget _buildSection4CustomerRating(Map<String, dynamic> data) {
    int rating = (data['customer_rating'] as double?)?.toInt() ?? 0;
    
    return _buildBaseCard(
      titleNumber: '4',
      title: 'Penilaian Pelanggan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text('$rating of 5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${data['customer_feedback'] ?? '-'}"',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: textDarkBrown.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text('Customer Feedback', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 5. Terapis Menilai Pelanggan
  Widget _buildSection5TherapistRatesCustomer() {
    return _buildBaseCard(
      titleNumber: '5',
      title: 'Terapis Menilai Pelanggan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nilai Pelanggan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 8),
          
          // Bintang Interaktif
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _therapistRating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    index < _therapistRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Chips Karakteristik
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ratingTags.map((tag) {
              bool isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? textDarkBrown : Colors.white,
                    border: Border.all(color: isSelected ? textDarkBrown : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : textDarkBrown,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Kolom Catatan
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: textDarkBrown),
            decoration: InputDecoration(
              hintText: 'Catatan tambahan...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryPeach),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF88A989), // Hijau sage sesuai desain
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Kirim Penilaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}