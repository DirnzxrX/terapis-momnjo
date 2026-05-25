import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://dashboard.momnjo.my.id/dev/api_terapis";

  // --- HELPER: MENGAMBIL TOKEN JWT DARI LOKAL ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // --- HELPER: MENGAMBIL COOKIE SESSION DARI LOKAL ---
  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_cookie');
  }

  // --- HELPER: MENGECEK STATUS LOGIN ---
  Future<bool> isLoggedIn() async {
    final String? token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // --- HELPER: FUNGSI MATA-MATA (DEBUG LOG) KE TERMINAL ---
  void _logDebug({
    required String url,
    Map<String, dynamic>? requestBody,
    required String responseBody,
    required String method,
    required int statusCode,
  }) {
    if (kDebugMode) {
      debugPrint("------------------- 🚀 API LOG START 🚀 -------------------");
      debugPrint("🔗 URL    : [$method] $url");
      debugPrint("📡 STATUS : $statusCode");
      if (requestBody != null) {
        debugPrint("📦 REQUEST: ${jsonEncode(requestBody)}");
      }
      debugPrint("✅ RESPONSE: $responseBody");
      debugPrint("------------------- 🔚 API LOG END -------------------");
    }
  }

  // =========================================================================
  // 1. FUNGSI UTAMA GET JOBS (All, Active, & History)
  // =========================================================================
  Future<Map<String, dynamic>> getJobs({String? status, String? search}) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie(); // Ambil cookie
    if (token == null) return {'success': false, 'message': 'Unauthorized. Token tidak ditemukan.'};

    final Map<String, String> queryParams = {};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/get_all_jobs.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie, // Sisipkan cookie jika ada
        },
      );

      _logDebug(url: uri.toString(), method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          return {'success': false, 'message': 'Format response server tidak valid.'};
        }
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Unauthorized. Token tidak valid.'};
      } else {
        try {
          final errorData = json.decode(response.body);
          return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil data (Status: ${response.statusCode})'};
        } catch (_) {
          return {'success': false, 'message': 'Gagal mengambil data (Status: ${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> getActiveJobs({String? search}) async {
    return await getJobs(status: 'open', search: search); 
  }

  // =========================================================================
  // 🔥 2. GET JOB DETAIL
  // =========================================================================
  Future<Map<String, dynamic>> getJobDetail(String idTransaksi) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    if (idTransaksi.trim().isEmpty) {
      return {'success': false, 'message': 'ID Transaksi wajib diisi.'};
    }

    final String url = '$baseUrl/get_job_detail.php?id_transaksi=$idTransaksi';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        return {'success': false, 'message': 'ID Transaksi tidak valid atau tidak lengkap.'};
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil detail pekerjaan.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil detail pekerjaan (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 UPDATE STATUS SIKLUS KERJA TERAPIS (Arrived, Start, Finish)
  // =========================================================================
  Future<Map<String, dynamic>> updateJobStatus({
    required String idTransaksi,
    required String action, // "arrived", "start", atau "finish"
    String? productName,
    String? imagePath,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/update_service.php';
    
    String mappedStatus = action;
    if (action.toLowerCase() == 'arrived') mappedStatus = 'Arrived';
    else if (action.toLowerCase() == 'start') mappedStatus = 'In Progress';
    else if (action.toLowerCase() == 'finish') mappedStatus = 'Completed';

    // 🔥 PERBAIKAN: Ambil waktu saat ini (Real-Time) dari HP saat tombol ditekan
    DateTime now = DateTime.now();
    String currentTime = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    try {
      http.Response response;

      if (action == 'arrived' || (imagePath != null && imagePath.isNotEmpty)) {
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        if (cookie != null) request.headers['Cookie'] = cookie; // Sisipkan cookie untuk multipart

        request.fields['id_transaksi'] = idTransaksi;
        // 🔥 PROTEKSI GANDA: Kirim id_booking juga jika API bingung format MNJ...
        request.fields['id_booking'] = idTransaksi; 
        request.fields['status'] = mappedStatus; 
        
        // 🔥 PERBAIKAN: Selipkan waktu mulai dan selesai ke dalam API POST
        if (action.toLowerCase() == 'start') {
           request.fields['waktu_mulai'] = currentTime;
        } else if (action.toLowerCase() == 'finish') {
           request.fields['waktu_selesai'] = currentTime;
        }

        if (imagePath != null && imagePath.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        }

        _logDebug(url: url, method: "POST (Multipart)", requestBody: request.fields, statusCode: 0, responseBody: "Mengirim data tiba & foto...");

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } 
      else {
        final Map<String, dynamic> body = {
          'id_transaksi': idTransaksi,
          // 🔥 PROTEKSI GANDA: Kirim id_booking juga jika API bingung format MNJ...
          'id_booking': idTransaksi, 
          'status': mappedStatus, 
        };
        
        // 🔥 PERBAIKAN: Selipkan waktu mulai dan selesai ke dalam JSON API
        if (action.toLowerCase() == 'start') {
           body['waktu_mulai'] = currentTime;
        } else if (action.toLowerCase() == 'finish') {
           body['waktu_selesai'] = currentTime;
        }

        if (productName != null && productName.isNotEmpty) {
          body['product_name'] = productName;
        }

        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            if (cookie != null) 'Cookie': cookie,
          },
          body: json.encode(body),
        );
      }

      _logDebug(url: url, method: "POST", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          
          bool isSuccess = false;
          if (data['success'] == true || data['success'] == 'true') {
             isSuccess = true;
          } else if (data['status'] == 'success') {
             isSuccess = true;
          }
          
          data['success'] = isSuccess;
          return data;
        } catch (e) {
          String partialError = response.body;
          if (partialError.length > 100) partialError = '${partialError.substring(0, 100)}...';
          return {'success': false, 'message': 'Server mengembalikan error: $partialError'};
        }
      } else {
        return {'success': false, 'message': 'Server Error (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi terputus: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL STATISTIK TERAPIS (HOME SCREEN)
  // =========================================================================
  Future<Map<String, dynamic>> getStats() async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/get_stats.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) return json.decode(response.body);
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal memuat statistik'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal memuat statistik (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // =========================================================================
  // UPDATE STATUS BOOKING KESELURUHAN (MENDUKUNG UPLOAD FOTO)
  // =========================================================================
  Future<Map<String, dynamic>> updateBookingStatus({
    required String idBooking,
    required String newStatus,
    String? imagePath,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    // 🔥 DIKEMBALIKAN KE ENDPOINT ASLI (update_booking_status.php)
    // update_service.php hanya untuk treatment item.
    final String url = '$baseUrl/update_booking_status.php';

    try {
      http.Response response;

      if (imagePath != null && imagePath.isNotEmpty) {
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        if (cookie != null) request.headers['Cookie'] = cookie;
        
        request.fields['id_booking'] = idBooking; 
        request.fields['status'] = newStatus;
        
        request.files.add(await http.MultipartFile.fromPath('image', imagePath)); 

        _logDebug(url: url, method: "POST (Multipart)", requestBody: request.fields, statusCode: 0, responseBody: "Mengirim foto...");

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        final Map<String, dynamic> body = {
          'id_booking': idBooking,
          'status': newStatus,
        };
        
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            if (cookie != null) 'Cookie': cookie,
          },
          body: json.encode(body),
        );
      }

      _logDebug(url: url, method: "POST", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Unauthorized. Token tidak valid atau kadaluarsa.'};
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal update status booking'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal update status booking (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENYIMPAN DATA MEDIS (Pemeriksaan Klien)
  // =========================================================================
  Future<Map<String, dynamic>> storeDataMedis({
    required String idTransaksi,
    required String idCustomer,
    String? suhu,
    String? tinggi,
    String? berat,
    String? tekanan,
    String? sistolik,
    String? diastolik,
    String? catatan,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    if (idTransaksi.trim().isEmpty || idCustomer.trim().isEmpty) {
      return {'success': false, 'message': 'ID Transaksi/Customer kosong.'};
    }

    String finalTekanan = tekanan ?? '';
    if (finalTekanan.isEmpty && sistolik != null && diastolik != null) {
      if (sistolik.isNotEmpty && diastolik.isNotEmpty) {
        finalTekanan = '$sistolik/$diastolik';
      }
    }

    final String url = '$baseUrl/store_data_medis.php';
    final Map<String, dynamic> payloadData = {
      'id_transaksi': idTransaksi,
      'id_customer': idCustomer,
      if (suhu != null && suhu.isNotEmpty) 'suhu': suhu,
      if (tinggi != null && tinggi.isNotEmpty) 'tinggi': tinggi,
      if (berat != null && berat.isNotEmpty) 'berat': berat,
      if (finalTekanan.isNotEmpty) 'tekanan': finalTekanan,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
        body: json.encode(payloadData),
      );

      _logDebug(url: url, method: "POST", requestBody: payloadData, statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final errorData = json.decode(response.body);
          return {'success': false, 'message': errorData['message'] ?? 'Server Error'};
        } catch (_) {
          return {'success': false, 'message': 'Server Error (Status: ${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi terputus: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL LIST RIWAYAT PEKERJAAN (HISTORY)
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryList({String? search}) async {
    return await getJobs(status: 'closed', search: search);
  }

  // =========================================================================
  // MENGAMBIL DETAIL RIWAYAT PEKERJAAN (HISTORY DETAIL)
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryDetail(String idTransaksi) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/history_detail.php?id_transaksi=$idTransaksi';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil detail history.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil detail history (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // RATE CUSTOMER (LAPORAN KUNJUNGAN)
  // =========================================================================
  Future<Map<String, dynamic>> rateCustomer({
    required String idTransaksi,
    required int rating,
    required List<String> tags,
    required String notes,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/update_service.php';
    final Map<String, dynamic> body = {
      'id_transaksi': idTransaksi,
      // 🔥 PROTEKSI GANDA
      'id_booking': idTransaksi,
      'status': 'Completed', 
      'rating': rating > 0 ? rating : 5, 
      'tags': tags,
      'notes': notes,
    };

    try {
      final response = await http.post(
        Uri.parse(url), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
        body: json.encode(body),
      );

      _logDebug(url: url, method: "POST", requestBody: body, statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengirim laporan kunjungan.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengirim laporan kunjungan (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // LOGIN (MENDUKUNG PENYIMPANAN COOKIE SESSION)
  // =========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    final String url = '$baseUrl/login.php';
    final Map<String, dynamic> body = {
      'username': username.trim(),
      'password': password.trim()
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      _logDebug(url: url, method: "POST", requestBody: body, statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // 🔥 PERBAIKAN: Mengecek success dengan sangat longgar
        bool isSuccess = responseData['success'] == true || 
                         responseData['success'] == 'true' || 
                         responseData['status'] == 'success';

        if (isSuccess) {
          final prefs = await SharedPreferences.getInstance();
          // Cari objek data, kalau API mengirim di root ya pakai root (responseData)
          final data = responseData['data'] ?? responseData;

          // Ekstrak token (cek berbagai macam key standar)
          final String? tokenToSave = data['token'] ?? data['jwt'] ?? responseData['token'];
          
          if (tokenToSave != null && tokenToSave.isNotEmpty) {
            await prefs.setString('jwt_token', tokenToSave);
            debugPrint("✅ API LOG: Token berhasil disimpan ke SharedPreferences.");
          }

          // Ekstrak nama
          final String? namaToSave = data['nama_lengkap'] ?? data['name'] ?? responseData['nama_lengkap'];
          if (namaToSave != null) {
            await prefs.setString('nama_lengkap', namaToSave);
          }
          
          // 🔥 SIMPAN COOKIE SESSION DARI HEADER JIKA DIBERIKAN OLEH SERVER
          final String? rawCookie = response.headers['set-cookie'];
          if (rawCookie != null) {
            await prefs.setString('session_cookie', rawCookie);
          }
        }
        return responseData;
      }
      return {'success': false, 'message': 'Gagal terhubung ke server (Status: ${response.statusCode}).'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau sistem: $e'};
    }
  }

  // =========================================================================
  // LOGOUT
  // =========================================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? savedAttendance = prefs.getString('attendance_history');
    
    // Ini otomatis akan menghapus 'jwt_token' dan 'session_cookie'
    await prefs.clear(); 
    
    if (savedAttendance != null) {
      await prefs.setString('attendance_history', savedAttendance);
    }
    
    debugPrint("------------------- 🚀 API LOG: LOGOUT LOCAL SUCCESS 🚀 -------------------");
  }

  // =========================================================================
  // MENGAMBIL SALDO TERAPIS (GET BALANCE) 
  // =========================================================================
  Future<Map<String, dynamic>> getBalance({
    String? source,
    String? startDate,
    String? endDate,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final Map<String, String> queryParams = {};
    if (source != null && source.isNotEmpty) queryParams['source'] = source;
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/get_balance.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: uri.toString(), method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('status')) {
           data['success'] = data['status'] == 'success';
        } else {
           data['success'] = true; 
        }
        
        return data;
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil saldo.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil saldo (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // SUBMIT PENARIKAN DANA (PAYOUT REQUEST)
  // =========================================================================
  Future<Map<String, dynamic>> submitPayoutRequest({
    required String jenisPayout,
    required int amount,
    required String bank,
    required String accountNumber,
    required String accountName,
    String? notes,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/request_payout.php';
    
    final Map<String, dynamic> body = {
      'jenis_payout': jenisPayout,
      'requested_amount': amount,
      'bank_account': bank,
      'account_number': accountNumber,
      'account_holder_name': accountName,
      if (notes != null && notes.isNotEmpty) 'note': notes,
    };

    try {
      final response = await http.post(
        Uri.parse(url), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
        body: json.encode(body),
      );

      _logDebug(url: url, method: "POST", requestBody: body, statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false, 
          'status': errorData['status'], 
          'message': errorData['message'] ?? 'Gagal memproses penarikan.'
        };
      } catch (_) {
        return {'success': false, 'message': 'Gagal memproses penarikan (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL RIWAYAT PENARIKAN (PAYOUT HISTORY)
  // =========================================================================
  Future<Map<String, dynamic>> getPayoutHistory({
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final Map<String, String> queryParams = {};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/get_payout_history.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: uri.toString(), method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('status')) {
           data['success'] = data['status'] == 'success';
        } else {
           data['success'] = true;
        }

        return data;
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }
      
      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil riwayat penarikan dana.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil riwayat penarikan dana (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL DETAIL PENARIKAN (PAYOUT DETAIL)
  // =========================================================================
  Future<Map<String, dynamic>> getPayoutDetail(int idPayout) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/get_detail_payout.php?id_payout=$idPayout';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil detail penarikan dana.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil detail penarikan dana (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL PROFIL TERAPIS (GET PROFILE)
  // =========================================================================
  Future<Map<String, dynamic>> getProfile() async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/get_profile.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout(); 
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil profil.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil profil (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL DATA DIRI TERAPIS (GET DATA DIRI)
  // =========================================================================
  Future<Map<String, dynamic>> getDataDiri() async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/get_data_diri.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout(); 
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil data diri.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil data diri (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // MENGAMBIL DATA CAROUSEL (BANNER TERAPIS)
  // =========================================================================
  Future<Map<String, dynamic>> getCarousel() async {
    final String url = '$baseUrl/get_carousel.php';
    final String? cookie = await _getCookie();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(
          url: url,
          method: "GET",
          statusCode: response.statusCode,
          responseBody: response.body);

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          return {'success': false, 'message': 'Format response server tidak valid.'};
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Gagal mengambil data carousel.'
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Gagal mengambil data carousel (Status: ${response.statusCode})'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 CEK STATUS ABSENSI HARI INI (On Duty / Off Duty)
  // =========================================================================
  Future<Map<String, dynamic>> checkAttendanceStatus() async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/store_absensi.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil status absensi.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil status absensi (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 KIRIM ABSENSI (Check-In atau Check-Out) MENDUKUNG FOTO & LOKASI
  // =========================================================================
  Future<Map<String, dynamic>> submitAttendance({
    required String action, // "check_in" atau "check_out"
    String? catatan,
    String? imagePath,
    String? lokasi,
  }) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/store_absensi.php';

    try {
      http.Response response;

      // Jika ada gambar, gunakan request berjenis Multipart
      if (imagePath != null && imagePath.isNotEmpty) {
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        if (cookie != null) request.headers['Cookie'] = cookie;

        request.fields['action'] = action;
        if (catatan != null && catatan.isNotEmpty) request.fields['catatan'] = catatan;
        if (lokasi != null && lokasi.isNotEmpty) request.fields['lokasi'] = lokasi;

        request.files.add(await http.MultipartFile.fromPath('image', imagePath));

        _logDebug(
          url: url,
          method: "POST (Multipart)",
          requestBody: request.fields,
          statusCode: 0,
          responseBody: "Mengirim data absensi & foto...",
        );

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Jika tidak ada gambar, gunakan standard POST JSON form
        final Map<String, dynamic> body = {
          'action': action,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          if (lokasi != null && lokasi.isNotEmpty) 'lokasi': lokasi,
        };

        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            if (cookie != null) 'Cookie': cookie,
          },
          body: json.encode(body),
        );
      }

      _logDebug(url: url, method: "POST", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Berhasil menerima tanggapan (Misal: ditolak karena belum check out)
        try {
          return json.decode(response.body);
        } catch (_) {
          return {'success': false, 'message': 'Terjadi kesalahan pemrosesan absensi.'};
        }
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengirim absensi.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengirim absensi (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 MENGAMBIL RIWAYAT ABSENSI TERAPIS
  // =========================================================================
  Future<Map<String, dynamic>> getAttendanceHistory({String? bulan, String? tahun}) async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final Map<String, String> queryParams = {};
    if (bulan != null && bulan.isNotEmpty) queryParams['bulan'] = bulan;
    if (tahun != null && tahun.isNotEmpty) queryParams['tahun'] = tahun;

    final uri = Uri.parse('$baseUrl/get_history_absensi.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      _logDebug(url: uri.toString(), method: "GET", statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Sesi habis, silakan login lagi.'};
      }

      try {
        final errorData = json.decode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil riwayat absensi.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil riwayat absensi (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

}