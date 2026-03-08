import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'other_profile_screen.dart';
import 'business_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _suggestedTravelers = [];
  List<Map<String, dynamic>> _suggestedBusinesses = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadSuggestions();
  }

  // ---------------- LOAD RECENT SEARCHES ----------------
  Future<void> _loadRecent() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase
        .from('recent_searches')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    setState(() {
      _recent = List<Map<String, dynamic>>.from(data);
    });
  }

  // ---------------- LOAD SUGGESTED USERS ----------------
  Future<void> _loadSuggestions() async {
    final travelers = await _supabase
        .from('profiles')
        .select()
        .eq('user_type', 'traveler')
        .limit(5);

    final businesses = await _supabase
        .from('business_accounts')
        .select()
        .limit(5);

    setState(() {
      _suggestedTravelers = List<Map<String, dynamic>>.from(travelers);
      _suggestedBusinesses = List<Map<String, dynamic>>.from(businesses);
    });
  }

  // ---------------- SAVE RECENT SEARCH ----------------
  Future<void> _saveRecent(String id, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('recent_searches').insert({
      'user_id': user.id,
      'searched_id': id,
      'searched_type': type,
    });

    _loadRecent();
  }

  // ---------------- DELETE SINGLE RECENT ----------------
  Future<void> _deleteRecent(String id) async {
    await _supabase.from('recent_searches').delete().eq('id', id);
    _loadRecent();
  }

  // ---------------- CLEAR ALL RECENT ----------------
  Future<void> _clearRecent() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('recent_searches')
        .delete()
        .eq('user_id', user.id);

    _loadRecent();
  }

  // ---------------- SEARCH ----------------
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final travelers = await _supabase
          .from('profiles')
          .select()
          .or('name.ilike.%$query%,username.ilike.%$query%')
          .eq('user_type', 'traveler');

      final businesses = await _supabase
          .from('business_accounts')
          .select()
          .ilike('agency_name', '%$query%');

      final merged = [
        ...travelers.map((e) => {...e, "type": "traveler"}),
        ...businesses.map((e) => {...e, "type": "business"}),
      ];

      setState(() {
        _results = List<Map<String, dynamic>>.from(merged);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ---------------- USER TILE ----------------
  Widget _buildUserTile(Map<String, dynamic> user) {
    final bool isBusiness = user["type"] == "business";

    final String name =
    isBusiness ? user["agency_name"] ?? "" : user["name"] ?? "";

    final String? avatar =
    isBusiness ? user["logo_url"] : user["avatar_url"];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
        avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(name),
      subtitle: Text(isBusiness ? "Business" : "Traveler"),
      onTap: () async {
        await _saveRecent(user["id"], user["type"]);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isBusiness
                ? BusinessProfileScreen(
              businessId: user["id"],
            )
                : OtherProfileScreen(
              userId: user["id"],
            ),
          ),
        );
      },
    );
  }

  // ---------------- RECENT TILE ----------------
  Widget _buildRecentTile(Map<String, dynamic> item) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: const Text("Recent search"),
      subtitle: Text(item["searched_type"]),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          _deleteRecent(item["id"]);
        },
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search travelers, businesses...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _search,
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())

          // ---------------- SEARCH RESULTS ----------------
              : _searchController.text.isNotEmpty
              ? ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) =>
                _buildUserTile(_results[i]),
          )

          // ---------------- DEFAULT VIEW ----------------
              : ListView(
            children: [
              if (_recent.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Searches",
                        style: TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _clearRecent,
                        child: const Text("Clear All"),
                      ),
                    ],
                  ),
                ),

              ..._recent.map(_buildRecentTile),

              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Suggested Travelers",
                  style:
                  TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              ..._suggestedTravelers
                  .map((e) => _buildUserTile(
                  {...e, "type": "traveler"})),

              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Suggested Businesses",
                  style:
                  TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              ..._suggestedBusinesses
                  .map((e) => _buildUserTile(
                  {...e, "type": "business"})),
            ],
          ),
        ),
      ],
    );
  }
}