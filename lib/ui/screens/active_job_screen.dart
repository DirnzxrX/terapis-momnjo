import 'package:flutter/material.dart';
import 'dart:async';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({Key? key}) : super(key: key);

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);

  Map<String, dynamic>? _bookingData;
  bool _isDataLoaded = false;

  Timer? _timer;
  int _secondsElapsed = 0; 
  final int _estimatedTotalSeconds = 90 * 60; 
  
  bool _hasStarted = false; 
  bool _isPaused = false; 

  final List<String> _steps = [
    'Konsultasi & Anamnesa',
    'Persiapan',
    'Massage Punggung',
    'Massage Kaki',
    'Relaksasi & Finishing',
  ];
  List<bool> _stepsDone = [false, false, false, false, false];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bookingData = args;
        
        if (args.containsKey('savedState') && args['savedState'] != null) {
          final saved = args['savedState'];
          _secondsElapsed = saved['secondsElapsed'] ?? 0;
          _hasStarted = saved['hasStarted'] ?? false;
          _isPaused = saved['isPaused'] ?? false;
          
          if (saved['stepsDone'] != null) {
            _stepsDone = List<bool>.from(saved['stepsDone']);
          }

          // PERBAIKAN FATAL: Selalu hidupkan mesin timer jika sudah pernah "Mulai"
          // Walaupun sedang pause, mesin timer harus "standby" di background
          if (_hasStarted) {
            _startTimer();
          }
        }
      }
      _isDataLoaded = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Cegah duplikasi timer
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) { // Cek mounted agar tidak error saat layar pindah
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _handleTimerAction() {
    if (!_hasStarted) {
      setState(() {
        _hasStarted = true;
        _isPaused = false;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Treatment resmi dimulai"), duration: Duration(seconds: 1)),
      );
    } else {
      setState(() {
        _isPaused = !_isPaused;
        // JAGA-JAGA: Jika mesin timer mati karena suatu hal, hidupkan lagi saat unpause
        if (!_isPaused && (_timer == null || !_timer!.isActive)) {
          _startTimer();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPaused ? "Treatment di-pause sementara" : "Treatment dilanjutkan"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRemaining(int elapsed, int total) {
    int remaining = total - elapsed;
    if (remaining < 0) remaining = 0;
    int minutes = remaining ~/ 60;
    int seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _saveStateAndPop() {
    _timer?.cancel();
    Navigator.pop(context, {
      'action': 'save_state',
      'secondsElapsed': _secondsElapsed,
      'stepsDone': _stepsDone,
      'hasStarted': _hasStarted,
      'isPaused': _isPaused,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        _saveStateAndPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: primaryPink,
          elevation: 0,
          title: const Text('Job Aktif', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _saveStateAndPop,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Container(height: 100, width: double.infinity, color: primaryPink),
                    Column(
                      children: [
                        _buildHeaderInfo(),
                        const SizedBox(height: 16),
                        _buildTimerCard(),
                        const SizedBox(height: 24),
                        _buildProgressSection(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final String namaKlien = _bookingData?['customer_fullname'] ?? 'Klien';
    final String layanan = _bookingData?['deskripsi'] ?? 'Layanan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(namaKlien, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(layanan, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.call_outlined, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    String statusText = !_hasStarted ? 'Menunggu Dimulai' : (_isPaused ? 'Durasi Dihentikan' : 'Durasi Berjalan');
    Color statusColor = !_hasStarted ? Colors.orange.shade700 : (_isPaused ? Colors.red.shade400 : Colors.grey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_secondsElapsed),
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: (!_hasStarted) ? Colors.grey.shade400 : (_isPaused ? Colors.red.shade700 : Colors.black87)
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Sisa Estimasi', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                _formatRemaining(_secondsElapsed, _estimatedTotalSeconds),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    int finishedCount = _stepsDone.where((element) => element == true).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Treatment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$finishedCount dari ${_steps.length} selesai', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          for (int i = 0; i < _steps.length; i++)
            _buildProgressItem(i, _steps[i], isDone: _stepsDone[i]),
        ],
      ),
    );
  }

  Widget _buildProgressItem(int index, String title, {required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          if (!_hasStarted) return;
          setState(() { _stepsDone[index] = !_stepsDone[index]; });
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? Colors.green : Colors.transparent,
                border: Border.all(color: isDone ? Colors.green : Colors.grey.shade400, width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.check, size: 14, color: isDone ? Colors.white : Colors.transparent),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 14, color: isDone ? Colors.black87 : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    IconData btnIcon = !_hasStarted ? Icons.play_arrow : (_isPaused ? Icons.play_arrow : Icons.pause);
    String btnText = !_hasStarted ? 'Mulai' : (_isPaused ? 'Resume' : 'Pause');
    Color btnColor = !_hasStarted ? Colors.green.shade600 : (_isPaused ? Colors.blue : primaryPink);

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleTimerAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: btnColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(btnIcon, color: btnColor, size: 18),
                  const SizedBox(width: 6),
                  Text(btnText, style: TextStyle(color: btnColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !_hasStarted ? null : _showFinishDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selesai Treatment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Selesaikan Treatment?"),
        content: const Text("Pastikan semua tahapan sudah selesai."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, {
                'action': 'finish_treatment',
                'durasi_aktual': _secondsElapsed,
              });
            },
            child: const Text("Ya, Selesai"),
          ),
        ],
      ),
    );
  }
}