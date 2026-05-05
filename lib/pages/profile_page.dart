import 'package:flutter/material.dart';
import '../models/search_history_entry.dart';
import '../services/search_history_service.dart';
import '../services/user_service.dart';
import '../connection/auth_service.dart';
import '../widgets/search_history_list.dart';
import '../widgets/logout_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  String? profileImageUrl;
  bool isLoading = true;

  String selectedFilter = 'single';
  List<SearchHistoryEntry> allEntries = [];

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadSearchHistory();
  }

  void fetchProfile() async {
    final token = await AuthService().getToken();
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userData = await UserService().getProfile(token);
    setState(() {
      username = userData?['username'];
      email = userData?['email'];
      profileImageUrl = userData?['profile_picture'];
      isLoading = false;
    });
  }

  void loadSearchHistory() async {
    final service = SearchHistoryService();
    final entries = await service.getHistory();
    setState(() => allEntries = entries);
  }

  void _logout() {
    AuthService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  List<SearchHistoryEntry> get filteredEntries =>
      allEntries.where((e) => e.type == selectedFilter).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ================= PROFILE CARD =================
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                      ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage:
                              profileImageUrl?.isNotEmpty == true
                                  ? NetworkImage(profileImageUrl!)
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          username ?? '-',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email ?? '-',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= SEARCH HISTORY =================
                Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        ),
                    ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Riwayat Pencarian",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 28),

                        // Filter chips (modern replacement for RadioListTile)
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("Single"),
                              selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                              selected: selectedFilter == 'single',
                              onSelected: (_) {
                                setState(() => selectedFilter = 'single');
                              },
                            ),
                            ChoiceChip(
                              label: const Text("From–To"),
                              selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                              selected: selectedFilter == 'from_to',
                              onSelected: (_) {
                                setState(() => selectedFilter = 'from_to');
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SearchHistoryList(entries: filteredEntries),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ================= LOGOUT =================
                LogoutButton(onPressed: _logout),
              ],
            ),
    );
  }
}
