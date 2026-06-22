import 'dart:convert';
import 'package:flutter/foundation.dart'; // Menyediakan kIsWeb
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // DITAMBAHKAN UNTUK FIX UPLOAD WEB
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      "https://dashboard.momnjo.my.id/dev/api_terapis";
  static const String baseImageUrl =
      "https://dashboard.momnjo.my.id/assets/images";

  // --- HELPER: MENGAMBIL TOKEN & COOKIE ---
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_cookie');
  }

  Future<bool> isLoggedIn() async {
    final String? token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // --- HELPER: FUNGSI MATA-MATA (DEBUG LOG) ---
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
      String logResp = responseBody.length > 500
          ? "${responseBody.substring(0, 500)}... [TRUNCATED]"
          : responseBody;
      debugPrint("✅ RESPONSE: $logResp");
      debugPrint("------------------- 🔚 API LOG END -------------------");
    }
  }

  // =========================================================================
  // CORE HTTP METHODS
  // =========================================================================

  Future<Map<String, String>> _buildHeaders() async {
    final String? token = await _getToken();
    final String? cookie = await _getCookie();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (cookie != null) 'Cookie': cookie,
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      logout();
      return {
        'success': false,
        'message': 'Sesi habis atau tidak valid, silakan login lagi.',
      };
    }

    try {
      final data = json.decode(response.body);

      bool isSuccess = false;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isSuccess = true;
      }

      if (data is Map<String, dynamic>) {
        if (data.containsKey('success')) {
          isSuccess = data['success'] == true || data['success'] == 'true';
        } else if (data.containsKey('status')) {
          isSuccess = data['status'] == 'success';
        }
        data['success'] = isSuccess;
        return data;
      }

      return {'success': isSuccess, 'data': data};
    } catch (e) {
      return {
        'success': false,
        'message':
            'Format response server tidak valid (Status: ${response.statusCode}).',
      };
    }
  }

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: (queryParams != null && queryParams.isNotEmpty)
          ? queryParams
          : null,
    );

    try {
      final headers = await _buildHeaders();
      final response = await http.get(uri, headers: headers);
      _logDebug(
        url: uri.toString(),
        method: "GET",
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    bool asForm = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _buildHeaders();
      http.Response response;

      if (asForm) {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        Map<String, String> formBody = body.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        response = await http.post(uri, headers: headers, body: formBody);
      } else {
        response = await http.post(
          uri,
          headers: headers,
          body: json.encode(body),
        );
      }

      _logDebug(
        url: uri.toString(),
        method: asForm ? "POST (Form)" : "POST",
        requestBody: body,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  // Menambahkan MediaType('image', 'jpeg') untuk validasi Backend PHP
  Future<Map<String, dynamic>> _multipartPost(
    String endpoint,
    Map<String, String> fields, {
    String? imagePath,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      var request = http.MultipartRequest('POST', uri);
      final headers = await _buildHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      if (imagePath != null && imagePath.isNotEmpty) {
        if (kIsWeb) {
          final blobUri = Uri.parse(imagePath);
          final response = await http.get(blobUri);
          final bytes = response.bodyBytes;

          String filename = 'upload.jpg';
          try {
            filename = blobUri.pathSegments.last;
          } catch (_) {}
          if (!filename.contains('.')) filename = 'upload.jpg';

          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: filename,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imagePath,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      _logDebug(
        url: uri.toString(),
        method: "POST (Multipart)",
        requestBody: fields,
        statusCode: 0,
        responseBody: "Mengirim data & file...",
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _logDebug(
        url: uri.toString(),
        method: "POST (Multipart Result)",
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan saat upload: $e',
      };
    }
  }

  // =========================================================================
  // LOGOUT, LOGIN & AUTH
  // =========================================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAttendance = prefs.getString('attendance_history');

    await prefs.clear();

    if (savedAttendance != null) {
      await prefs.setString('attendance_history', savedAttendance);
    }
    debugPrint(
      "------------------- 🚀 API LOG: LOGOUT LOCAL SUCCESS 🚀 -------------------",
    );
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await _post('/login.php', {
      'username': username.trim(),
      'password': password.trim(),
    });

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final data = result['data'] ?? result;

      final String? tokenToSave =
          data['token'] ?? data['jwt'] ?? result['token'];
      if (tokenToSave != null && tokenToSave.isNotEmpty) {
        await prefs.setString('jwt_token', tokenToSave);
      }

      final String? namaToSave =
          data['nama_lengkap'] ?? data['name'] ?? result['nama_lengkap'];
      if (namaToSave != null) {
        await prefs.setString('nama_lengkap', namaToSave);
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    return await _post('/change_password.php', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // =========================================================================
  // BATCH 1: JOBS & HISTORY
  // =========================================================================
  Future<Map<String, dynamic>> getJobs({String? status, String? search}) async {
    final Map<String, String> params = {};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get('/get_all_jobs.php', queryParams: params);
  }

  Future<Map<String, dynamic>> getActiveJobs({String? search}) async {
    return await getJobs(status: 'open', search: search);
  }

  Future<Map<String, dynamic>> getJobDetail(String idTransaksi) async {
    if (idTransaksi.trim().isEmpty)
      return {'success': false, 'message': 'ID Transaksi wajib diisi.'};
    return await _get(
      '/get_job_detail.php',
      queryParams: {'id_transaksi': idTransaksi},
    );
  }

  Future<Map<String, dynamic>> getHistoryList() async {
    return await _get('/history.php');
  }

  Future<Map<String, dynamic>> getHistoryDetail(String idTransaksi) async {
    return await _get(
      '/history_detail.php',
      queryParams: {'id_transaksi': idTransaksi},
    );
  }

  // Mengambil daftar service yang sedang aktif berdasarkan token terapis
  Future<Map<String, dynamic>> getActiveServices({
    String? idTransaksi,
    String? idBooking,
  }) async {
    final Map<String, String> params = {'scope': 'active'};
    if (idTransaksi != null && idTransaksi.trim().isNotEmpty) {
      params['id_transaksi'] = idTransaksi.trim();
    }
    if (idBooking != null && idBooking.trim().isNotEmpty) {
      params['id_booking'] = idBooking.trim();
    }
    return await _get('/get_service.php', queryParams: params);
  }

  // =========================================================================
  // BATCH 2: UPDATE STATUS, REPORTS & DATA MEDIS
  // =========================================================================
  Future<Map<String, dynamic>> updateJobStatus({
    required String idTransaksi,
    required String action,
    String? idBooking,
    String? idDetail, // 🔥 DITAMBAHKAN: Parameter idDetail
    String? productName,
    String? imagePath,
  }) async {
    String mappedStatus = action;
    if (action.toLowerCase() == 'arrived')
      mappedStatus = 'Arrived';
    else if (action.toLowerCase() == 'start')
      mappedStatus = 'Started';
    else if (action.toLowerCase() == 'pause' || action.toLowerCase() == 'resume')
      mappedStatus = 'Started';
    else if (action.toLowerCase() == 'finish')
      mappedStatus = 'Closed';

    // ❌ JAM LOKAL DIHAPUS: Backend sekarang menggunakan NOW() sesuai file PATCH

    final Map<String, String> fields = {
      'id_transaksi': idTransaksi,
      'id_booking': (idBooking != null && idBooking.isNotEmpty)
          ? idBooking
          : idTransaksi,
      'action': action, // 🔥 Kirim literal action ke backend untuk dibaca PHP
      'status': mappedStatus,
    };

    // 🔥 DITAMBAHKAN: Kirim id_detail sebagai identifier utama
    if (idDetail != null && idDetail.isNotEmpty) fields['id_detail'] = idDetail;

    // Fallback: biarkan product_name terkirim jika ada
    if (productName != null && productName.isNotEmpty)
      fields['product_name'] = productName;

    if (action == 'arrived' || (imagePath != null && imagePath.isNotEmpty)) {
      return await _multipartPost(
        '/update_service.php',
        fields,
        imagePath: imagePath,
      );
    } else {
      return await _post('/update_service.php', fields);
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String idBooking,
    required String newStatus,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      return await _multipartPost('/update_booking_status.php', {
        'id_booking': idBooking,
        'status': newStatus,
      }, imagePath: imagePath);
    }
    return await _post('/update_booking_status.php', {
      'id_booking': idBooking,
      'status': newStatus,
    });
  }

  Future<Map<String, dynamic>> rateCustomer({
    required String idTransaksi,
    required int rating,
    required List<String> tags,
    required String notes,
  }) async {
    return await _post('/rate_customer.php', {
      'id_transaksi': idTransaksi,
      'rating': rating > 0 ? rating : 5,
      'tags': tags,
      'notes': notes,
    });
  }

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
    if (idTransaksi.trim().isEmpty || idCustomer.trim().isEmpty) {
      return {'success': false, 'message': 'ID Transaksi/Customer kosong.'};
    }

    String finalTekanan = tekanan ?? '';
    if (finalTekanan.isEmpty &&
        sistolik != null &&
        diastolik != null &&
        sistolik.isNotEmpty &&
        diastolik.isNotEmpty) {
      finalTekanan = '$sistolik/$diastolik';
    }

    final Map<String, String> fields = {
      'id_transaksi': idTransaksi,
      'id_customer': idCustomer,
    };

    if (suhu != null && suhu.isNotEmpty) fields['suhu'] = suhu;
    if (tinggi != null && tinggi.isNotEmpty) fields['tinggi'] = tinggi;
    if (berat != null && berat.isNotEmpty) fields['berat'] = berat;
    if (finalTekanan.isNotEmpty) fields['tekanan'] = finalTekanan;
    if (catatan != null && catatan.isNotEmpty) fields['catatan'] = catatan;

    return await _post('/store_data_medis.php', fields, asForm: true);
  }

  Future<Map<String, dynamic>> getStoredDataMedis({String? idTransaksi}) async {
    final Map<String, String> params = {};
    if (idTransaksi != null && idTransaksi.isNotEmpty) {
      params['id_transaksi'] = idTransaksi;
    }
    return await _get('/get_stored_data_medis.php', queryParams: params);
  }

  // =========================================================================
  // BATCH 3: ATTENDANCE, PROFILE & OTHER INFO
  // =========================================================================
  Future<Map<String, dynamic>> getStats() async => await _get('/get_stats.php');
  Future<Map<String, dynamic>> getProfile() async =>
      await _get('/get_profile.php');
  Future<Map<String, dynamic>> getDataDiri() async =>
      await _get('/get_data_diri.php');
  Future<Map<String, dynamic>> getCarousel() async =>
      await _get('/get_carousel.php');
  Future<Map<String, dynamic>> checkAttendanceStatus() async =>
      await _get('/store_absensi.php');
  Future<Map<String, dynamic>> getGeraiWa() async =>
      await _get('/get_gerai_wa.php');

  Future<Map<String, dynamic>> submitAttendance({
    required String action,
    String? catatan,
    String? imagePath,
    String? lokasi,
  }) async {
    final fields = {'action': action};
    if (catatan != null && catatan.isNotEmpty) fields['catatan'] = catatan;
    if (lokasi != null && lokasi.isNotEmpty) fields['lokasi'] = lokasi;

    if (imagePath != null && imagePath.isNotEmpty) {
      return await _multipartPost(
        '/store_absensi.php',
        fields,
        imagePath: imagePath,
      );
    }
    return await _post('/store_absensi.php', fields);
  }

  Future<Map<String, dynamic>> getAttendanceHistory({
    String? bulan,
    String? tahun,
  }) async {
    final Map<String, String> params = {};
    if (bulan != null && bulan.isNotEmpty) params['bulan'] = bulan;
    if (tahun != null && tahun.isNotEmpty) params['tahun'] = tahun;
    return await _get('/get_history_absensi.php', queryParams: params);
  }

  // =========================================================================
  // BATCH 4: FINANCE & PAYOUT
  // =========================================================================
  Future<Map<String, dynamic>> getBalance({
    String? source,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> params = {};
    if (source != null && source.isNotEmpty) params['source'] = source;
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    return await _get('/get_balance.php', queryParams: params);
  }

  Future<Map<String, dynamic>> getEarnings({
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> params = {};
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    return await _get('/get_earnings.php', queryParams: params);
  }

  Future<Map<String, dynamic>> submitPayoutRequest({
    required String jenisPayout,
    required int amount,
    required String bank,
    required String accountNumber,
    required String accountName,
    String? notes,
  }) async {
    return await _post('/request_payout.php', {
      'jenis_payout': jenisPayout,
      'requested_amount': amount,
      'bank_account': bank,
      'account_number': accountNumber,
      'account_holder_name': accountName,
      if (notes != null && notes.isNotEmpty) 'note': notes,
    });
  }

  Future<Map<String, dynamic>> getPayoutHistory({
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> params = {};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    return await _get('/get_payout_history.php', queryParams: params);
  }

  Future<Map<String, dynamic>> getPayoutDetail(int idPayout) async {
    return await _get(
      '/get_detail_payout.php',
      queryParams: {'id_payout': idPayout.toString()},
    );
  }

  // =========================================================================
  // BATCH 5: TERAPIS REPORTS
  // =========================================================================
  Future<Map<String, dynamic>> getTerapisReportSummary({
    String? startDate,
    String? endDate,
    String? kodeGerai,
  }) async {
    final Map<String, String> params = {};
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    if (kodeGerai != null && kodeGerai.isNotEmpty)
      params['kode_gerai'] = kodeGerai;
    return await _get('/get_terapis_report.php', queryParams: params);
  }

  Future<Map<String, dynamic>> getTerapisCommissionDetail({
    String? startDate,
    String? endDate,
    String? kodeGerai,
  }) async {
    final Map<String, String> params = {'detail': 'komisi'};
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    if (kodeGerai != null && kodeGerai.isNotEmpty)
      params['kode_gerai'] = kodeGerai;
    return await _get('/get_terapis_report.php', queryParams: params);
  }

  Future<Map<String, dynamic>> getTerapisOverrideDetail({
    String? startDate,
    String? endDate,
    String? kodeGerai,
  }) async {
    final Map<String, String> params = {'detail': 'override'};
    if (startDate != null && startDate.isNotEmpty)
      params['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
    if (kodeGerai != null && kodeGerai.isNotEmpty)
      params['kode_gerai'] = kodeGerai;
    return await _get('/get_terapis_report.php', queryParams: params);
  }

  // =========================================================================
  // NEW: UPDATE DATA DIRI / PROFILE
  // =========================================================================
  Future<Map<String, dynamic>> updateDataDiri({
    String? namaLengkap,
    String? tanggalLahir, // 🔥 DITAMBAHKAN
    String? email,
    String? noTelepon,
    String? alamat,
    String? imagePath,
  }) async {
    final Map<String, String> fields = {};

    if (namaLengkap != null && namaLengkap.isNotEmpty)
      fields['nama_lengkap'] = namaLengkap;

    // 🔥 DITAMBAHKAN: Mengirim tanggal lahir ke backend
    if (tanggalLahir != null && tanggalLahir.isNotEmpty)
      fields['tanggal_lahir'] = tanggalLahir;

    if (email != null && email.isNotEmpty) fields['email'] = email;
    if (noTelepon != null && noTelepon.isNotEmpty)
      fields['no_telepon'] = noTelepon;
    if (alamat != null && alamat.isNotEmpty) fields['alamat'] = alamat;

    // Selalu gunakan _multipartPost untuk mematuhi aturan "Wajib multipart/form-data"
    // dari tim backend, terlepas dari apakah user melampirkan gambar baru atau tidak.
    return await _multipartPost(
      '/update_data_diri.php',
      fields,
      imagePath: imagePath,
    );
  }
}
