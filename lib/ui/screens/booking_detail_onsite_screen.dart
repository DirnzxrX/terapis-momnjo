import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart';
import 'pemeriksaan_screen.dart'; 

class DetailBookingOnsiteScreen extends StatefulWidget {
  const DetailBookingOnsiteScreen({Key? key}) : super(key: key);

  @override
  State<DetailBookingOnsiteScreen> createState() => _DetailBookingOnsiteScreenState();
}

class _DetailBookingOnsiteScreenState extends State<DetailBookingOnsiteScreen> {
  final Color primaryPink = const Color(0xFFE8647C);

  String _currentStatus = '';
  Map<String, dynamic>? _data;
  bool _isInitialized = false;
  bool _isUpdatingStatus = false; 
  
  Map<String, dynamic>? _savedActiveJobState; 
  bool _isPemeriksaanSkipped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _data = args;
        String passedStatus = args['booking_status'] ?? args['status'] ?? 'Accepted';
        passedStatus = passedStatus.trim(); 
        
        if (['new', 'open', 'menunggu', 'pending'].contains(passedStatus.toLowerCase())) {
          passedStatus = 'Accepted';
        }
        _currentStatus = passedStatus;

        // Inisialisasi status skip dari data API (jika ada)
        var pemDone = args['is_pemeriksaan_done'] ?? args['pemeriksaan_selesai'];
        bool isSkipped = args['is_skipped'] == true || args['skipped'] == true || args['pemeriksaan_skipped'] == true;
        
