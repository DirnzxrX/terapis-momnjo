import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  String _namaTerapis = 'Terapis'; 
  String _fotoProfile = ''; 
  int _bookingHariIni = 0;
  int _selesai = 0;
  Map<String, dynamic>? _nextBooking;
  bool _isLoading = true;

  // STATE STATUS KERJA
  bool _isOnDuty = false; 

  // STATE NOTIFIKASI
  bool _hasNewNotification = false;
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- FUNGSI LOAD DATA DARI LOKAL & API ---
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? namaSimpanan = prefs.getString('nama_lengkap');
      String? fotoSimpanan = prefs.getString('foto'); 
      String namaTampil = 'Terapis'; 
      
      bool isOnDutySimpanan = prefs.getBool('is_on_duty') ?? false;

      if (namaSimpanan != null && namaSimpanan.trim().isNotEmpty) {
        namaTampil = namaSimpanan;
      }
      
      final api = ApiService();
      
      // Mengambil tanggal hari ini untuk filter data
      final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int todayJobsCount = 0;
      int todayHistoryCount = 0;

      // 1. FETCH JOBS (Tugas Aktif) - Gunakan getActiveJobs agar sinkron dengan Schedule Screen
      final jobsResponse = await api.getActiveJobs(); 
      Map<String, dynamic>? nextBook;
      List<Map<String, String>> newNotifs = [];
      bool hasNewNotif = false;
      
      if (jobsResponse['success'] == true && jobsResponse['data'] != null) {
        List jobs = jobsResponse['data'];
        List openJobs = [];
        
        for (var job in jobs) {
          final String status = (job['status'] ?? job['booking_status'] ?? '').toString().toLowerCase().trim();
          final String startTime = job['start_time']?.toString() ?? '';
          
          // Hitung booking hari ini (berdasarkan waktu mulai yang mengandung tanggal hari ini)
          if (startTime.startsWith(todayStr)) {
            todayJobsCount++;
          }

          if (!['close', 'closed', 'completed'].contains(status)) {
            openJobs.add(job);
          }
        }

        if (openJobs.isNotEmpty) {
          openJobs.sort((a, b) {
            DateTime timeA = DateTime.tryParse(a['start_time']?.toString() ?? '') ?? DateTime(2000);
            DateTime timeB = DateTime.tryParse(b['start_time']?.toString() ?? '') ?? DateTime(2000);
            // Ubah jadi Ascending agar tugas yang paling dekat waktunya muncul duluan
            return timeA.compareTo(timeB); 
          });

          nextBook = openJobs.first; 
          
          // SIMULASI NOTIFIKASI TUGAS BARU 
          final namaKlien = nextBook?['customer_name'] ?? 'Klien';
          final deskripsi = nextBook?['treatment_summary'] ?? 'Treatment';
          final rawJam = nextBook?['start_time']?.toString() ?? '--:--';
          
          newNotifs.add({
            'title': 'Tugas Baru Masuk!',
            'body': 'Anda ditugaskan untuk melakukan $deskripsi kepada $namaKlien pada pukul ${_formatTime(rawJam)}.',
            'time': 'Baru saja',
          });
          hasNewNotif = true;
        }
      }

      // 2. FETCH HISTORY (Riwayat Selesai)
      final historyResponse = await api.getHistoryList();
      if (historyResponse['status'] == 'success' || historyResponse['success'] == true) {
         List historyList = historyResponse['data'] ?? [];
         for(var item in historyList) {
            // Cek berbagai kemungkinan nama field tanggal dari backend
            String tgl = item['tgl_dokumen'] ?? item['tgl_transaksi'] ?? item['date'] ?? '';
            // Jika tanggal history sama dengan hari ini, tambahkan ke counter Selesai
            if (tgl.startsWith(todayStr)) {
               todayHistoryCount++;
            }
         }
      }

      if (mounted) {
        setState(() {
          _namaTerapis = namaTampil;
          _fotoProfile = fotoSimpanan ?? '';
          _isOnDuty = isOnDutySimpanan; 
          _bookingHariIni = todayJobsCount;
          _selesai = todayHistoryCount;
          _nextBooking = nextBook;
          
          _notifications = newNotifs;
          _hasNewNotification = hasNewNotif;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 FUNGSI UNTUK MENGUBAH STATUS KERJA
  Future<void> _toggleDutyStatus(bool value) async {
    setState(() {
      _isOnDuty = value;
    });
    
    // Simpan ke memori lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_on_duty', value);

    // TODO: Jika nanti ada API untuk kirim status absensi ke Backend PHP, panggil di sini
    // contoh: await ApiService().updateStatusAbsensi(value ? 'on' : 'off');
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '--:--';
    try {
      if (rawTime.contains(' ')) {
        final timePart = rawTime.split(' ')[1]; 
        final parts = timePart.split(':');
        if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      }
      if (rawTime.split(':').length >= 2) {
         final parts = rawTime.split(':');
         return '${parts[0]}:${parts[1]}';
      }
      return rawTime;
    } catch (e) {
      return rawTime; 
    }
  }

  void _showNotificationModal(BuildContext context) {
    setState(() {
      _hasNewNotification = false;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDarkBrown)),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _notifications.clear());
                        Navigator.pop(context);
                      },
                      child: Text('Bersihkan', style: TextStyle(color: primaryPeach, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              const SizedBox(height: 10),
              if (_notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('Tidak ada pemberitahuan baru.', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ..._notifications.map((notif) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryPeach.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryPeach.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_turned_in, size: 16, color: primaryPeach),
                              const SizedBox(width: 8),
                              Text(notif['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: textDarkBrown)),
                            ],
                          ),
                          Text(notif['time']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notif['body']!, style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), height: 1.4)),
                    ],
                  ),
                )).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- DEFINISI WARNA DESAIN BARU ---
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);
  final Color goldBrown = const Color(0xFFB08D57);

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
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData, 
            color: primaryPeach,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  
                  // RINGKASAN HARI INI
                  Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown),
                  ),
                  const SizedBox(height: 12),
                  _buildSummarySection(),
                  const SizedBox(height: 24),
                  
                  // TUGAS BERIKUTNYA
                  Text(
                    'Tugas Berikutnya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDarkBrown),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_nextBooking != null)
                    _buildNextBookingCard(context)
                  else
                    // Muncul jika di jadwal memang tidak ada tugas aktif
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada pekerjaan',
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // BANNER GAMBAR PENGGANTI AKSI CEPAT
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/gambar1.jpeg', 
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Siapkan gambar di assets/gambar1.jpeg', 
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _fotoProfile.isNotEmpty && _fotoProfile.startsWith('http')
              ? NetworkImage(_fotoProfile)
              : const AssetImage('assets/default_profile.png') as ImageProvider, 
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat pagi,',
              style: TextStyle(fontSize: 14, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w500), 
            ),
            Text(
              _namaTerapis,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDarkBrown),
            ),
          ],
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              onPressed: () => _showNotificationModal(context),
              icon: Icon(Icons.notifications_none_rounded, size: 28, color: textDarkBrown),
            ),
            if (_hasNewNotification)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 🔥 UPDATE: Tampilan Status Kerja Baru Sesuai Referensi Gambar (Tombol Kapsul & Jam Besar)
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // KIRI: Label Status Kerja, Tombol Pill ON/OFF DUTY, dan Jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Kerja', style: TextStyle(fontSize: 14, color: textDarkBrown.withOpacity(0.7), fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tombol Kapsul (Pill) untuk mengganti status
                    GestureDetector(
                      onTap: () => _toggleDutyStatus(!_isOnDuty),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isOnDuty ? const Color(0xFFE8F5E9) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isOnDuty ? 'ON DUTY' : 'OFF DUTY', 
                          style: TextStyle(
                            color: _isOnDuty ? const Color(0xFF4CAF50) : Colors.grey.shade600, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 11,
                            letterSpacing: 0.5,
                          )
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Jam Kerja (Besar dan Tebal)
                    Text('08.00 - 17.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown)),
                  ],
                ),
              ],
            ),
          ),
          
          // KANAN: Tombol Absensi & Chat Admin (Tetap Dipertahankan)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/leave_management').then((_) {
                    _loadData();
                  });
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryPeach.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.assignment_turned_in, color: primaryPeach, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text('Absensi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDarkBrown)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chat_admin'),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryPeach.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline, color: primaryPeach, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text('Chat Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDarkBrown)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            _isLoading ? '...' : _bookingHariIni.toString(), 
            'Booking Hari Ini', 
            textDarkBrown,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            _isLoading ? '...' : _selesai.toString(), 
            'Selesai', 
            goldBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String value, String label, Color valueColor) {
    return Container(
      height: 110, 
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: valueColor)),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNextBookingCard(BuildContext context) {
    final rawJam = _nextBooking?['start_time']?.toString() ?? '--:--';
    final jam = _formatTime(rawJam); 
    final namaKlien = _nextBooking?['customer_name'] ?? 'Klien';
    final deskripsi = _nextBooking?['treatment_summary'] ?? 'Treatment';
    
    final roomType = _nextBooking?['room_type']?.toString() ?? '';
    final gerai = _nextBooking?['gerai']?.toString() ?? '';
    String alamat = [gerai, roomType].where((e) => e.isNotEmpty).join(' - ');
    if (alamat.isEmpty) {
      alamat = 'Menunggu konfirmasi lokasi';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(jam, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDarkBrown)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaKlien, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                Text(deskripsi, style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: textDarkBrown.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(alamat, 
                        style: TextStyle(fontSize: 11, color: textDarkBrown.withOpacity(0.6)), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/booking_detail', arguments: _nextBooking).then((_) {
                _loadData();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPeach,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              elevation: 0,
            ),
            child: const Row(
              children: [
                Text('Detail', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }
}