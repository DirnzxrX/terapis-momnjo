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

  // --- VARIABEL KOTAK PINK DARI API (SEBAGAI FALLBACK) ---
  double _totalKomisiAllTime = 0;
  double _komisiTreatmentAllTime = 0;
  double _komisiPaketAllTime = 0;

  // --- VARIABEL OMSET API (SEBAGAI FALLBACK) ---
  double _pendapatanKotorTreatment = 0;
  double _totalPenjualanPaket = 0;
  
  // --- VARIABEL LIST RIWAYAT ---
  List<dynamic> _rincianTreatment = []; 
  List<dynamic> _rincianPaket = [];
  List<dynamic> _payoutHistory = [];

  // State DateRange untuk Filter
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // 🔥 PERMINTAAN: Default awal adalah Semua Waktu (Tanpa Filter)
    _selectedDateRange = null; 
    _fetchAllData();
  }

  void _fetchAllData() {
    _fetchEarningsData();
    _fetchPayoutHistory();
  }

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
      initialDateRange: _selectedDateRange,
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
      // Panggil ulang API untuk update data Omset saja
      _fetchEarningsData();
    }
  }

  // --- FUNGSI TARIK API PENDAPATAN (BALANCE) ---
  Future<void> _fetchEarningsData() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. SELALU AMBIL DATA ALL-TIME UNTUK KOTAK PINK (PAYOUT)
      final respAllTime = await ApiService().getBalance();
      Map<String, dynamic> dataAllTime = {};
      if (respAllTime['status'] == 'success' || respAllTime['success'] == true) {
        dataAllTime = respAllTime['data'] ?? {};
      }

      // 2. AMBIL DATA FILTER JIKA TANGGAL DIPILIH UNTUK OMSET
      Map<String, dynamic> dataFiltered = dataAllTime;
      if (_selectedDateRange != null) {
        String startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        String endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        final respFiltered = await ApiService().getBalance(startDate: startStr, endDate: endStr);
        if (respFiltered['status'] == 'success' || respFiltered['success'] == true) {
          dataFiltered = respFiltered['data'] ?? {};
        }
      }

      setState(() {
        // --- DATA KOTAK PINK (JANGAN BERUBAH OLEH FILTER TANGGAL) ---
        _totalKomisiAllTime = _parseDouble(dataAllTime['total_balance_keseluruhan']);
        final Map<String, dynamic> tAllTime = dataAllTime['treatment'] ?? {};
        final Map<String, dynamic> pAllTime = dataAllTime['paket'] ?? {};
        _komisiTreatmentAllTime = _parseDouble(tAllTime['total_balance_treatment'] ?? tAllTime['komisi_treatment']);
        _komisiPaketAllTime = _parseDouble(pAllTime['total_balance_paket'] ?? pAllTime['komisi_paket']);
        
        // --- DATA OMSET DI BAWAH KOTAK PINK (TERPENGARUH FILTER) ---
        final Map<String, dynamic> tFiltered = dataFiltered['treatment'] ?? {};
        final Map<String, dynamic> pFiltered = dataFiltered['paket'] ?? {};
        _pendapatanKotorTreatment = _parseDouble(tFiltered['pendapatan_sebelum_diskon']);
        _totalPenjualanPaket = _parseDouble(pFiltered['harga_paket']);
        
        _isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan jaringan atau sistem.');
      debugPrint('Exception: $e');
    }
  }

  // --- FUNGSI TARIK API RIWAYAT PENARIKAN (PAYOUT) & RINCIAN TREATMENT ---
  Future<void> _fetchPayoutHistory() async {
    try {
      final response = await ApiService().getPayoutHistory();
      
      if (response['status'] == 'success' || response['success'] == true) {
        if (mounted) {
          setState(() {
            final responseData = response['data'];
            
            if (responseData is List) {
              _payoutHistory = responseData;
            } else if (responseData is Map) {
              _payoutHistory = responseData['history'] ?? responseData['data'] ?? responseData['payout_history'] ?? [];
            }

            final balanceInfo = (responseData is Map && responseData.containsKey('balance_info')) 
                ? responseData['balance_info'] 
                : response['balance_info'];

            if (balanceInfo != null) {
              final treatmentData = balanceInfo['treatment'] ?? {};
              final paketData = balanceInfo['paket'] ?? {};

              _rincianTreatment = treatmentData['rincian_treatment'] ?? balanceInfo['rincian_treatment'] ?? [];
              _rincianPaket = paketData['rincian_paket'] ?? balanceInfo['rincian_paket'] ?? [];
            }
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
    if (_selectedDateRange == null) return 'Semua Waktu';
    String start = DateFormat('dd MMM yyyy').format(_selectedDateRange!.start);
    String end = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);
    if (start == end) return start; // Jika pilih 1 hari yang sama
    return '$start - $end';
  }

  // 🔥 FUNGSI FILTER LIST LOKAL AGAR DAFTAR SESUAI TANGGAL YANG DIPILIH
  List<dynamic> _filterListByDate(List<dynamic> list, String dateFieldKey) {
    if (_selectedDateRange == null) return list; // Kembalikan semua jika tidak ada filter
    
    return list.where((item) {
      String tgl = item[dateFieldKey] ?? item['created_at'] ?? '';
      if (tgl.isEmpty) return true; // Tampilkan saja jika tidak ada data tanggal
      
      try {
        DateTime dt = DateTime.parse(tgl);
        DateTime start = _selectedDateRange!.start;
        DateTime end = _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) && 
               dt.isBefore(end.add(const Duration(seconds: 1)));
      } catch (e) {
        return true;
      }
    }).toList();
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Komisi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey.shade700, size: 26),
                    onPressed: _fetchAllData, 
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 2. Row Periode (Mendukung Penghapusan Filter)
            if (_selectedTab != 'Riwayat Payout')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Periode', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        if (_selectedDateRange != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedDateRange = null);
                              _fetchEarningsData(); // Kembalikan ke Semua Waktu
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.cancel, color: Colors.grey.shade400, size: 22),
                            ),
                          ),
                        GestureDetector(
                          onTap: _pickDateRange, 
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  ],
                ),
              ),

            // 3. Card Dinamis (Komisi / Payout)
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
    String mainTitle = _selectedTab == 'Treatment' ? 'Total Komisi Treatment' : 'Total Komisi Paket';
    String subTitle = _selectedTab == 'Treatment' ? 'Total Omset Keseluruhan' : 'Total Penjualan Paket';
    
    // 🔥 PERBAIKAN: Hitung jumlah Omset dan Komisi 100% dari data yang ada di list (Dinamis & Pasti Akurat)
    double calculatedKomisi = 0;
    double calculatedOmset = 0;

    if (_selectedTab == 'Treatment') {
      final filteredList = _filterListByDate(_rincianTreatment, 'tgl_dokumen');
      for (var item in filteredList) {
        double omsetItem = _parseDouble(item['pendapatan_sebelum_diskon']);
        double komisiItem = _parseDouble(item['komisi']);
        
        // Terapkan 5% otomatis jika komisi 0
        if (komisiItem <= 0 && omsetItem > 0) {
          komisiItem = omsetItem * 0.05;
        }
        
        calculatedOmset += omsetItem;
        calculatedKomisi += komisiItem;
      }
      
      // Jika kosong (karena API belum meload rincian), gunakan fallback API mentah
      if (calculatedKomisi == 0 && _komisiTreatmentAllTime > 0) calculatedKomisi = _komisiTreatmentAllTime;
      if (calculatedOmset == 0 && _pendapatanKotorTreatment > 0) calculatedOmset = _pendapatanKotorTreatment;

    } else {
      final filteredList = _filterListByDate(_rincianPaket, 'tgl_transaksi');
      for (var item in filteredList) {
        double hargaItem = _parseDouble(item['harga_paket']);
        double komisiItem = _parseDouble(item['komisi']);
        
        if (komisiItem <= 0 && hargaItem > 0) {
          komisiItem = hargaItem * 0.05;
        }
        
        calculatedOmset += hargaItem;
        calculatedKomisi += komisiItem;
      }

      if (calculatedKomisi == 0 && _komisiPaketAllTime > 0) calculatedKomisi = _komisiPaketAllTime;
      if (calculatedOmset == 0 && _totalPenjualanPaket > 0) calculatedOmset = _totalPenjualanPaket;
    }

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
                // Tampilkan hasil hitungan dinamis
                Text(formatRupiah(calculatedKomisi), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                
                // 🔥 TOMBOL REQUEST PAYOUT
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context, 
                        '/request_payout',
                        arguments: _selectedTab.toLowerCase(), 
                      );
                      
                      if (result == true) {
                        setState(() => _selectedTab = 'Riwayat Payout');
                        _fetchAllData(); 
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
              children: [
                _buildSubEarning(subTitle, formatRupiah(calculatedOmset)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard() {
    // Sama seperti di atas, kita pastikan angka total keseluruhan komisi juga dihitung bersih dari daftar 5%
    double calculatedTotalKeseluruhan = 0;
    
    for (var item in _rincianTreatment) {
      double omset = _parseDouble(item['pendapatan_sebelum_diskon']);
      double komisi = _parseDouble(item['komisi']);
      if (komisi <= 0 && omset > 0) komisi = omset * 0.05;
      calculatedTotalKeseluruhan += komisi;
    }
    for (var item in _rincianPaket) {
      double harga = _parseDouble(item['harga_paket']);
      double komisi = _parseDouble(item['komisi']);
      if (komisi <= 0 && harga > 0) komisi = harga * 0.05;
      calculatedTotalKeseluruhan += komisi;
    }
    
    // Jika karena suatu alasan array kosong, gunakan angka mentah backend
    if (calculatedTotalKeseluruhan == 0 && _totalKomisiAllTime > 0) {
      calculatedTotalKeseluruhan = _totalKomisiAllTime;
    }

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
          Text(formatRupiah(calculatedTotalKeseluruhan), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
    // Terapkan Filter Tanggal ke List
    final filteredList = _filterListByDate(_rincianTreatment, 'tgl_dokumen');

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada riwayat treatment.', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final namaTreatment = item['product_name'] ?? 'Treatment Tidak Diketahui';
        final qty = item['quantity'] ?? 1;
        
        final pendapatanKotorItem = _parseDouble(item['pendapatan_sebelum_diskon']);
        double komisiItem = _parseDouble(item['komisi']);

        // 🔥 PERBAIKAN: Jika API mengirim komisi 0, hitung otomatis 5% dari harga
        if (komisiItem <= 0 && pendapatanKotorItem > 0) {
          komisiItem = pendapatanKotorItem * 0.05;
        }
        
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
    // Terapkan Filter Tanggal ke List Paket
    final filteredList = _filterListByDate(_rincianPaket, 'tgl_transaksi');

    if (filteredList.isEmpty) {
      return Center(
        child: Text('Belum ada penjualan paket.', style: TextStyle(color: Colors.grey.shade500))
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final namaPaket = item['package_custom_name'] ?? 'Paket Tidak Diketahui';
        final hargaPaket = _parseDouble(item['harga_paket']);
        double komisiItem = _parseDouble(item['komisi']);

        // 🔥 PERBAIKAN: Jika API mengirim komisi 0, hitung otomatis 5% dari harga paket
        if (komisiItem <= 0 && hargaPaket > 0) {
          komisiItem = hargaPaket * 0.05;
        }
        
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

  Widget _buildPayoutListView() {
    // Bisa difilter juga (opsional), namun untuk Riwayat Payout seringkali dibiarkan semua
    // Di sini kita biarkan semua saja karena ini halaman payout history
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