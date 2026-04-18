import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // DITAMBAHKAN: Untuk memaksa parsing JSON dari String

class ApiService {
  static const String baseUrl = 'https://app.momnjo.com/dev/api_terapis';
  
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', 
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        debugPrint('➡️ REQUEST [${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ RESPONSE [${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('❌ API Error: ${e.response?.statusCode} - ${e.message}');
        return handler.next(e);
      },
    ));
  }

  // =========================================================================
  // 1. FUNGSI LOGIN (REAL API PHP)
  // =========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/login.php', data: {
        'username': username.trim(),
        'password': password,
      });

      // LAPISAN PELINDUNG: Konversi paksa (Safety Net)
      // Jika PHP mengembalikan String (akibat lupa set Header JSON), kita paksa parse.
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {
          // Jika gagal parse, berarti PHP benar-benar mengembalikan teks acak / HTML error.
        }
      }

      if (response.statusCode == 200) {
        if (responseData is Map) {
          // Respons adalah Map JSON yang sah
          if (responseData['success'] == true) {
            final prefs = await SharedPreferences.getInstance();
            
            // Gunakan nullable operator (?) untuk menghindari null exception
            final token = responseData['data']?['token'];
            final namaLengkap = responseData['data']?['nama_lengkap'];

            if (token != null) await prefs.setString('token', token);
            if (namaLengkap != null) await prefs.setString('nama_lengkap', namaLengkap);

            // Kita harus pastikan tipe yang dikembalikan adalah Map<String, dynamic>
            return Map<String, dynamic>.from(responseData);
          } else {
             // Berhasil di-parse, tetapi backend menyatakan success: false
             return {
               'success': false, 
               'message': responseData['message'] ?? 'Login Gagal. Kredensial tidak valid.'
             };
          }
        } else {
           // Respons 200 OK, tapi isinya bukan Map JSON (misal: "Database connection failed")
           // Kita tidak bisa menggunakan responseData['message'], karena ini String.
           return {
             'success': false, 
             'message': 'Format respons server tidak dikenali: \n$responseData'
           };
        }
      }
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
      
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem (Parse Error): $e'};
    }
  }

  // =========================================================================
  // 2. FUNGSI LOGOUT (REAL API PHP)
  // =========================================================================
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('nama_lengkap');
      return true;
    } catch (e) {
      debugPrint("Error saat logout: $e");
      return false;
    }
  }

  // =========================================================================
  // 3. FUNGSI AMBIL STATISTIK HARIAN (REAL API PHP)
  // =========================================================================
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/stats.php');
      
      dynamic responseData = response.data;
      if (responseData is String) {
        try { responseData = jsonDecode(responseData); } catch (_) {}
      }
      
      if (response.statusCode == 200 && responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      }
      return {'success': false, 'message': 'Gagal mengambil data statistik'};
      
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // =========================================================================
  // 4. FUNGSI AMBIL DAFTAR PEKERJAAN (REAL API PHP)
  // =========================================================================
  Future<Map<String, dynamic>> getJobs({String status = 'Open'}) async {
    try {
      final response = await _dio.get('/get_jobs.php', queryParameters: {
        'status': status,
      });

      dynamic responseData = response.data;
      if (responseData is String) {
        try { responseData = jsonDecode(responseData); } catch (_) {}
      }

      if (response.statusCode == 200 && responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      }
      return {'success': false, 'message': 'Gagal mengambil daftar pekerjaan'};
      
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // =========================================================================
  // FUNGSI BANTUAN UNTUK MENANGANI ERROR API SECARA ELEGAN
  // =========================================================================
  Map<String, dynamic> _handleDioError(DioException e) {
    String errorMessage = 'Terjadi kesalahan jaringan.';
    
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Koneksi ke server terputus (Timeout).';
    } else if (e.response != null) {
      // Sama seperti di atas, amankan parse error message
      dynamic errorData = e.response?.data;
      if (errorData is String) {
        try { errorData = jsonDecode(errorData); } catch (_) {}
      }
      
      if (errorData is Map && errorData['message'] != null) {
        errorMessage = errorData['message'];
      } else {
        errorMessage = 'Server merespons dengan kode: ${e.response?.statusCode}';
      }
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Tidak ada koneksi internet / Server tidak dapat dijangkau.';
    }

    return {
      'success': false,
      'message': errorMessage,
    };
  }
}