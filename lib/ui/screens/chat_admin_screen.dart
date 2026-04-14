import 'package:flutter/material.dart';

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({Key? key}) : super(key: key);

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Chat Admin',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Header Profil Admin
          _buildAdminHeader(),
          
          // 2. Area Percakapan (Chat Bubbles)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildReceiverMessage('Halo Rina, ada yang bisa dibantu?', '09:10'),
                const SizedBox(height: 16),
                _buildSenderMessage('Saya sudah sampai lokasi', '09:12'),
                const SizedBox(height: 16),
                _buildReceiverMessage('Terima kasih, selamat bekerja 🙏', '09:12'),
                const SizedBox(height: 16),
                _buildSenderMessage('Baik admin', '09:13'),
              ],
            ),
          ),
          
          // 3. Quick Replies (Balasan Cepat)
          _buildQuickReplies(),
          
          // 4. Input Area (Ketik Pesan)
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'), // Placeholder foto admin
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Mom n Jo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black87, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4), // Sudut tajam untuk penerima
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primaryPink.withOpacity(0.15), // Warna pink muda khas Mom n Jo
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4), // Sudut tajam untuk pengirim
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 14, color: Colors.blue), // Tanda baca biru (read receipt)
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final replies = ['Saya OTW', 'Sudah sampai', 'Customer tidak respon'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  reply,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: primaryPink,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}