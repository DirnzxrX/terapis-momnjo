import 'package:flutter/material.dart';

class DetailLaporanScreen extends StatefulWidget {
  // PERBAIKAN: Dibuat opsional agar tidak error saat didaftarkan di rute main.dart
  final Map<String, dynamic>? reportData;

  const DetailLaporanScreen({Key? key, this.reportData}) : super(key: key);

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> with SingleTickerProviderStateMixin {
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);
  final Color badgeGreenBg = const Color(0xFFE8F5E9);
  final Color badgeGreenText = const Color(0xFF2E7D32);
  final Color badgeOrangeBg = const Color(0xFFFFF3E0);
  final Color badgeOrangeText = const Color(0xFFE65100);

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper untuk mendapatkan data baik dari constructor maupun dari Navigator arguments
  Map<String, dynamic> _getEffectiveData() {
    if (widget.reportData != null) return widget.reportData!;
    
    // Mencoba mengambil data dari rute rute (jika dipanggil via pushNamed)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args;
    }
    
    // Data cadangan (fallback) agar aplikasi tidak crash jika tidak ada data sama sekali
    return {
      'customer_name': 'Sarah Johnson',
      'avatar': 'https://i.pravatar.cc/150?img=43',
      'treatment_name': 'Pijat Pascamelahirkan - 90 mnt',
      'therapist_name': 'Rina Herlina',
      'date': '18 Apr 2026',
      'location': 'MomNJo Darmawangsa',
      'status': 'Submitted',
      'is_home_visit': true,
    };
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: child,
        ),
      ),
    );
  }

  void _showImagePreview(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _getEffectiveData(); // Mengambil data yang tersedia

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
          leadingWidth: 100,
          leading: TextButton.icon(
            icon: Icon(Icons.arrow_back, color: textDarkBrown, size: 20),
            label: Text('Kembali', style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              Text('Laporan Kunjungan', style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Laporan Pekerjaan Selesai', style: TextStyle(color: textDarkBrown.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAnimatedCard(_buildHeaderCard(data), 0),
              _buildAnimatedCard(_buildProgresTreatmentCard(), 1),
              _buildAnimatedCard(_buildCatatanTerapisCard(), 2),
              _buildAnimatedCard(_buildHasilKlienCard(), 3),
              _buildAnimatedCard(_buildFotoPendukungCard(), 4),
              _buildAnimatedCard(_buildInfoPelacakanCard(), 5),
              _buildAnimatedCard(_buildCustomerFeedbackCard(), 6),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(data['avatar'] ?? 'https://i.pravatar.cc/150?img=43'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['customer_name'] ?? 'Sarah Johnson',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['treatment_name'] ?? 'Pijat Pascamelahirkan - 90 mnt',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(Icons.check, 'Dikirim', badgeGreenBg, badgeGreenText),
                        const SizedBox(width: 8),
                        _buildBadge(Icons.home, 'Kunjungan Rumah', badgeOrangeBg, badgeOrangeText),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          _buildInfoRowCompact('Terapis:', data['therapist_name'] ?? 'Rina Herlina'),
          const SizedBox(height: 6),
          _buildInfoRowCompact('Tanggal:', '${data['date'] ?? '18 Apr 2026'} - 15:30'),
          const SizedBox(height: 6),
          _buildInfoRowCompact('Cabang / Alamat:', data['location'] ?? 'MomNJo Darmawangsa'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: badgeGreenBg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: badgeGreenText),
                    const SizedBox(width: 6),
                    Text('Disetujui oleh Admin', style: TextStyle(color: badgeGreenText, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('18 Apr 2026 15:40', style: TextStyle(color: badgeGreenText, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresTreatmentCard() {
    final List<String> progres = [
      'Konsultasi Awal',
      'Persiapan Peralatan',
      'Perawatan Utama',
      'Penyelesaian',
      'Edukasi Pelanggan'
    ];

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progres Treatment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          ...progres.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check, size: 18, color: Colors.black87),
                const SizedBox(width: 8),
                Text(item, style: TextStyle(fontSize: 14, color: textDarkBrown, fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCatatanTerapisCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catatan Terapis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E6), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Pelanggan merasa rileks setelah sesi. Tidak ada keluhan selama perawatan. Disarankan hidrasi dan istirahat. Disarankan perawatan lanjutan minggu depan.',
              style: TextStyle(fontSize: 13, color: textDarkBrown, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasilKlienCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hasil Klien', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEmojiChip('😁', 'Sangat Puas', badgeOrangeBg),
              _buildEmojiChip('😊', 'Nyaman', badgeOrangeBg),
              _buildEmojiChip('👍', 'Direkomendasikan', badgeOrangeBg),
              _buildEmojiChip('📌', 'Perlu Tindak Lanjut', badgeOrangeBg),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Catatan Pelanggan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text('(Opsional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pelanggan meminta terapis yang sama untuk pemesanan berikutnya',
            style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPendukungCard() {
    final photos = [
      {'url': 'https://picsum.photos/seed/1/300/200', 'label': 'Persiapan Ruangan'},
      {'url': 'https://picsum.photos/seed/2/300/200', 'label': 'Peralatan Siap'},
      {'url': 'https://picsum.photos/seed/3/300/200', 'label': 'Area Perawatan'},
      {'url': 'https://picsum.photos/seed/4/300/200', 'label': 'Foto Penyelesaian'},
    ];

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Pendukung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePreview(photos[index]['url']!, photos[index]['label']!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(photos[index]['url']!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                          ),
                          child: Text(
                            photos[index]['label']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPelacakanCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Info Pelacakan Kunjungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          _buildTrackingRow(Icons.location_on_outlined, 'Waktu Kedatangan:', '13:55'),
          const SizedBox(height: 8),
          _buildTrackingRow(Icons.play_circle_outline, 'Mulai Perawatan:', '14:00'),
          const SizedBox(height: 8),
          _buildTrackingRow(Icons.stop_circle_outlined, 'Selesai Perawatan:', '15:30'),
          const SizedBox(height: 8),
          _buildTrackingRow(Icons.timer_outlined, 'Total Durasi:', '90 mnt'),
          const SizedBox(height: 8),
          _buildTrackingRow(Icons.verified_outlined, 'GPS Terverifikasi:', 'Ya'),
        ],
      ),
    );
  }

  Widget _buildCustomerFeedbackCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 18)),
              ),
              const SizedBox(width: 8),
              Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDarkBrown)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Terapis luar biasa, sangat profesional dan lembut.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- SMALL HELPERS ---

  Widget _buildBadge(IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRowCompact(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmojiChip(String emoji, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: textDarkBrown, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTrackingRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.bold)),
      ],
    );
  }
}