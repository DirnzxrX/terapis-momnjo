import 'package:flutter/material.dart';
import 'package:therapist_momnjo/data/api_service.dart'; 

class VisitReportScreen extends StatefulWidget {
  const VisitReportScreen({Key? key}) : super(key: key);

  @override
  State<VisitReportScreen> createState() => _VisitReportScreenState();
}

class _VisitReportScreenState extends State<VisitReportScreen> {
  // --- WARNA DESAIN ---
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPink = const Color(0xFFFF8A9B); 
  final Color buttonDraftGray = const Color(0xFF9E9E9E);
  final Color textRequiredOrange = const Color(0xFFC06B52);
  final Color appBarCream = const Color(0xFFFAF3E6);

  // --- STATE VARIABEL ---
  final TextEditingController _notesController = TextEditingController();
  int _charCount = 0;
  final int _maxChar = 500;
  
  // Simulasi daftar foto
  final List<String> _photos = []; 

  // --- STATE UNTUK API & RATING ---
  Map<String, dynamic>? _bookingData;
  bool _isDataLoaded = false;
  bool _isLoading = false;
  
  int _rating = 0; 
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Ramah', 'Tepat Waktu', 'Kooperatif', 
    'Ruangan Bersih', 'Banyak Maunya', 'Sulit Dihubungi'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bookingData = args;
      }
      _isDataLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _notesController.addListener(() {
      setState(() {
        _charCount = _notesController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- HELPER FUNGSI ---
  void _showSnackbar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _simulasikanTambahFoto() {
    if (_photos.length >= 5) {
      _showSnackbar('Maksimal 5 foto pendukung', isSuccess: false);
      return;
    }
    setState(() {
      _photos.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/150/150');
    });
  }

  void _hapusFoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  // 🔥 FUNGSI BARU: SKIP LAPORAN
  void _skipReport() {
    _showSnackbar('Laporan dilewati. Bisa diisi nanti di menu Riwayat.');
    
    // Langsung banting ke layar Home tanpa submit ke API
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  // --- FUNGSI SUBMIT KE API BACKEND ---
  Future<void> _submitReport() async {
    if (_rating == 0) {
      _showSnackbar('Harap berikan rating bintang untuk klien!', isSuccess: false);
      return;
    }
    if (_notesController.text.trim().isEmpty) {
      _showSnackbar('Catatan Internal wajib diisi!', isSuccess: false);
      return;
    }

    final String idTransaksi = _bookingData?['id_transaksi']?.toString() ?? '';
    if (idTransaksi.isEmpty) {
      _showSnackbar('Error: ID Transaksi tidak ditemukan.', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final result = await api.rateCustomer(
        idTransaksi: idTransaksi,
        rating: _rating,
        tags: _selectedTags,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      if (result['status'] == 'success' || result['success'] == true) {
        _showSnackbar('Laporan Kunjungan berhasil disubmit!');
        
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        });
      } else {
        _showSnackbar(result['message'] ?? 'Gagal menyimpan laporan', isSuccess: false);
      }
    } catch (e) {
      if (mounted) _showSnackbar('Kesalahan jaringan: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), 
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoKlien(),
                const SizedBox(height: 20),
                _buildRatingCard(), 
                const SizedBox(height: 20),
                _buildCatatanCard(),
                const SizedBox(height: 20),
                _buildFotoCard(),
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: appBarCream,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textDarkBrown),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Laporan Kunjungan',
        style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w900, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        // Tombol Skip ditaruh juga di pojok kanan atas biar gampang dijangkau
        TextButton(
          onPressed: _isLoading ? null : _skipReport,
          child: Text('Lewati', style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInfoKlien() {
    String namaKlien = _bookingData?['customer_name']?.toString() ?? _bookingData?['customer_fullname']?.toString() ?? 'Klien';
    String idTransaksi = _bookingData?['id_transaksi']?.toString() ?? '-';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin, color: primaryPink, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaKlien, style: TextStyle(fontWeight: FontWeight.bold, color: textDarkBrown, fontSize: 15)),
                Text('TRX: $idTransaksi', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Penilaian Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
              Text('Wajib', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textRequiredOrange)),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? Colors.amber.shade500 : Colors.grey.shade300,
                    size: 42,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0 ? 'Ketuk bintang untuk menilai' : '$_rating dari 5 Bintang',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          
          Text('Sikap Klien (Pilih minimal 1)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : textDarkBrown, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: primaryPink,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? primaryPink : Colors.grey.shade300),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) _selectedTags.add(tag);
                    else _selectedTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Catatan Internal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
              Text('Wajib', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textRequiredOrange)),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 6,
                  maxLength: _maxChar,
                  style: TextStyle(fontSize: 14, color: textDarkBrown),
                  decoration: InputDecoration(
                    hintText: 'Ketik laporan detail mengenai kondisi klien, treatment yang diberikan, dan catatan penting lainnya di sini...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    counterText: '', 
                  ),
                ),
                Text('$_charCount / $_maxChar', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Pendukung (${_photos.length} Foto)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._photos.asMap().entries.map((entry) {
                int index = entry.key;
                String url = entry.value;
                return _buildPhotoThumbnail(url, index);
              }).toList(),
              
              if (_photos.length < 5) 
                InkWell(
                  onTap: _simulasikanTambahFoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: textDarkBrown, size: 24),
                        const SizedBox(height: 6),
                        Text('Tambah', style: TextStyle(fontSize: 12, color: textDarkBrown, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String url, int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
            onPressed: () => _hapusFoto(index),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 🔥 TOMBOL LEWATI
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _skipReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonDraftGray,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(' Lewati ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            
            // TOMBOL SUBMIT
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(' Submit Report ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}