import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:geolocator/geolocator.dart'; 
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
  bool _isLoadingDetail = false; 
  
  String? _arrivalPhotoPath; 
  Position? _currentPosition;
  String _photoTimestamp = '';

  bool _isPemeriksaanSkipped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _data = Map<String, dynamic>.from(args); 
        String passedStatus = args['booking_status'] ?? args['status'] ?? 'Open';
        passedStatus = passedStatus.trim(); 
        
        if (['new', 'open', 'menunggu', 'pending'].contains(passedStatus.toLowerCase())) {
          passedStatus = 'Accepted';
        }
        _currentStatus = passedStatus;

        final idTrans = _data?['id_transaksi']?.toString();
        if (idTrans != null && idTrans.isNotEmpty) {
          _loadJobDetail(idTrans);
        }
      } else {
        _currentStatus = 'Accepted';
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadJobDetail(String idTransaksi) async {
    setState(() => _isLoadingDetail = true);
    
    final response = await ApiService().getJobDetail(idTransaksi);
    
    if (mounted && response['success'] == true) {
      setState(() {
        _data!['address'] = response['address'];
        _data!['coordinate_address'] = response['coordinate_address'];
        _data!['catatan_alamat'] = response['catatan_alamat'];
        
        if (response['data'] != null && response['data'] is List) {
          _data!['treatments'] = response['data']; 
        }
      });
    }
    
    if (mounted) {
      setState(() => _isLoadingDetail = false);
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

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return 'Pekerjaan di terima';
      case 'arrived': return 'Sudah tiba';
      case 'pemeriksaan': return 'Cek Kesehatan';
      case 'started': return 'Mulai';
      case 'completed': 
      case 'closed': return 'Selesai';
      default: return status.toUpperCase();
    }
  }

  Future<void> _openMap(String coordinate) async {
    if (coordinate.isEmpty) return;

    final cleanCoordinate = coordinate.replaceAll(' ', '');
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$cleanCoordinate");
    final Uri fallbackUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$cleanCoordinate");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Aplikasi Maps tidak ditemukan';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka Maps: $e'), backgroundColor: Colors.red),
        );
      }
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
      imagePath: _arrivalPhotoPath, 
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

  Future<void> _captureSelfieAndLocation() async {
    setState(() => _isUpdatingStatus = true); 

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif. Mohon nyalakan lokasi Anda.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen. Silakan atur di Setting HP.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, 
      );

      if (photo != null) {
        if (!mounted) return;

        setState(() {
          _arrivalPhotoPath = photo.path;
          _currentPosition = position;
          _photoTimestamp = DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());
        });
        
        _showArrivalPhotoDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _showArrivalPhotoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Kedatangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pastikan wajah, lokasi, dan waktu sudah sesuai sebelum dikirim.', style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              
              if (_arrivalPhotoPath != null)
                SizedBox(
                  width: MediaQuery.of(context).size.width, 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Image.file(
                          File(_arrivalPhotoPath!), 
                          height: 300, 
                          width: double.maxFinite, 
                          fit: BoxFit.cover
                        ),
                        Container(
                          width: double.maxFinite, 
                          color: Colors.black.withOpacity(0.6), 
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_photoTimestamp, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Lat: ${_currentPosition?.latitude}\nLng: ${_currentPosition?.longitude}', 
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() { _arrivalPhotoPath = null; });
                      Navigator.pop(context);
                    }, 
                    child: Text('Ulangi', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); 
                      await _updateStatusAPI('Arrived'); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      elevation: 0
                    ),
                    child: const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
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
    String defaultAlamat = [gerai, roomType].where((e) => e.isNotEmpty).join(' - ');

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
      body: Stack(
        children: [
          Column(
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
                      _buildLocationCard(defaultAlamat),
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
          if (_isLoadingDetail)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

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
            child: Text(
              _getStatusLabel(status).toUpperCase(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
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

  Widget _buildLocationCard(String defaultAlamat) {
    final String address = _data?['address']?.toString() ?? defaultAlamat;
    final String catatan = _data?['catatan_alamat']?.toString() ?? _data?['patokan']?.toString() ?? 'Tidak ada catatan alamat/patokan khusus';
    final String coordinate = _data?['coordinate_address']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.black87, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(catatan, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          
          if (coordinate.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.black12),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openMap(coordinate),
                icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFFE8647C)),
                label: const Text(
                  'Arahkan ke Lokasi (Maps)', 
                  style: TextStyle(color: Color(0xFFE8647C), fontWeight: FontWeight.bold)
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE8647C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  // --- BAGIAN YANG DIPERBARUI: MENAMPILKAN DURASI LAYANAN ---
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
            String name = item is Map ? (item['name'] ?? item['product_name'] ?? 'Layanan') : item.toString();
            
            // Ekstrak durasi dari map (Sesuaikan key 'duration' atau 'durasi' dengan response API Anda)
            String duration = '';
            if (item is Map) {
              String rawDuration = (item['duration'] ?? item['durasi'] ?? item['waktu'] ?? '').toString();
              // Hapus kata 'min', 'mins', atau 'menit' bawaan dari API menggunakan property caseSensitive
              duration = rawDuration.replaceAll(RegExp(r'minutes|minute|mins|min|menit', caseSensitive: false), '').trim();
            }

            bool isDone = item is Map ? (item['is_done'] == true) : false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.spa_outlined, color: Colors.pink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14)),
                        // Tampilkan durasi jika ada
                        if (duration.isNotEmpty && duration != 'null')
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$duration Menit', 
                              style: const TextStyle(fontSize: 12, color: Colors.black54)
                            ),
                          ),
                      ],
                    ),
                  ),
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
        _buildTimelineStep('Pekerjaan di terima', '', true, false),
        _buildTimelineStep('Sudah tiba', '', isArrived, false),
        _buildTimelineStep('Cek Kesehatan', '', isPemeriksaan, false, isSkipped: _isPemeriksaanSkipped), 
        _buildTimelineStep('Mulai', '', isStarted, false),
        _buildTimelineStep('Selesai', '', isCompleted, true),
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
            if (!last) Container(width: 2, height: 30, color: (done && !isSkipped) ? Colors.green.withOpacity(0.5) : (done && isSkipped) ? Colors.red.withOpacity(0.3) : Colors.grey.shade300)
          ]
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text(label, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal, color: (done && isSkipped) ? Colors.red : Colors.black87)), 
              if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 12)),
            ]
          )
        ),
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
      return _buildSingleActionButton('CEK KESEHATAN KLIEN', () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PemeriksaanScreen(bookingData: _data)));
        
        if (result == 'skipped') {
          setState(() {
            _isPemeriksaanSkipped = true;
          });
        } else {
          setState(() {
            _isPemeriksaanSkipped = false;
          });
        }
        
        await _updateStatusAPI('Pemeriksaan');
      });
    }

    if (s == 'pemeriksaan') {
      return _buildSingleActionButton('MULAI SESI TREATMENT', () async {
        await _updateStatusAPI('Started');
        if (mounted) {
          final result = await Navigator.pushNamed(context, '/active_job', arguments: _data);
          
          if (result != null && result is Map && result['action'] == 'finish_treatment') {
             setState(() {
               _currentStatus = 'Closed';
               _data?['booking_status'] = 'Closed';
             });
             Navigator.pushReplacementNamed(context, '/visit_report', arguments: _data);
          }
        }
      });
    }

    if (s == 'started') {
      return _buildSingleActionButton('SELESAIKAN KUNJUNGAN', () async {
        setState(() { _isUpdatingStatus = true; }); 
        
        final api = ApiService();
        final List<dynamic> treatments = _data?['treatments'] ?? [];
        final String idTransaksi = _data?['id_transaksi']?.toString() ?? '';

        for (var item in treatments) {
          bool alreadyDone = item is Map && item['is_done'] == true;
          if (!alreadyDone) {
            String pName = '';
            if (item is Map) {
              pName = (item['product_name'] ?? item['name'] ?? '').toString().trim();
            } else {
              pName = item.toString().trim();
            }

            if (pName.isNotEmpty && idTransaksi.isNotEmpty) {
              await api.updateJobStatus(
                idTransaksi: idTransaksi,
                action: 'finish',
                productName: pName,
              );
            }
          }
        }

        await _updateStatusAPI('Closed');
        
        setState(() { _isUpdatingStatus = false; });
        
        if (mounted) Navigator.pushReplacementNamed(context, '/visit_report', arguments: _data);
      });
    }

    if (s == 'completed' || s == 'closed') {
      return _buildSingleActionButton('BUAT LAPORAN KUNJUNGAN', () async {
        setState(() { _isUpdatingStatus = true; }); 
        
        final api = ApiService();
        final List<dynamic> treatments = _data?['treatments'] ?? [];
        final String idTransaksi = _data?['id_transaksi']?.toString() ?? '';

        for (var item in treatments) {
          bool alreadyDone = item is Map && item['is_done'] == true;
          if (!alreadyDone) {
            String pName = '';
            if (item is Map) {
              pName = (item['product_name'] ?? item['name'] ?? '').toString().trim();
            } else {
              pName = item.toString().trim();
            }

            if (pName.isNotEmpty && idTransaksi.isNotEmpty) {
              await api.updateJobStatus(
                idTransaksi: idTransaksi,
                action: 'finish',
                productName: pName,
              );
            }
          }
        }
        
        setState(() { _isUpdatingStatus = false; });
        if (mounted) Navigator.pushReplacementNamed(context, '/visit_report', arguments: _data);
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus ? null : _captureSelfieAndLocation,
                icon: _isUpdatingStatus 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                label: Text(_isUpdatingStatus ? 'MENUNGGU GPS...' : 'SUDAH TIBA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}