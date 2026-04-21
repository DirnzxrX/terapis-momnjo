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

  // =========================================================================
  // 1. FUNGSI UTAMA GET JOBS (Active Jobs)
  // =========================================================================
  Future<Map<String, dynamic>> getJobs({String? status, String? search}) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Unauthorized. Token tidak ditemukan.'};

    String urlString = '$baseUrl/api_terapis/get_all_jobs.php';
    List<String> queryParams = [];
    
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=$search');
    }
    
    if (queryParams.isNotEmpty) {
      urlString += '?${queryParams.join('&')}';
    }

    try {
      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

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
        return {'success': false, 'message': 'Gagal mengambil data (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  /// Shortcut panggil Job yang masih Open (dipakai di ScheduleScreen)
  Future<Map<String, dynamic>> getActiveJobs({String? search}) async {
    return await getJobs(status: 'open', search: search);
  }

  // =========================================================================
  // UPDATE STATUS TREATMENT PER-ITEM (Centang Layanan)
  // =========================================================================
  Future<Map<String, dynamic>> updateJobStatus(String idTransaksi, String productName) async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_terapis/update_job_status.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_transaksi': idTransaksi,
          'product_name': productName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        try {
          return json.decode(response.body);
        } catch (e) {
          String partialError = response.body;
          if (partialError.length > 100) partialError = '${partialError.substring(0, 100)}...';
          return {'status': 'error', 'message': 'Server mengembalikan error PHP: $partialError'};
        }
      } else {
        return {'status': 'error', 'message': 'Server Error (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi terputus: $e'};
    }
  }

  // =========================================================================
  // 2. MENGAMBIL STATISTIK TERAPIS (HOME SCREEN)
  // =========================================================================
  Future<Map<String, dynamic>> getStats() async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api_terapis/get_stats.php'),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'message': 'Gagal memuat statistik'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // =========================================================================
  // 3. UPDATE STATUS BOOKING KESELURUHAN (Arrived, Pemeriksaan, Started, Closed)
  // =========================================================================
  Future<Map<String, dynamic>> updateBookingStatus({
    required String idBooking, 
    required String newStatus,
    String? imagePath, 
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

    try {
      final String endpoint = '$baseUrl/api_terapis/update_booking_status.php'; 

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_booking': idBooking,
          'status': newStatus, 
          // Jika backend butuh base64 imagePath untuk arrived, kirim di sini
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal update status booking'};
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
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    if (idTransaksi.trim().isEmpty || idCustomer.trim().isEmpty) {
      return {'status': 'error', 'message': 'ID Transaksi/Customer kosong.'};
    }

    String finalTekanan = tekanan ?? '';
    if (finalTekanan.isEmpty && sistolik != null && diastolik != null) {
      if (sistolik.isNotEmpty && diastolik.isNotEmpty) {
        finalTekanan = '$sistolik/$diastolik';
      }
    }

    try {
      final Map<String, dynamic> payloadData = {
        'id_transaksi': idTransaksi,
        'id_customer': idCustomer, 
        if (suhu != null && suhu.isNotEmpty) 'suhu': suhu,
        if (tinggi != null && tinggi.isNotEmpty) 'tinggi': tinggi,
        if (berat != null && berat.isNotEmpty) 'berat': berat,
        if (finalTekanan.isNotEmpty) 'tekanan': finalTekanan,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api_terapis/store_data_medis.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payloadData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server Error'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi terputus: $e'};
    }
  }

  // =========================================================================
  // [NEW] 5. MENGAMBIL LIST RIWAYAT PEKERJAAN (HISTORY)
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryList() async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api_terapis/history.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {'status': 'error', 'message': 'Sesi habis, silakan login lagi.'};
      }
      return {'status': 'error', 'message': 'Gagal mengambil data history.'};
    } catch (e) {
      return {'status': 'error', 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // [NEW] 6. MENGAMBIL DETAIL RIWAYAT PEKERJAAN
  // =========================================================================
  Future<Map<String, dynamic>> getHistoryDetail(String idTransaksi) async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api_terapis/history_detail.php?id_transaksi=$idTransaksi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Gagal mengambil detail history.'};
    } catch (e) {
      return {'status': 'error', 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // [NEW] 7. RATE CUSTOMER (LAPORAN KUNJUNGAN)
  // =========================================================================
  Future<Map<String, dynamic>> rateCustomer({
    required String idTransaksi,
    required int rating,
    required List<String> tags,
    required String notes,
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_terapis/rate_customer.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_transaksi': idTransaksi,
          'rating': rating,
          'tags': tags,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Gagal mengirim laporan kunjungan.'};
    } catch (e) {
      return {'status': 'error', 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // =========================================================================
  // 8. LOGIN
  // =========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_terapis/login.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username.trim(), 
          'password': password.trim()
        }),
      );
      
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
  // 9. LOGOUT
  // =========================================================================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Bersihkan semua data sesi
  }
}