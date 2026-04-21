import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryPink = const Color(0xFFF48FB1); // Disamakan dengan home_screen.dart
  final Color textDark = Colors.black87;

  // --- STATE DATA PENGATURAN DUMMY ---
  String _userName = 'Rina Terapis';
  String _userPhone = '+62 812 3456 7890';
  bool _is2FAEnabled = false;

  // --- HELPER UNTUK MENAMPILKAN PESAN (SNACKBAR) ---
  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- FITUR 1: EDIT PROFIL ---
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userName = nameController.text;
                  _userPhone = phoneController.text;
                });
                Navigator.pop(context);
                _showInfoMessage('Profil berhasil diperbarui!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- FITUR 2: UBAH KATA SANDI ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email & Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true, 
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true, 
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true, 
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPink)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showInfoMessage('Kata sandi berhasil diubah!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- FITUR 3: VERIFIKASI DUA LANGKAH (2FA) ---
  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Verifikasi Dua Langkah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tambahkan lapisan keamanan ekstra ke akun Anda. Jika diaktifkan, Anda akan memerlukan kode OTP khusus saat melakukan login.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      title: const Text('Aktifkan 2FA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _is2FAEnabled,
                      activeColor: primaryPink,
                      onChanged: (val) {
                        setDialogState(() => _is2FAEnabled = val);
                        setState(() => _is2FAEnabled = val); // Update ke UI Induk
                        if (val) {
                          _showInfoMessage('Verifikasi Dua Langkah diaktifkan');
                        } else {
                          _showInfoMessage('Verifikasi Dua Langkah dimatikan');
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar gambar background terlihat
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDark),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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
        body: SafeArea(
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
                      subtitle: 'Ubah nama & nomor telepon',
                      onTap: _showEditProfileDialog,
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.lock_outline, 
                      title: 'Email & Kata Sandi', 
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
              color: primaryPink.withOpacity(0.15), // Efek transparan dari primaryPink
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'), 
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName, // Menggunakan variabel dinamis
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_userPhone • TRP00128', // Menggunakan variabel dinamis
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
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