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

  // --- 1. MENGAMBIL DAFTAR SEMUA PEKERJAAN (GET ALL JOBS) ---
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

  // --- 2. MENGAMBIL STATISTIK TERAPIS (HOME SCREEN) ---
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

  // --- 3. MENYELESAIKAN STATUS TREATMENT PER-ITEM ---
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

  // --- 4. MENYIMPAN DATA MEDIS ---
  Future<Map<String, dynamic>> storeDataMedis({
    required String idTransaksi,
    required String idCustomer,
    String? suhu,
    String? tinggi,
    String? berat,
    String? tekanan,
    String? sistolik, // Menambahkan parameter sistolik dari UI
    String? diastolik, // Menambahkan parameter diastolik dari UI
    String? catatan,
  }) async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Token tidak ditemukan'};

    // CEGAH ERROR 500 KARENA ID KOSONG
    if (idTransaksi.trim().isEmpty || idCustomer.trim().isEmpty) {
      return {'status': 'error', 'message': 'ID Transaksi atau ID Customer tidak terbaca. Harap kembali dan buka ulang halaman ini.'};
    }

    // GABUNGKAN SISTOLIK DAN DIASTOLIK (Contoh: "120/80") JIKA TEKANAN KOSONG
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
        if (sistolik != null && sistolik.isNotEmpty) 'sistolik': sistolik, // Jaga-jaga jika backend minta terpisah
        if (diastolik != null && diastolik.isNotEmpty) 'diastolik': diastolik, // Jaga-jaga jika backend minta terpisah
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      };

      // PRINT INI AKAN MUNCUL DI TERMINAL/DEBUG CONSOLE ANDA
      debugPrint("==== DEBUG PAYLOAD API STORE DATA MEDIS ====");
      debugPrint(jsonEncode(payloadData));
      debugPrint("==============================================");

      final response = await http.post(
        Uri.parse('$baseUrl/api_terapis/store_data_medis.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payloadData),
      );

      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 401) {
        try {
          return json.decode(response.body);
        } catch (e) {
          String partialError = response.body;
          if (partialError.length > 100) partialError = '${partialError.substring(0, 100)}...';
          return {'status': 'error', 'message': 'Server error: $partialError'};
        }
      } else {
        return {'status': 'error', 'message': 'Server Error (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi terputus: $e'};
    }
  }

  // --- 5. MENGAMBIL DATA MEDIS ---
  Future<Map<String, dynamic>> getStoredDataMedis({String? idTransaksi}) async {
    final String? token = await _getToken();
    if (token == null) return {'status': 'error', 'message': 'Unauthorized. Token tidak ditemukan.'};

    String urlString = '$baseUrl/api_terapis/get_stored_data_medis.php';
    if (idTransaksi != null && idTransaksi.isNotEmpty) {
      urlString += '?id_transaksi=$idTransaksi';
    }

    try {
      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          return {'status': 'error', 'message': 'Format response server tidak valid.'};
        }
      } else if (response.statusCode == 401) {
        await logout();
        return {'status': 'error', 'message': 'Unauthorized. Token tidak valid atau kadaluarsa.'};
      } else {
        return {'status': 'error', 'message': 'Gagal mengambil data (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  // --- 6. LOGIN ---
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
          if (data['foto'] != null) await prefs.setString('foto', data['foto']);
          if (data['email'] != null) await prefs.setString('email', data['email']);
          if (data['username'] != null) await prefs.setString('username', data['username']);
          if (data['id_pegawai'] != null) await prefs.setInt('id_pegawai', data['id_pegawai']);
        }
        return responseData;
      }
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau sistem.'};
    }
  }

  // --- 7. LOGOUT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('nama_lengkap');
    await prefs.remove('foto');
    await prefs.remove('email');
    await prefs.remove('username');
    await prefs.remove('id_pegawai');
    await prefs.remove('is_on_duty');
  }
}