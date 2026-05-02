import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://app.momnjo.com/dev";

  // --- HELPER: MENGAMBIL TOKEN JWT DARI LOKAL ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
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
  // 1. FUNGSI UTAMA GET JOBS (Active Jobs)
  // =========================================================================
  Future<Map<String, dynamic>> getJobs({String? status, String? search}) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Unauthorized. Token tidak ditemukan.'};

    final Map<String, String> queryParams = {};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/api_terapis/get_all_jobs.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
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
    return await getJobs(search: search); 
  }

  // =========================================================================
  // UPDATE STATUS TREATMENT PER-ITEM (Centang Layanan)
  // =========================================================================
  Future<Map<String, dynamic>> updateJobStatus(String idTransaksi, String productName) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/update_job_status.php';
    final Map<String, dynamic> body = {
      'id_transaksi': idTransaksi,
      'product_name': productName,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      _logDebug(url: url, method: "POST", requestBody: body, statusCode: response.statusCode, responseBody: response.body);

      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        try {
          return json.decode(response.body);
        } catch (e) {
          String partialError = response.body;
          if (partialError.length > 100) partialError = '${partialError.substring(0, 100)}...';
          return {'success': false, 'message': 'Server mengembalikan error PHP: $partialError'};
        }
      } else {
        return {'success': false, 'message': 'Server Error (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi terputus: $e'};
    }
  }

  // =========================================================================
  // 2. MENGAMBIL STATISTIK TERAPIS (HOME SCREEN)
  // =========================================================================
  Future<Map<String, dynamic>> getStats() async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/get_stats.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
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
  // 🔥 3. UPDATE STATUS BOOKING KESELURUHAN (MENDUKUNG UPLOAD FOTO)
  // =========================================================================
  Future<Map<String, dynamic>> updateBookingStatus({
    required String idBooking,
    required String newStatus,
    String? imagePath,
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/update_booking_status.php';

    try {
      http.Response response;

      if (imagePath != null && imagePath.isNotEmpty) {
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        
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
  // 4. MENYIMPAN DATA MEDIS (Pemeriksaan Klien)
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

    final String url = '$baseUrl/api_terapis/store_data_medis.php';
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
  // 5. MENGAMBIL LIST RIWAYAT PEKERJAAN (HISTORY)
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryList() async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/history.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil data history.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil data history (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 6. MENGAMBIL DETAIL RIWAYAT PEKERJAAN
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryDetail(String idTransaksi) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/history_detail.php?id_transaksi=$idTransaksi';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
  // 7. RATE CUSTOMER (LAPORAN KUNJUNGAN)
  // =========================================================================
  Future<Map<String, dynamic>> rateCustomer({
    required String idTransaksi,
    required int rating,
    required List<String> tags,
    required String notes,
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/rate_customer.php';
    final Map<String, dynamic> body = {
      'id_transaksi': idTransaksi,
      'rating': rating,
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
  // 9. LOGIN
  // =========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    final String url = '$baseUrl/api_terapis/login.php';
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

      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 401) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final data = responseData['data'];

          if (data['token'] != null) await prefs.setString('jwt_token', data['token']);
          if (data['nama_lengkap'] != null) await prefs.setString('nama_lengkap', data['nama_lengkap']);
        }
        return responseData;
      }
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau sistem.'};
    }
  }

  // =========================================================================
  // 10. LOGOUT
  // =========================================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Bersihkan semua data sesi
    debugPrint("------------------- 🚀 API LOG: LOGOUT LOCAL SUCCESS 🚀 -------------------");
  }

  // =========================================================================
  // 🔥 11. MENGAMBIL SALDO TERAPIS (GET BALANCE) 
  // =========================================================================
  Future<Map<String, dynamic>> getBalance({
    String? source,
    String? startDate,
    String? endDate,
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final Map<String, String> queryParams = {};
    if (source != null && source.isNotEmpty) queryParams['source'] = source;
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/api_terapis/get_balance.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil saldo.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil saldo (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 12. SUBMIT PENARIKAN DANA (PAYOUT REQUEST)
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
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/request_payout.php';
    
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
  // 🔥 13. MENGAMBIL RIWAYAT PENARIKAN (PAYOUT HISTORY)
  // =========================================================================
  Future<Map<String, dynamic>> getPayoutHistory({String? status}) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final Map<String, String> queryParams = {};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/api_terapis/get_payout_history.php')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
        return {'success': false, 'message': errorData['message'] ?? 'Gagal mengambil riwayat penarikan dana.'};
      } catch (_) {
        return {'success': false, 'message': 'Gagal mengambil riwayat penarikan dana (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 🔥 14. MENGAMBIL DETAIL PENARIKAN (PAYOUT DETAIL)
  // =========================================================================
  Future<Map<String, dynamic>> getPayoutDetail(int idPayout) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/get_detail_payout.php?id_payout=$idPayout';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
  // 🔥 15. MENGAMBIL PROFIL TERAPIS (GET PROFILE) - BARU DITAMBAHKAN
  // =========================================================================
  Future<Map<String, dynamic>> getProfile() async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    final String url = '$baseUrl/api_terapis/get_profile.php';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logDebug(url: url, method: "GET", statusCode: response.statusCode, responseBody: response.body);

      // Sesuai dokumentasi: 200 untuk OK, 401 untuk Unauthorized, 404 untuk Not Found
      if (response.statusCode == 200 || response.statusCode == 404) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout(); // Jika Unauthorized / token mati, paksa logout lokal
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
}