import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class HistoryDetailPayoutScreen extends StatefulWidget {
  const HistoryDetailPayoutScreen({Key? key}) : super(key: key);

  @override
  State<HistoryDetailPayoutScreen> createState() => _HistoryDetailPayoutScreenState();
}

class _HistoryDetailPayoutScreenState extends State<HistoryDetailPayoutScreen> {
  // --- WARNA DESAIN ---
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPink = const Color(0xFFE8647C);
  final Color bgLight = const Color(0xFFFDF6F5);

  int _idPayout = 0;
  Future<Map<String, dynamic>>? _detailFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 1. Menangkap data item yang dikirim dari EarningsScreen
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      _idPayout = int.tryParse(args['id_payout']?.toString() ?? '0') ?? 0;
    } else if (args is int) {
      _idPayout = args;
    } else if (args is String) {
      _idPayout = int.tryParse(args) ?? 0;
    }

    // 2. Panggil API jika _idPayout berhasil didapatkan dan future belum di-set
    if (_idPayout != 0 && _detailFuture == null) {
      _detailFuture = ApiService().getPayoutDetail(_idPayout);
    }
  }

  // --- HELPER: FORMAT RUPIAH ---
  String _formatRupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // --- HELPER: WARNA STATUS ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'on_process': 
        return Colors.orange.shade700;
      case 'approved': 
      case 'success': 
      case 'completed': 
        return Colors.green.shade700;
      case 'rejected': 
      case 'failed': 
        return Colors.red.shade700;
      default: 
        return Colors.grey;
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
            'Detail Penarikan',
            style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _idPayout == 0 
            ? _buildErrorState('ID Penarikan tidak valid.')
            : _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailFuture,
      builder: (context, snapshot) {
        
        // 1. STATE LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. STATE ERROR
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?['status'] == 'error') {
          final errorMsg = snapshot.data?['message'] ?? 'Gagal memuat detail data (404/403).';
          return _buildErrorState(errorMsg);
        }

        // 3. STATE SUCCESS
        final data = snapshot.data!['data'] as Map<String, dynamic>;
        
        final String status = data['status'] ?? 'Pending';
        
        // Aturan UI/UX Nominal Transfer (Fallback ke requested amount jika total_transfer null/0)
        final int requestedAmount = int.tryParse(data['requested_amount']?.toString() ?? '0') ?? 0;
        final int? totalTransferRaw = data['total_transfer'] != null ? int.tryParse(data['total_transfer'].toString()) : null;
        final int finalAmountToShow = (totalTransferRaw != null && totalTransferRaw > 0) ? totalTransferRaw : requestedAmount;

        final String? note = data['note'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded, 
                      size: 40, 
                      color: _getStatusColor(status)
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Nominal Penarikan (Besar)
                Center(
                  child: Text(
                    _formatRupiah(finalAmountToShow),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDarkBrown),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Rincian Detail
                _buildDetailRow('Status', status.toUpperCase(), valueColor: _getStatusColor(status), isBoldValue: true),
                const Divider(height: 32, thickness: 1),
                
                // 🔥 BAGIAN INI YANG DIUBAH 🔥
                _buildDetailRow('ID', 'PY-$_idPayout', isBoldValue: true),
                
                _buildDetailRow(
                  (totalTransferRaw != null && totalTransferRaw > 0) ? 'Total Ditransfer' : 'Nominal Pengajuan', 
                  _formatRupiah(finalAmountToShow), 
                  isBoldValue: true
                ),
                _buildDetailRow('Bank Tujuan', data['bank_account'] ?? '-'),
                _buildDetailRow('Nomor Rekening', data['account_number'] ?? '-'),
                _buildDetailRow('Nama Pemilik', data['account_holder_name'] ?? '-'),
                const Divider(height: 32, thickness: 1),
                _buildDetailRow('Tanggal Request', data['created_at'] ?? '-'),
                
                // RULES UI/UX: Tampilkan box note hanya jika note ada isinya dari Admin
                if (note != null && note.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50, 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            Text('Catatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(note, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDarkBrown,
                fontSize: 14,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(errorMsg, textAlign: TextAlign.center, style: TextStyle(color: textDarkBrown, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
            child: const Text('Kembali', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}