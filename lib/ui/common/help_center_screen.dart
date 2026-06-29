import 'package:flutter/material.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String _menuText = '''Silakan ketik angka untuk memilih pertanyaan:
1. Bagaimana cara meminjam sepeda?
2. Berapa biaya sewa sepeda?
3. Bagaimana cara mengembalikan sepeda?
4. Sepeda yang saya pinjam bermasalah.
5. Bagaimana jika stasiun tujuan penuh?''';

  final Map<String, String> _faqAnswers = {
    '1': 'Untuk meminjam sepeda, pergi ke menu "Rent" (tengah bawah), lalu arahkan kamera ke QR Code yang ada di stasiun atau sepeda. Jika berhasil, kunci otomatis terbuka dan sesi peminjaman dimulai.',
    '2': 'Saat ini layanan peminjaman sepeda Velocy sepenuhnya GRATIS (Rp 0) khusus untuk mahasiswa dan civitas akademika di area kampus.',
    '3': 'Bawa sepeda ke stasiun terdekat. Masukkan sepeda ke dock yang kosong. Sesi peminjaman akan otomatis berakhir setelah dock mendeteksi dan mengunci sepeda.',
    '4': 'Mohon maaf atas ketidaknyamanan ini. Harap parkirkan sepeda dengan aman di pinggir jalan dan laporkan stasiun/sepeda bermasalah ke petugas melalui nomor darurat kami.',
    '5': 'Jika stasiun tujuan penuh, Anda harus mencari stasiun lain yang memiliki dock kosong untuk mengembalikan sepeda. Gunakan peta di menu Home untuk melihat stasiun terdekat.',
  };

  @override
  void initState() {
    super.initState();
    // Pesan pertama dari bot
    _messages.add(ChatMessage(
      text: 'Halo! Selamat datang di Pusat Bantuan Velocy. Ada yang bisa saya bantu?\n\n$_menuText',
      isUser: false,
    ));
  }

  void _handleSubmitted(String text) {
    text = text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();

    // Bot berpikir sejenak...
    Future.delayed(const Duration(milliseconds: 500), () {
      _botReply(text);
    });
  }

  void _botReply(String userText) {
    String reply;
    if (_faqAnswers.containsKey(userText)) {
      reply = _faqAnswers[userText]!;
      // Setelah menjawab, kasih menu lagi agar user tidak bingung
      reply += '\n\nAda pertanyaan lain?\n$_menuText';
    } else {
      reply = 'Maaf, saya tidak mengerti pilihan "$userText".\n\n$_menuText';
    }

    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // tambah offset
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textMain(context)),
        title: Text(
          AppLocalizations.isIndo ? 'Pusat Bantuan' : 'Help Center',
          style: TextStyle(
            color: AppTheme.textMain(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.primary(context),
                child: const Icon(Icons.support_agent, color: Colors.white),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary(context) : AppTheme.surface(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
                boxShadow: [
                  if (!AppTheme.isDark(context) && !isUser)
                    const BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textMain(context),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 12.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.surfaceVariant(context),
                child: Icon(Icons.person, color: AppTheme.primary(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.number,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: 'Ketik angka pertanyaan...',
                  hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.bg(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: TextStyle(color: AppTheme.textMain(context)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary(context),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
