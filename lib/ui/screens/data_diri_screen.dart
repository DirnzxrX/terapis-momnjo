import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Mengecek apakah jalan di Web
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapist_momnjo/data/api_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({Key? key}) : super(key: key);

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  final Color textDarkBrown = const Color(0xFF4A332B);
  final Color primaryPeach = const Color(0xFFECA898);

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Variabel Data Statis (Tidak bisa diubah dari HP)
  String _noPegawai = "-";
  String _gerai = "-";
  String _fotoProfil = "";
  String _namaAsliUntukAvatar = "Mom N Jo"; 

  // Variabel Data Dinamis (Bisa diubah - Tanggal Lahir)
  String _tanggalLahirTampil = "-"; 
  String _tanggalLahirRaw = "";     

  // Controllers untuk Data Dinamis (Bisa diubah - Teks)
  final TextEditingController _nameCtrl = TextEditingController(); 
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  
  // Gunakan XFile agar support di Web maupun Android/iOS
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDataDiriAPI();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); 
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // --- 1. MENGAMBIL DATA DARI API ---
  Future<void> _loadDataDiriAPI() async {
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final response = await api.getDataDiri();

      if (response['status'] == 'success' || response['success'] == true) {
        final data = response['data'] ?? {};
        if (mounted) {
          _populateData(data, fromApi: true);
        }
      } else {
        _loadFallbackData();
      }
    } catch (e) {
      _loadFallbackData();
    }
  }

  // --- 2. FUNGSI CADANGAN ---
  Future<void> _loadFallbackData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        Map<String, dynamic> localData = {
          'nama_lengkap': prefs.getString('fullname') ?? prefs.getString('nama_lengkap'),
          'no_telepon': prefs.getString('no_telepon') ?? prefs.getString('phone'),
          'email': prefs.getString('email'),
          'tanggal_lahir': prefs.getString('tanggal_lahir'),
          'alamat': prefs.getString('alamat'),
          'no_pegawai': prefs.getString('username') ?? prefs.getString('id_terapis'),
          'gerai': prefs.getString('gerai') ?? prefs.getString('branch'),
          'foto_profil': prefs.getString('foto_profil'),
        };
        _populateData(localData, fromApi: false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI UTAMA MEMASUKKAN DATA KE UI ---
  void _populateData(Map<String, dynamic> data, {required bool fromApi}) {
    setState(() {
      // Setup Tanggal Lahir
      String tglLahirServer = _checkEmpty(data['tanggal_lahir']);
      _tanggalLahirRaw = tglLahirServer != "-" ? tglLahirServer : ""; 
      _tanggalLahirTampil = _formatDate(tglLahirServer);
      
      _noPegawai = _checkEmpty(data['no_pegawai']);
      _gerai = _checkEmpty(data['gerai']);

      // Isi nilai controller (Data Dinamis)
      String namaRaw = _checkEmpty(data['nama_lengkap']);
      _nameCtrl.text = namaRaw;
      _namaAsliUntukAvatar = namaRaw != "-" ? namaRaw : "Mom N Jo";
      
      _emailCtrl.text = _checkEmpty(data['email']);
      _phoneCtrl.text = _checkEmpty(data['no_telepon']);
      _addressCtrl.text = _checkEmpty(data['alamat']);
      
      // 🔥 SABUK PENGAMAN URL FOTO (Anti Mixed-Content & Missing Base URL)
      String foto = data['foto_profil']?.toString() ?? data['foto']?.toString() ?? data['image']?.toString() ?? "";
      String compiledFotoUrl = "";
      
      if (foto.isNotEmpty && foto != "null" && foto != "-") {
        if (foto.startsWith('http')) {
          // Tangkal Mixed Content: paksa http jadi https
          compiledFotoUrl = foto.replaceFirst('http://', 'https://'); 
        } else {
          // Tangkal nama file mentah: gabungkan dengan Base URL
          compiledFotoUrl = "${ApiService.baseImageUrl}/$foto"; 
        }
        // Bypass cache browser agar jika foto diupdate, perubahannya langsung terlihat (tidak nyangkut)
        compiledFotoUrl = "$compiledFotoUrl?v=${DateTime.now().millisecondsSinceEpoch}";
      }

      _fotoProfil = compiledFotoUrl.isNotEmpty 
          ? compiledFotoUrl 
          : "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_namaAsliUntukAvatar)}&background=ECA898&color=fff";
      
      _isLoading = false;
    });
  }

  // --- 3. FUNGSI PILIH GAMBAR DARI GALERI ---
  Future<void> _pickImage() async {
    if (!_isEditing) return; 
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka galeri.')),
      );
    }
  }

  // --- FUNGSI PILIH TANGGAL LAHIR (DATE PICKER) ---
  Future<void> _pickDate() async {
    if (!_isEditing) return; 

    DateTime initialDate = DateTime.now();
    if (_tanggalLahirRaw.isNotEmpty && _tanggalLahirRaw != "-") {
      try {
        initialDate = DateTime.parse(_tanggalLahirRaw);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950), 
      lastDate: DateTime.now(),  
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: textDarkBrown, 
              onPrimary: Colors.white,
              onSurface: textDarkBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalLahirRaw = DateFormat('yyyy-MM-dd').format(pickedDate);
        _tanggalLahirTampil = DateFormat('dd MMMM yyyy').format(pickedDate);
      });
    }
  }

  // --- 4. FUNGSI SIMPAN PERUBAHAN KE API ---
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final api = ApiService();
      final response = await api.updateDataDiri(
        namaLengkap: _nameCtrl.text.trim(), 
        tanggalLahir: _tanggalLahirRaw, 
        email: _emailCtrl.text.trim(),
        noTelepon: _phoneCtrl.text.trim(),
        alamat: _addressCtrl.text.trim(),
        imagePath: _selectedImage?.path, // Path bisa dibaca oleh Web maupun Mobile di ApiService
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil diperbarui!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
          
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullname', _nameCtrl.text.trim());
          await prefs.setString('nama_lengkap', _nameCtrl.text.trim());
          await prefs.setString('tanggal_lahir', _tanggalLahirRaw);
          
          setState(() {
            _isEditing = false;
            _tanggalLahirTampil = DateFormat('dd MMMM yyyy').format(DateTime.parse(_tanggalLahirRaw));
            _selectedImage = null; 
          });
          
          // Refresh data untuk memastikan data yang ditampilkan adalah data terbaru dari server
          _loadDataDiriAPI(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal menyimpan data'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- HELPER FORMATTING ---
  String _checkEmpty(dynamic value) {
    if (value == null) return "-";
    String valStr = value.toString().trim();
    if (valStr.isEmpty || valStr == "null") return "-";
    return valStr;
  }

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
        backgroundColor: Colors.transparent,
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
          actions: [
            if (!_isLoading)
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: _isEditing ? Colors.red : textDarkBrown,
                ),
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                    // Reset foto yang dipilih jika batal edit
                    if (!_isEditing) _selectedImage = null; 
                  });
                },
              )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFECA898))) 
            : RefreshIndicator(
                onRefresh: _loadDataDiriAPI,
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
                          _buildEditableItem(Icons.person_outline, 'Nama Lengkap', _nameCtrl, TextInputType.name),
                          _buildDatePickerItem(Icons.calendar_today_outlined, 'Tanggal Lahir', _tanggalLahirTampil),
                          _buildEditableItem(Icons.phone_outlined, 'Nomor Telepon', _phoneCtrl, TextInputType.phone),
                          _buildEditableItem(Icons.email_outlined, 'Email', _emailCtrl, TextInputType.emailAddress),
                          _buildEditableItem(Icons.location_on_outlined, 'Alamat', _addressCtrl, TextInputType.multiline),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Kartu Informasi Pekerjaan
                      _buildInfoSection(
                        title: 'Informasi Pekerjaan',
                        items: [
                          _buildStaticItem(Icons.badge_outlined, 'No.Pegawai', _noPegawai),
                          _buildStaticItem(Icons.map_outlined, 'Gerai / Area', _gerai),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _isEditing ? _buildSaveButton() : null,
      ),
    );
  }

  // --- KUMPULAN WIDGET HELPER ---
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
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
                // 🔥 Penanganan Error Gambar jika link rusak / 404 dari Server
                onBackgroundImageError: (exception, stackTrace) {
                  if (mounted && _fotoProfil.isNotEmpty && !_fotoProfil.contains('ui-avatars')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _fotoProfil = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_namaAsliUntukAvatar)}&background=ECA898&color=fff";
                      });
                    });
                  }
                },
                // Logika Tampilan: Tampilkan gambar lokal (jika ada yg dipilih) ATAU gambar dari server
                backgroundImage: _selectedImage != null 
                    ? (kIsWeb 
                        ? NetworkImage(_selectedImage!.path) 
                        : FileImage(File(_selectedImage!.path))) as ImageProvider
                    : NetworkImage(_fotoProfil), 
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
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
            ),
        ],
      ),
    );
  }

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

  Widget _buildDatePickerItem(IconData icon, String label, String value) {
    return InkWell(
      onTap: _isEditing ? _pickDate : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _isEditing ? primaryPeach : Colors.grey.shade400),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12, 
                      color: _isEditing ? primaryPeach : Colors.grey.shade500, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkBrown),
                      ),
                      if (_isEditing)
                        Icon(Icons.edit_calendar, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 4),
                    Divider(height: 1, color: primaryPeach, thickness: 2), 
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticItem(IconData icon, String label, String value) {
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

  Widget _buildEditableItem(IconData icon, String label, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _isEditing ? primaryPeach : Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12, 
                    color: _isEditing ? primaryPeach : Colors.grey.shade500, 
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 4),
                if (!_isEditing)
                  Text(
                    controller.text.isEmpty ? "-" : controller.text,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkBrown),
                  )
                else
                  TextFormField(
                    controller: controller,
                    keyboardType: type,
                    maxLines: type == TextInputType.multiline ? null : 1,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkBrown),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPeach, width: 2)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: textDarkBrown,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}