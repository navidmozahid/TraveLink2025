import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_agency_service.dart';
import 'edit_business_profile_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;
  final bool isOwner;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
    this.isOwner = false,
  });

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseAgencyService _agencyService = SupabaseAgencyService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;

  Map<String, dynamic>? _business;
  List<Map<String, dynamic>> _posts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await Future.wait([
      _loadBusinessProfile(),
      _loadBusinessPosts(),
    ]);
  }

  Future<void> _loadBusinessProfile() async {
    final data =
    await _agencyService.getBusinessProfileById(widget.businessId);
    if (!mounted) return;
    setState(() {
      _business = data;
      _loading = false;
    });
  }

  Future<void> _loadBusinessPosts() async {
    final posts = await _supabase
        .from('posts')
        .select('id, created_at')
        .eq('user_id', widget.businessId)
        .order('created_at', ascending: false);

    if (posts.isEmpty) {
      setState(() => _posts = []);
      return;
    }

    final postIds = posts.map((p) => p['id']).toList();

    final media = await _supabase
        .from('post_media')
        .select()
        .inFilter('post_id', postIds);

    final Map<String, String> previewMap = {};
    for (final m in media) {
      previewMap.putIfAbsent(m['post_id'], () => m['media_url']);
    }

    setState(() {
      _posts = posts
          .map<Map<String, dynamic>>((p) => {
        ...p,
        'preview_url': previewMap[p['id']],
      })
          .toList();
    });
  }

  // ---------------- LOGO UPLOAD ----------------
  Future<void> _pickAndUploadLogo() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploading = true);
    await _agencyService.uploadBusinessLogo(File(file.path));
    await _loadBusinessProfile();
    if (mounted) setState(() => _uploading = false);
  }

  // ---------------- FOLLOW COUNTS ----------------
  Stream<int> _followersCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) =>
    rows.where((r) => r['following_id'] == widget.businessId).length);
  }

  Stream<int> _followingCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) =>
    rows.where((r) => r['follower_id'] == widget.businessId).length);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_business == null) {
      return const Center(child: Text("Business not found"));
    }

    final name = _business!['agency_name'] ?? '';
    final type = _business!['agency_type'] ?? '';
    final logo = _business!['logo_url'];
    final phone = _business!['phone'];
    final description = _business!['description'] ?? '';
    final status = _business!['status'] ?? 'pending';

    final location = [
      _business!['city'],
      _business!['country'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final documents =
        (_business!['documents'] as List?)?.cast<String>() ?? [];

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.isOwner ? _pickAndUploadLogo : null,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage:
                      logo != null && logo.isNotEmpty
                          ? NetworkImage(logo)
                          : null,
                      child: logo == null
                          ? const Icon(Icons.business, size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(type,
                            style: const TextStyle(color: Colors.grey)),
                        if (location.isNotEmpty)
                          Text(location,
                              style:
                              const TextStyle(color: Colors.grey)),
                        if (phone != null && phone.toString().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(phone.toString(),
                                  style: const TextStyle(
                                      color: Colors.grey)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem("Posts", _posts.length.toString()),
                StreamBuilder<int>(
                  stream: _followersCount(),
                  builder: (_, s) =>
                      _StatItem("Followers", '${s.data ?? 0}'),
                ),
                StreamBuilder<int>(
                  stream: _followingCount(),
                  builder: (_, s) =>
                      _StatItem("Following", '${s.data ?? 0}'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(text: "About"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(2),
                    itemCount: _posts.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (_, i) {
                      final url = _posts[i]['preview_url'];
                      return url == null
                          ? Container(color: Colors.grey[300])
                          : Image.network(url, fit: BoxFit.cover);
                    },
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aboutItem("Description",
                            description.isNotEmpty
                                ? description
                                : 'No description'),
                        _aboutItem("Phone", phone),
                        _aboutItem("Email", _business!['email']),
                        _aboutItem("Address", _business!['address']),
                        _aboutItem(
                            "License ID", _business!['license_id']),
                        _aboutItem("Status", status),
                        if (documents.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text("Documents",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          for (final d in documents)
                            InkWell(
                              onTap: () async {
                                final url = _supabase.storage
                                    .from('business-docs')
                                    .getPublicUrl(d);
                                await launchUrl(Uri.parse(url),
                                    mode: LaunchMode.externalApplication);
                              },
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: Text(d,
                                    style: const TextStyle(
                                        color: Colors.blue)),
                              ),
                            ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ✏️ EDIT BUTTON (OWNER ONLY)
        if (widget.isOwner)
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton.small(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditBusinessProfileScreen(business: _business!),
                  ),
                );
                _reloadAll();
              },
              child: const Icon(Icons.edit),
            ),
          ),

        if (_uploading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child:
              const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _aboutItem(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value.toString(),
              style:
              const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  const _StatItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
