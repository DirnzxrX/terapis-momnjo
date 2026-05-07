import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart'; 

class RequestPayoutScreen extends StatefulWidget {
  const RequestPayoutScreen({Key? key}) : super(key: key);

  @override
  State<RequestPayoutScreen> createState() => _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends State<RequestPayoutScreen> {
  // --- WARNA DESAIN ---
  final Color bgLight = const Color(0xFFFDF6F5); 
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPink = const Color(0xFFE8647C); 

  // --- STATE FORM ---
  String _selectedJenisPayout = 'treatment'; // Default ke saldo treatment
  String? _selectedBank;
  final List<String> _bankList = ['BCA', 'Mandiri', 'BNI', 'BRI', 'BSI', 'CIMB Niaga'];
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isConfirmed = false;
  String _displayAmount = 'Rp 0';

  // --- STATE API ---
  bool _isLoadingBalance = true;
  bool _isSubmitting = false;
  
  // 🔥 STATE BARU UNTUK MEMISAHKAN SALDO DAN TANGGAL
  int _availableBalance = 0; // Nominal yang tampil di layar
  int _saldoTreatment = 0; // Nominal asli treatment
  int _saldoPaket = 0; // Nominal asli paket
  
  String? _startDate;
  String? _endDate;

  bool _isInit = true; // Penanda untuk membaca argumen pertama kali

  @override
  void initState() {
    super.initState();

    _amountController.addListener(() {
      setState(() {
        if (_amountController.text.trim().isEmpty) {
          _displayAmount = 'Rp 0';
        } else {
          _displayAmount = 'Rp ${_amountController.text.trim()}';
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Menangkap argumen yang dikirim dari EarningsScreen
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is Map) {
          // Tangkap tab dan parameter tanggal
          final tab = args['tab']?.toString().toLowerCase() ?? 'treatment';
          _selectedJenisPayout = tab == 'paket' ? 'paket' : 'treatment';
          _startDate = args['startDate'];
          _endDate = args['endDate'];
        } else if (args is String) {
          // Fallback jika arguments hanya berupa string (nama tab)
          _selectedJenisPayout = args.toLowerCase() == 'paket' ? 'paket' : 'treatment';
        }
      }
      
      _isInit = false;
      // 🔥 LANGSUNG TEMBAK API MENGGUNAKAN TANGGAL YANG SUDAH DITANGKAP
      _fetchBalance(); 
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- HELPER UNTUK PARSING DAN FILTER TANGGAL SECARA IDENTIK ---
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<dynamic> _filterListByDate(List<dynamic> list, String primaryKey, {String? fallbackKey}) {
    if (_startDate == null || _endDate == null) return list; 
    
    return list.where((item) {
      String tgl = item[primaryKey] ?? (fallbackKey != null ? item[fallbackKey] : null) ?? item['created_at'] ?? '';
      if (tgl.isEmpty) return true; 
      
      try {
        DateTime dt = DateTime.parse(tgl);
        DateTime start = DateTime.parse(_startDate!);
        DateTime end = DateTime.parse(_endDate!).add(const Duration(hours: 23, minutes: 59, seconds: 59));
        
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) && 
               dt.isBefore(end.add(const Duration(seconds: 1)));
      } catch (e) {
        return true;
      }
    }).toList();
  }

  // --- FUNGSI MENGAMBIL SALDO DARI API LALU DIHITUNG IDENTIK DENGAN EARNINGS ---
  Future<void> _fetchBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final api = ApiService();
      
      // 🔥 TEMBAK KEDUA API (BALANCE DAN HISTORY) MENGGUNAKAN FILTER TANGGAL
      final balanceRes = await api.getBalance(startDate: _startDate, endDate: _endDate); 
      final historyRes = await api.getPayoutHistory(startDate: _startDate, endDate: _endDate);

      if (mounted) {
        double omsetTreatment = 0;
        double komisiTreatment = 0;
        double omsetPaket = 0;
        double komisiPaket = 0;
        
        List<dynamic> rincianTreatment = [];
        List<dynamic> rincianPaket = [];

        // 1. EKSTRAK DARI BALANCE API
        if (balanceRes['success'] == true || balanceRes['status'] == 'success') {
          final data = balanceRes['data'] ?? {};
          final Map<String, dynamic> tData = data['treatment'] ?? {};
          final Map<String, dynamic> pData = data['paket'] ?? {};

          omsetTreatment = _parseDouble(tData['total_omset_treatment'] ?? tData['pendapatan_sebelum_diskon'] ?? tData['total_omset']);
          komisiTreatment = _parseDouble(tData['total_komisi_treatment'] ?? tData['komisi_treatment'] ?? tData['total_komisi'] ?? tData['total_balance_treatment']);

          omsetPaket = _parseDouble(pData['total_omset_paket'] ?? pData['harga_paket'] ?? pData['total_omset']);
          komisiPaket = _parseDouble(pData['total_komisi_paket'] ?? pData['komisi_paket_bersih'] ?? pData['total_komisi'] ?? pData['total_balance_paket']);
        }

        // 2. EKSTRAK DARI HISTORY API
        if (historyRes['success'] == true || historyRes['status'] == 'success') {
          final hData = historyRes['data'];
          final balanceInfo = (hData is Map && hData.containsKey('balance_info')) ? hData['balance_info'] : historyRes['balance_info'];

          if (balanceInfo != null) {
            final tData = balanceInfo['treatment'] ?? {};
            final pData = balanceInfo['paket'] ?? {};

            rincianTreatment = tData['rincian_treatment'] ?? balanceInfo['rincian_treatment'] ?? [];
            
            List<dynamic> listPaketGabungan = [];
            if (pData['rincian_paket'] != null) listPaketGabungan.addAll(pData['rincian_paket']);
            if (pData['rincian_override'] != null) listPaketGabungan.addAll(pData['rincian_override']);
            if (listPaketGabungan.isEmpty && balanceInfo['rincian_paket'] != null) {
              listPaketGabungan.addAll(balanceInfo['rincian_paket']);
            }
            rincianPaket = listPaketGabungan;
          }
        }

        // 3. FILTER HISTORY SESUAI TANGGAL (Persis Seperti Earnings Screen)
        final filteredTreatment = _filterListByDate(rincianTreatment, 'tgl_dokumen');
        final filteredPaket = _filterListByDate(rincianPaket, 'tgl_transaksi', fallbackKey: 'tgl_dokumen');

        // 4. SINKRONISASI LOGIKA PERHITUNGAN MENGGUNAKAN DATA API TERBARU
        if (komisiTreatment < (omsetTreatment * 0.04)) {
          double sumKomisi = 0;
          for (var item in filteredTreatment) {
            double o = _parseDouble(item['pendapatan_sebelum_diskon'] ?? item['harga'] ?? item['total_omset']);
            double k = _parseDouble(item['komisi_treatment'] ?? item['komisi_terapis'] ?? item['komisi_kotor'] ?? item['komisi_bersih'] ?? item['komisi']);
            if (k <= 0 && o > 0) k = o * 0.05; 
            sumKomisi += k;
          }
          if (sumKomisi > 0) komisiTreatment = sumKomisi;
        }

        if (komisiPaket < (omsetPaket * 0.04)) {
          double sumKomisi = 0;
          for (var item in filteredPaket) {
            bool isOverrideDeduction = item.containsKey('overriding_terapis') && item.containsKey('potongan_komisi');
            if (isOverrideDeduction) {
              sumKomisi -= _parseDouble(item['potongan_komisi']);
            } else {
              double o = _parseDouble(item['harga_paket'] ?? item['harga'] ?? item['omset']);
              double k = _parseDouble(item['komisi_paket_bersih'] ?? item['komisi_bersih'] ?? item['komisi_terapis'] ?? item['komisi']);
              if (k <= 0 && o > 0) k = o * 0.05; 
              sumKomisi += k;
            }
          }
          if (sumKomisi > 0) komisiPaket = sumKomisi;
        }

        setState(() {
          // Tetapkan saldo mutlak
          _saldoTreatment = komisiTreatment.toInt();
          _saldoPaket = komisiPaket.toInt();
          _isLoadingBalance = false;
          _updateDisplayedBalance();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat saldo. Periksa koneksi Anda.')),
        );
      }
    }
  }

  // 🔥 FUNGSI UNTUK MERUBAH TAMPILAN SALDO SAAT DROPDOWN DIUBAH
  void _updateDisplayedBalance() {
    setState(() {
      if (_selectedJenisPayout == 'treatment') {
        _availableBalance = _saldoTreatment;
      } else if (_selectedJenisPayout == 'paket') {
        _availableBalance = _saldoPaket;
      }
    });
  }

  // --- FUNGSI FORMAT RUPIAH MANUAL ---
  String _formatRupiah(int value) {
    String number = value.toString();
    String result = '';
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      count++;
      if (count % 3 == 0 && i > 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  // --- FUNGSI SUBMIT REQUEST PAYOUT KE API ---
  Future<void> _submitPayout() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap masukkan nominal penarikan!')));
      return;
    }
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih bank tujuan!')));
      return;
    }
    if (_accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor dan Nama Rekening wajib diisi!')));
      return;
    }
    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda harus mencentang konfirmasi data!')));
      return;
    }

    // Membersihkan format titik menjadi integer murni untuk dikirim ke API
    String rawAmount = _amountController.text.replaceAll('.', '');
    int amountToSubmit = int.tryParse(rawAmount) ?? 0;

    // Validasi Saldo Cukup berdasarkan saldo dinamis yang sedang tampil
    if (amountToSubmit > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saldo Anda tidak mencukupi untuk nominal ini!'),
          backgroundColor: Colors.red.shade400,
        )
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final api = ApiService();
      final response = await api.submitPayoutRequest(
        jenisPayout: _selectedJenisPayout, 
        amount: amountToSubmit,
        bank: _selectedBank!,
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountNameController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true || response['status'] == 'success') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Permintaan penarikan dana Anda telah masuk antrean proses.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context, true); // Kembali & beri tanda bahwa request sukses
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengirim permintaan payout.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Terjadi kesalahan. Periksa koneksi internet Anda.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDarkBrown),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Permohonan Penarikan',
            style: TextStyle(color: textDarkBrown, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 24),
                
