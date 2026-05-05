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

  // --- CACHE SESI LOKAL ---
  // Menyimpan state timer di memory sementara agar saat user kembali dari 
  // Detail Booking (Lanjut Treatment), waktu tidak ter-reset.
  static final Map<String, Map<String, dynamic>> _jobStateCache = {};

  Map<String, dynamic>? _bookingData;
  bool _isDataLoaded = false;
  bool _isApiLoading = false; 

  String _idTransaksiAsli = '';
  String _idBookingAsli = '';
  String _idBerhasilDigunakan = ''; 
  String _productName = '';

  Timer? _timer;
  int _secondsElapsed = 0; 
  int _estimatedTotalSeconds = 0; 
  
  bool _hasStarted = false; 
  bool _isPaused = false; 

  bool _allowPop = false; 

  List<dynamic> _treatments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bookingData = args;
        
        _idTransaksiAsli = args['id_transaksi']?.toString() ?? args['transaksi_id']?.toString() ?? '';
        _idBookingAsli = args['id_booking']?.toString() ?? '';
        _idBerhasilDigunakan = _idTransaksiAsli.isNotEmpty ? _idTransaksiAsli : _idBookingAsli;

        _productName = args['product_name']?.toString() ?? '';
        
        _treatments = args['treatments'] ?? args['services'] ?? [];

        if (_treatments.isEmpty) {
          String fallbackName = args['treatment_summary'] ?? args['treatment_name'] ?? _productName;
          if (fallbackName.isNotEmpty && fallbackName.toLowerCase() != 'treatment' && fallbackName.toLowerCase() != 'layanan') {
            var fallbackDur = args['duration'] ?? args['durasi'];
            int parsedDur = _parseDuration(fallbackDur, fallbackName);
            _treatments = [{'name': fallbackName.trim(), 'qty': 1, 'durasi': parsedDur}];
          }
        }

        // --- HITUNG TOTAL DURASI DENGAN AKURAT ---
        if (_treatments.isNotEmpty) {
          int totalMenit = 0;
          for (var item in _treatments) {
            int dur = 60; // Default jika gagal ambil data
            int qty = 1;
            if (item is Map) {
              dur = _parseDuration(item['duration'] ?? item['durasi'], _getRobustTreatmentName(item));
              qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
            } else {
              dur = _parseDuration(null, item.toString());
            }
            totalMenit += (dur * qty);
          }
          _estimatedTotalSeconds = totalMenit * 60; 
        } else {
          var rootDur = args['duration'] ?? args['durasi'];
          _estimatedTotalSeconds = _parseDuration(rootDur, _productName.isNotEmpty ? _productName : '60 min') * 60;
        }

        // 🔥 PERBAIKAN: Default Jangan Auto-Start! Harus pencet Mulai.
        _hasStarted = false; 
        _isPaused = false; 
        _secondsElapsed = 0; 
        
        // --- 1. PULIHKAN WAKTU DARI ARGS LANGSUNG (Kembali pakai tombol back UI) ---
        if (args.containsKey('savedState') && args['savedState'] != null) {
          final saved = args['savedState'];
          _secondsElapsed = saved['secondsElapsed'] ?? 0;
          _hasStarted = saved['hasStarted'] ?? false;
          _isPaused = saved['isPaused'] ?? false;
        } 
        // --- 2. PULIHKAN WAKTU DARI CACHE LOKAL (Jika masuk dari "Lanjut Treatment") ---
        else if (_jobStateCache.containsKey(_idBerhasilDigunakan)) {
          final cache = _jobStateCache[_idBerhasilDigunakan]!;
          _hasStarted = cache['hasStarted'] ?? _hasStarted;
          _isPaused = cache['isPaused'] ?? false;
          
          int savedSec = cache['secondsElapsed'] ?? 0;
          DateTime? lastTick = cache['lastTick'];
          
          if (lastTick != null && _hasStarted && !_isPaused) {
             int diff = DateTime.now().difference(lastTick).inSeconds;
             _secondsElapsed = savedSec + diff;
          } else {
             _secondsElapsed = savedSec;
          }
        }
        // --- 3. JIKA BARU DIBUKA (Tanpa Cache), BACA DURASI LAMA TAPI PAUSE ---
        else {
          int? elapsedFromArgs = int.tryParse(args['durasi_berjalan']?.toString() ?? '') ??
                                 int.tryParse(args['durasi_aktual']?.toString() ?? '') ??
                                 int.tryParse(args['elapsed_time']?.toString() ?? '');

          if (elapsedFromArgs != null && elapsedFromArgs > 0) {
             _secondsElapsed = elapsedFromArgs;
             _hasStarted = true;
             _isPaused = true; // Paksa masuk ke status Pause agar user tekan "Resume"
          } 
        }

        // Jalankan timer HANYA jika dipulihkan dari state yang tidak di-pause
        if (_hasStarted && !_isPaused) {
           _startTimer();
        }
      }
      _isDataLoaded = true;
    }
  }

  // --- Fungsi Update Cache Helper ---
  void _updateCache() {
    if (_idBerhasilDigunakan.isEmpty) return;
    _jobStateCache[_idBerhasilDigunakan] = {
      'secondsElapsed': _secondsElapsed,
      'lastTick': DateTime.now(),
      'hasStarted': _hasStarted,
      'isPaused': _isPaused,
    };
  }

  String _getRobustTreatmentName(dynamic item) {
    String pName = '';
    if (item is Map) {
      pName = (item['product_name'] ?? item['name'] ?? item['treatment_name'] ?? item['deskripsi'] ?? item['nama_layanan'] ?? '').toString().trim();
    } else {
      pName = item?.toString().trim() ?? '';
    }

    if (pName.isEmpty) pName = _productName.trim();
    if (pName.isEmpty) pName = _bookingData?['treatment_name']?.toString().trim() ?? '';
    if (pName.isEmpty) pName = _bookingData?['treatment_summary']?.toString().trim() ?? '';
    
    return pName.isEmpty ? 'Treatment' : pName;
  }

  Future<Map<String, dynamic>> _robustUpdateJobStatus(ApiService api, String action, dynamic item) async {
    List<String> idsToTry = [];
    
    if (item is Map) {
      if (item['id_transaksi'] != null) idsToTry.add(item['id_transaksi'].toString());
      if (item['transaksi_id'] != null) idsToTry.add(item['transaksi_id'].toString());
      if (item['id_detail'] != null) idsToTry.add(item['id_detail'].toString());
      if (item['id'] != null) idsToTry.add(item['id'].toString());
    }

    if (_idTransaksiAsli.isNotEmpty && !idsToTry.contains(_idTransaksiAsli)) idsToTry.add(_idTransaksiAsli);
    if (_idBookingAsli.isNotEmpty && !idsToTry.contains(_idBookingAsli)) idsToTry.add(_idBookingAsli);

    if (idsToTry.isEmpty) return {'success': false, 'message': 'ID Transaksi & ID Booking kosong.'};

    Set<String> possibleNames = {};
    void addName(String? n) {
      if (n != null && n.trim().isNotEmpty) possibleNames.add(n.trim()); 
    }

    addName(_getRobustTreatmentName(item));
    if (item is Map) {
      addName(item['product_name']?.toString());
      addName(item['treatment_name']?.toString());
      addName(item['name']?.toString());
      addName(item['deskripsi']?.toString());
      addName(item['nama_layanan']?.toString());
    } else {
      addName(item?.toString());
    }

    if (_bookingData != null) {
       addName(_bookingData!['product_name']?.toString());
       addName(_bookingData!['treatment_name']?.toString());
       addName(_bookingData!['treatment_summary']?.toString());
    }

    List<String> cleanedNames = possibleNames
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'treatment' && e.toLowerCase() != 'layanan')
        .toList();
    
    List<String> finalNamesToTry = [];
    for(String name in cleanedNames) {
      finalNamesToTry.add(name); 
      String noQty = name.replaceAll(RegExp(r'\(\d+[xX]\)'), '').trim();
      if (noQty != name && noQty.isNotEmpty) finalNamesToTry.add(noQty); 
      if (!name.toLowerCase().contains('x)')) finalNamesToTry.add('$name (1x)'); 
    }
    
    finalNamesToTry = finalNamesToTry.where((e) => e.isNotEmpty).toSet().toList();
    if (finalNamesToTry.isEmpty) finalNamesToTry.add('Treatment'); 

    Map<String, dynamic> lastResult = {'success': false, 'message': 'Gagal terhubung ke server.'};
    String? meaningfulError;
    
    for (String targetId in idsToTry) {
      for (String pName in finalNamesToTry) {
        debugPrint("API Test Job ($action) -> ID: $targetId | Nama: '$pName'");
        
        final result = await api.updateJobStatus(
          idTransaksi: targetId,
          action: action,
          productName: pName,
        );
        
        if (result['success'] == true || result['status'] == 'success') {
          _idBerhasilDigunakan = targetId; 
          return result; 
        } else {
          String msg = result['message']?.toString().toLowerCase() ?? '';
          if (msg.contains('sudah dimulai') || msg.contains('sudah selesai') || msg.contains('sudah diselesaikan')) {
             _idBerhasilDigunakan = targetId;
             return {'success': true, 'message': result['message']};
          }
          if (!msg.contains('wajib diisi') && meaningfulError == null) {
             meaningfulError = result['message'];
          }
        }
        lastResult = result;
      }
    }
    
    if (meaningfulError != null) lastResult['message'] = meaningfulError;
    return lastResult; 
  }

  int _parseDuration(dynamic durValue, String fallbackName) {
    if (durValue != null && durValue.toString().trim().isNotEmpty) {
      String durStr = durValue.toString().toLowerCase().trim();
      
      int? parsed = int.tryParse(durStr);
      if (parsed != null && parsed > 0) return parsed;
      
      final RegExp regExp = RegExp(r'(\d+)');
      final match = regExp.firstMatch(durStr);
      if (match != null) {
         int extracted = int.tryParse(match.group(1) ?? '60') ?? 60;
         if (extracted > 0) return extracted;
      }
    }
    
    final RegExp regExpName = RegExp(r'(\d+)\s*(min|menit|mins)', caseSensitive: false);
    final matchName = regExpName.firstMatch(fallbackName);
    if (matchName != null) {
       return int.tryParse(matchName.group(1) ?? '60') ?? 60;
    }

    return 60; 
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
        _updateCache(); 
      }
    });
  }

  Future<void> _handleTimerAction() async {
    if (!_hasStarted) {
      setState(() => _isApiLoading = true);
      
      final api = ApiService();
      dynamic firstTreatment = _treatments.isNotEmpty ? _treatments[0] : _bookingData;
      
      final result = await _robustUpdateJobStatus(api, 'start', firstTreatment);
      
      setState(() => _isApiLoading = false);

      if (result['success'] == true) {
        setState(() {
          _hasStarted = true;
          _isPaused = false;
        });
        _updateCache();
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Treatment resmi dimulai", style: TextStyle(color: Colors.white)), 
            backgroundColor: Colors.green, 
            duration: Duration(seconds: 1)
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Gagal Memulai", style: TextStyle(color: Colors.red)),
            content: Text(
              "${result['message'] ?? 'Error tidak diketahui.'}\n\n"
              "Saran:\n1. Pastikan Anda BENAR ditugaskan untuk layanan ini.\n"
              "2. Pastikan ID Transaksi/Booking valid.\n"
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                }, 
                child: const Text("Tutup", style: TextStyle(color: Colors.grey))
              )
            ],
          )
        );
      }
    } 
    else {
      setState(() {
        _isPaused = !_isPaused;
        _updateCache();
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

  void _showFinishDialog() async {
    // Tampilkan Dialog Konfirmasi Penyelesaian LANGSUNG
    bool? isFinishSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) { 
        return StatefulBuilder(
          builder: (BuildContext stateContext, StateSetter setDialogState) { 
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
                  : const Text("Pastikan semua tindakan untuk treatment ini telah selesai dikerjakan."),
              actions: [
                if (!_isApiLoading)
                  TextButton(
                    onPressed: () {
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop(false);
                      }
                    }, 
                    child: const Text("Batal", style: TextStyle(color: Colors.grey))
                  ),
                ElevatedButton(
                  onPressed: _isApiLoading ? null : () async {
                    setDialogState(() => _isApiLoading = true); 
                    
                    final api = ApiService();
                    bool jobHasError = false;
                    String errorMessage = "";

                    // Menyelesaikan SEMUA treatment secara otomatis di background
                    for (int i = 0; i < _treatments.length; i++) {
                      var item = _treatments[i];
                      
                      bool alreadyDoneFromBackend = false;
                      if (item is Map) {
                         var dVal = item['is_done'];
                         alreadyDoneFromBackend = (dVal == true || dVal == 'true' || dVal == 1 || dVal == '1');
                      }

                      if (alreadyDoneFromBackend) continue; 

                      final result = await _robustUpdateJobStatus(api, 'finish', item);
                      
                      if (result['success'] != true) {
                        jobHasError = true;
                        errorMessage = result['message'] ?? 'Gagal menyelesaikan treatment ke-${i+1}';
                        break; 
                      }
                    }

                    bool isAllSuccess = !jobHasError;
                    
                    // Menutup status booking jika semuanya berhasil
                    if (isAllSuccess) {
                      String idBooking = _bookingData?['id_booking']?.toString() ?? '';
                      if (idBooking.isNotEmpty) {
                        final finalResult = await api.updateBookingStatus(
                          idBooking: idBooking, 
                          newStatus: 'Closed' 
                        );

                        if (finalResult['success'] != true && finalResult['status'] != 'success') {
                          isAllSuccess = false;
                          errorMessage = finalResult['message'] ?? 'Gagal menutup status booking keseluruhan.';
                        }
                      }
                    }
                    
                    if (mounted) setDialogState(() => _isApiLoading = false);

                    if (isAllSuccess) {
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    } else {
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop(false);
                      }
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

    if (isFinishSuccess == true) {
      _timer?.cancel();
      _jobStateCache.remove(_idBerhasilDigunakan);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Treatment berhasil diselesaikan!"), backgroundColor: Colors.green),
      );

      setState(() {
        _allowPop = true;
      });

      // LANGSUNG KEMBALI KE BOOKING DETAIL MENGIRIM SIGNAL FINISH
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop({
            'action': 'finish_treatment',
            'durasi_aktual': _secondsElapsed,
            'is_fully_completed': true,
          });
        }
      });
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

  // 🔥 PERBAIKAN: Mencegah looping saat tekan Back dan menghindari salah tafsir di BookingDetail
  void _saveStateAndPop() {
    if (_allowPop) return; 
    _timer?.cancel();
    _updateCache();
    
    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        // Mengirimkan parameter 'back' yang tegas agar layar BookingDetail
        // sadar bahwa Anda hanya kembali (bukan Selesai).
        Navigator.of(context).pop({
          'action': 'back',
          'is_fully_completed': false,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop, 
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daftar Treatment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (int i = 0; i < _treatments.length; i++)
            _buildTreatmentCard(_treatments[i]),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(dynamic item) {
    String name = _getRobustTreatmentName(item); 
    
    String qty = item is Map ? (item['qty']?.toString() ?? '1') : '1';
    int durasiMenit = 60;
    
    if (item is Map) {
      durasiMenit = _parseDuration(item['duration'] ?? item['durasi'], name);
    } else {
      durasiMenit = _parseDuration(null, name);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name, 
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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