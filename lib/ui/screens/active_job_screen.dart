import 'package:flutter/material.dart';
import 'dart:async';
import 'package:therapist_momnjo/data/api_service.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({Key? key}) : super(key: key);

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);

  Map<String, dynamic>? _bookingData;
  bool _isDataLoaded = false;
  bool _isApiLoading = false; 

  String _idTransaksi = '';
  String _productName = '';

  Timer? _timer;
  int _secondsElapsed = 0; 
  int _estimatedTotalSeconds = 0; 
  
  bool _hasStarted = false; 
  bool _isPaused = false; 

  List<dynamic> _treatments = [];
  List<bool> _treatmentsDone = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bookingData = args;
        
        _idTransaksi = args['id_transaksi']?.toString() ?? '';
        _productName = args['product_name']?.toString() ?? 'Treatment';
        
        _treatments = args['treatments'] ?? [];

        if (_treatments.isEmpty && _productName.isNotEmpty && _productName != 'Treatment') {
          _treatments = [_productName];
        }

        // --- LOGIKA AKUMULASI WAKTU ---
        if (_treatments.isNotEmpty) {
          int totalMenit = 0;
          for (var item in _treatments) {
            int dur = 60;
            int qty = 1;
            if (item is Map) {
              dur = int.tryParse(item['durasi']?.toString() ?? '60') ?? 60;
              qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
            } else {
              dur = _extractDurationFromProductName(item.toString()) ~/ 60;
            }
            totalMenit += (dur * qty);
          }
          _estimatedTotalSeconds = totalMenit * 60; 
        } else {
          _estimatedTotalSeconds = _extractDurationFromProductName(_productName);
        }

        if (args.containsKey('savedState') && args['savedState'] != null) {
          final saved = args['savedState'];
          _secondsElapsed = saved['secondsElapsed'] ?? 0;
          _hasStarted = saved['hasStarted'] ?? false;
          _isPaused = saved['isPaused'] ?? false;
          
          if (saved['treatmentsDone'] != null) {
            _treatmentsDone = List<bool>.from(saved['treatmentsDone']);
          } else {
            _treatmentsDone = List.filled(_treatments.length, false);
          }

          if (_hasStarted && !_isPaused) {
            _startTimer();
          }
        } else {
          _treatmentsDone = List.generate(_treatments.length, (index) {
            final item = _treatments[index];
            if (item is Map && item['is_done'] == true) return true;
            return false;
          });
        }
      }
      _isDataLoaded = true;
    }
  }

  int _extractDurationFromProductName(String name) {
    final RegExp regExp = RegExp(r'(\d+)\s*(min|menit|mins)', caseSensitive: false);
    final match = regExp.firstMatch(name);
    
    if (match != null) {
      int minutes = int.tryParse(match.group(1) ?? '60') ?? 60;
      return minutes * 60; 
    }
    return 60 * 60; 
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) { 
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _handleTimerAction() async {
    if (!_hasStarted) {
      setState(() => _isApiLoading = true);
      
      final api = ApiService();
      String startProductName = _treatments.isNotEmpty 
          ? (_treatments[0] is Map ? (_treatments[0]['name'] ?? _productName) : _treatments[0].toString()) 
          : _productName;

      final result = await api.updateJobStatus(
        idTransaksi: _idTransaksi,
        action: 'start',
        productName: startProductName,
      );

      setState(() => _isApiLoading = false);

      if (result['success'] == true) {
        setState(() {
          _hasStarted = true;
          _isPaused = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Treatment resmi dimulai", style: TextStyle(color: Colors.white)), 
            backgroundColor: Colors.green, 
            duration: Duration(seconds: 1)
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Gagal memulai treatment dari server"), backgroundColor: Colors.red),
        );
      }
    } else {
      setState(() {
        _isPaused = !_isPaused;
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

  void _showFinishDialog() {
    if (_treatmentsDone.contains(false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap centang semua layanan sebelum menyelesaikan treatment!"), 
          backgroundColor: Colors.redAccent
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !_isApiLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Selesaikan Treatment?"),
              content: _isApiLoading 
                  ? const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text("Memproses ke server..."),
                      ],
                    )
                  : const Text("Pastikan semua tahapan sudah selesai."),
              actions: [
                if (!_isApiLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Batal", style: TextStyle(color: Colors.grey))
                  ),
                ElevatedButton(
                  onPressed: _isApiLoading ? null : () async {
                    setDialogState(() => _isApiLoading = true);
                    
                    final api = ApiService();
                    bool isAllSuccess = true;
                    String errorMessage = "";

                    // 1. --- LOOPING TEMBAK API FINISH PER TREATMENT ---
                    for (int i = 0; i < _treatments.length; i++) {
                      if (_treatmentsDone[i]) {
                        var item = _treatments[i];
                        
                        bool alreadyDoneFromBackend = item is Map && item['is_done'] == true;
                        if (alreadyDoneFromBackend) {
                          continue; 
                        }

                        String currentProductName = item is Map ? (item['name'] ?? '') : item.toString();
                        
                        if (currentProductName.isNotEmpty) {
                          final result = await api.updateJobStatus(
                            idTransaksi: _idTransaksi,
                            action: 'finish',
                            productName: currentProductName,
                          );
                          
                          if (result['success'] != true) {
                            String msg = result['message']?.toString().toLowerCase() ?? '';
                            if (!msg.contains('sudah selesai') && !msg.contains('sudah diselesaikan')) {
                              isAllSuccess = false;
                              errorMessage = result['message'] ?? 'Gagal menyelesaikan $currentProductName';
                              break; 
                            }
                          }
                        }
                      }
                    }

                    // 🔥 2. --- PERBAIKAN FATAL: TEMBAK API BOOKING COMPLETED ---
                    // Ini yang biasanya memicu backend PHP untuk menyuntikkan komisi ke database Earning
                    if (isAllSuccess) {
                      String idBooking = _bookingData?['id_booking']?.toString() ?? '';
                      if (idBooking.isNotEmpty) {
                        // Mengubah status booking utama menjadi 'completed' (atau sesuaikan dengan kata kunci backend, misal 'selesai')
                        final finalResult = await api.updateBookingStatus(
                          idBooking: idBooking, 
                          newStatus: 'completed' 
                        );

                        if (finalResult['success'] != true) {
                          isAllSuccess = false;
                          errorMessage = finalResult['message'] ?? 'Gagal menutup status booking keseluruhan.';
                        }
                      }
                    }
                    
                    if (mounted) setDialogState(() => _isApiLoading = false);

                    if (isAllSuccess) {
                      Navigator.pop(context); // Tutup dialog
                      _timer?.cancel();
                      
                      // Beri notifikasi sukses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Treatment berhasil diselesaikan!"), backgroundColor: Colors.green),
                      );

                      // Kembali ke halaman sebelumnya dengan parameter bahwa ini sudah fix selesai total
                      Navigator.pop(context, {
                        'action': 'finish_treatment',
                        'durasi_aktual': _secondsElapsed,
                        'stepsDone': _treatmentsDone,
                        'is_fully_completed': true // Parameter tambahan
                      });
                    } else {
                      Navigator.pop(context); // Tutup dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
                  child: const Text("Ya, Selesai", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
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
      'product_name': _productName,
      'secondsElapsed': _secondsElapsed,
      'treatmentsDone': _treatmentsDone,
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
    String rawCustomerName = _bookingData?['customer_name']?.toString() ?? '';
    
    if (rawCustomerName.trim().isEmpty) {
      rawCustomerName = _bookingData?['customer_fullname']?.toString() ?? ''; 
    }
    final String idBooking = _bookingData?['id_booking']?.toString() ?? '';
    if (rawCustomerName.trim().isEmpty) rawCustomerName = idBooking;
    
    final String namaKlien = (rawCustomerName.trim().isNotEmpty && rawCustomerName != '-') ? rawCustomerName : 'Klien Tanpa Nama';
    final String labelLayanan = _treatments.isNotEmpty ? '${_treatments.length} Layanan' : _productName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaKlien, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(labelLayanan, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context, 
                '/cek_pemeriksaan', 
                arguments: _bookingData, 
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 20),
            ),
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
    if (_treatments.isEmpty) return const SizedBox.shrink();

    int finishedCount = _treatmentsDone.where((element) => element == true).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daftar Treatment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$finishedCount dari ${_treatments.length} selesai dikerjakan', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          for (int i = 0; i < _treatments.length; i++)
            _buildTreatmentCard(i, _treatments[i], isDone: _treatmentsDone[i]),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(int index, dynamic item, {required bool isDone}) {
    String name = item is Map ? (item['name'] ?? 'Layanan') : item.toString();
    String qty = item is Map ? (item['qty']?.toString() ?? '1') : '1';
    int durasiMenit = item is Map ? (int.tryParse(item['durasi']?.toString() ?? '60') ?? 60) : 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (!_hasStarted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mulai treatment terlebih dahulu.'), duration: Duration(seconds: 1)),
            );
            return;
          }
          setState(() { _treatmentsDone[index] = !_treatmentsDone[index]; });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withOpacity(0.05) : Colors.white,
            border: Border.all(color: isDone ? Colors.green.shade300 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : Colors.transparent,
                  border: Border.all(color: isDone ? Colors.green : Colors.grey.shade400, width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.check, size: 16, color: isDone ? Colors.white : Colors.transparent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: isDone ? TextDecoration.lineThrough : null, 
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jumlah: $qty x  •  Durasi: $durasiMenit menit', 
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              onPressed: _isApiLoading ? null : _handleTimerAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: btnColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isApiLoading && !_hasStarted
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
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
              onPressed: (!_hasStarted || _isApiLoading) ? null : _showFinishDialog,
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
}