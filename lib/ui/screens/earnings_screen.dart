import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final Color mockupPink = const Color(0xFFE8647C); 
  final Color bgLight = const Color(0xFFFFF7F7); 

  // Default tab 'Treatment'
  String _selectedTab = 'Treatment'; 
  bool _isLoading = true;

  // --- VARIABEL UNTUK MENAMPUNG DATA API ---
  double _totalKomisi = 0;
  
  // Treatment Data
  double _pendapatanKotorTreatment = 0;
  double _pendapatanBersihTreatment = 0;
  double _komisiTreatment = 0;
  List<dynamic> _rincianTreatment = []; 

  // Paket Data
  double _totalPenjualanPaket = 0;
  double _komisiPaket = 0;
  List<dynamic> _rincianPaket = [];

  // Payout History Data
  List<dynamic> _payoutHistory = [];

  // Periode Data
  String _startDate = '';
  String _endDate = '';
  
  // State tambahan untuk nyimpen pilihan tanggal dari kalender
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    
    // 🔥 SET DEFAULT PERIODE: Bulan Berjalan
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0), // Hari terakhir bulan ini
    );

    // Ambil data pertama kali berdasarkan range default
    _fetchDataForSelectedRange();
  }

  // 🔥 FUNGSI PEMBANTU UNTUK MEMANGGIL API BERDASARKAN FILTER
  void _fetchDataForSelectedRange() {
    if (_selectedDateRange != null) {
      String start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      String end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      _fetchEarningsData(start: start, end: end);
    } else {
      _fetchEarningsData();
    }
    
    // Panggil juga API Riwayat Payout
    _fetchPayoutHistory();
  }

  // 🔥 HELPER AMAN UNTUK PARSING ANGKA DARI JSON PHP
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // 🔥 BUKA KALENDER FILTER PERIODE
  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime(now.year + 5);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0), // Akhir bulan berjalan
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: mockupPink, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      
      // Panggil data dengan tanggal yang baru dipilih
      _fetchDataForSelectedRange();
    }
  }

  // --- FUNGSI TARIK API PENDAPATAN ---
  Future<void> _fetchEarningsData({String? start, String? end}) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService().getBalance(startDate: start, endDate: end);

      if (response['status'] == 'success' || response['success'] == true) {
        final data = response['data'] ?? {};

        setState(() {
          _totalKomisi = _parseDouble(data['total_balance_keseluruhan']);
          
          final Map<String, dynamic> treatmentData = data['treatment'] ?? {};
          final Map<String, dynamic> paketData = data['paket'] ?? {};
          
          // Parsing Treatment
          _pendapatanKotorTreatment = _parseDouble(treatmentData['pendapatan_sebelum_diskon']);
          _pendapatanBersihTreatment = _parseDouble(treatmentData['pendapatan_setelah_diskon']);
          _komisiTreatment = _parseDouble(treatmentData['komisi_treatment']);
          _rincianTreatment = treatmentData['rincian_treatment'] ?? data['rincian_treatment'] ?? []; 

          // Parsing Paket
          _totalPenjualanPaket = _parseDouble(paketData['harga_paket']);
          _komisiPaket = _parseDouble(paketData['komisi_paket']);
          _rincianPaket = paketData['rincian_paket'] ?? data['rincian_paket'] ?? [];
          
          _startDate = data['periode']?['start_date'] ?? '';
          _endDate = data['periode']?['end_date'] ?? '';

          _isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Gagal mengambil data pendapatan');
      }
    } catch (e) {
      _showError('Terjadi kesalahan jaringan atau sistem.');
      debugPrint('Exception: $e');
    }
  }

  // --- FUNGSI TARIK API RIWAYAT PENARIKAN (PAYOUT) ---
  Future<void> _fetchPayoutHistory() async {
    try {
      final response = await ApiService().getPayoutHistory();
      if (response['status'] == 'success' || response['success'] == true) {
        if (mounted) {
          setState(() {
            _payoutHistory = response['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Exception fetching payout history: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating, 
      ));
    }
  }

  String _getPeriodeText() {
    if (_selectedDateRange == null) return 'Bulan Ini';
    String start = DateFormat('dd MMM').format(_selectedDateRange!.start);
    String end = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8647C)))
          : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Komisi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey.shade700, size: 26),
                    onPressed: _fetchDataForSelectedRange, 
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 2. Row Periode (Disembunyikan jika di tab Riwayat Payout)
            if (_selectedTab != 'Riwayat Payout')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Periode', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    GestureDetector(
                      onTap: _pickDateRange, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, color: mockupPink, size: 16),
                            const SizedBox(width: 6),
                            Text(_getPeriodeText(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Card Dinamis
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedTab == 'Riwayat Payout' ? _buildPayoutCard() : _buildEarningsCard(),
            ),
            
            const SizedBox(height: 24),

            // 4. Custom Tabs
            _buildTabs(),
            const SizedBox(height: 24),

            // 5. Container List Riwayat Dinamis
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildListViewContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    String mainTitle = _selectedTab == 'Treatment' ? 'Komisi Treatment' : 'Komisi Paket';
    double mainAmount = _selectedTab == 'Treatment' ? _komisiTreatment : _komisiPaket;

    return Container(
      key: ValueKey('EarningsCard_$_selectedTab'),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: mockupPink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: mockupPink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                Text(mainTitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(formatRupiah(mainAmount), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                
                // 🔥 TOMBOL REQUEST PAYOUT
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/request_payout');
                      if (result == true) {
                        setState(() => _selectedTab = 'Riwayat Payout');
                        _fetchDataForSelectedRange(); // Ambil update terbaru (termasuk riwayat) setelah berhasil
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Riwayat Penarikan Dana sedang diperbarui...'), backgroundColor: Colors.green),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC2185B), 
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(' Request Payout ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _selectedTab == 'Treatment' 
                ? [
                    // Menggunakan pendapatan kotor
                    _buildSubEarning('Total Omset', formatRupiah(_pendapatanKotorTreatment)),
                  ]
                : [
                    _buildSubEarning('Total Penjualan Paket', formatRupiah(_totalPenjualanPaket)),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard() {
    return Container(
      key: const ValueKey('PayoutCard'),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: mockupPink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: mockupPink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('Total Komisi Keseluruhan', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(formatRupiah(_totalKomisi), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Keseluruhan komisi yang Anda dapatkan', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSubEarning(String label, String amount) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(amount, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = ['Treatment', 'Paket', 'Riwayat Payout'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? mockupPink : Colors.white,
                  borderRadius: BorderRadius.circular(20), 
                  boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12, 
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListViewContent() {
    if (_selectedTab == 'Treatment') {
      return _buildTreatmentListView(); 
    } else if (_selectedTab == 'Paket') {
      return _buildPaketListView();
    } else {
      return _buildPayoutListView();
    }
  }

  Widget _buildTreatmentListView() {
    if (_rincianTreatment.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada riwayat treatment pada periode ini.', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _rincianTreatment.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _rincianTreatment[index];
        final namaTreatment = item['product_name'] ?? 'Treatment Tidak Diketahui';
        final qty = item['quantity'] ?? 1;
        
        final komisiItem = _parseDouble(item['komisi']);
        final pendapatanKotorItem = _parseDouble(item['pendapatan_sebelum_diskon']);
        
        String tglDokumen = item['tgl_dokumen'] ?? '';
        String jam = item['jam'] ?? '';
        
        String displayDate = tglDokumen;
        String displayTime = jam;

        try {
          if (tglDokumen.isNotEmpty) {
            DateTime dt = DateTime.parse(tglDokumen);
            displayDate = DateFormat('dd MMM yyyy').format(dt);
          }
          if (jam.isNotEmpty) {
            DateTime dtTime = DateTime.parse('${tglDokumen.isNotEmpty ? tglDokumen : '1970-01-01'} $jam');
            displayTime = DateFormat('HH:mm').format(dtTime);
          }
        } catch (e) {}

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                      if (displayTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(displayTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ]
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaTreatment, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Harga: ${formatRupiah(pendapatanKotorItem)}  •  Qty: $qty', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+ ${formatRupiah(komisiItem)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text('Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaketListView() {
    if (_rincianPaket.isEmpty) {
      return Center(
        child: Text('Belum ada penjualan paket pada periode ini.', style: TextStyle(color: Colors.grey.shade500))
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _rincianPaket.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _rincianPaket[index];
        final namaPaket = item['package_custom_name'] ?? 'Paket Tidak Diketahui';
        final hargaPaket = _parseDouble(item['harga_paket']);
        final komisiItem = _parseDouble(item['komisi']);
        
        String tglTransaksi = item['tgl_transaksi'] ?? '';
        String displayDatePaket = tglTransaksi;
        String displayTimePaket = '';

        try {
          if (tglTransaksi.isNotEmpty) {
            DateTime dt = DateTime.parse(tglTransaksi);
            displayDatePaket = DateFormat('dd MMM yyyy').format(dt);
            displayTimePaket = DateFormat('HH:mm').format(dt);
          }
        } catch (e) {}

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayDatePaket, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                      if (displayTimePaket.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(displayTimePaket, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ]
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaPaket, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Harga: ${formatRupiah(hargaPaket)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+ ${formatRupiah(komisiItem)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text('Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 FUNGSI BARU UNTUK RENDER LIST RIWAYAT ASLI DARI API
  Widget _buildPayoutListView() {
    if (_payoutHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada riwayat penarikan dana.', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _payoutHistory.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _payoutHistory[index];
        
        // Menerapkan UI / UX berdasarkan dokumentasi API Payout History
        final String status = (item['status'] ?? 'pending').toString().toLowerCase();
        final String idPayout = item['id_payout']?.toString() ?? '-';
        final double amount = _parseDouble(item['requested_amount']);
        final String note = item['note']?.toString() ?? '';
        
        String displayDate = item['created_at'] ?? '';
        try {
          if (displayDate.isNotEmpty) {
            DateTime dt = DateTime.parse(displayDate);
            displayDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
          }
        } catch (_) {}

        Color statusColor = Colors.amber.shade700;
        Color statusBgColor = Colors.amber.shade100;
        String statusText = 'Pending';

        if (status == 'pending' || status == 'on_process') {
          statusColor = Colors.amber.shade700;
          statusBgColor = Colors.amber.shade100;
          statusText = status == 'on_process' ? 'Diproses' : 'Pending';
        } else if (status == 'approved' || status == 'completed') {
          statusColor = Colors.green.shade700;
          statusBgColor = Colors.green.shade100;
          statusText = status == 'completed' ? 'Selesai' : 'Disetujui';
        } else if (status == 'rejected') {
          statusColor = Colors.red.shade700;
          statusBgColor = Colors.red.shade100;
          statusText = 'Ditolak';
        }

        return InkWell(
          onTap: () {
            // Membuka detail menggunakan item
            Navigator.pushNamed(context, '/history_detail_payout', arguments: item);
          },
          borderRadius: BorderRadius.circular(8), 
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('ID: PY-$idPayout', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      Text(formatRupiah(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(note, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor, 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6, 
                            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                          ),
                          const SizedBox(width: 6),
                          Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}