        if ((pemDone == true || pemDone == 'true' || pemDone == 1 || pemDone == '1') && !isSkipped) {
           _isPemeriksaanSkipped = false;
        } else if (isSkipped) {
           _isPemeriksaanSkipped = true;
        }
      } else {
        _currentStatus = 'Accepted';
      }
      _isInitialized = true;
    }
  }

  Future<void> _updateStatusAPI(String newStatus) async {
    final String bookingId = _data?['id_booking']?.toString() ?? '';
    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Booking tidak ditemukan. Gagal update.')),
      );
      return;
    }

    setState(() { _isUpdatingStatus = true; });
    
    final api = ApiService();
    final response = await api.updateBookingStatus(
      idBooking: bookingId, 
      newStatus: newStatus,
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
        setState(() {
          _currentStatus = newStatus;
          _data?['booking_status'] = newStatus; 
        });
      }
    }
  }

  Future<void> _openActiveJob() async {
    final result = await Navigator.pushNamed(
      context, 
      '/active_job',
      arguments: {
        ...?_data,
        'savedState': _savedActiveJobState,
        'pemeriksaan_skipped': _isPemeriksaanSkipped,
        'booking_status': _currentStatus
      },
    );

    if (result != null && result is Map) {
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['action'] == 'finish_treatment') {
        setState(() {
          // 🔥 UPDATE: Jika pemeriksaan sudah beres di layar Job Aktif, ubah status skip jadi false (Centang Hijau)
          if (resultMap['isPemeriksaanSelesai'] == true) {
             _isPemeriksaanSkipped = false; 
          }
          
          _currentStatus = 'Closed'; 
          _data?['booking_status'] = 'Closed';
          _data?['durasi_aktual'] = resultMap['durasi_aktual'];
          _savedActiveJobState = {
            'secondsElapsed': resultMap['durasi_aktual'],
            'hasStarted': true,
            'isPaused': true, 
            'stepsDone': resultMap['stepsDone'] ?? [true, true, true, true, true],
          };
        });
      } else if (resultMap['action'] == 'save_state') {
        setState(() {
          // 🔥 UPDATE: Jika user melakukan Resume dan mengisi form lalu back (Pause), hilangkan silang merahnya
          if (resultMap['isPemeriksaanSelesai'] == true) {
             _isPemeriksaanSkipped = false; 
          }
          _currentStatus = 'Started';
          _savedActiveJobState = resultMap;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = _data?['customer_name'] ?? _data?['customer_fullname'] ?? 'Klien';
    final String telepon = _data?['customer_phone'] ?? _data?['phone'] ?? '0812 456 7890';
    final String gerai = _data?['gerai'] ?? 'Klinik Mom n Jo';
    final String roomType = _data?['room_type'] ?? 'Onsite';
    final String startTime = _data?['start_time'] ?? '';

    List<dynamic> layananList = [];
    if (_data != null && _data!['treatment_name'] != null) {
      layananList = [{'name': _data!['treatment_name'], 'duration': 'Sesuai Layanan'}];
    } else {
      layananList = _data?['treatments'] ?? _data?['services'] ?? [];
    }

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, true); 
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white, 
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context, true); 
            },
          ),
          title: const Text('Detail Booking (Onsite)', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
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
                    _buildLocationCard(gerai, roomType),
                    const SizedBox(height: 16),
                    _buildServiceCard(layananList, startTime), 
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
            _buildBottomButton(layananList),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String nama, String telepon, String status) {
    Color statusBg;
    String statusIndo = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'new': 
      case 'open': 
      case 'accepted': 
        statusBg = const Color(0xFF9C27B0); 
        statusIndo = 'DITERIMA';
        break;
      case 'pemeriksaan': 
        statusBg = Colors.purple.shade400; 
        statusIndo = 'PEMERIKSAAN';
        break; 
      case 'started': 
        statusBg = Colors.indigo.shade400; 
        statusIndo = 'DIMULAI';
        break;
      case 'completed': 
      case 'closed': 
        statusBg = Colors.green.shade500; 
        statusIndo = 'SELESAI';
        break;
      default: 
        statusBg = Colors.grey;
        statusIndo = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  statusIndo, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              if (_data?['id_booking'] != null)
                Text(_data!['id_booking'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
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
              const SizedBox(width: 8),
              _buildSmallIconButton(Icons.chat_outlined, onTap: () async {
                final String waNumber = telepon.replaceAll(RegExp(r'\D'), ''); 
                final Uri waUrl = Uri.parse('https://wa.me/$waNumber');
                if (await canLaunchUrl(waUrl)) await launchUrl(waUrl, mode: LaunchMode.externalApplication);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(icon, size: 20, color: Colors.black87), onPressed: onTap ?? () {}),
    );
  }

  Widget _buildLocationCard(String gerai, String roomType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.business_outlined, color: Colors.black87, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gerai, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tipe Ruangan: $roomType', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(List<dynamic> layananList, String startTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Layanan yang Dipilih', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (startTime.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text('Waktu Mulai: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.tryParse(startTime) ?? DateTime.now())}', style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
          ],
          ...layananList.map((item) {
            String name = (item is Map) ? (item['name'] ?? item['treatment_name'] ?? item['deskripsi'] ?? 'Layanan') : item.toString();
            String duration = (item is Map) ? (item['duration']?.toString() ?? item['durasi']?.toString() ?? 'Sesuai Layanan') : '90 menit';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.spa_outlined, color: primaryPink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Durasi: $duration', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan Customer', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_data?['notes'] ?? _data?['catatan'] ?? 'Tidak ada catatan khusus dari pelanggan.', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final s = currentStatus.toLowerCase();
    bool isAssigned = !['new', 'open'].contains(s);
    bool isPemeriksaan = ['pemeriksaan', 'started', 'completed', 'closed'].contains(s); 
    bool isStarted = ['started', 'completed', 'closed'].contains(s);
    bool isCompleted = ['completed', 'closed'].contains(s);

    return Column(
      children: [
        _buildTimelineStep('Pekerjaan Diterima', isAssigned ? '' : 'Menunggu', isAssigned, false),
        _buildTimelineStep('Cek Kesehatan', isPemeriksaan ? '' : '-', isPemeriksaan, false, isSkipped: _isPemeriksaanSkipped), 
        _buildTimelineStep('Mulai', isStarted ? '' : '-', isStarted, false),
        _buildTimelineStep('Selesai', isCompleted ? '' : '', isCompleted, true),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String time, bool done, bool last, {bool isSkipped = false}) {
    IconData icon = Icons.radio_button_unchecked;
    Color color = Colors.grey;

    if (done) {
      if (isSkipped) {
        icon = Icons.cancel; 
        color = Colors.red;
      } else {
        icon = Icons.check_circle; 
        color = Colors.green;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 20),
            if (!last) Container(width: 2, height: 30, color: done ? color.withOpacity(0.5) : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal, color: done ? Colors.black87 : Colors.grey)),
              Text(time, style: TextStyle(fontSize: 12, color: isSkipped ? Colors.red : Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(List<dynamic> layananList) {
    final s = _currentStatus.toLowerCase();
    String text = 'PANGGIL KLIEN (PEMERIKSAAN)';
    if (s == 'accepted' || s == 'new' || s == 'open') text = 'Cek Kesehatan'; 
    else if (s == 'pemeriksaan') text = 'MULAI SESI TREATMENT'; 
    else if (s == 'started') text = 'LANJUT TREATMENT';
    else if (s == 'completed' || s == 'closed') text = 'BUAT LAPORAN KUNJUNGAN';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isUpdatingStatus ? null : () async {
            if (s == 'accepted' || s == 'new' || s == 'open') {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PemeriksaanScreen(bookingData: _data)));
              
              if (result == null) return; 

              if (result == 'skipped') {
                setState(() {
                  _isPemeriksaanSkipped = true;
                  _isUpdatingStatus = true;
                });

                final String idTransaksi = _data?['id_transaksi']?.toString() ?? '';
                final String idCustomer = _data?['id_customer']?.toString() ?? _data?['customer_id']?.toString() ?? '';
                
                if (idTransaksi.isNotEmpty && idCustomer.isNotEmpty) {
                  await ApiService().storeDataMedis(
                    idTransaksi: idTransaksi,
                    idCustomer: idCustomer,
                    catatan: 'Pemeriksaan dilewati (Skipped) oleh Terapis',
                  );
                }

                setState(() { _isUpdatingStatus = false; });
              } else {
                setState(() => _isPemeriksaanSkipped = false);
              }
              
              await _updateStatusAPI('Pemeriksaan'); 
            }
            else if (s == 'pemeriksaan') {
              await _updateStatusAPI('Started');
              await _openActiveJob();
            } 
            else if (s == 'started') {
              await _openActiveJob();
            } 
            else if (s == 'completed' || s == 'closed') {
              Navigator.pushReplacementNamed(
                context, 
                '/visit_report', 
                result: true, 
                arguments: _data
              );
            } 
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: (s == 'accepted' || s == 'new' || s == 'open') ? Colors.teal : primaryPink,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isUpdatingStatus 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}