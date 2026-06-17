import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart'; // Pastikan import ApiService ada

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({Key? key}) : super(key: key);

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  // --- WARNA DESAIN ---
  final Color primaryOrange = const Color(0xFFE5804D); 
  final Color textDarkBrown = const Color(0xFF4A332B);
  
  // --- STATE VARIABLES ---
  bool _isDataLoaded = false;
  bool _isOnDuty = false; 
  double _dragValue = 0.0; 
  bool _isDragging = false;
  bool _isSubmitting = false; 

  String _therapistName = 'Memuat...';

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<Map<String, dynamic>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- PERBAIKAN ARSITEKTUR: SUMBER KEBENARAN DARI API SERVER ---
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    // 1. Load Nama Terapis dan Status Toggle dari Local 
    String? savedName = prefs.getString('user_name') ?? prefs.getString('nama_lengkap');
    bool currentDutyStatus = prefs.getBool('is_on_duty') ?? false;

    // 2. Load Riwayat Absensi LANGSUNG DARI SERVER API
    await _fetchHistoryFromServer();

    if (mounted) {
      setState(() {
        _therapistName = (savedName != null && savedName.isNotEmpty) ? savedName : 'Terapis (Belum diset)';
        _isOnDuty = currentDutyStatus;
        _dragValue = _isOnDuty ? 1.0 : 0.0;
        _isDataLoaded = true;
      });
    }
  }

  // --- FUNGSI PARSING JSON YANG SUDAH DIPERBAIKI ---
  Future<void> _fetchHistoryFromServer() async {
    try {
      final apiResult = await ApiService().getAttendanceHistory();
      
      if (apiResult['success'] == true && apiResult['data'] != null) {
        
        // Membaca object 'history' di dalam object 'data'
        final dataMap = apiResult['data'] as Map<String, dynamic>;
        final List<dynamic> rawData = dataMap['history'] ?? [];
        
        setState(() {
          _attendanceHistory = rawData.map((item) {
            final mapItem = Map<String, dynamic>.from(item);
            
            // Ekstrak nested object
            final checkInMap = mapItem['check_in'] as Map<String, dynamic>?;
            final checkOutMap = mapItem['check_out'] as Map<String, dynamic>?;

            // Helper untuk mengambil jam dari format "2026-06-17 09:58:06" menjadi "09:58 WIB"
            String formatTime(String? datetime) {
              if (datetime == null || datetime.isEmpty) return '--';
              try {
                final timePart = datetime.split(' ').last; 
                if (timePart.length >= 5) {
                  final hm = timePart.substring(0, 5); 
                  return '$hm WIB';
                }
                return timePart;
              } catch (_) {
                return datetime;
              }
            }

            // Helper untuk memoles tanggal
            String formatDateLabel(String? rawDate) {
              if (rawDate == null || rawDate.isEmpty) return '-';
              try {
                DateTime dt = DateTime.parse(rawDate);
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
                return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
              } catch (e) {
                return rawDate;
              }
            }

            return {
              'type': 'Absensi Reguler', 
              'date': formatDateLabel(mapItem['tanggal']),
              'in': formatTime(checkInMap?['waktu']),
              'out': formatTime(checkOutMap?['waktu']),
              'status': 'Hadir', 
              'reason': (mapItem['catatan'] != null && mapItem['catatan'].toString().isNotEmpty) 
                          ? mapItem['catatan'] 
                          : null,
            };
          }).toList();
        });
      } else {
        setState(() => _attendanceHistory = []);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data riwayat dari server: $e");
    }
  }

  // 🔥 LOGIKA TOGGLE ABSENSI
  Future<void> _handleDutyToggle(bool newDutyStatus) async {
    if (_isOnDuty == newDutyStatus || _isSubmitting) {
      setState(() => _dragValue = _isOnDuty ? 1.0 : 0.0);
      return; 
    }

    setState(() { _isSubmitting = true; });

    _showInfoMessage('Memproses absensi ke server...');

    String action = newDutyStatus ? 'check_in' : 'check_out';
    final apiResult = await ApiService().submitAttendance(action: action);

    if (apiResult['success'] == true || apiResult['status'] == 'success') {
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_on_duty', newDutyStatus);

      // Paksa HP mengambil ulang data terbaru dari Server setelah sukses absen
      await _fetchHistoryFromServer();

      if (mounted) {
        setState(() {
          _isOnDuty = newDutyStatus;
          _dragValue = _isOnDuty ? 1.0 : 0.0;
          _isSubmitting = false;
        });
        
        _showInfoMessage(newDutyStatus ? 'Berhasil Absen Masuk (On Duty)' : 'Berhasil Absen Keluar (Off Duty)');
      }

    } else {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _dragValue = _isOnDuty ? 1.0 : 0.0; 
        });
        _showInfoMessage(apiResult['message'] ?? 'Gagal absensi ke server.', isError: true);
      }
    }
  }

  void _showInfoMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime initial = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryOrange, onPrimary: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _filterStartDate = picked;
          if (_filterEndDate != null && _filterEndDate!.isBefore(_filterStartDate!)) _filterEndDate = null;
        } else {
          if (_filterStartDate != null && picked.isBefore(_filterStartDate!)) {
            _showInfoMessage('Tanggal Selesai tidak boleh sebelum Tanggal Mulai!', isError: true);
            return;
          }
          _filterEndDate = picked;
        }
        if (_filterStartDate != null && _filterEndDate != null) {
          _showInfoMessage('Memfilter data dari ${_formatDate(_filterStartDate)} ke ${_formatDate(_filterEndDate)}');
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // --- KEMBALIKAN FUNGSI INI AGAR FILTER TANGGAL BERFUNGSI ---
  DateTime? _parseDateStr(String dateStr) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = months.indexOf(parts[1]) + 1;
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
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
            'Manajemen Absensi', 
            style: TextStyle(color: textDarkBrown, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                
                Text(
                  'Riwayat Kehadiran', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)
                ),
                const SizedBox(height: 16),
                
                _buildAttendanceHistory(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=43')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_therapistName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown)),
                    Text('Terapis', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (!_isDataLoaded)
            const SizedBox(
              height: 54, 
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const double thumbWidth = 40.0;
                const double padding = 8.0;
                final double maxDrag = constraints.maxWidth - thumbWidth - (padding * 2);
                double leftPos = _isDragging ? (_dragValue * maxDrag) + padding : (_isOnDuty ? maxDrag + padding : padding);

                return GestureDetector(
                  onTap: () {
                    _handleDutyToggle(!_isOnDuty);
                  },
                  onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                  onHorizontalDragUpdate: (details) {
                    if (_isSubmitting) return; 
                    setState(() {
                      double currentLeft = (_dragValue * maxDrag) + details.delta.dx;
                      _dragValue = (currentLeft / maxDrag).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                    
                    bool shouldBeOnDuty = _dragValue > 0.5;
                    _handleDutyToggle(shouldBeOnDuty);
                  },
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      color: _isOnDuty ? primaryOrange : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Duration(milliseconds: _isDragging ? 0 : 250), curve: Curves.easeInOut,
                          left: leftPos, top: 8, bottom: 8,
                          child: Container(
                            width: thumbWidth, 
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: _isSubmitting 
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0), 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                ) 
                              : null,
                          ),
                        ),
                        Center(
                          child: Text(
                            _isSubmitting ? 'Memproses...' : (_isOnDuty ? 'Geser untuk Absen Keluar' : 'Geser untuk Absen Masuk'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    List<Map<String, dynamic>> filteredList = _attendanceHistory.where((item) {
      if (_filterStartDate == null && _filterEndDate == null) return true;

      DateTime? itemDate = _parseDateStr(item['date']);
      if (itemDate == null) return true; 

      DateTime? start = _filterStartDate != null ? DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day) : null;
      DateTime? end = _filterEndDate != null ? DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day) : null;

      if (start != null && itemDate.isBefore(start)) return false;
      if (end != null && itemDate.isAfter(end)) return false;

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Berdasarkan Tanggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
                Text('Pilih Rentang Tanggal', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
            if (_filterStartDate != null || _filterEndDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterStartDate = null;
                    _filterEndDate = null;
                  });
                },
                child: Text('Reset Filter', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDateField('Pilih Tanggal', _formatDate(_filterStartDate), () => _selectDate(context, isStart: true))),
            const SizedBox(width: 12),
            Expanded(child: _buildDateField('Pilih Tanggal', _formatDate(_filterEndDate), () => _selectDate(context, isStart: false))),
          ],
        ),
        const SizedBox(height: 24),

        if (filteredList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                _isDataLoaded ? 'Tidak ada riwayat absensi pada rentang tanggal tersebut.' : 'Memuat riwayat dari server...', 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...filteredList.map((item) => _buildAttendanceCard(item)).toList(),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data) {
    Color badgeBgColor;
    Color badgeTextColor;
    
    if (data['status'] == 'Hadir') {
      badgeBgColor = Colors.green.shade100;
      badgeTextColor = Colors.green.shade800;
    } else if (data['status'].toString().contains('Terlambat')) {
      badgeBgColor = Colors.orange.shade100;
      badgeTextColor = Colors.orange.shade900;
    } else {
      badgeBgColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade900;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['type'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textDarkBrown)),
                Row(
                  children: [
                    Text(data['date'], style: TextStyle(fontSize: 12, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(data['status'], style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (data['reason'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Alasan: ${data['reason']}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red.shade800)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F2ED), 
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Masuk', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(data['in'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textDarkBrown)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300), 
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Keluar', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(data['out'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textDarkBrown)),
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

  Widget _buildDateField(String label, String dateStr, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                dateStr, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: dateStr == 'Pilih Tanggal' ? FontWeight.normal : FontWeight.w600,
                  color: dateStr == 'Pilih Tanggal' ? Colors.grey.shade400 : textDarkBrown
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}