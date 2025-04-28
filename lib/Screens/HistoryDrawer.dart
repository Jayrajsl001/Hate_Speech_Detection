import 'package:flutter/material.dart';
import 'package:hate_speech/DBhelper/mongodb.dart';
import 'package:hate_speech/Utils/themeProvider.dart';
import 'package:provider/provider.dart';

class HistoryDrawer extends StatefulWidget {
  final String userName;
  final Function(List<Map<String, dynamic>>, String, String) onSelectHistory;
  final Function() onLogout;

  const HistoryDrawer({
    Key? key,
    required this.userName,
    required this.onSelectHistory,
    required this.onLogout,
  }) : super(key: key);

  @override
  _HistoryDrawerState createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  /// 🔹 Fetch and refresh chat history
  void _refreshHistory() {
    setState(() {
      _historyFuture = mongodb.getChatHistory(widget.userName);
    });
  }

  /// 🔹 Rename chat
  void _renameChat(String chatId, String newChatName) async {
    bool success =
        await mongodb.renameChat(widget.userName, chatId, newChatName);

    if (success) {
      if (mounted) {
        _refreshHistory(); // ✅ Refresh UI
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to rename chat")),
        );
      }
    }
  }

  /// 🔹 Delete chat
  void _deleteChat(String chatId) async {
    bool success = await mongodb.deleteChat(widget.userName, chatId);

    if (success) {
      if (mounted) {
        _refreshHistory(); // ✅ Refresh UI
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete chat")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: isDarkMode ? Colors.black : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Chat History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSelectHistory([], "New Chat", "");
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text("New Chat"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final history = snapshot.data ?? [];

                /// 🔹 Extract unique chat names with IDs
                Map<String, String> chatNames = {};
                for (var chat in history) {
                  String chatId = chat['_id']?.toString() ?? "";
                  String chatName = chat['chatName'] ?? "Unnamed Chat";
                  if (!chatNames.containsKey(chatId)) {
                    chatNames[chatId] = chatName;
                  }
                }

                return ListView(
                  padding: EdgeInsets.zero,
                  children: chatNames.entries.map<Widget>((entry) {
                    return _buildHistoryTile(
                        entry.key, entry.value, isDarkMode);
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(String chatId, String chatName, bool isDarkMode) {
    return ListTile(
      title: Text(chatName),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'Rename') {
            _showRenameDialog(chatId, chatName);
          } else if (value == 'Delete') {
            _deleteChat(chatId);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'Rename', child: Text('Rename')),
          const PopupMenuItem(value: 'Delete', child: Text('Delete')),
        ],
      ),
      onTap: () async {
        List<Map<String, dynamic>> chatSession =
            await mongodb.getChatSession(chatId);
        widget.onSelectHistory(chatSession, chatName, chatId);
        Navigator.pop(context);
      },
    );
  }

  void _showRenameDialog(String chatId, String oldChatName) {
    TextEditingController _renameController =
        TextEditingController(text: oldChatName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Chat"),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_renameController.text.trim().isNotEmpty) {
                  _renameChat(chatId, _renameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }
}
