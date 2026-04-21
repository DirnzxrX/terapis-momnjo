import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  // STATE: Untuk menyimpan "titipan" data dari layar Active Job
  Map<String, dynamic>? _savedActiveJobState; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _data = args;
        String passedStatus = args['status'] ?? 'Accepted';
        
        // Jika dari API/sebelumnya statusnya 'new' atau 'open', otomatis anggap 'Accepted'
        if (passedStatus.toLowerCase() == 'new' || passedStatus.toLowerCase() == 'open') {
          passedStatus = 'Accepted';
        }
        _currentStatus = passedStatus;
      } else {
        // Otomatis terkonfirmasi (Accepted) saat mendapat job baru
        _currentStatus = 'Accepted';
      }
      _isInitialized = true;
    }
  }

  void _nextStatus() {
    setState(() {
      final s = _currentStatus.toLowerCase();
      if (s == 'accepted' || s == 'new' || s == 'open') {
        _currentStatus = 'Pemeriksaan'; // Langsung ke Pemeriksaan
      } else if (s == 'pemeriksaan') {
        _currentStatus = 'Started';     
      } else if (s == 'started') {
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
    // --- MENGAMBIL DATA DARI STRUKTUR API TERBARU ---
    final String nama = _data?['customer_name'] ?? _data?['customer_fullname'] ?? 'Siti Rahmawati';
    final String telepon = _data?['customer_phone'] ?? _data?['phone'] ?? '0812 456 7890';
    
    // Lokasi dari API
    final String gerai = _data?['gerai'] ?? 'Klinik Mom n Jo';
    final String roomType = _data?['room_type'] ?? 'Onsite';
    final String alamat = '$gerai (Ruang: $roomType)';
    
    final String startTime = _data?['start_time'] ?? '';

    // MENGAMBIL LIST LAYANAN DINAMIS
    List<dynamic> layananList = [];
    if (_data != null && _data!['treatment_name'] != null) {
      // Jika data datang dari API baru (satu treatment)
      layananList = [
        {
          'name': _data!['treatment_name'],
          'duration': 'Sesuai Layanan', 
        }
      ];
    } else {
      // Fallback ke format lama
      layananList = _data?['treatments'] ?? _data?['services'] ?? [
        {
          'name': _data?['deskripsi'] ?? 'Mother Care Massage',
          'duration': _data?['durasi'] ?? '90 menit',
        }
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            if (_currentStatus.toLowerCase() == 'completed') {
              setState(() {
                _currentStatus = 'Started'; 
              });
              await _openActiveJob();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Detail Booking (Onsite)', 
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)
        ),
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
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileCard(String nama, String telepon, String status) {
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'new': 
      case 'open': 
      case 'accepted': statusBg = const Color(0xFF9C27B0); break;
      case 'pemeriksaan': statusBg = Colors.purple.shade400; break; 
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  (status.toLowerCase() == 'new' || status.toLowerCase() == 'open') ? 'ACCEPTED' : status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              if (_data?['id_booking'] != null)
                Text(
                  _data!['id_booking'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                ),
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
              // IKON TELEPON BIASA
              _buildSmallIconButton(Icons.phone_outlined, onTap: () async {
                final Uri telUrl = Uri.parse('tel:$telepon');
                if (await canLaunchUrl(telUrl)) {
                  await launchUrl(telUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka aplikasi Telepon')));
                }
              }),
              const SizedBox(width: 8),
              // IKON CHAT WHATSAPP
              _buildSmallIconButton(Icons.chat_outlined, onTap: () async {
                final String waNumber = telepon.replaceAll(RegExp(r'\D'), ''); 
                final Uri waUrl = Uri.parse('https://wa.me/$waNumber');
                if (await canLaunchUrl(waUrl)) {
                  await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
                }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
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
                Text('Waktu Mulai: $startTime', style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
          ],

          ...layananList.map((item) {
            String name = 'Layanan';
            String duration = '90 menit';

            if (item is Map) {
              name = item['name'] ?? item['treatment_name'] ?? item['deskripsi'] ?? 'Layanan';
              duration = item['duration']?.toString() ?? item['durasi']?.toString() ?? 'Sesuai Layanan';
            } else {
              name = item.toString();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catatan Customer', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tidak ada catatan khusus dari pelanggan.', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final s = currentStatus.toLowerCase();
    
    // LOGIKA TIMELINE ONSITE: Tanpa OTW dan Arrived
    bool isAssigned = !['new', 'open'].contains(s);
    bool isPemeriksaan = ['pemeriksaan', 'started', 'completed'].contains(s); 
    bool isStarted = ['started', 'completed'].contains(s);
    bool isCompleted = s == 'completed';

    return Column(
      children: [
        _buildTimelineStep('Assigned', isAssigned ? 'Terkonfirmasi' : 'Menunggu', isAssigned, false),
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
    final s = _currentStatus.toLowerCase();

    // TAMPILAN BUTTON: Langsung masuk Pemeriksaan
    String text = 'PEMERIKSAAN KLIEN';
    if (s == 'accepted' || s == 'new' || s == 'open') text = 'PEMERIKSAAN KLIEN'; 
    else if (s == 'pemeriksaan') text = 'START TREATMENT'; 
    else if (s == 'started') text = 'LANJUT TREATMENT';
    else if (s == 'completed') text = 'COMPLETE TREATMENT';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () async {
            // LOGIKA STATUS SELANJUTNYA UNTUK ONSITE
            if (s == 'accepted' || s == 'new' || s == 'open') {
              setState(() { _currentStatus = 'Pemeriksaan'; });
            }
            else if (s == 'pemeriksaan' || s == 'started') {
              if (s == 'pemeriksaan') {
                setState(() { _currentStatus = 'Started'; });
              }
              await _openActiveJob();
            } 
            else if (s == 'completed') {
              Navigator.pushReplacementNamed(
                context, 
                '/visit_report',
                arguments: _data, 
              );
            } 
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}