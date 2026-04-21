import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart';
import 'pemeriksaan_screen.dart'; 

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({Key? key}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final Color primaryPink = const Color(0xFFE8647C);

  String _currentStatus = '';
  Map<String, dynamic>? _data;
  bool _isInitialized = false;
  bool _isUpdatingStatus = false; 
  
  String? _arrivalPhotoPath; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _data = args;
        String passedStatus = args['booking_status'] ?? args['status'] ?? 'Open';
        passedStatus = passedStatus.trim(); 
        
        if (['new', 'open', 'menunggu', 'pending'].contains(passedStatus.toLowerCase())) {
          passedStatus = 'Accepted';
        }
        _currentStatus = passedStatus;
      } else {
        _currentStatus = 'Accepted';
      }
      _isInitialized = true;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return raw;
    }
  }

  // --- FUNGSI UPDATE STATUS KE BACKEND ---
  Future<void> _updateStatusAPI(String newStatus) async {
    final String bookingId = _data?['id_booking']?.toString() ?? '';
    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Booking tidak ditemukan. Gagal update.')),
      );
      return;
    }

    setState(() { _isUpdatingStatus = true; });
    
    // Panggil API (Pastikan fungsi updateBookingStatus sudah ada di api_service.dart)
    final api = ApiService();
    final response = await api.updateBookingStatus(
      idBooking: bookingId, 
      newStatus: newStatus,
      imagePath: _arrivalPhotoPath // Opsional: kirim path foto jika ada
    );

    if (mounted) {
      setState(() { _isUpdatingStatus = false; });
      if (response['success'] == true || response['status'] == 'success') {
        setState(() {
          _currentStatus = newStatus;
          _data?['booking_status'] = newStatus; 
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal update status server')),
        );
        // Tetap paksa update lokal buat testing kalau API belum siap (Hapus nanti kalau prod)
        setState(() {
          _currentStatus = newStatus;
          _data?['booking_status'] = newStatus; 
        });
      }
    }
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    // TODO: Ganti dengan ImagePicker beneran nanti
    await Future.delayed(const Duration(milliseconds: 500));
    setDialogState(() {
      _arrivalPhotoPath = "captured_image_simulated.png"; 
    });
  }

  void _showArrivalPhotoDialog() {
    _arrivalPhotoPath = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Konfirmasi Kedatangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Silakan upload foto bukti kedatangan di lokasi (Home Service).', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        color: _arrivalPhotoPath != null ? Colors.green.withOpacity(0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _arrivalPhotoPath != null ? Colors.green : Colors.grey.shade300, width: 2),
                      ),
                      child: _arrivalPhotoPath != null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 30)),
                              const SizedBox(height: 12),
                              const Text('Foto Diambil', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.camera_alt, color: primaryPink, size: 32)),
                              const SizedBox(height: 12),
                              Text('Ambil Foto', style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _arrivalPhotoPath == null ? null : () async {
                          Navigator.pop(context); 
                          await _updateStatusAPI('Arrived'); 
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryPink, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('Kirim Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String idBooking = _data?['id_booking']?.toString() ?? '-';
    final String idTransaksi = _data?['id_transaksi']?.toString() ?? '-';
    final String startTime = _formatDateTime(_data?['start_time']?.toString());
    
    String rawCustomerName = _data?['customer_name']?.toString() ?? '';
    if (rawCustomerName.trim().isEmpty) rawCustomerName = idBooking;
    
    final String nama = rawCustomerName;
    final String telepon = _data?['customer_phone'] ?? _data?['phone'] ?? 'Nomor tidak tersedia';
    
    final String roomType = _data?['room_type']?.toString() ?? '';
    final String gerai = _data?['gerai']?.toString() ?? '';
    String alamat = [gerai, roomType].where((e) => e.isNotEmpty).join(' - ');

    final List<dynamic> layananList = _data?['treatments'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('Detail Home Service', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(nama, telepon, _currentStatus),
                  const SizedBox(height: 16),
                  _buildBookingInfoCard(idBooking, idTransaksi, startTime), 
                  const SizedBox(height: 16),
                  _buildLocationCard(alamat),
                  const SizedBox(height: 16),
                  _buildServiceCard(layananList), 
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                  const Text('Timeline Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildTimeline(_currentStatus),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (Sama seperti sebelumnya) ---
  Widget _buildProfileCard(String nama, String telepon, String status) {
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'arrived': statusBg = Colors.teal.shade400; break;
      case 'pemeriksaan': statusBg = Colors.purple.shade400; break; 
      case 'started': statusBg = Colors.indigo.shade400; break;
      case 'completed': case 'closed': statusBg = Colors.green.shade500; break;
      default: statusBg = const Color(0xFF9C27B0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32')), 
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(telepon, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              _buildSmallIconButton(Icons.phone_outlined, onTap: () async {
                final Uri telUrl = Uri.parse('tel:$telepon');
                if (await canLaunchUrl(telUrl)) await launchUrl(telUrl);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, {VoidCallback? onTap}) {
    return Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(icon, size: 20, color: Colors.black87), onPressed: onTap ?? () {}));
  }

  Widget _buildBookingInfoCard(String idBooking, String idTransaksi, String startTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Booking', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow('ID Booking', idBooking),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
          _buildInfoRow('ID Transaksi', idTransaksi),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
          _buildInfoRow('Tanggal & Waktu', startTime),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))]);
  }

  Widget _buildLocationCard(String alamat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.black87, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alamat, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_data?['patokan'] ?? 'Tidak ada catatan patokan khusus', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(List<dynamic> layananList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Layanan yang Dipilih', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...layananList.map((item) {
            String name = item is Map ? (item['name'] ?? 'Layanan') : item.toString();
            bool isDone = item is Map ? (item['is_done'] == true) : false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.spa_outlined, color: Colors.pink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name)),
                  if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Catatan Customer', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_data?['notes'] ?? _data?['catatan'] ?? 'Tidak ada catatan khusus.', style: const TextStyle(fontSize: 14)),
      ]),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final s = currentStatus.toLowerCase();
    bool isArrived = ['arrived', 'pemeriksaan', 'started', 'completed', 'closed'].contains(s);
    bool isPemeriksaan = ['pemeriksaan', 'started', 'completed', 'closed'].contains(s); 
    bool isStarted = ['started', 'completed', 'closed'].contains(s);
    bool isCompleted = ['completed', 'closed'].contains(s);

    return Column(
      children: [
        _buildTimelineStep('Assigned', 'Terkonfirmasi', true, false),
        _buildTimelineStep('Arrived', isArrived ? 'Sampai' : '-', isArrived, false),
        _buildTimelineStep('Pemeriksaan', isPemeriksaan ? 'Selesai' : '-', isPemeriksaan, false), 
        _buildTimelineStep('Started', isStarted ? 'Mulai' : '-', isStarted, false),
        _buildTimelineStep('Completed', isCompleted ? 'Selesai' : '-', isCompleted, true),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String time, bool done, bool last) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.grey, size: 20), 
            if (!last) Container(width: 2, height: 30, color: done ? Colors.green.withOpacity(0.5) : Colors.grey.shade300)
          ]
        ),
        const SizedBox(width: 12),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal)), Text(time, style: const TextStyle(fontSize: 12))])),
      ],
    );
  }

  Widget _buildSingleActionButton(String label, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isUpdatingStatus ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: primaryPink, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isUpdatingStatus 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final s = _currentStatus.toLowerCase();

    if (s == 'arrived') {
      return _buildSingleActionButton('PEMERIKSAAN KLIEN', () async {
        // Melempar ID Customer sesuai dokumen API ke PemeriksaanScreen
        await Navigator.push(context, MaterialPageRoute(builder: (context) => PemeriksaanScreen(bookingData: _data)));
        await _updateStatusAPI('Pemeriksaan'); 
      });
    }

    if (s == 'pemeriksaan') {
      return _buildSingleActionButton('MULAI SESI TREATMENT', () async {
        await _updateStatusAPI('Started');
        if (mounted) Navigator.pushNamed(context, '/active_job', arguments: _data);
      });
    }

    if (s == 'started') {
      return _buildSingleActionButton('SELESAIKAN KUNJUNGAN', () async {
        await _updateStatusAPI('Closed');
        // Langsung masuk ke Layanan Laporan Kunjungan (rate_customer.php)
        if (mounted) Navigator.pushReplacementNamed(context, '/visit_report', arguments: _data);
      });
    }

    if (s == 'completed' || s == 'closed') {
      return _buildSingleActionButton('BUAT LAPORAN KUNJUNGAN', () {
        Navigator.pushReplacementNamed(context, '/visit_report', arguments: _data);
      });
    }

    // Default: Status Accepted / Open
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _showArrivalPhotoDialog,
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                label: const Text('ARRIVED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => PemeriksaanScreen(bookingData: _data)));
                  await _updateStatusAPI('Pemeriksaan'); 
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('SKIP', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}