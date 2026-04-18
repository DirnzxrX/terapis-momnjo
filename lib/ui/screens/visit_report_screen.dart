import 'package:flutter/material.dart';

class VisitReportScreen extends StatelessWidget {
  const VisitReportScreen({Key? key}) : super(key: key);

  final Color primaryPink = const Color(0xFFF48FB1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Kunjungan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildReportItem(
                  icon: Icons.assignment_ind_outlined,
                  iconColor: Colors.orange,
                  title: 'Kondisi Awal',
                  statusText: '2/2',
                ),
                _buildDivider(),
                _buildReportItem(
                  icon: Icons.spa_outlined,
                  iconColor: Colors.pink,
                  title: 'Tindakan yang Dilakukan',
                  statusText: '3/3',
                ),
                _buildDivider(),
                _buildReportItem(
                  icon: Icons.fact_check_outlined,
                  iconColor: Colors.green,
                  title: 'Hasil Treatment',
                  statusText: '2/2',
                ),
                _buildDivider(),
                _buildReportItem(
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  iconColor: Colors.blue,
                  title: 'Respon Customer',
                  statusText: '1/1',
                ),
                _buildDivider(),
                // PERHATIAN: Bagian "Rekomendasi" telah Dihapus dari sini sesuai permintaan Anda.
                _buildReportItem(
                  icon: Icons.note_alt_outlined,
                  iconColor: Colors.blueGrey,
                  title: 'Catatan Internal',
                  statusText: 'Opsional',
                  isOptional: true,
                ),
                _buildDivider(),
                _buildReportItem(
                  icon: Icons.camera_alt_outlined,
                  iconColor: Colors.teal,
                  title: 'Foto Pendukung',
                  statusText: '2 foto',
                ),
                _buildDivider(),
                _buildReportItem(
                  icon: Icons.draw_outlined,
                  iconColor: Colors.redAccent,
                  title: 'Tanda Tangan',
                  statusText: 'Belum',
                  isPending: true,
                ),
                _buildDivider(),
              ],
            ),
          ),
          
          // Bottom Action Buttons
          _buildBottomActions(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildReportItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String statusText,
    bool isOptional = false,
    bool isPending = false,
  }) {
    // Menentukan warna teks status di sebelah kanan
    Color statusColor = Colors.black87;
    if (isOptional) {
      statusColor = Colors.grey.shade500;
    } else if (isPending) {
      statusColor = Colors.red;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isOptional ? FontWeight.normal : FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: () {
        // Aksi ketika item di-tap untuk mengisi form bagian tersebut
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Simpan Draft
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Simpan Draft',
                style: TextStyle(color: primaryPink, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Tombol Lanjut & Submit
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Lanjut & Submit',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}