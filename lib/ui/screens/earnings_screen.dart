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

  // --- SOURCE OF TRUTH DARI API GET_TERAPIS_REPORT ---
  double _totalKomisiAllTime = 0; // Sekarang mengambil dari pengerjaan_terapis -> total_nominal
  double _komisiReguler = 0;      // komisi_reguler_5_persen
  double _komisiRedeem = 0;       // komisi_override_5_persen
  double _grandTotal = 0;         // pendapatan_setelah_diskon

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

      // Memanggil API get_terapis_report.php
      final response = await ApiService().getTerapisReport(startDate: startStr, endDate: endStr);
      
      if (response['success'] == true || response['status'] == 'success') {
        final Map<String, dynamic> data = response['data'] ?? {};
        final Map<String, dynamic> pendapatan = data['pendapatan_terapis'] ?? {};
        final Map<String, dynamic> pengerjaan = data['pengerjaan_terapis'] ?? {};

        if (mounted) {
          setState(() {
            // 🔥 PERUBAHAN: Sekarang mengambil dari total_nominal sesuai permintaan Anda
            _totalKomisiAllTime = _parseDouble(pengerjaan['total_nominal']);
            
            _komisiReguler = _parseDouble(pendapatan['komisi_reguler_5_persen']);
            _komisiRedeem = _parseDouble(pendapatan['komisi_override_5_persen']);
            
            // 🔥 PERUBAHAN: Total Omset sekarang mengambil data komisi_5_persen
            _grandTotal = _parseDouble(pendapatan['komisi_5_persen']);
            
            _rincianTransaksi = pengerjaan['items'] ?? [];
            _isLoading = false;
          });
        }
      } else {
         _showError(response['message'] ?? 'Gagal mengambil data laporan.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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
                'Total Nominal', // Teks ini bisa dikembalikan ke 'Total Komisi' jika Anda mau
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
          child: _buildSmallStatCard('Komisi\nRedeem 5%', formatRupiah(_komisiRedeem), isMinus: _komisiRedeem < 0),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallStatCard('Total\nOmset', formatRupiah(_grandTotal)),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String title, String amount, {bool isMinus = false}) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3),
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
        
        final String tglRaw = item['tgl'] ?? item['created_at'] ?? '2026-05-11';
        final String tgl = tglRaw.split(' ')[0]; 
        final String trxId = item['id_trx'] ?? item['transaction_id'] ?? 'TRX-UNKNOWN';
        final String customerName = item['nama_cust'] ?? item['customer_name'] ?? 'Customer';
        final String treatment = item['treatment'] ?? item['product_name'] ?? 'Treatment Khusus';
        
        final double hargaSatuan = _parseDouble(item['nominal'] ?? item['harga_satuan']);
        final double totalHarga = _parseDouble(item['subtotal_nominal'] ?? item['total_harga']);
        final String keterangan = item['keterangan'] ?? 'Normal';
        
        final bool showBadge = keterangan.isNotEmpty; 

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
              
              if (!isPinkCard) ...[
                 const SizedBox(height: 12),
                 Divider(color: Colors.grey.shade100, height: 1),
              ],
              const SizedBox(height: 12),
              
              Text('Nama Customer', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
              Text(customerName, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 12),
              
              Text('Treatment / Keterangan', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
              Text(treatment, style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harga Satuan', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                      Text(formatRupiah(hargaSatuan), style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Harga', style: TextStyle(fontSize: 11, color: isPinkCard ? Colors.black54 : Colors.grey.shade600)),
                      Text(formatRupiah(totalHarga), style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              if (showBadge && !isPinkCard) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: keterangan.toLowerCase() == 'normal' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      keterangan == 'Normal' ? 'Selesai' : 'Redeem Paket', 
                      style: TextStyle(
                        fontSize: 11, 
                        color: keterangan.toLowerCase() == 'normal' ? Colors.green.shade600 : Colors.orange.shade700, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}