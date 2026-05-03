import 'package:flutter/material.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart'; // Jangan lupa import intl untuk format waktu

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({Key? key}) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  // --- WARNA DESAIN SESUAI MOCKUP ---
  final Color primaryPeach = const Color(0xFFECA898); 
  final Color textDarkBrown = const Color(0xFF4A332B); 
  final Color bgBaseColor = const Color(0xFFFDF6F5); 

  String _idTransaksi = '';
  Map<String, dynamic>? _detailData;
  bool _isLoadingDetail = true;
  bool _isSubmittingRating = false;
  String? _errorMessage;

  // State untuk Bagian 4 (Catatan Laporan dari Terapis)
  final TextEditingController _notesController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_idTransaksi.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _idTransaksi = args['id_transaksi']?.toString() ?? args['id_booking']?.toString() ?? '';
        if (_idTransaksi.isNotEmpty) {
          _fetchDetail();
        } else {
          setState(() {
            _isLoadingDetail = false;
            _errorMessage = 'ID Transaksi tidak ditemukan.';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- FUNGSI TARIK DATA DETAIL DARI API ---
  Future<void> _fetchDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.getHistoryDetail(_idTransaksi);

      if (response['status'] == 'success' || response['success'] == true) {
        if (mounted) {
          setState(() {
            _detailData = response['data'];
            _isLoadingDetail = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat detail aktivitas.';
            _isLoadingDetail = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kesalahan jaringan: $e';
          _isLoadingDetail = false;
        });
      }
    }
  }

  // --- FUNGSI SUBMIT LAPORAN (TANPA BINTANG/TAGS) ---
  Future<void> _submitRating() async {
    setState(() => _isSubmittingRating = true);

    try {
      final api = ApiService();
      final response = await api.rateCustomer(
        idTransaksi: _idTransaksi,
        rating: 0, // Default 0 karena sistem bintang dihilangkan
        tags: [],  // Default list kosong karena sistem tags dihilangkan
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmittingRating = false);
        if (response['status'] == 'success' || response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan berhasil dikirim!'), backgroundColor: Colors.green),
          );
          _fetchDetail(); // Refresh data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mengirim catatan.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kesalahan jaringan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBaseColor, 
      appBar: AppBar(
        backgroundColor: primaryPeach, 
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
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoadingDetail) {
      return Center(child: CircularProgressIndicator(color: primaryPeach));
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
              onPressed: _fetchDetail,
              style: ElevatedButton.styleFrom(backgroundColor: primaryPeach),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (_detailData == null) {
      return const Center(child: Text('Data tidak ditemukan.'));
    }

    final infoPelanggan = _detailData!['informasi_pelanggan'] ?? {};
    final infoTreatment = _detailData!['informasi_treatment'] ?? {};
    final infoWaktu = _detailData!['informasi_waktu'] ?? {};
    final rateTerapis = _detailData!['penilaian_terapis'] ?? {};

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'TRX: $_idTransaksi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textDarkBrown.withOpacity(0.5), letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSection1CustomerInfo(infoPelanggan),
            const SizedBox(height: 16),
            _buildSection2TreatmentInfo(infoTreatment),
            const SizedBox(height: 16),
            
            // 🔥 Lempar infoTreatment juga untuk ambil datanya
            _buildSection3TimeInfo(infoWaktu, infoTreatment),
            const SizedBox(height: 16),
            
            rateTerapis['is_submitted'] == true 
                ? _buildSection4TherapistRatingReadOnly(rateTerapis)
                : _buildSection4TherapistRatesCustomerForm(),
                
            const SizedBox(height: 40),
          ],
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
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, 
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
              CircleAvatar(
                radius: 28, 
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(data['customer_avatar'] ?? 'https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['customer_name'] ?? '-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
                    const SizedBox(height: 2),
                    Text('ID: ${data['customer_id'] ?? '-'}', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.7))),
                  ],
                ),
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
                    Text(data['customer_no'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor Telepon', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(data['phone'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tipe Layanan:', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Text(data['tipe_layanan'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Alamat:', style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Text(data['alamat'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.w600)),
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
                TextSpan(text: data['therapist_name'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Catatan / Keluhan Pelanggan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text(
            data['notes'] != null && data['notes'].toString().isNotEmpty ? data['notes'] : '-',
            style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8)),
          ),
          const SizedBox(height: 12),
          Text('Permintaan Tambahan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 4),
          Text(data['extra_request'] ?? '-', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8))),
        ],
      ),
    );
  }

  // 🔥 3. INFORMASI WAKTU DENGAN KALKULASI PINTAR (Di-Update)
  Widget _buildSection3TimeInfo(Map<String, dynamic> dataWaktu, Map<String, dynamic> dataTreatment) {
    String rawStart = dataWaktu['start_time']?.toString() ?? '';
    String rawEnd = dataWaktu['end_time']?.toString() ?? '';
    String rawDuration = dataWaktu['total_duration']?.toString() ?? '';

    if (rawStart.toLowerCase() == 'null') rawStart = '';
    if (rawEnd.toLowerCase() == 'null') rawEnd = '';
    if (rawDuration.toLowerCase() == 'null') rawDuration = '';

    // Ekstrak durasi (angka)
    int durasiMenit = 0;
    if (rawDuration.isNotEmpty) {
      durasiMenit = int.tryParse(rawDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    // Jika dari waktu tidak ada, coba ambil durasi dari nama treatment (misal: "Deep Tissue 80 min")
    if (durasiMenit == 0) {
      String tName = dataTreatment['treatment_name']?.toString() ?? '';
      final match = RegExp(r'(\d+)\s*(min|menit|mins|m)').firstMatch(tName.toLowerCase());
      if (match != null) {
        durasiMenit = int.tryParse(match.group(1) ?? '60') ?? 60;
      } else {
        durasiMenit = 60; // Fallback kalau gak ketemu angka
      }
    }

    String displayMulai = 'Belum tercatat';
    String displaySelesai = 'Belum tercatat';
    String displayDurasi = (rawDuration.isNotEmpty && rawDuration != '-') ? rawDuration : '$durasiMenit menit';

    if (rawStart.isNotEmpty && rawStart != '-') {
      try {
        DateTime startDt = DateTime.parse(rawStart);
        displayMulai = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDt);
        
        if (rawEnd.isNotEmpty && rawEnd != '-') {
          DateTime endDt = DateTime.parse(rawEnd);
          displaySelesai = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDt);
        } else {
          // HITUNG OTOMATIS WAKTU SELESAI
          DateTime calculatedEndDt = startDt.add(Duration(minutes: durasiMenit));
          displaySelesai = DateFormat('yyyy-MM-dd HH:mm:ss').format(calculatedEndDt);
        }
      } catch (e) {
        displayMulai = rawStart;
        displaySelesai = rawEnd.isNotEmpty ? rawEnd : 'Belum tercatat';
      }
    }

    return _buildBaseCard(
      titleNumber: '3',
      title: 'Informasi Waktu',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text('Waktu Mulai:', style: TextStyle(fontSize: 13, color: textDarkBrown)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayMulai, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: displayMulai == 'Belum tercatat' ? Colors.redAccent : textDarkBrown
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Row(
            children: [
              Icon(Icons.stop_circle, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              Text('Waktu Selesai:', style: TextStyle(fontSize: 13, color: textDarkBrown)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displaySelesai, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: displaySelesai == 'Belum tercatat' ? Colors.redAccent : textDarkBrown
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Row(
            children: [
              Icon(Icons.timer, color: Colors.orange.shade400, size: 20),
              const SizedBox(width: 8),
              Text('Total Durasi:', style: TextStyle(fontSize: 13, color: textDarkBrown)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayDurasi, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: displayDurasi == '-' ? Colors.redAccent : primaryPeach
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Laporan Kunjungan (HANYA KOLOM CATATAN)
  Widget _buildSection4TherapistRatesCustomerForm() {
    return _buildBaseCard(
      titleNumber: '4',
      title: 'Laporan Kunjungan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catatan / Laporan Pelayanan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(fontSize: 13, color: textDarkBrown),
            decoration: InputDecoration(
              hintText: 'Tuliskan laporan aktivitas atau catatan tambahan di sini...',
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingRating ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF88A989), 
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmittingRating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // 4B. Terapis Menilai Pelanggan (MODE READ-ONLY UNTUK CATATAN SAJA)
  Widget _buildSection4TherapistRatingReadOnly(Map<String, dynamic> data) {
    String notes = data['notes']?.toString() ?? '';

    return _buildBaseCard(
      titleNumber: '4',
      title: 'Laporan Kunjungan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '"$notes"',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: textDarkBrown.withOpacity(0.8)),
              ),
            )
          else
            Text(
              'Anda tidak meninggalkan catatan untuk aktivitas ini.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}