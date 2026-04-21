import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // WAJIB untuk TextInputFormatter

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
  String? _selectedBank;
  final List<String> _bankList = ['BCA', 'Mandiri', 'BNI', 'BRI', 'BSI', 'CIMB Niaga'];
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isConfirmed = false;
  String _displayAmount = 'Rp 0';

  @override
  void initState() {
    super.initState();
    // Listener ini sekarang diuntungkan oleh Formatter kita,
    // karena _amountController.text sudah otomatis mengandung titik (e.g., "1.500.000")
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
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitPayout() {
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

    // 🚨 PERINGATAN LOGIKA BACKEND:
    // Karena kita memakai formatter titik (1.500.000), sebelum dikirim ke API/Backend,
    // Anda WAJIB membersihkan titiknya menjadi integer murni, contoh:
    // String rawAmount = _amountController.text.replaceAll('.', '');
    // int amountToSubmit = int.parse(rawAmount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text('Permintaan penarikan dana Anda telah masuk antrean proses.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context, true); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
            child: const Text('OK'),
          )
        ],
      ),
    );
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
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: textDarkBrown),
              onPressed: () {},
            ),
          ],
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
                
                // IMPLEMENTASI FORMATTER DAN PERMANENT PREFIX
                _buildInputField(
                  label: 'Amount',
                  hint: 'Masukkan nominal',
                  controller: _amountController,
                  // Menggunakan Widget statis agar "Rp" selalu muncul dari awal tanpa menunggu fokus
                  prefixWidget: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                    child: Text(
                      'Rp', 
                      style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  // Memanggil formatter kustom yang kita buat di bawah
                  inputFormatters: [CurrencyFormat()], 
                ),
                const SizedBox(height: 20),

                Text('Bank Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                const SizedBox(height: 8),
                _buildDropdownField(),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Account Number',
                  hint: 'Account Number',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Account Holder Name',
                  hint: 'Account Holder Name',
                  controller: _accountNameController,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: 'Notes (Optional)',
                  hint: 'Notes (Optional)',
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
          Text('Rp 2.350.000', style: TextStyle(color: textDarkBrown, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Withdrawable Today', style: TextStyle(color: textDarkBrown.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label, 
    required String hint, 
    required TextEditingController controller,
    Widget? prefixWidget, // Diubah menjadi Widget agar bisa menerima Text statis
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters, // Tambahan parameter Formatter
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
            inputFormatters: inputFormatters, // Menerapkan Formatter di sini
            style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: prefixWidget, // Menggunakan prefixIcon agar statis permanen
              // prefixIconConstraints berfungsi agar kotak 'Rp' tidak memakan terlalu banyak ruang bawaan icon
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
              'I confirm the payout data is correct.',
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
        onPressed: _submitPayout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC2185B),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text(
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
// Memformat teks secara instan saat pengguna mengetik agar titik ribuan 
// diletakkan di tempat yang tepat tanpa merusak perilaku alami kursor.
class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Bersihkan semua input dan ambil hanya angkanya saja
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) return newValue.copyWith(text: '');

    // 2. Susun ulang angkanya dengan titik setiap 3 digit dari belakang
    String newText = '';
    int count = 0;
    for (int i = numericOnly.length - 1; i >= 0; i--) {
      newText = numericOnly[i] + newText;
      count++;
      if (count % 3 == 0 && i > 0) {
        newText = '.$newText';
      }
    }

    // 3. Kembalikan nilai baru beserta posisi kursor yang dijaga di akhir tulisan
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}