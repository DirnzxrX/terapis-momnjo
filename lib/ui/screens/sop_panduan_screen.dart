import 'package:flutter/material.dart';

class SopPanduanScreen extends StatelessWidget {
  const SopPanduanScreen({Key? key}) : super(key: key);

  final Color textDark = Colors.black87;
  final Color primaryPink = const Color(0xFFE8647C);

  // Data statis (dummy) untuk daftar SOP
  final List<Map<String, String>> _sopList = const [
    {
      'title': 'SOP Home Visit (Kunjungan Rumah)',
      'size': '1.2 MB',
      'date': '12 Jan 2026',
    },
    {
      'title': 'Standar Pelayanan Baby Spa',
      'size': '2.5 MB',
      'date': '05 Feb 2026',
    },
    {
      'title': 'Panduan Prenatal Massage (Ibu Hamil)',
      'size': '1.8 MB',
      'date': '20 Mar 2026',
    },
    {
      'title': 'Standar Penampilan & Etika Terapis',
      'size': '800 KB',
      'date': '15 Apr 2026',
    },
    {
      'title': 'Panduan Keselamatan & Kesehatan Kerja (K3)',
      'size': '3.1 MB',
      'date': '02 Apr 2026',
    },
  ];

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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'SOP & Panduan',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _sopList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sop = _sopList[index];
            return _buildSopCard(context, sop);
          },
        ),
      ),
    );
  }

  Widget _buildSopCard(BuildContext context, Map<String, String> sop) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Menampilkan feedback saat dokumen ditekan
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Membuka dokumen: ${sop['title']}...'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ikon Dokumen
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: primaryPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Detail Dokumen
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sop['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'PDF • ${sop['size']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            sop['date']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tombol Unduh / Lihat
                const SizedBox(width: 8),
                Icon(
                  Icons.download_for_offline,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}