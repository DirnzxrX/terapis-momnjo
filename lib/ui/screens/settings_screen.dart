import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:therapist_momnjo/ui/screens/data_diri_screen.dart'; // Pastikan path import ini sesuai

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);
  final Color textDark = Colors.black87;

  // --- STATE DATA DINAMIS ---
  bool _isLoading = true;
  String _userName = 'Terapis';
  String _userPhone = '';
  String _idTerapis = '';
  String _fotoProfil = ''; // Inisialisasi kosong, fallback ditangani di method build

  // Default fallback image
  final String _defaultAvatar = 'https://ui-avatars.com/api/?name=Terapis&background=F48FB1&color=fff';

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  // --- FUNGSI MENGAMBIL DATA DARI API & LOCAL ---
  Future<void> _loadSettingsData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data lokal dulu untuk tampilan cepat (Instant UI)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('fullname') ?? 
                    prefs.getString('nama_lengkap') ?? 
                    prefs.getString('nama') ?? 'Terapis';
        
        _userPhone = prefs.getString('no_telepon') ?? 
                     prefs.getString('phone') ?? '';
        
        _idTerapis = prefs.getString('no_pegawai') ?? 
                     prefs.getString('username') ?? 
                     prefs.getString('id_terapis') ?? '';
        
        // --- PERBAIKAN: Cek cache foto lokal dengan anti Mixed-Content ---
        String localFoto = prefs.getString('foto_profil') ?? '';
        if (localFoto.isNotEmpty && localFoto != "null" && localFoto != "-") {
           if (localFoto.startsWith('http')) {
             localFoto = localFoto.replaceFirst('http://', 'https://'); // Tangkal Mixed Content dari cache
           } else {
             localFoto = "${ApiService.baseImageUrl}/$localFoto";
           }
        }
        _fotoProfil = localFoto;
      });

      // 2. Tarik data terbaru dari server (Sync Data)
      // MENGGUNAKAN getDataDiri() KARENA ENDPOINT INI YANG MEMILIKI FOTO PROFIL (Sama dengan DataDiriScreen)
      final response = await ApiService().getDataDiri();

      if ((response['success'] == true || response['status'] == 'success') && response['data'] != null) {
        final data = response['data'];
        
        String remoteName = data['nama_lengkap'] ?? data['fullname'] ?? data['name'] ?? data['nama'] ?? _userName;
        String remotePhone = data['no_telepon'] ?? data['phone'] ?? data['telepon'] ?? _userPhone;
        // DataDiriScreen menggunakan no_pegawai
        String remoteId = data['no_pegawai'] ?? data['id_terapis'] ?? data['username'] ?? data['id']?.toString() ?? _idTerapis;
        
        // --- LOGIKA PERBAIKAN FOTO PROFIL (Anti Mixed-Content & Missing Base URL) ---
        String rawFoto = data['foto_profil']?.toString() ?? data['foto']?.toString() ?? data['image']?.toString() ?? "";
        String remoteFoto = "";
        
        if (rawFoto.isNotEmpty && rawFoto != "null" && rawFoto != "-") {
           // Cek apakah server mengembalikan full URL (http...) atau hanya nama file
           if (rawFoto.startsWith('http')) {
             remoteFoto = rawFoto.replaceFirst('http://', 'https://'); // Tangkal Mixed Content
           } else {
             // Jika hanya nama file, gabungkan dengan baseImageUrl dari ApiService
             remoteFoto = "${ApiService.baseImageUrl}/$rawFoto"; 
           }
        }

        setState(() {
          _userName = remoteName;
          _userPhone = remotePhone;
          _idTerapis = remoteId;
          // Bypass cache jika gambar baru diupload dengan nambah query parameter unik (timestamp)
          _fotoProfil = remoteFoto.isNotEmpty ? "$remoteFoto?v=${DateTime.now().millisecondsSinceEpoch}" : "";
        });

        // 3. Update SharedPreferences agar sinkron
        await prefs.setString('nama_lengkap', remoteName);
        await prefs.setString('fullname', remoteName);
        await prefs.setString('no_telepon', remotePhone);
        if (rawFoto.isNotEmpty) await prefs.setString('foto_profil', rawFoto); // Simpan rawFoto (nama file) agar tidak dobel URL
        if (remoteId.isNotEmpty) await prefs.setString('no_pegawai', remoteId);
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HELPER UNTUK MENAMPILKAN PESAN (SNACKBAR) ---
  void _showInfoMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- FITUR 2: UBAH KATA SANDI (REAL API INTEGRATION) ---
  void _showChangePasswordDialog() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordCtrl,
                      obscureText: true, 
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Saat Ini',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: true, 
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: true, 
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: isSubmitting ? Colors.grey : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // 1. Validasi Lokal
                    if (oldPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty || confirmPasswordCtrl.text.isEmpty) {
                      _showInfoMessage('Semua kolom harus diisi!', isError: true);
                      return;
                    }
                    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                      _showInfoMessage('Kata sandi baru dan konfirmasi tidak cocok!', isError: true);
                      return;
                    }
                    if (newPasswordCtrl.text.length < 6) {
                      _showInfoMessage('Kata sandi baru minimal 6 karakter!', isError: true);
                      return;
                    }

                    // 2. Eksekusi API
                    setStateDialog(() => isSubmitting = true);
                    
                    try {
                      final response = await ApiService().changePassword(
                        oldPasswordCtrl.text,
                        newPasswordCtrl.text,
                      );

                      if (response['success'] == true) {
                        if (context.mounted) Navigator.pop(context);
                        _showInfoMessage(response['message'] ?? 'Kata sandi berhasil diubah!');
                      } else {
                        _showInfoMessage(response['message'] ?? 'Gagal mengubah kata sandi', isError: true);
                      }
                    } catch (e) {
                      _showInfoMessage('Terjadi kesalahan jaringan.', isError: true);
                    } finally {
                      if (mounted) setStateDialog(() => isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'), // Ganti dengan path bg kamu jika error
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pengaturan',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      
                      _buildSectionCard(
                        title: 'Akun & Keamanan',
                        children: [
                          _buildListTile(
                            icon: Icons.person_outline, 
                            title: 'Edit Profil', 
                            subtitle: 'Ubah kontak, alamat & foto',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DataDiriScreen()),
                              ).then((_) {
                                // Refresh tampilan setelah user selesai edit profil dan kembali
                                _loadSettingsData();
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildListTile(
                            icon: Icons.lock_outline, 
                            title: 'Kata Sandi', 
                            subtitle: 'Ubah kata sandi akun',
                            onTap: _showChangePasswordDialog,
                          ),
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

  // --- WIDGET COMPONENTS ---

  Widget _buildProfileCard() {
    String subtitle = "";
    if (_userPhone.isNotEmpty) subtitle += _userPhone;
    if (_userPhone.isNotEmpty && _idTerapis.isNotEmpty) subtitle += " • ";
    if (_idTerapis.isNotEmpty) subtitle += _idTerapis;

    // Perbaikan penanganan Image
    ImageProvider avatarImage;
    if (_fotoProfil.isNotEmpty && _fotoProfil.startsWith('http')) {
      avatarImage = NetworkImage(_fotoProfil);
    } else {
      // Jika string kosong atau bukan URL, gunakan API ui-avatars berdasarkan nama
      String safeName = Uri.encodeComponent(_userName.isNotEmpty ? _userName : "Terapis");
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=$safeName&background=F48FB1&color=fff');
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryPink.withOpacity(0.15),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarImage, 
              onBackgroundImageError: (_, __) {
                // Fallback jika image corrupt / 404
                setState(() {
                  _fotoProfil = ""; // Set kosong, build ulang pakai ui-avatars
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    Color? iconColor,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.grey.shade700).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.grey.shade700,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: textColor ?? textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null 
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ) 
          : null,
      trailing: showTrailing 
          ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20) 
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }
}