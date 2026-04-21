import 'package:flutter/material.dart';
import 'package:therapist_momnjo/data/api_service.dart';

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

  // State untuk Bagian 5 (Rating dari Terapis)
  int _therapistRating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _notesController = TextEditingController();

  final List<String> _ratingTags = [
    'Ramah', 'Tepat Waktu', 'Kooperatif', 
    'Ruangan Bersih', 'Banyak Maunya', 'Sulit Dihubungi'
  ];

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

  // --- FUNGSI SUBMIT RATING ---
  Future<void> _submitRating() async {
    if (_therapistRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap berikan rating (bintang) terlebih dahulu.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmittingRating = true);

    try {
      final api = ApiService();
      final response = await api.rateCustomer(
        idTransaksi: _idTransaksi,
        rating: _therapistRating,
        tags: _selectedTags,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmittingRating = false);
        if (response['status'] == 'success' || response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating berhasil dikirim!'), backgroundColor: Colors.green),
          );
          _fetchDetail(); // Refresh data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mengirim rating.'), backgroundColor: Colors.redAccent),
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
    final ratePelanggan = _detailData!['penilaian_pelanggan'] ?? {};
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
            
            // 🔥 SECTION WAKTU DENGAN NULL CHECKER SADIS
            _buildSection3TimeInfo(infoWaktu),
            
            const SizedBox(height: 16),
            _buildSection4CustomerRating(ratePelanggan),
            const SizedBox(height: 16),
            
            rateTerapis['is_submitted'] == true 
                ? _buildSection5TherapistRatingReadOnly(rateTerapis)
                : _buildSection5TherapistRatesCustomerForm(),
                
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

  // 🔥 3. INFORMASI WAKTU DENGAN NULL CHECKER
  Widget _buildSection3TimeInfo(Map<String, dynamic> data) {
    String rawStart = data['start_time']?.toString() ?? '';
    String rawEnd = data['end_time']?.toString() ?? '';
    String rawDuration = data['total_duration']?.toString() ?? '';

    // Antisipasi string "null" dari balasan PHP
    if (rawStart.toLowerCase() == 'null') rawStart = '';
    if (rawEnd.toLowerCase() == 'null') rawEnd = '';
    if (rawDuration.toLowerCase() == 'null') rawDuration = '';

    // Set fallback biar kelihatan jelas kalau backend emang kosong
    String startTimeStr = rawStart.isNotEmpty ? rawStart : 'Belum tercatat';
    String endTimeStr = rawEnd.isNotEmpty ? rawEnd : 'Belum tercatat';
    String totalDuration = rawDuration.isNotEmpty ? rawDuration : '-';

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
                  startTimeStr, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: startTimeStr == 'Belum tercatat' ? Colors.redAccent : textDarkBrown
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
                  endTimeStr, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: endTimeStr == 'Belum tercatat' ? Colors.redAccent : textDarkBrown
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
                  totalDuration, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: totalDuration == '-' ? Colors.redAccent : primaryPeach
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

  // 4. Penilaian Pelanggan
  Widget _buildSection4CustomerRating(Map<String, dynamic> data) {
    bool isRated = data['is_rated'] ?? false;

    if (!isRated) {
      return _buildBaseCard(
        titleNumber: '4',
        title: 'Penilaian Pelanggan',
        content: Text(
          'Pelanggan belum memberikan ulasan untuk layanan ini.',
          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
        ),
      );
    }

    int rating = int.tryParse(data['stars']?.toString() ?? '0') ?? 0;
    
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
            '"${data['feedback'] ?? '-'}"',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: textDarkBrown.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text('Customer Feedback', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 5. Terapis Menilai Pelanggan (MODE FORM)
  Widget _buildSection5TherapistRatesCustomerForm() {
    return _buildBaseCard(
      titleNumber: '5',
      title: 'Terapis Menilai Pelanggan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nilai Pelanggan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 8),
          
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
                  : const Text('Kirim Penilaian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // 5B. Terapis Menilai Pelanggan (MODE READ-ONLY)
  Widget _buildSection5TherapistRatingReadOnly(Map<String, dynamic> data) {
    int rating = int.tryParse(data['stars']?.toString() ?? '0') ?? 0;
    List<dynamic> submittedTags = data['tags'] ?? [];
    String notes = data['notes']?.toString() ?? '';

    return _buildBaseCard(
      titleNumber: '5',
      title: 'Laporan & Penilaian Anda',
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
          
          if (submittedTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: submittedTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryPeach.withOpacity(0.1),
                    border: Border.all(color: primaryPeach),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag.toString(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDarkBrown),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

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
            ),
        ],
      ),
    );
  }
}