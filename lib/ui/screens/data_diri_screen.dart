import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart'; // Import ApiService
import 'package:intl/intl.dart';

class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({Key? key}) : super(key: key);

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);

  // --- STATE VARIABEL UNTUK DATA DINAMIS ---
  bool _isLoading = true;
  String _namaLengkap = "-";
  String _noTelepon = "-";
  String _email = "-";
  String _tanggalLahir = "-";
  String _jenisKelamin = "-";
  String _alamat = "-";
  String _noPegawai = "-";
  String _gerai = "-";
  String _fotoProfil = ""; 

  @override
  void initState() {
    super.initState();
    _loadDataDiriAPI();
  }

  // --- 1. FUNGSI UTAMA MENGAMBIL DATA DARI API ---
  Future<void> _loadDataDiriAPI() async {
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final response = await api.getDataDiri();

      if (response['status'] == 'success' || response['success'] == true) {
        final data = response['data'] ?? {};
        
        if (mounted) {
          setState(() {
            _namaLengkap = _checkEmpty(data['nama_lengkap']);
            _noTelepon = _checkEmpty(data['no_telepon']);
            _email = _checkEmpty(data['email']);
            
            // Format tanggal lahir jika ada
            String tglLahirRaw = _checkEmpty(data['tanggal_lahir']);
            _tanggalLahir = _formatDate(tglLahirRaw);
            
            _jenisKelamin = _checkEmpty(data['jenis_kelamin']);
            _alamat = _checkEmpty(data['alamat']);
            _noPegawai = _checkEmpty(data['no_pegawai']);
            _gerai = _checkEmpty(data['gerai']);
            
            String foto = data['foto_profil']?.toString() ?? "";
            // Jika foto kosong dari API, buat avatar dengan inisial nama
            _fotoProfil = foto.isNotEmpty ? foto : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_namaLengkap != "-" ? _namaLengkap : "Mom N Jo")}&background=ECA898&color=fff";
            
            _isLoading = false;
          });
        }
      } else {
        // Jika API membalas error (misal 404), fallback ke memori lokal
        _loadFallbackData();
      }
    } catch (e) {
      // Jika internet putus, fallback ke memori lokal
      _loadFallbackData();
    }
  }

  // --- 2. FUNGSI CADANGAN JIKA API GAGAL (AMBIL DARI LOKAL) ---
  Future<void> _loadFallbackData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _namaLengkap = prefs.getString('fullname') ?? prefs.getString('nama_lengkap') ?? "-";
          _noTelepon = prefs.getString('no_telepon') ?? prefs.getString('phone') ?? "-";
          _email = prefs.getString('email') ?? "-";
          _tanggalLahir = prefs.getString('tanggal_lahir') ?? "-";
          _jenisKelamin = prefs.getString('jenis_kelamin') ?? "-";
          _alamat = prefs.getString('alamat') ?? "-";
          _noPegawai = prefs.getString('username') ?? prefs.getString('id_terapis') ?? "-";
          _gerai = prefs.getString('gerai') ?? prefs.getString('branch') ?? "-";
          
          String foto = prefs.getString('foto_profil') ?? "";
          _fotoProfil = foto.isNotEmpty ? foto : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_namaLengkap != "-" ? _namaLengkap : "Mom N Jo")}&background=ECA898&color=fff";
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER UNTUK CEK STRING KOSONG ---
  String _checkEmpty(dynamic value) {
    if (value == null) return "-";
    String valStr = value.toString().trim();
    if (valStr.isEmpty || valStr == "null") return "-";
    return valStr;
  }

  // --- HELPER UNTUK FORMAT TANGGAL ---
  String _formatDate(String dateStr) {
    if (dateStr == "-") return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/baground2.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar gambar terlihat
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDarkBrown),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Data Diri',
            style: TextStyle(
              color: textDarkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator()) 
            : RefreshIndicator(
                onRefresh: _loadDataDiriAPI, // Tarik ke bawah untuk refresh dari API
                color: primaryPeach,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      _buildProfilePicture(),
                      const SizedBox(height: 24),
                      
                      // Kartu Informasi Pribadi
                      _buildInfoSection(
                        title: 'Informasi Pribadi',
                        items: [
                          _buildInfoItem(Icons.person_outline, 'Nama Lengkap', _namaLengkap),
                          _buildInfoItem(Icons.phone_outlined, 'Nomor Telepon', _noTelepon),
                          _buildInfoItem(Icons.email_outlined, 'Email', _email),
                          _buildInfoItem(Icons.calendar_today_outlined, 'Tanggal Lahir', _tanggalLahir),
                          _buildInfoItem(Icons.female_outlined, 'Jenis Kelamin', _jenisKelamin),
                          _buildInfoItem(Icons.location_on_outlined, 'Alamat', _alamat),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Kartu Informasi Pekerjaan
                      _buildInfoSection(
                        title: 'Informasi Pekerjaan',
                        items: [
                          _buildInfoItem(Icons.badge_outlined, 'No.Pegawai', _noPegawai),
                          _buildInfoItem(Icons.map_outlined, 'Gerai / Area', _gerai),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Komponen Foto Profil + Ikon Kamera
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: NetworkImage(_fotoProfil), 
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPeach,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Komponen Card Pembungkus List Informasi
  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDarkBrown,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Komponen Baris Informasi (Icon + Label + Value)
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}