import 'package:flutter/material.dart';

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
  
  // STATE: Untuk menyimpan "titipan" data dari layar Active Job
  Map<String, dynamic>? _savedActiveJobState; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _data = args;
        _currentStatus = args['status'] ?? 'Accepted';
      } else {
        _currentStatus = 'Accepted';
      }
      _isInitialized = true;
    }
  }

  void _nextStatus() {
    setState(() {
      if (_currentStatus.toLowerCase() == 'accepted' || _currentStatus.toLowerCase() == 'new') {
        _currentStatus = 'OTW';
      } else if (_currentStatus.toLowerCase() == 'otw') {
        _currentStatus = 'Arrived';
      } else if (_currentStatus.toLowerCase() == 'arrived') {
        _currentStatus = 'Started';
      } else if (_currentStatus.toLowerCase() == 'started') {
        _currentStatus = 'Completed';
      }
    });
  }

  // FUNGSI PUSAT: Membuka layar Job Aktif (ActiveJobScreen)
  Future<void> _openActiveJob() async {
    final result = await Navigator.pushNamed(
      context, 
      '/active_job',
      arguments: {
        ...?_data,
        'savedState': _savedActiveJobState, 
      },
    );

    if (result != null && result is Map) {
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['action'] == 'finish_treatment') {
        setState(() {
          _currentStatus = 'Completed';
        });
        _data?['durasi_aktual'] = resultMap['durasi_aktual'];
        
        // MENYIMPAN STATE TERAKHIR: Dipaksa isPaused: true agar saat balik lagi waktunya tidak jalan otomatis
        setState(() {
          _savedActiveJobState = {
            'secondsElapsed': resultMap['durasi_aktual'],
            'hasStarted': true,
            'isPaused': true, 
            'stepsDone': resultMap['stepsDone'] ?? [true, true, true, true, true],
          };
        });
      } else if (resultMap['action'] == 'save_state') {
        setState(() {
          _currentStatus = 'Started';
          _savedActiveJobState = resultMap;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = _data?['customer_fullname'] ?? 'Dewi Lestari';
    final String layanan = _data?['deskripsi'] ?? 'Mother Care Massage';
    final String alamat = _data?['alamat'] ?? 'Jl. Melati No. 10, Bandung';

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              // LOGIKA BAJAK: Jika status sudah Completed, tombol back akan mengedit data
              if (_currentStatus.toLowerCase() == 'completed') {
                setState(() {
                  _currentStatus = 'Started'; 
                });
                await _openActiveJob();
              } else {
                Navigator.pop(context); // Kembali ke jadwal jika belum selesai
              }
            },
          ),
          title: const Text(
            'Detail Booking', 
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(nama, _currentStatus),
                    const SizedBox(height: 16),
                    _buildLocationCard(alamat),
                    const SizedBox(height: 16),
                    _buildServiceCard(layanan),
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Timeline Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
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
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileCard(String nama, String status) {
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'new': statusBg = Colors.blue.shade400; break;
      case 'accepted': statusBg = const Color(0xFF9C27B0); break;
      case 'otw': statusBg = Colors.orange.shade400; break;
      case 'arrived': statusBg = Colors.teal.shade400; break;
      case 'started': statusBg = Colors.indigo.shade400; break;
      case 'completed': statusBg = Colors.green.shade500; break;
      default: statusBg = Colors.grey;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
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
                    const Text('0812 456 7890', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              _buildSmallIconButton(Icons.phone_outlined),
              const SizedBox(width: 8),
              _buildSmallIconButton(Icons.chat_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(icon, size: 20, color: Colors.black87), onPressed: () {}),
    );
  }

  Widget _buildLocationCard(String alamat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
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
                const Text('Patokan: Depan gerbang warna hitam', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                Text('Lihat di Maps', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String layanan) {
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
          const Text('Layanan', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(layanan, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Durasi', style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text('90 menit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catatan Customer', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Ibu hamil trimester 2, tidak ada keluhan', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    bool isOtw = ['otw', 'arrived', 'started', 'completed'].contains(currentStatus.toLowerCase());
    bool isArrived = ['arrived', 'started', 'completed'].contains(currentStatus.toLowerCase());
    bool isStarted = ['started', 'completed'].contains(currentStatus.toLowerCase());
    bool isCompleted = currentStatus.toLowerCase() == 'completed';

    return Column(
      children: [
        _buildTimelineStep('Assigned', '13 Mei 08.30', true, false),
        _buildTimelineStep('OTW', isOtw ? 'Aktif' : '-', isOtw, false),
        _buildTimelineStep('Arrived', isArrived ? 'Sampai' : '-', isArrived, false),
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
            if (!last) Container(width: 2, height: 30, color: done ? Colors.green.withOpacity(0.5) : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal, color: done ? Colors.black87 : Colors.grey)),
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    String text = 'OTW';
    if (_currentStatus.toLowerCase() == 'otw') text = 'ARRIVED';
    else if (_currentStatus.toLowerCase() == 'arrived') text = 'START TREATMENT';
    else if (_currentStatus.toLowerCase() == 'started') text = 'LANJUT TREATMENT';
    else if (_currentStatus.toLowerCase() == 'completed') text = 'COMPLETE TREATMENT';

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent, 
      child: ElevatedButton(
        onPressed: () async {
          if (_currentStatus.toLowerCase() == 'arrived' || _currentStatus.toLowerCase() == 'started') {
            if (_currentStatus.toLowerCase() == 'arrived') {
              setState(() { _currentStatus = 'Started'; });
            }
            await _openActiveJob();
          } 
          else if (_currentStatus.toLowerCase() == 'completed') {
            Navigator.pushReplacementNamed(
              context, 
              '/visit_report',
              arguments: _data, 
            );
          } 
          else {
            _nextStatus();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}