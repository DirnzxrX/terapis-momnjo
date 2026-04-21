import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // WAJIB UNTUK MEMORI
import 'dart:convert'; // WAJIB UNTUK MENGUBAH LIST/MAP MENJADI STRING JSON

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
  bool _isDataLoaded = false; // Penanda agar UI menunggu memori selesai dibaca
  bool _isOnDuty = false; 
  double _dragValue = 0.0; 
  bool _isDragging = false;

  String _selectedLeaveType = 'Cuti Tahunan';
  final List<String> _leaveTypes = ['Cuti Tahunan', 'Sakit', 'Cuti Darurat', 'Cuti Melahirkan', 'Izin'];
  
  String _selectedHistoryTab = 'Riwayat Cuti';

  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  final List<Map<String, dynamic>> _leaveHistory = [
    {'title': 'Cuti Tahunan', 'date': '16 Apr 2026 - 18 Apr 2026', 'reason': 'Acara pernikahan keluarga', 'status': 'Menunggu', 'color': Colors.orange.shade300},
    {'title': 'Cuti Sakit', 'date': '10 Mar 2026 - 11 Mar 2026', 'reason': 'Gejala flu dan demam', 'status': 'Disetujui', 'color': Colors.green.shade400},
  ];

  // Hapus kata 'final' agar list riwayat absensi ini bisa ditimpa oleh memori lokal
  List<Map<String, dynamic>> _attendanceHistory = [
    {
      'type': 'Daily Record', 'date': '16 Apr 2026', 
      'in': '08:02 WIB', 'out': '17:05 WIB', 
      'status': 'Present', 'reason': null,
    },
    {
      'type': 'Daily Record', 'date': '15 Apr 2026', 
      'in': '08:30 WIB', 'out': '17:00 WIB', 
      'status': 'Late: 30m', 'reason': null,
    },
    {
      'type': '14 Apr Record', 'date': '14 Apr 2026', 
      'in': '07:58 WIB', 'out': '17:00 WIB', 
      'status': 'Present', 'reason': null,
    },
    {
      'type': '13 Apr Record', 'date': '13 Apr 2026', 
      'in': '--', 'out': '--', 
      'status': 'Absent', 'reason': 'Sick leave',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDutyStatus(); // 🚨 BACA MEMORI SAAT LAYAR DIBANGUN
  }

  // --- ARSITEKTUR MEMORI: MEMBACA STATUS DAN RIWAYAT ---
  Future<void> _loadDutyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    // Load Riwayat Absensi dari memori HP
    final String? savedHistory = prefs.getString('attendance_history');
    if (savedHistory != null) {
      try {
        final List<dynamic> decodedHistory = jsonDecode(savedHistory);
        _attendanceHistory = decodedHistory.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Gagal membaca riwayat absensi dari memori: $e');
      }
    }

    setState(() {
      _isOnDuty = prefs.getBool('is_on_duty') ?? false;
      _dragValue = _isOnDuty ? 1.0 : 0.0;
      _isDataLoaded = true; // Sinyal bahwa memori selesai dibaca
    });
  }

  // --- FUNGSI UNTUK MENYIMPAN RIWAYAT ABSENSI KE MEMORI ---
  Future<void> _saveAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedHistory = jsonEncode(_attendanceHistory);
    await prefs.setString('attendance_history', encodedHistory);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
  }

  String _getCurrentDateStr() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
  }

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

  // --- ARSITEKTUR MEMORI: MENYIMPAN STATUS BARU ---
  Future<void> _handleDutyToggle(bool newDutyStatus) async {
    if (_isOnDuty == newDutyStatus) return; 

    // 🚨 SIMPAN KE MEMORI HP SETIAP KALI SLIDER DIGESER
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_on_duty', newDutyStatus);

    setState(() {
      _isOnDuty = newDutyStatus;
      _dragValue = _isOnDuty ? 1.0 : 0.0;

      final currentTime = _getCurrentTime();
      final currentDate = _getCurrentDateStr();

      if (_isOnDuty) {
        _attendanceHistory.insert(0, {
          'type': 'Daily Record',
          'date': currentDate,
          'in': currentTime,
          'out': '--', 
          'status': 'Present',
          'reason': null,
        });
        _showInfoMessage('Berhasil Clock In (On Duty) pada $currentTime');
      } else {
        for (var record in _attendanceHistory) {
          if (record['out'] == '--') {
            record['out'] = currentTime; 
            break; 
          }
        }
        _showInfoMessage('Berhasil Clock Out (Off Duty) pada $currentTime');
      }
    });

    // 🚨 SIMPAN RIWAYAT BARU KE DALAM MEMORI SETELAH UI DIUPDATE
    await _saveAttendanceHistory();
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

  Future<void> _selectDate(BuildContext context, {required bool isStart, required bool isForFilter}) async {
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
        if (isForFilter) {
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
        } else {
          if (isStart) {
            _startDate = picked;
            if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
          } else {
            if (_startDate != null && picked.isBefore(_startDate!)) {
              _showInfoMessage('Tanggal Selesai tidak boleh sebelum Tanggal Mulai!', isError: true);
              return;
            }
            _endDate = picked;
          }
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _submitLeaveRequest() {
    if (_startDate == null || _endDate == null) {
      _showInfoMessage('Harap pilih Tanggal Mulai dan Tanggal Selesai terlebih dahulu.', isError: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showInfoMessage('Harap isi alasan pengajuan cuti Anda.', isError: true);
      return;
    }

    String dateRange = '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';

    setState(() {
      _leaveHistory.insert(0, {
        'title': _selectedLeaveType,
        'date': dateRange,
        'reason': _reasonController.text.trim(),
        'status': 'Menunggu',
        'color': Colors.orange.shade300,
      });

      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedLeaveType = _leaveTypes.first;
    });

    _showInfoMessage('Pengajuan $_selectedLeaveType berhasil dikirim!');
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
            'Manajemen Cuti', 
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
                
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedHistoryTab == 'Riwayat Cuti' 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pengajuan Cuti Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDarkBrown)),
                            const SizedBox(height: 12),
                            _buildNewLeaveForm(),
                            const SizedBox(height: 24),
                            Center(
                              child: Text('Riwayat Catatan', style: TextStyle(fontSize: 14, color: textDarkBrown, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                _buildHistoryTabs(),
                const SizedBox(height: 16),
                
                _selectedHistoryTab == 'Riwayat Cuti' 
                    ? _buildLeaveHistory() 
                    : _buildAttendanceHistory(),
                    
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sarah Johnson', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDarkBrown)),
                  Text('Terapis Senior', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tahan render slider sampai memori berhasil ditarik agar tidak berkedip (flash)
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
                    setState(() {
                      double currentLeft = (_dragValue * maxDrag) + details.delta.dx;
                      _dragValue = (currentLeft / maxDrag).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                    _handleDutyToggle(_dragValue > 0.5);
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
                          child: Container(width: thumbWidth, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                        ),
                        Center(
                          child: Text(
                            _isOnDuty ? 'Geser ke Off Duty' : 'Geser ke On Duty',
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

  Widget _buildNewLeaveForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis Cuti', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            isExpanded: true, value: _selectedLeaveType,
            underline: Container(height: 1, color: Colors.grey.shade300), 
            icon: Icon(Icons.arrow_drop_down, color: textDarkBrown),
            style: TextStyle(color: textDarkBrown, fontSize: 16, fontWeight: FontWeight.w600),
            items: _leaveTypes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (val) => setState(() => _selectedLeaveType = val!),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDateField('Tanggal Mulai', _formatDate(_startDate), () => _selectDate(context, isStart: true, isForFilter: false))),
              const SizedBox(width: 16),
              Expanded(child: _buildDateField('Tanggal Selesai', _formatDate(_endDate), () => _selectDate(context, isStart: false, isForFilter: false))),
            ],
          ),
          const SizedBox(height: 20),
          Text('Alasan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          TextField(
            controller: _reasonController, maxLines: 1, style: TextStyle(color: textDarkBrown, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Masukkan alasan di sini...', hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryOrange)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLeaveRequest, 
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Kirim Pengajuan Cuti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHistoryTab = 'Riwayat Cuti'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedHistoryTab == 'Riwayat Cuti' ? primaryOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedHistoryTab == 'Riwayat Cuti' ? primaryOrange : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                'Riwayat Cuti',
                style: TextStyle(color: _selectedHistoryTab == 'Riwayat Cuti' ? Colors.white : textDarkBrown, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHistoryTab = 'Riwayat Absensi'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedHistoryTab == 'Riwayat Absensi' ? primaryOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedHistoryTab == 'Riwayat Absensi' ? primaryOrange : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                'Riwayat Absensi',
                style: TextStyle(color: _selectedHistoryTab == 'Riwayat Absensi' ? Colors.white : textDarkBrown, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveHistory() {
    return Column(
      children: List.generate(_leaveHistory.length, (index) {
        final item = _leaveHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['title'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textDarkBrown)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: item['color'].withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(item['status'], style: TextStyle(color: item['color'], fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(item['date'], style: TextStyle(fontSize: 13, color: textDarkBrown.withOpacity(0.8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Alasan: ${item['reason']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        );
      }),
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
                Text('Filter by Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkBrown)),
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
            Expanded(child: _buildDateField('Pilih Tanggal', _formatDate(_filterStartDate), () => _selectDate(context, isStart: true, isForFilter: true))),
            const SizedBox(width: 12),
            Expanded(child: _buildDateField('Pilih Tanggal', _formatDate(_filterEndDate), () => _selectDate(context, isStart: false, isForFilter: true))),
          ],
        ),
        const SizedBox(height: 24),

        if (filteredList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Tidak ada riwayat absensi pada rentang tanggal tersebut.', 
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
    
    if (data['status'] == 'Present') {
      badgeBgColor = Colors.green.shade100;
      badgeTextColor = Colors.green.shade800;
    } else if (data['status'].toString().contains('Late')) {
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
                child: Text('Reason: ${data['reason']}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red.shade800)),
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