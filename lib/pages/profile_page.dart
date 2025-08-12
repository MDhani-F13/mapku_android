import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/search_history_entry.dart';
import '../services/search_history_service.dart';
import '../services/user_service.dart';
import '../connection/auth_service.dart';
import '../widgets/search_history_list.dart';

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
    if (userData != null) {
      setState(() {
        username = userData['username'];
        email = userData['email'];
        profileImageUrl = userData['profile_picture'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
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
      appBar: AppBar(title: const Text("Profil Saya")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto profil dan data pengguna
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username ?? '-',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(email ?? '-', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Filter radio button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Riwayat Pencarian",
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: const Text("Single"),
                          value: 'single',
                          groupValue: selectedFilter,
                          onChanged: (val) {
                            setState(() => selectedFilter = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text("From-To"),
                          value: 'from_to',
                          groupValue: selectedFilter,
                          onChanged: (val) {
                            setState(() => selectedFilter = val!);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Daftar riwayat
                  SearchHistoryList(entries: filteredEntries),

                  const SizedBox(height: 24),
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
