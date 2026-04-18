import 'package:flutter/material.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({Key? key}) : super(key: key);

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);
  final Color primaryOrange = const Color(0xFFE78351);
  
  // --- STATE VARIABLES ---
  bool _isOnDuty = true;
  String _selectedLeaveType = 'Annual Leave';
  final List<String> _leaveTypes = ['Annual Leave', 'Sick Leave', 'Emergency Leave'];
  
  // State untuk Form Input
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  // State Dinamis untuk Riwayat Cuti (Simulasi Database)
  final List<Map<String, dynamic>> _leaveHistory = [
    {
      'title': 'Annual Leave',
      'date': '16 Apr - 18 Apr 2026',
      'reason': 'Family wedding',
      'status': 'Pending',
      'color': Colors.orange,
    },
    {
      'title': 'Sick Leave',
      'date': '10 Mar - 11 Mar 2026',
      'reason': 'Flu symptoms',
      'status': 'Approved',
      'color': Colors.green,
    },
    {
      'title': 'Annual Leave',
      'date': '05 Feb - 07 Feb 2026',
      'reason': 'Busy schedule',
      'status': 'Rejected',
      'color': Colors.red,
    },
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // --- LOGIKA DATE PICKER ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart 
          ? (_startDate ?? DateTime.now()) 
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(), // Cegah cuti di masa lalu
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryOrange, // Warna header & date yang dipilih
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Validasi otomatis: Jika End Date ternyata lebih kecil dari Start Date baru, reset End Date!
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          // Validasi manual: Jangan izinkan End Date sebelum Start Date
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tanggal Selesai tidak boleh sebelum Tanggal Mulai!')),
            );
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // --- LOGIKA SUBMIT CUTI ---
  void _submitLeaveRequest() {
    // 1. Validasi Kekosongan Data (Sparring Point: Jangan izinkan data sampah masuk ke sistem)
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih Tanggal Mulai dan Tanggal Selesai!')),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi alasan cuti Anda!')),
      );
      return;
    }

    // 2. Format Data untuk disimpan
    String dateRange = _startDate!.isAtSameMomentAs(_endDate!) 
        ? _formatDate(_startDate) 
        : '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';

    // 3. Masukkan ke State List (Simulasi POST ke API)
    setState(() {
      _leaveHistory.insert(0, {
        'title': _selectedLeaveType,
        'date': dateRange,
        'reason': _reasonController.text.trim(),
        'status': 'Pending',
        'color': Colors.orange,
      });

      // 4. Bersihkan Form setelah sukses
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedLeaveType = 'Annual Leave';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan cuti berhasil dikirim! (Simulasi)')),
    );
  }

  // --- LOGIKA CANCEL CUTI ---
  void _cancelRequest(int index) {
    // Sparring Point: Konfirmasi ulang sebelum melakukan tindakan destruktif!
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Cuti?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan cuti ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tidak', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _leaveHistory.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengajuan cuti dibatalkan.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Leave Management',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          // Memastikan keyboard turun saat tap di luar text field
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildNewLeaveForm(),
                const SizedBox(height: 24),
                _buildLeaveHistory(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Sarah Johnson',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (!_isOnDuty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(12)),
                          child: const Text('ON LEAVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  const Text('Senior Therapist', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Custom Slider Toggle
          GestureDetector(
            onTap: () => setState(() => _isOnDuty = !_isOnDuty),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _isOnDuty ? primaryOrange : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _isOnDuty ? 200 : 5, 
                    right: _isOnDuty ? 5 : 200,
                    top: 5,
                    bottom: 5,
                    child: Container(
                      width: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                  Center(
                    child: Text(
                      _isOnDuty ? 'Slide to Off Duty' : 'Slide to On Duty',
                      style: TextStyle(
                        color: _isOnDuty ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewLeaveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('New Leave Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedLeaveType,
                items: _leaveTypes.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (val) => setState(() => _selectedLeaveType = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateField('Start Date', _formatDate(_startDate), () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('End Date', _formatDate(_endDate), () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Reason', style: TextStyle(fontSize: 12, color: Colors.grey)),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter your reason here...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit Leave Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String dateStr, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateStr, 
                    style: TextStyle(
                      fontSize: 13, 
                      color: dateStr == 'Pilih Tanggal' ? Colors.grey : Colors.black87
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Leave History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Render history secara dinamis dari State List
        if (_leaveHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Belum ada riwayat cuti.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...List.generate(_leaveHistory.length, (index) {
            final item = _leaveHistory[index];
            return _buildHistoryItem(
              index,
              item['title'],
              item['date'],
              item['reason'],
              item['status'],
              item['color'],
            );
          }),
      ],
    );
  }

  Widget _buildHistoryItem(int index, String title, String date, String reason, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Reason: $reason', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          
          // Hanya tampilkan tombol Cancel jika status masih Pending
          if (status == 'Pending') ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _cancelRequest(index),
                child: const Text('Cancel Request', style: TextStyle(color: Colors.redAccent, fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}