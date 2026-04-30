import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _fotoProfil = "https://i.pravatar.cc/150?img=5"; // Gambar fallback jika API belum ada foto

  @override
  void initState() {
    super.initState();
    _loadDataDiri();
  }

  // --- FUNGSI MENGAMBIL DATA DARI SHARED PREFERENCES ---
  Future<void> _loadDataDiri() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Mengambil data, pastikan KEY yang digunakan ('nama_lengkap', 'no_telepon', dll) 
      // sama dengan KEY yang Anda simpan saat login.
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
          _fotoProfil = prefs.getString('foto_profil') ?? "https://i.pravatar.cc/150?img=5";
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            ? const Center(child: CircularProgressIndicator()) // Menampilkan loading saat memuat data
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildProfilePicture(),
                    const SizedBox(height: 24),
                    
                    // Kartu Informasi Pribadi (Data Dinamis)
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
                    
                    // Kartu Informasi Pekerjaan (Data Dinamis)
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
              backgroundImage: NetworkImage(_fotoProfil), // Foto Dinamis
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