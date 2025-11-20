import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';

// Color constants - Warna hijau segar seperti filter popup
const Color kGreen = Colors.green;
const Color kWhite = Colors.white;

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

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
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

      // Build response message
      final responseText = _buildResponseText(result);

      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          calorieData: result,
        ));
        _isLoading = false;
      });

      _scrollToBottom();
      
      // Simpan riwayat chat
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Maaf, terjadi kesalahan. Silakan coba lagi.',
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
    final totalCalories = result['totalCalories'] ?? 0;
    final items = result['items'] as List<dynamic>? ?? [];
    final summary = result['response'] as String? ?? '';

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
    
    buffer.writeln('📊 Rincian Kalori:\n');

    for (final item in items) {
      final name = item['name'] ?? '';
      final calories = item['calories'] ?? 0;
      final protein = item['protein'] ?? 0;
      final carbs = item['carbs'] ?? 0;
      final fats = item['fats'] ?? 0;

      buffer.writeln('• $name: $calories kkal');
      buffer.writeln('  Protein: ${protein}g | Karbo: ${carbs}g | Lemak: ${fats}g\n');
    }

    buffer.writeln('Total: $totalCalories kkal');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: kWhite,
        title: const Text(
          'AI Calorie Tracker',
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
                return _MessageBubble(
                  message: message,
                  onSaveLog: message.calorieData != null
                      ? () => _saveToLog(message.calorieData!)
                      : null,
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
              color: kWhite,
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
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
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
  final VoidCallback? onSaveLog;

  const _MessageBubble({
    required this.message,
    this.onSaveLog,
  });

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
              child: Icon(
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
                Container(
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
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(
                Icons.person,
                size: 18,
                color: kWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
