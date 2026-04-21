import 'package:flutter/material.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class PemeriksaanScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData; 
  
  const PemeriksaanScreen({Key? key, this.bookingData}) : super(key: key);

  @override
  State<PemeriksaanScreen> createState() => _PemeriksaanScreenState();
}

class _PemeriksaanScreenState extends State<PemeriksaanScreen> {
  final Color bgOuter = const Color(0xFFC07B6A);
  final Color bgInner = const Color(0xFFF4EBE1);
  final Color cardColor = Colors.white;
  final Color inputColor = const Color(0xFFECDAC9);
  final Color textDark = const Color(0xFF2D1A11);
  final Color buttonColor = const Color(0xFF97463C);

  final TextEditingController _suhuController = TextEditingController();
  final TextEditingController _tinggiController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _sistolikController = TextEditingController();
  final TextEditingController _diastolikController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  final ValueNotifier<int> _catatanLength = ValueNotifier<int>(0);
  final int _maxCatatanLength = 500;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _catatanController.addListener(() => _catatanLength.value = _catatanController.text.length);
  }

  @override
  void dispose() {
    _suhuController.dispose(); 
    _tinggiController.dispose(); 
    _beratController.dispose();
    _sistolikController.dispose(); 
    _diastolikController.dispose(); 
    _catatanController.dispose();
    _catatanLength.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    final suhu = _suhuController.text;
    final tinggi = _tinggiController.text;
    final berat = _beratController.text;
    final sistolik = _sistolikController.text;
    final diastolik = _diastolikController.text;
    final catatan = _catatanController.text;

    if (suhu.isEmpty || tinggi.isEmpty || berat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suhu, Tinggi, dan Berat tidak boleh kosong!'), backgroundColor: Colors.redAccent));
      return;
    }

    final args = widget.bookingData ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Log untuk pengecekan di terminal
    debugPrint("DEBUG: Data yang diterima di Pemeriksaan: $args");

    String idTransaksi = (args?['id_transaksi'] ?? args?['id_booking'] ?? '').toString();
    
    // --- PERBAIKAN: SEKARANG MENGAMBIL ID CUSTOMER DARI API BARU ---
    String idCustomer = (args?['id_customer'] ?? '').toString();

    if (idTransaksi.isEmpty || idTransaksi == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: ID Transaksi tidak ditemukan.'), backgroundColor: Colors.redAccent));
      return;
    }
    
    // Validasi tambahan agar error lebih jelas jika Backend lupa mengirim ID Customer lagi
    if (idCustomer.isEmpty || idCustomer == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: ID Customer tidak ditemukan dari data booking.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService().storeDataMedis(
        idTransaksi: idTransaksi,
        idCustomer: idCustomer, // Menggunakan ID yang asli dari Backend
        suhu: suhu, 
        tinggi: tinggi, 
        berat: berat,
        sistolik: sistolik, 
        diastolik: diastolik,
        catatan: catatan,
      );

      if (!mounted) return;

      if (result['status'] == 'success' || result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Data pemeriksaan berhasil disimpan!'), backgroundColor: buttonColor));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kesalahan jaringan: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgOuter,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: bgInner, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(children: [
                          GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.arrow_back_ios_new, color: textDark, size: 20)),
                          const SizedBox(width: 16),
                          Text('Pemeriksaan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark)),
                        ]),
                      ),
                      Divider(color: Colors.black.withOpacity(0.05), height: 1, thickness: 2),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildCardPemeriksaan(),
                            const SizedBox(height: 20),
                            _buildCardCatatan(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: bgInner,
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Row(
            children: [
              // TOMBOL SIMPAN (KIRI) - TANPA IKON
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(backgroundColor: buttonColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              // TOMBOL SKIP (KANAN)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: buttonColor, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: Text('Skip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: buttonColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPemeriksaan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.monitor_heart_outlined, color: buttonColor, size: 24), const SizedBox(width: 8), Text('Tanda Vital & Fisik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark))]),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _buildInputField('Suhu', '°C', _suhuController, isDecimal: true)), const SizedBox(width: 16), Expanded(child: _buildInputField('Tinggi', 'cm', _tinggiController))]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _buildInputField('Berat', 'kg', _beratController, isDecimal: true)), const SizedBox(width: 16), const Expanded(child: SizedBox())]),
          const SizedBox(height: 24),
          Text('Tekanan Darah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _buildInputField('Sistolik', 'mmHg', _sistolikController)), const SizedBox(width: 16), Expanded(child: _buildInputField('Diastolik', 'mmHg', _diastolikController))]),
        ],
      ),
    );
  }

  Widget _buildCardCatatan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.edit_note_outlined, color: buttonColor, size: 24), const SizedBox(width: 8), Text('Catatan Tambahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark))]),
              ValueListenableBuilder<int>(valueListenable: _catatanLength, builder: (context, value, child) => Text('$value/$_maxCatatanLength', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _catatanController, maxLines: 5, maxLength: _maxCatatanLength,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(hintText: 'Tambahkan catatan...', filled: true, fillColor: inputColor.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String suffix, TextEditingController controller, {bool isDecimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark.withOpacity(0.8))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: isDecimal), 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), suffixText: suffix),
          ),
        ),
      ],
    );
  }
}