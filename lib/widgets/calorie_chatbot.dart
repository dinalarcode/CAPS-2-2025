import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';

// Color constants - Warna hijau segar seperti filter popup
const Color kGreen = Colors.green;
const Color kGreenLight = Color(0xFF7BB662);
const Color kWhite = Colors.white;
const Color kGreyText = Color(0xFF888888);

/// AI Chatbot untuk estimasi kalori makanan
class CalorieChatbot extends StatefulWidget {
  final VoidCallback? onFoodLogSaved; // BARU: Callback setelah save
  
  const CalorieChatbot({super.key, this.onFoodLogSaved});

  @override
  State<CalorieChatbot> createState() => _CalorieChatbotState();
}

class _CalorieChatbotState extends State<CalorieChatbot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
    _loadChatHistory();
  }
  
  // Load user photo dari Firestore users collection
  Future<void> _loadUserPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        if (data != null && data.containsKey('profile')) {
          final profile = data['profile'] as Map<String, dynamic>?;
          if (profile != null) {
            // Prioritas baru: ambil profilePicture (asset path atau URL)
            String? pic;
            if (profile.containsKey('profilePicture')) {
              final raw = profile['profilePicture'];
              if (raw is String && raw.isNotEmpty) {
                pic = raw;
                debugPrint('📸 Found profile.profilePicture: $pic');
              }
            }
            // Masih dukung photoUrl jika ada (misal URL dari upload)
            if (pic == null && profile.containsKey('photoUrl')) {
              final raw = profile['photoUrl'];
              if (raw is String && raw.isNotEmpty) {
                pic = raw;
                debugPrint('📸 Found profile.photoUrl: $pic');
              }
            }
            if (mounted) {
              setState(() {
                _userPhotoUrl = pic;
              });
            }
            if (_userPhotoUrl == null) {
              debugPrint('⚠️ Tidak menemukan profilePicture/photoUrl di profile map');
            }
          } else {
            debugPrint('⚠️ Profile map null');
          }
        } else {
          debugPrint('⚠️ Profile data not found');
        }
        // Fallback: cek top-level profilePicture dulu, lalu photoUrl
        if (_userPhotoUrl == null) {
          final topProfilePic = data?['profilePicture'];
          if (topProfilePic is String && topProfilePic.isNotEmpty) {
            setState(() => _userPhotoUrl = topProfilePic);
            debugPrint('📸 Fallback top-level profilePicture loaded: $topProfilePic');
          }
        }
        if (_userPhotoUrl == null) {
          final topPhoto = data?['photoUrl'];
          if (topPhoto is String && topPhoto.isNotEmpty) {
            setState(() => _userPhotoUrl = topPhoto);
            debugPrint('📸 Fallback top-level photoUrl loaded: $topPhoto');
          }
        }
      }
      // Fallback terakhir: gunakan FirebaseAuth user.photoURL
      if (_userPhotoUrl == null && user.photoURL != null && user.photoURL!.isNotEmpty) {
        setState(() => _userPhotoUrl = user.photoURL);
        debugPrint('📸 Fallback auth photoURL loaded');
      }
    } catch (e) {
      debugPrint('❌ Error loading user photo: $e');
    }
  }
  
  // Load riwayat chat dari Firestore
  Future<void> _loadChatHistory() async {
    // Tampilkan welcome message dulu untuk UX yang lebih baik
    _addWelcomeMessage();
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final chatDoc = await FirebaseFirestore.instance
          .collection('ai_chat_history')
          .doc(uid)
          .collection('chats')
          .doc(today)
          .get();
      
      if (chatDoc.exists && mounted) {
        final data = chatDoc.data()!;
        final messages = (data['messages'] as List<dynamic>?)?.map((m) {
          return ChatMessage(
            text: m['text'] ?? '',
            isUser: m['isUser'] ?? false,
            timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            calorieData: m['calorieData'] as Map<String, dynamic>?,
          );
        }).toList() ?? [];
        
        // Jika ada history, replace welcome message dengan history
        if (messages.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
          });
          
          debugPrint('✅ Loaded ${messages.length} chat messages from history');
          
          // PENTING: Scroll ke bawah setelah load history
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
      // Keep welcome message if error
    }
  }
  
  void _addWelcomeMessage() {
    if (_messages.isEmpty && mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Halo! 👋\n\nSaya asisten AI untuk menghitung kalori makanan. Ceritakan makanan apa yang kamu makan di luar, dan saya akan bantu estimasi kalorinya!\n\nContoh:\n"Aku makan nasi goreng + telur ceplok"\n"2 potong ayam goreng sama es teh manis"',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }
  
  // Simpan riwayat chat ke Firestore
  Future<void> _saveChatHistory() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final messagesData = _messages.map((m) => {
        'text': m.text,
        'isUser': m.isUser,
        'timestamp': Timestamp.fromDate(m.timestamp),
        'calorieData': m.calorieData,
      }).toList();
      
      await FirebaseFirestore.instance
          .collection('ai_chat_history')
          .doc(uid)
          .collection('chats')
          .doc(today)
          .set({
        'messages': messagesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('💾 Chat history saved');
    } catch (e) {
      debugPrint('❌ Error saving chat history: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Edit dan resend message
  Future<void> _editAndResendMessage(int messageIndex, String newText) async {
    if (newText.trim().isEmpty) return;
    
    // Remove messages dari index yang diedit sampai akhir (termasuk response AI)
    setState(() {
      _messages.removeRange(messageIndex, _messages.length);
    });
    
    // Resend dengan text baru
    _controller.text = newText;
    await _sendMessage();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get AI response
      final result = await GeminiService.estimateCalories(userMessage);
      // Pastikan originalInput tersedia untuk penyimpanan log
      result['originalInput'] = userMessage;

      // Build response message
      final responseText = _buildResponseText(result);
      
      // Check if it's valid food data (has calories > 0 AND has items)
      final totalCalories = result['totalCalories'] ?? 0;
      final items = result['items'] as List?;
      final hasValidData = totalCalories > 0 && items != null && items.isNotEmpty;
      
      debugPrint('🐞 Debug: totalCalories=$totalCalories, items=${items?.length ?? 0}, hasValidData=$hasValidData');

      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          calorieData: hasValidData ? result : null, // Only if truly valid
        ));
        _isLoading = false;
      });

      _scrollToBottom();
      
      // Simpan riwayat chat
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Maaf, terjadi kesalahan saat menghubungi server AI. Silakan coba lagi dalam beberapa saat. 🙏',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      // Simpan error message juga
      await _saveChatHistory();
    }
  }

  String _buildResponseText(Map<String, dynamic> result) {
    final isFood = result['isFood'] as bool? ?? true;
    final totalCalories = result['totalCalories'] ?? 0;
    final items = result['items'] as List<dynamic>? ?? [];
    final summary = result['summary'] as String? ?? result['response'] as String? ?? '';

    debugPrint('🐛 Parse result: isFood=$isFood, calories=$totalCalories, items count=${items.length}');

    // Handle non-food queries
    if (isFood == false) {
      return summary.isNotEmpty
          ? summary
          : 'Maaf, saya hanya bisa membantu menghitung kalori makanan dan minuman. Silakan ceritakan makanan atau minuman apa yang kamu konsumsi! 😊';
    }

    // Handle food queries without valid data (errors)
    if (totalCalories == 0 || items.isEmpty) {
      return summary.isNotEmpty
          ? summary
          : 'Maaf, saya tidak bisa mengenali makanan tersebut. Coba deskripsikan dengan lebih detail ya!';
    }

    final buffer = StringBuffer();
    
    // Opening dengan summary yang friendly
    if (summary.isNotEmpty) {
      buffer.writeln(summary);
      buffer.writeln();
    }
    
    buffer.writeln('📊 Rincian Kalori:');

    // Breakdown PER item makanan/minuman
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item['name'] ?? '';
      final portion = item['portion'] ?? '';
      final calories = item['calories'] ?? 0;
      final protein = item['protein'] ?? 0;
      final carbs = item['carbs'] ?? 0;
      final fats = item['fats'] ?? 0;
      buffer.writeln();
      buffer.writeln('${i + 1}. $name${portion.isNotEmpty ? " ($portion)" : ""}');
      buffer.writeln('   Kalori: $calories kkal');
      buffer.writeln('   Protein: ${protein}g | Karbo: ${carbs}g | Lemak: ${fats}g');
    }

    // Total semua item
    final totalProtein = result['totalProtein'] ?? 0;
    final totalCarbs = result['totalCarbs'] ?? 0;
    final totalFats = result['totalFats'] ?? 0;

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('TOTAL:');
    buffer.writeln('Kalori: $totalCalories kkal');
    buffer.writeln('Protein: ${totalProtein}g | Karbo: ${totalCarbs}g | Lemak: ${totalFats}g');

    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveToLog(Map<String, dynamic> calorieData) async {
    final totalCalories = calorieData['totalCalories'] ?? 0;
    final items = calorieData['items'] as List<dynamic>? ?? [];
    final originalInput = calorieData['originalInput'] as String? ?? '';

    if (totalCalories == 0) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Save to Firestore
    final success = await GeminiService.saveFoodLog(
      calories: totalCalories,
      foodDescription: originalInput,
      items: items.cast<Map<String, dynamic>>(),
      mealType: 'Lainnya',
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Berhasil disimpan! ($totalCalories kkal)'
              : '❌ Gagal menyimpan. Coba lagi.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    if (success) {
      setState(() {
        _messages.add(ChatMessage(
          text: '✅ Log makanan berhasil disimpan ke riwayat harianmu!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      
      // Simpan chat history
      await _saveChatHistory();
      
      // BARU: Trigger callback untuk refresh homepage
      widget.onFoodLogSaved?.call();
    }
  }
  
  // Helper untuk check sama hari atau tidak
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Helper untuk format tanggal
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Hari Ini';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kGreenLight, kGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: kWhite,
        title: const Text(
          'NutriAI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final showDateSeparator = index == 0 || 
                    !_isSameDay(_messages[index - 1].timestamp, message.timestamp);
                
                return Column(
                  children: [
                    // Date separator
                    if (showDateSeparator)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _formatDate(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    // Message bubble
                    _MessageBubble(
                      message: message,
                      userPhotoUrl: _userPhotoUrl,
                      onSaveLog: message.calorieData != null
                          ? () => _saveToLog(message.calorieData!)
                          : null,
                      onEdit: message.isUser
                          ? (newText) => _editAndResendMessage(index, newText)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menghitung...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ceritakan makanan yang kamu makan...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: kGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: kWhite, size: 20),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? calorieData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.calorieData,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? userPhotoUrl;
  final VoidCallback? onSaveLog;
  final Function(String)? onEdit;

  const _MessageBubble({
    required this.message,
    this.userPhotoUrl,
    this.onSaveLog,
    this.onEdit,
  });

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: kGreen),
              title: const Text('Salin Teks'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teks berhasil disalin'),
                    backgroundColor: kGreen,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit, color: kGreen),
                title: const Text('Edit dan Kirim Ulang'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pesan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Edit pesan Anda...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && onEdit != null) {
                onEdit!(newText);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: kWhite,
            ),
            child: const Text('Kirim Ulang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade50,
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Chat bubble dengan long press menu
                GestureDetector(
                  onLongPress: () => _showOptionsMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? kWhite : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: kGreyText,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Inline action icons (lebih mudah ditemukan daripada long press)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.copy, size: 18, color: kGreen),
                        tooltip: 'Salin',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teks disalin'),
                              duration: Duration(seconds: 1),
                              backgroundColor: kGreen,
                            ),
                          );
                        },
                      ),
                      if (onEdit != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.edit, size: 18, color: kGreen),
                          tooltip: 'Edit & Kirim Ulang',
                          onPressed: () => _showEditDialog(context),
                        ),
                      if (onSaveLog != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.save, size: 18, color: kGreen),
                          tooltip: 'Simpan ke Log',
                          onPressed: onSaveLog,
                        ),
                    ],
                  ),
                ),
                
                // Save button (hanya untuk AI response dengan valid data)
                if (onSaveLog != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onSaveLog,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Simpan ke Log Harian'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: kWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _ProfileAvatar(photo: userPhotoUrl),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photo;
  const _ProfileAvatar({this.photo});

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? provider;
    if (photo != null && photo!.isNotEmpty) {
      if (photo!.startsWith('assets/')) {
        provider = AssetImage(photo!);
      } else {
        provider = NetworkImage(photo!);
      }
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: kGreen,
      backgroundImage: provider,
      child: provider == null
          ? const Icon(
              Icons.person,
              size: 18,
              color: kWhite,
            )
          : null,
    );
  }
}