                Text('Sumber Saldo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                const SizedBox(height: 8),
                _buildJenisPayoutDropdown(),
                const SizedBox(height: 20),
                
                _buildInputField(
                  label: 'Jumlah',
                  hint: 'Masukkan Nominal',
                  controller: _amountController,
                  prefixWidget: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                    child: Text(
                      'Rp', 
                      style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyFormat()], 
                ),
                const SizedBox(height: 20),

                Text('Akun Bank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                const SizedBox(height: 8),
                _buildDropdownField(),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Nomor',
                  hint: 'Nomor Rekening',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Nama',
                  hint: 'Nama Pemilik Rekening',
                  controller: _accountNameController,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Catatan (Optional)',
                  hint: 'Catatan tambahan',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                _buildSummaryBox(),
                const SizedBox(height: 24),

                _buildConfirmationCheckbox(),
                const SizedBox(height: 24),

                _buildSubmitButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildBalanceCard() {
    String periodeText = 'Hari Ini';
    
    // Tampilkan label tanggal jika sedang menggunakan filter
    if (_startDate != null && _endDate != null) {
      if (_startDate == _endDate) {
        try {
          periodeText = 'pada ${DateFormat('dd MMM yyyy').format(DateTime.parse(_startDate!))}';
        } catch (_) {}
      } else {
        try {
          periodeText = 'Periode ${DateFormat('dd MMM').format(DateTime.parse(_startDate!))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(_endDate!))}';
        } catch (_) {}
      }
    } else {
       periodeText = 'pada ${DateFormat('dd MMM yyyy').format(DateTime.now())}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.15), 
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Saldo yang Tersedia', style: TextStyle(color: textDarkBrown.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          
          // Indikator loading atau nominal asli
          _isLoadingBalance
              ? const SizedBox(
                  height: 38,
                  width: 38,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Text(_formatRupiah(_availableBalance), style: TextStyle(color: textDarkBrown, fontSize: 32, fontWeight: FontWeight.w900)),
          
          const SizedBox(height: 4),
          Text(
            _startDate != null ? 'Sesuai Filter $periodeText' : 'Dapat Ditarik $periodeText', 
            style: TextStyle(color: textDarkBrown.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  // Widget Dropdown Jenis Saldo
  Widget _buildJenisPayoutDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedJenisPayout,
          icon: Icon(Icons.keyboard_arrow_down, color: textDarkBrown),
          style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15),
          items: const [
            DropdownMenuItem(value: 'treatment', child: Text('Saldo Layanan (Treatment)')),
            DropdownMenuItem(value: 'paket', child: Text('Saldo Paket')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedJenisPayout = newValue;
                // PANGGIL FUNGSI INI AGAR SALDO OTOMATIS BERUBAH
                _updateDisplayedBalance();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label, 
    required String hint, 
    required TextEditingController controller,
    Widget? prefixWidget, 
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters, 
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: prefixWidget, 
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: prefixWidget == null ? 16 : 0, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select Bank', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          value: _selectedBank,
          icon: Icon(Icons.keyboard_arrow_down, color: textDarkBrown),
          style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15),
          items: _bankList.map((String bank) {
            return DropdownMenuItem<String>(
              value: bank,
              child: Text(bank),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedBank = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jumlah permintaan:', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600)),
              Text(_displayAmount, style: TextStyle(fontSize: 14, color: textDarkBrown, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Transfer:', style: TextStyle(fontSize: 14, color: textDarkBrown, fontWeight: FontWeight.w900)),
              Text(_displayAmount, style: TextStyle(fontSize: 16, color: textDarkBrown, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isConfirmed,
            activeColor: textDarkBrown,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (bool? value) {
              setState(() {
                _isConfirmed = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              'Saya mengonfirmasi bahwa data penarikan ini sudah benar.',
              style: TextStyle(fontSize: 13, color: textDarkBrown, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting || _isLoadingBalance ? null : _submitPayout, 
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC2185B),
          disabledBackgroundColor: Colors.grey.shade400, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                ' Ajukan Permintaan Permbayaran ',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// ============================================================================
// LOGIKA ARSITEKTUR KUSTOM: FORMATTER MATA UANG RUPIAH
// ============================================================================
class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return newValue.copyWith(text: '');

    String newText = '';
    int count = 0;
    for (int i = numericOnly.length - 1; i >= 0; i--) {
      newText = numericOnly[i] + newText;
      count++;
      if (count % 3 == 0 && i > 0) {
        newText = '.$newText';
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}