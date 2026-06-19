import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart'; // Sesuaikan dengan path ApiService Anda

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  // --- COLOR PALETTE ---
  final Color mockupPink = const Color(0xFFE3889B);     // Warna tombol dan highlight
  final Color bgLight = const Color(0xFFFFF0F2);        // Warna background layar
  final Color cardPink = const Color(0xFFEAA6B4);       // Warna list item bergantian
  final Color textDark = const Color(0xFF2D2D2D);       // Warna teks gelap

  bool _isLoading = true;

  // --- SOURCE OF TRUTH DARI API ---
  double _totalKomisiAllTime = 0; 
  double _komisiReguler = 0;      
  double _komisiRedeem = 0;       
  double _grandTotal = 0;         

  List<dynamic> _rincianTransaksi = []; 

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2).format(amount);
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: mockupPink,
              onPrimary: Colors.white,
              onSurface: textDark,
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
      _fetchEarningsData();
    }
  }

  Future<void> _fetchEarningsData() async {
    setState(() => _isLoading = true);
    
    try {
      String? startStr;
      String? endStr;

      if (_selectedDateRange != null) {
        startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      // Memanggil API Ringkasan dan Detail secara paralel untuk efisiensi
      final summaryFuture = ApiService().getTerapisReportSummary(startDate: startStr, endDate: endStr);
      final detailFuture = ApiService().getTerapisCommissionDetail(startDate: startStr, endDate: endStr);

      final results = await Future.wait([summaryFuture, detailFuture]);
      final responseSummary = results[0];
      final responseDetail = results[1];
      
      if (responseSummary['success'] == true || responseSummary['status'] == 'success') {
        final Map<String, dynamic> dataSum = responseSummary['data'] ?? {};
        final Map<String, dynamic> pendapatan = dataSum['pendapatan_terapis'] ?? {};
        final Map<String, dynamic> pengerjaan = dataSum['pengerjaan_terapis'] ?? {};

        final Map<String, dynamic> dataDet = responseDetail['data'] ?? {};
        final Map<String, dynamic> komisiTerapis = dataDet['komisi_terapis'] ?? {};

        if (mounted) {
          setState(() {
            _totalKomisiAllTime = _parseDouble(pengerjaan['total_nominal']);
            _komisiReguler = _parseDouble(pendapatan['komisi_reguler_5_persen']);
            _komisiRedeem = _parseDouble(pendapatan['komisi_override_5_persen']);
            _grandTotal = _parseDouble(pendapatan['komisi_5_persen']);
            
            _rincianTransaksi = komisiTerapis['items'] ?? [];
            _isLoading = false;
          });
        }
      } else {
         _showError(responseSummary['message'] ?? 'Gagal mengambil data laporan.');
      }
    } catch (e) {
      _showError('Terjadi kesalahan sistem: $e');
      debugPrint('Exception: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // =========================================================================
  // 🔥 FUNGSI BARU: MENAMPILKAN MODAL OVERRIDE (ENDPOINT C)
  // Ini fungsi yang hilang di kode Anda sebelumnya, menyebabkan error kompilasi.
  // =========================================================================
  void _showOverrideModal() {
    String? startStr;
    String? endStr;

    if (_selectedDateRange != null) {
      startStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      endStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 5,
                width: 40,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Detail Komisi Override (Silang)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: ApiService().getTerapisOverrideDetail(startDate: startStr, endDate: endStr),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: mockupPink));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Terjadi kesalahan jaringan.', style: TextStyle(color: Colors.red.shade600)));
                    }

                    final data = snapshot.data ?? {};
                    if (data['status'] != 'success') {
                      return Center(child: Text(data['message'] ?? 'Gagal memuat data.'));
                    }

                    final overrideData = data['data']?['override_komisi'] ?? {};
                    final List items = overrideData['items'] ?? [];

                    if (items.isEmpty) {
                      return Center(child: Text('Tidak ada riwayat komisi silang (override).', style: TextStyle(color: Colors.grey.shade500)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        // Proteksi .toString()
                        final String tglRaw = item['tanggal_redeem']?.toString() ?? '-';
                        final String trxId = item['id_transaksi']?.toString() ?? '-';
                        final String customerName = item['customer_name']?.toString() ?? 'Customer';
                        
                        final String productName = item['product_name']?.toString() ?? '-';
                        final String packageName = item['package_custom_name']?.toString() ?? '-';
                        final String packageId = item['id_package_custom']?.toString() ?? '-';
                        
                        final String terapisPengerjaan = item['terapis_pengerjaan']?.toString() ?? '-';
                        final String terapisPenjual = item['id_terapis']?.toString() ?? '-';
                        
                        final double komisiDidapat = _parseDouble(item['komisi_5_persen']);
                        final String jenisOverride = item['jenis_override']?.toString() ?? '';
                        final String gerai = item['nama_used_gerai']?.toString() ?? '-';

                        bool isMasuk = jenisOverride == 'override_masuk';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isMasuk ? Colors.blue.shade100 : Colors.red.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(tglRaw, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isMasuk ? Colors.blue.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isMasuk ? 'Override Masuk (+)' : 'Override Keluar (-)',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMasuk ? Colors.blue.shade700 : Colors.red.shade700),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Customer: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Trx ID: $trxId', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Penjual Paket: $terapisPenjual', style: TextStyle(fontSize: 12, color: isMasuk ? Colors.grey.shade800 : Colors.red.shade700, fontWeight: isMasuk ? FontWeight.normal : FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Dikerjakan Oleh: $terapisPengerjaan', style: TextStyle(fontSize: 12, color: isMasuk ? Colors.blue.shade700 : Colors.grey.shade800, fontWeight: isMasuk ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text('Pengerjaan: $productName', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              Text('Dari Paket: $packageName ($packageId)', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              Text('Gerai: $gerai', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Komisi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(
                                    formatRupiah(komisiDidapat),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isMasuk ? textDark : Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: const Text(
          'Pendapatan Terapis',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: mockupPink))
          : RefreshIndicator(
              color: mockupPink,
              onRefresh: () async => _fetchEarningsData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateFilter(),
                    const SizedBox(height: 16),
                    _buildMainKomisiCard(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                    const SizedBox(height: 24),
                    _buildTransactionList(),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildDateFilter() {
    String startDate = 'Start Date';
    String endDate = 'End Date';

    if (_selectedDateRange != null) {
      startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    }

    return GestureDetector(
      onTap: _pickDateRange,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(startDate, style: TextStyle(color: _selectedDateRange == null ? Colors.grey.shade400 : textDark, fontSize: 13)),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('End', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(endDate, style: TextStyle(color: _selectedDateRange == null ? Colors.grey.shade400 : textDark, fontSize: 13)),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainKomisiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mockupPink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mockupPink.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Omset',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(_totalKomisiAllTime),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(Icons.shopping_bag_rounded, color: Colors.white70, size: 40),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard('Komisi\nReguler 5%', formatRupiah(_komisiReguler)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallStatCard(
            'Komisi\nRedeem 5%', 
            formatRupiah(_komisiRedeem), 
            isMinus: _komisiRedeem < 0,
            onTap: _showOverrideModal, 
            isClickable: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallStatCard('Total\nKomisi', formatRupiah(_grandTotal)),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String title, String amount, {bool isMinus = false, VoidCallback? onTap, bool isClickable = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isClickable ? Border.all(color: mockupPink.withOpacity(0.5), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3),
                ),
                if (isClickable) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.touch_app, size: 12, color: mockupPink), 
                ]
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMinus ? Colors.red.shade600 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_rincianTransaksi.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rincianTransaksi.length,
      itemBuilder: (context, index) {
        final item = _rincianTransaksi[index];
        final bool isPinkCard = index % 2 != 0; 
        
        final String tglRaw = item['tanggal']?.toString() ?? '1970-01-01';
        final String tgl = tglRaw.split(' ')[0]; 
        final String trxId = item['kode_transaksi']?.toString() ?? 'TRX-UNKNOWN';
        final String customerName = item['customer_name']?.toString() ?? 'Customer';
        final String treatment = item['deskripsi']?.toString() ?? 'Treatment Khusus';
        
        final double nilaiTreatment = _parseDouble(item['nilai_sebelum_diskon']);
        final double komisiDidapat = _parseDouble(item['komisi_5_persen']);
        final String jenisKomisi = item['jenis_komisi']?.toString() ?? 'regular_treatment';
        
        final bool isRedeem = item['is_redeem'] == true || item['is_redeem'] == 'true';
        final String? packageId = item['id_package_custom_detail']?.toString();
        
        // 🔥 MENANGKAP NAMA PENGERJA DARI API
        final String terapisPengerjaan = item['terapis_pengerjaan']?.toString() ?? '-';
        final String terapisPenjual = item['id_terapis']?.toString() ?? '-';
        
        String badgeText = 'Normal';
        Color badgeColor = Colors.green.shade50;
        Color badgeTextColor = Colors.green.shade600;

        if (jenisKomisi == 'override_masuk') {
            badgeText = 'Override (+)';
            badgeColor = Colors.blue.shade50;
            badgeTextColor = Colors.blue.shade700;
        } else if (jenisKomisi == 'override_keluar') {
            badgeText = 'Override (-)';
            badgeColor = Colors.red.shade50;
            badgeTextColor = Colors.red.shade700;
        } else if (jenisKomisi == 'regular_paket' || jenisKomisi == 'regular_gift') {
            badgeText = 'Penjualan Paket';
            badgeColor = Colors.orange.shade50;
            badgeTextColor = Colors.orange.shade700;
        } else if (isRedeem) {
            badgeText = 'Redeem Paket';
            badgeColor = Colors.purple.shade50;
            badgeTextColor = Colors.purple.shade700;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPinkCard ? cardPink : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transaction', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                      Text(tgl, style: TextStyle(fontSize: 11, color: textDark, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(trxId, style: TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500)),
                ],
              ),
              
              const SizedBox(height: 12),
              if (!isPinkCard) Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 12),
              
              Text('Nama Customer', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
              Text(customerName, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 12),
              
              Text('Treatment / Keterangan', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
              Text(treatment, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),
              
              // 🔥 MENAMPILKAN NAMA TERAPIS PENGERJAAN DI DEPAN
              Text('Dikerjakan Oleh', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
              Text(terapisPengerjaan, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),

              if (isRedeem && packageId != null && packageId.isNotEmpty) ...[
                 const SizedBox(height: 12),
                 Text('ID Paket (Redeem)', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                 Text(packageId, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
              ],
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nilai Treatment', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                      Text(formatRupiah(nilaiTreatment), style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Komisi Didapat', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                      Text(formatRupiah(komisiDidapat), style: TextStyle(fontSize: 13, color: komisiDidapat < 0 ? Colors.red : textDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText, 
                    style: TextStyle(
                      fontSize: 11, 
                      color: badgeTextColor, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}