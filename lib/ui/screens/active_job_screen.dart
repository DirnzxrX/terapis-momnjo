import 'package:flutter/material.dart';
import 'dart:async';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Tambahan untuk AudioPlayer

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({Key? key}) : super(key: key);

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);

  // Inisialisasi Audio Player dan flag popup
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasShownTimeUpPopup = false;

  Map<String, dynamic>? _bookingData;
  bool _isDataLoaded = false;
  bool _isApiLoading = false;

  String _idTransaksiAsli = '';
  String _idBookingAsli = '';
  String _productName = '';

  Timer? _uiTimer;
  DateTime? _waktuMulaiServer;
  Duration _serverTimeOffset = Duration.zero; // Selisih waktu device vs server
  DateTime? _elapsedAnchorServerTime;

  int _secondsElapsed = 0;
  int _elapsedAnchorSeconds = 0;
  int _estimatedTotalSeconds = 0;

  bool _hasStarted = false;
  bool _isPaused = false;
  bool _allowPop = false;
  DateTime? _pauseStartedAtServer;
  int _pausedTotalSeconds = 0;

  List<dynamic> _treatments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _bookingData = args;

        _idTransaksiAsli =
            args['id_transaksi']?.toString() ??
            args['transaksi_id']?.toString() ??
            '';
        _idBookingAsli = args['id_booking']?.toString() ?? '';
        _productName = args['product_name']?.toString() ?? '';

        _treatments = args['treatments'] ?? args['services'] ?? [];

        if (_treatments.isEmpty) {
          String fallbackName =
              args['treatment_summary'] ??
              args['treatment_name'] ??
              _productName;
          if (fallbackName.isNotEmpty &&
              fallbackName.toLowerCase() != 'treatment' &&
              fallbackName.toLowerCase() != 'layanan') {
            var fallbackDur = args['duration'] ?? args['durasi'];
            int parsedDur = _parseDuration(fallbackDur, fallbackName);
            // Defaulting id_detail ke yang ada di root args jika tersedia
            _treatments = [
              {
                'id_detail': args['id_detail'],
                'name': fallbackName.trim(),
                'qty': 1,
                'durasi': parsedDur,
              },
            ];
          }
        }

        if (_treatments.isNotEmpty) {
          int totalMenit = 0;
          for (var item in _treatments) {
            int dur = 60;
            int qty = 1;
            if (item is Map) {
              dur = _parseDuration(
                item['duration'] ?? item['durasi'],
                _getRobustTreatmentName(item),
              );
              qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
            } else {
              dur = _parseDuration(null, item.toString());
            }
            totalMenit += (dur * qty);
          }
          _estimatedTotalSeconds = totalMenit * 60;
        } else {
          var rootDur = args['duration'] ?? args['durasi'];
          _estimatedTotalSeconds =
              _parseDuration(
                rootDur,
                _productName.isNotEmpty ? _productName : '60 min',
              ) *
              60;
        }

        // Ambil data dari server sebagai sumber kebenaran (Source of Truth)
        _syncWithServer();
      }
      _isDataLoaded = true;
    }
  }

  /// Sinkronisasi dengan get_service.php untuk mendapatkan timestamp akurat
  Future<bool> _syncWithServer() async {
    if (mounted) setState(() => _isApiLoading = true);
    bool syncedStarted = false;

    try {
      final api = ApiService();
      final response = await api.getActiveServices(
        idTransaksi: _idTransaksiAsli,
        idBooking: _idBookingAsli,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          final serverTime = _parseServerDateTime(data['server_time']);
          if (serverTime != null) {
            _serverTimeOffset = serverTime.difference(DateTime.now());
          }

          final rawItems = data['items'];
          final items = rawItems is List ? rawItems : <dynamic>[];
          final currentService = _findCurrentService(
            items,
            targetIdDetail: _activeIdDetail(),
          );

          if (currentService != null && _serviceHasStarted(currentService)) {
            final startTime =
                _parseServerDateTime(currentService['waktu_mulai_iso']) ??
                _parseServerDateTime(currentService['waktu_mulai']);
            final elapsedSeconds = _parseInt(currentService['elapsed_seconds']);
            final isPaused = _serviceIsPaused(currentService);
            final pauseStartedAt =
                _parseServerDateTime(currentService['pause_started_at_iso']) ??
                _parseServerDateTime(currentService['pause_started_at']);
            final pausedTotalSeconds = _parseInt(
              currentService['paused_total_seconds'],
            );

            if (mounted) {
              setState(() {
                _applyStartedState(
                  waktuMulai: startTime,
                  elapsedSeconds: elapsedSeconds,
                  isPaused: isPaused,
                  pauseStartedAt: pauseStartedAt,
                  pausedTotalSeconds: pausedTotalSeconds,
                );
              });
              if (isPaused) {
                _uiTimer?.cancel();
              } else {
                _startUiTimer();
              }
            }
            syncedStarted = true;
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal sync dengan server: $e");
    } finally {
      if (mounted) setState(() => _isApiLoading = false);
    }

    return syncedStarted;
  }

  // Helper untuk mendapatkan waktu sekarang menyesuaikan waktu server
  DateTime get _currentServerTime => DateTime.now().add(_serverTimeOffset);

  String _asCleanString(dynamic value) => value?.toString().trim() ?? '';

  bool _sameId(dynamic value, String expected) {
    return expected.trim().isNotEmpty &&
        _asCleanString(value) == expected.trim();
  }

  bool _parseBool(dynamic value) {
    if (value == true || value == 1) return true;
    final text = _asCleanString(value).toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_asCleanString(value)) ?? fallback;
  }

  DateTime? _parseServerDateTime(dynamic value) {
    final raw = _asCleanString(value);
    if (raw.isEmpty ||
        raw.toLowerCase() == 'null' ||
        raw.startsWith('0000-00-00')) {
      return null;
    }

    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  String? _activeIdDetail() {
    final firstTreatment = _treatments.isNotEmpty
        ? _treatments[0]
        : _bookingData;
    if (firstTreatment is Map && firstTreatment['id_detail'] != null) {
      final idDetail = _asCleanString(firstTreatment['id_detail']);
      if (idDetail.isNotEmpty) return idDetail;
    }

    final fallbackId = _asCleanString(_bookingData?['id_detail']);
    return fallbackId.isEmpty ? null : fallbackId;
  }

  Map<dynamic, dynamic>? _findCurrentService(
    List<dynamic> items, {
    String? targetIdDetail,
  }) {
    final matches = <Map<dynamic, dynamic>>[];

    for (final item in items) {
      if (item is! Map) continue;

      final matchesDetail =
          targetIdDetail != null && _sameId(item['id_detail'], targetIdDetail);
      final matchesTransaction = _sameId(
        item['id_transaksi'],
        _idTransaksiAsli,
      );
      final matchesBooking = _sameId(item['id_booking'], _idBookingAsli);

      if (matchesDetail || matchesTransaction || matchesBooking) {
        matches.add(item);
      }
    }

    if (matches.isEmpty) return null;

    for (final item in matches) {
      if (_serviceHasStarted(item)) return item;
    }

    return matches.first;
  }

  bool _serviceHasStarted(Map<dynamic, dynamic> item) {
    final state = _asCleanString(item['service_state']).toLowerCase();
    final status = _asCleanString(item['status_layanan']).toLowerCase();
    final hasFinishTime =
        _parseServerDateTime(item['waktu_selesai_iso']) != null ||
        _parseServerDateTime(item['waktu_selesai']) != null;

    if (state == 'completed' || status == 'selesai' || hasFinishTime) {
      return false;
    }

    final hasStartTime =
        _parseServerDateTime(item['waktu_mulai_iso']) != null ||
        _parseServerDateTime(item['waktu_mulai']) != null;

    return _parseBool(item['is_in_progress']) ||
        _serviceIsPaused(item) ||
        state == 'paused' ||
        state == 'in_progress' ||
        status == 'proses' ||
        hasStartTime;
  }

  bool _serviceIsPaused(Map<dynamic, dynamic> item) {
    final state = _asCleanString(item['service_state']).toLowerCase();
    return _parseBool(item['is_paused']) || state == 'paused';
  }

  void _applyStartedState({
    DateTime? waktuMulai,
    int? elapsedSeconds,
    bool isPaused = false,
    DateTime? pauseStartedAt,
    int? pausedTotalSeconds,
  }) {
    _hasStarted = true;
    _isPaused = isPaused;
    _pauseStartedAtServer = pauseStartedAt;
    _pausedTotalSeconds = pausedTotalSeconds ?? _pausedTotalSeconds;

    if (waktuMulai != null) {
      _waktuMulaiServer = waktuMulai;
    }

    int cleanElapsed = elapsedSeconds ?? _secondsElapsed;
    if (cleanElapsed <= 0 && _waktuMulaiServer != null) {
      final rawElapsed = _currentServerTime
          .difference(_waktuMulaiServer!)
          .inSeconds;
      cleanElapsed = rawElapsed - _pausedTotalSeconds;
    }

    _secondsElapsed = cleanElapsed > 0 ? cleanElapsed : 0;
    _elapsedAnchorSeconds = _secondsElapsed;
    _elapsedAnchorServerTime = _currentServerTime;

    if (_waktuMulaiServer == null && _secondsElapsed > 0) {
      _waktuMulaiServer = _currentServerTime.subtract(
        Duration(seconds: _secondsElapsed + _pausedTotalSeconds),
      );
    }
  }

  void _updateElapsedFromStart() {
    if (_isPaused) return;

    if (_elapsedAnchorServerTime != null) {
      final diff = _currentServerTime
          .difference(_elapsedAnchorServerTime!)
          .inSeconds;
      final nextElapsed = _elapsedAnchorSeconds + (diff > 0 ? diff : 0);
      _secondsElapsed = nextElapsed > 0 ? nextElapsed : 0;
      return;
    }

    if (_waktuMulaiServer == null) return;
    final diff = _currentServerTime.difference(_waktuMulaiServer!).inSeconds;
    final nextElapsed = diff - _pausedTotalSeconds;
    _secondsElapsed = nextElapsed > 0 ? nextElapsed : 0;
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    if (_isPaused) return;

    _updateElapsedFromStart();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_hasStarted && !_isPaused) {
        setState(() {
          _updateElapsedFromStart();
        });
        
        // Cek apakah waktu sudah habis setiap detiknya
        _checkTimeUp(); 
      }
    });
  }

  // === FUNGSI BARU: CEK WAKTU HABIS ===
  void _checkTimeUp() {
    // Jika durasi berjalan sudah melampaui total estimasi dan popup belum muncul
    if (_secondsElapsed >= _estimatedTotalSeconds && 
        !_hasShownTimeUpPopup && 
        _estimatedTotalSeconds > 0) {
      
      _hasShownTimeUpPopup = true;
      _playAlarmAndShowPopup();
    }
  }

  // === FUNGSI BARU: PLAY ALARM & TAMPILKAN POPUP ===
  Future<void> _playAlarmAndShowPopup() async {
    try {
      // Set audio supaya looping (berulang) sampai dimatikan
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Mainkan audio. (Catatan: Pastikan ekstensi file kamu di folder benar. 
      // Jika namanya hanya "alarm" tapi format mp3, tulis alarm.mp3. Jika wav tulis alarm.wav)
      await _audioPlayer.play(AssetSource('audio/alarm.mp3')); 
    } catch (e) {
      debugPrint("Gagal memutar audio alarm: $e");
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // User dipaksa klik tombol 'Tutup'
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC), // Soft pink
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alarm_on_rounded,
                  color: primaryPink,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Waktu Selesai!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Estimasi waktu untuk treatment ini sudah habis. Silakan selesaikan treatment jika sudah rampung.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _audioPlayer.stop(); // MATIKAN ALARM
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Tutup Alarm",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _audioPlayer.stop(); // Hentikan alarm jika halaman di-close paksa
    _audioPlayer.dispose(); // Bersihkan audio player
    super.dispose();
  }

  String _getRobustTreatmentName(dynamic item) {
    String pName = '';
    if (item is Map) {
      pName =
          (item['product_name'] ??
                  item['name'] ??
                  item['treatment_name'] ??
                  item['deskripsi'] ??
                  item['nama_layanan'] ??
                  '')
              .toString()
              .trim();
    } else {
      pName = item?.toString().trim() ?? '';
    }

    if (pName.isEmpty) pName = _productName.trim();
    if (pName.isEmpty)
      pName = _bookingData?['treatment_name']?.toString().trim() ?? '';
    if (pName.isEmpty)
      pName = _bookingData?['treatment_summary']?.toString().trim() ?? '';

    return pName.isEmpty ? 'Treatment' : pName;
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

    final RegExp regExpName = RegExp(
      r'(\d+)\s*(min|menit|mins)',
      caseSensitive: false,
    );
    final matchName = regExpName.firstMatch(fallbackName);
    if (matchName != null) {
      return int.tryParse(matchName.group(1) ?? '60') ?? 60;
    }
    return 60;
  }

  Future<void> _handleTimerAction() async {
    if (!_hasStarted) {
      setState(() => _isApiLoading = true);

      final api = ApiService();
      final targetIdDetail = _activeIdDetail();

      if (targetIdDetail == null || _idTransaksiAsli.isEmpty) {
        setState(() => _isApiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Error: ID Detail atau Transaksi tidak ditemukan.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await api.updateJobStatus(
        idTransaksi: _idTransaksiAsli,
        idBooking: _idBookingAsli,
        idDetail: targetIdDetail,
        action: 'start',
      );

      if (!mounted) return;

      if (result['success'] == true || result['status'] == 'success') {
        final syncedStarted = await _syncWithServer();
        if (!syncedStarted && mounted) {
          final data = result['data'];
          DateTime? startedAt;
          int elapsedSeconds = 0;

          if (data is Map) {
            startedAt =
                _parseServerDateTime(data['waktu_mulai_iso']) ??
                _parseServerDateTime(data['waktu_mulai']);
            elapsedSeconds = _parseInt(data['elapsed_seconds']);
          }

          setState(() {
            if (startedAt != null) {
              _applyStartedState(
                waktuMulai: startedAt,
                elapsedSeconds: elapsedSeconds,
              );
            } else {
              _applyStartedState(elapsedSeconds: elapsedSeconds);
            }
            _isApiLoading = false;
          });
          _startUiTimer();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Treatment resmi dimulai",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        setState(() => _isApiLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              "Gagal Memulai",
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              result['message'] ??
                  'Error tidak diketahui saat menghubungi server.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handlePauseResumeAction({required bool pause}) async {
    if (!_hasStarted || _isApiLoading) return;

    final targetIdDetail = _activeIdDetail();
    if (targetIdDetail == null || _idTransaksiAsli.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: ID Detail atau Transaksi tidak ditemukan."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApiLoading = true);

    try {
      final api = ApiService();
      final result = await api.updateJobStatus(
        idTransaksi: _idTransaksiAsli,
        idBooking: _idBookingAsli,
        idDetail: targetIdDetail,
        action: pause ? 'pause' : 'resume',
      );

      if (!mounted) return;

      if (result['success'] == true || result['status'] == 'success') {
        final syncedStarted = await _syncWithServer();

        if (!syncedStarted && mounted) {
          setState(() {
            _isPaused = pause;
            _pauseStartedAtServer = pause ? _currentServerTime : null;
            _elapsedAnchorSeconds = _secondsElapsed;
            _elapsedAnchorServerTime = _currentServerTime;
            _isApiLoading = false;
          });

          if (pause) {
            _uiTimer?.cancel();
          } else {
            _startUiTimer();
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pause ? "Treatment dijeda" : "Treatment dilanjutkan"),
              backgroundColor: pause ? Colors.orange.shade700 : Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        setState(() => _isApiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  (pause ? 'Gagal pause treatment.' : 'Gagal resume treatment.'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApiLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengubah state treatment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFinishDialog() async {
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
                  : const Text(
                      "Pastikan semua tindakan untuk treatment ini telah selesai dikerjakan.",
                    ),
              actions: [
                if (!_isApiLoading)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(
                      "Batal",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isApiLoading
                      ? null
                      : () async {
                          setDialogState(() => _isApiLoading = true);

                          final api = ApiService();
                          bool jobHasError = false;
                          String errorMessage = "";

                          for (int i = 0; i < _treatments.length; i++) {
                            var item = _treatments[i];

                            bool alreadyDoneFromBackend = false;
                            String? currentIdDetail;

                            if (item is Map) {
                              var dVal = item['is_done'];
                              alreadyDoneFromBackend =
                                  (dVal == true ||
                                  dVal == 'true' ||
                                  dVal == 1 ||
                                  dVal == '1');
                              currentIdDetail = item['id_detail']?.toString();
                            }

                            if (alreadyDoneFromBackend) continue;
                            if (currentIdDetail == null) {
                              currentIdDetail = _bookingData?['id_detail']
                                  ?.toString();
                            }

                            if (currentIdDetail != null) {
                              final result = await api.updateJobStatus(
                                idTransaksi: _idTransaksiAsli,
                                idBooking: _idBookingAsli,
                                idDetail: currentIdDetail,
                                action: 'finish',
                              );
                              if (result['success'] != true) {
                                jobHasError = true;
                                errorMessage =
                                    result['message'] ??
                                    'Gagal menyelesaikan treatment ke-${i + 1}';
                                break;
                              }
                            }
                          }

                          if (mounted)
                            setDialogState(() => _isApiLoading = false);

                          if (!jobHasError) {
                            Navigator.of(dialogContext).pop(true);
                          } else {
                            Navigator.of(dialogContext).pop(false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
                  child: const Text(
                    "Ya, Selesai",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (isFinishSuccess == true) {
      _uiTimer?.cancel();
      _audioPlayer.stop(); // Matikan alarm jika user finish treatment

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Treatment berhasil diselesaikan!"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _allowPop = true;
      });

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

  void _saveStateAndPop() {
    if (_allowPop) return;
    _uiTimer?.cancel();
    _audioPlayer.stop(); // Matikan alarm kalau user back

    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(
          context,
        ).pop({
          'action': 'save_state',
          'secondsElapsed': _secondsElapsed,
          'durasi_aktual': _secondsElapsed,
          'hasStarted': _hasStarted,
          'isPaused': _isPaused,
          'service_state': _isPaused ? 'paused' : 'in_progress',
          'paused_total_seconds': _pausedTotalSeconds,
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
          title: const Text(
            'Job Aktif',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                    Container(
                      height: 100,
                      width: double.infinity,
                      color: primaryPink,
                    ),
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

    final String namaKlien =
        (rawCustomerName.trim().isNotEmpty && rawCustomerName != '-')
        ? rawCustomerName
        : 'Klien Tanpa Nama';
    final String labelLayanan = _treatments.isNotEmpty
        ? '${_treatments.length} Layanan'
        : _productName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaKlien,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  labelLayanan,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    String statusText = !_hasStarted
        ? 'Menunggu Dimulai'
        : (_isPaused ? 'Treatment Dijeda' : 'Durasi Berjalan');
    Color statusColor = !_hasStarted
        ? Colors.orange.shade700
        : (_isPaused ? Colors.orange.shade700 : Colors.green.shade600);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_secondsElapsed),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: (!_hasStarted) ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Sisa Estimasi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatRemaining(_secondsElapsed, _estimatedTotalSeconds),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
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
          const Text(
            'Daftar Treatment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
    int durasiMenit = item is Map
        ? _parseDuration(item['duration'] ?? item['durasi'], name)
        : _parseDuration(null, name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jumlah: $qty x  •  Durasi: $durasiMenit menit',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final Color secondaryColor = _isPaused
        ? Colors.green.shade600
        : Colors.orange.shade700;
    final IconData secondaryIcon = _isPaused ? Icons.play_arrow : Icons.pause;
    final String secondaryLabel = _isPaused ? 'Lanjutkan' : 'Pause';

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isApiLoading
                  ? null
                  : (_hasStarted
                      ? () => _handlePauseResumeAction(pause: !_isPaused)
                      : _handleTimerAction),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _hasStarted ? secondaryColor : Colors.green.shade600,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isApiLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasStarted ? secondaryIcon : Icons.play_arrow,
                          color: _hasStarted
                              ? secondaryColor
                              : Colors.green.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _hasStarted ? secondaryLabel : 'Mulai',
                          style: TextStyle(
                            color: _hasStarted
                                ? secondaryColor
                                : Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (!_hasStarted || _isApiLoading)
                  ? null
                  : _showFinishDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Selesai Treatment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}