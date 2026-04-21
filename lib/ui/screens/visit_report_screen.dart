import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // Listener untuk menghitung jumlah karakter secara real-time
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
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.grey.shade800,
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
      // Menambahkan URL gambar acak sebagai simulasi foto yang diunggah
      _photos.add('https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/150/150');
    });
  }

  void _hapusFoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _simpanDraft() {
    if (_notesController.text.isEmpty && _photos.isEmpty) {
      _showSnackbar('Draft masih kosong', isSuccess: false);
      return;
    }
    _showSnackbar('Draft Laporan berhasil disimpan');
  }

  void _submitReport() {
    if (_notesController.text.trim().isEmpty) {
      _showSnackbar('Catatan Internal wajib diisi!', isSuccess: false);
      return;
    }
    _showSnackbar('Laporan Kunjungan berhasil disubmit!');
    // Setelah sukses submit, kembali ke halaman sebelumnya
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/baground2.jpeg'), // Mempertahankan background pola
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Menutup keyboard saat tap area kosong
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCatatanCard(),
                const SizedBox(height: 20),
                _buildFotoCard(),
                const SizedBox(height: 100), // Spasi bawah agar tidak tertutup tombol
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

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
        style: TextStyle(
          color: textDarkBrown,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: textDarkBrown),
          onPressed: () {
            _showSnackbar('Menu opsi tambahan', isSuccess: false);
          },
        ),
      ],
    );
  }

  Widget _buildCatatanCard() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan Terapis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textDarkBrown,
                ),
              ),
              Text(
                'Wajib',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textRequiredOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Input Field Box
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
                    counterText: '', // Menghilangkan default counter bawaan TextField
                  ),
                ),
                // Custom Counter di pojok kanan bawah
                Text(
                  '$_charCount / $_maxChar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto Pendukung (${_photos.length} Foto)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textDarkBrown,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid Foto & Tombol Tambah
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // List foto yang sudah ditambahkan
              ..._photos.asMap().entries.map((entry) {
                int index = entry.key;
                String url = entry.value;
                return _buildPhotoThumbnail(url, index);
              }).toList(),
              
              // Tombol "Tambah"
              if (_photos.length < 5) // Batasi maksimal 5 foto
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
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12,
                            color: textDarkBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Tombol hapus di pojok kanan atas
        Positioned(
          top: -4,
          right: -4,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Tombol Simpan Draft
            Expanded(
              child: ElevatedButton(
                onPressed: _simpanDraft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonDraftGray,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  ' Simpan Draft ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Tombol Submit Report
            Expanded(
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      ' Submit Report ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}