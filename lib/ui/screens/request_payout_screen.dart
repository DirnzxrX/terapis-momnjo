import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
  
  // 🔥 STATE BARU UNTUK MEMISAHKAN SALDO
  int _availableBalance = 0; // Nominal yang tampil di layar
  int _saldoTreatment = 0; // Nominal asli treatment
  int _saldoPaket = 0; // Nominal asli paket

  bool _isInit = true; // Penanda untuk membaca argumen pertama kali

  @override
  void initState() {
    super.initState();
    _fetchBalance(); // Menarik data saldo asli dari API

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
      if (args != null && args is String) {
        if (args.toLowerCase() == 'paket') {
          _selectedJenisPayout = 'paket';
        } else {
          _selectedJenisPayout = 'treatment';
        }
      }
      _isInit = false;
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

  // --- FUNGSI MENGAMBIL SALDO ASLI DARI API ---
  Future<void> _fetchBalance() async {
    try {
      final api = ApiService();
      final response = await api.getBalance(); 

      if (mounted) {
        setState(() {
          if ((response['success'] == true || response['status'] == 'success') && response['data'] != null) {
            final data = response['data'];
            
            // 🔥 MENGAMBIL DATA MASING-MASING SEPERTI DI EARNINGS SCREEN
            final Map<String, dynamic> treatmentData = data['treatment'] ?? {};
            final Map<String, dynamic> paketData = data['paket'] ?? {};

            // Mengambil saldo total spesifik yang bisa ditarik
            _saldoTreatment = (double.tryParse(treatmentData['total_balance_treatment']?.toString() ?? '0') ?? 0.0).toInt();
            _saldoPaket = (double.tryParse(paketData['total_balance_paket']?.toString() ?? '0') ?? 0.0).toInt();

            // Set tampilan awal sesuai dropdown yang sedang aktif (default: treatment)
            _updateDisplayedBalance();
          }
          _isLoadingBalance = false;
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

  // 🔥 FUNGSI BARU UNTUK MERUBAH TAMPILAN SALDO SAAT DROPDOWN DIUBAH
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
            'Request Payout',
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
                  label: 'Amount',
                  hint: 'Masukkan nominal',
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

                Text('Bank Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                const SizedBox(height: 8),
                _buildDropdownField(),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Account Number',
                  hint: 'Nomor Rekening',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Account Holder Name',
                  hint: 'Nama Pemilik Rekening',
                  controller: _accountNameController,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Notes (Optional)',
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
          Text('Available Balance', style: TextStyle(color: textDarkBrown.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
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
          Text('Withdrawable Today', style: TextStyle(color: textDarkBrown.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Widget baru untuk Dropdown Jenis Saldo
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
                // 🔥 PANGGIL FUNGSI INI AGAR SALDO OTOMATIS BERUBAH
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
              Text('Requested Amount:', style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600)),
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
                ' Submit Payout Request ',
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