import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travelink/screens/dashboard/business_sales_screen.dart';
import 'package:travelink/screens/dashboard/create_event_screen.dart';
import 'package:travelink/screens/dashboard/my_events_screen.dart';
import 'package:travelink/screens/event_group/event_group_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState
    extends State<BusinessDashboardScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;

  int totalOffer = 0;
  int activeOffer = 0;
  int totalPurchased = 0;
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 🔹 Get business id
    final business = await supabase
        .from('business_accounts')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final businessId = business['id'];

    // 🔹 Get all events of this business
    final events = await supabase
        .from('events')
        .select()
        .eq('business_id', businessId);

    int _totalOffer = events.length;
    int _activeOffer = 0;
    int _totalPurchased = 0;
    double _totalRevenue = 0;

    for (final event in events) {
      final sold =
          (event['sold_count'] as num?)?.toInt() ?? 0;

      final total =
          (event['total_limit'] as num?)?.toInt() ?? 0;

      final price =
      (event['offer_price'] ?? event['regular_price'])
          .toDouble();

      if (sold < total) {
        _activeOffer++;
      }

      _totalPurchased += sold;
      _totalRevenue += sold * price;
    }

    setState(() {
      totalOffer = _totalOffer;
      activeOffer = _activeOffer;
      totalPurchased = _totalPurchased;
      totalRevenue = _totalRevenue;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final result =
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CreateEventScreen(),
                        ),
                      );

                      if (result == true) {
                        _loadStats();
                      }
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF0073e6),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            20),
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      "+ Create Event",
                      style: TextStyle(
                          fontWeight:
                          FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= STATS GRID =================
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: "Total Offer",
                      value:
                      totalOffer.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatCard(
                      title: "Active Offer",
                      value:
                      activeOffer.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title:
                      "Offer Purchased",
                      value:
                      totalPurchased
                          .toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatCard(
                      title:
                      "Current Revenue",
                      value:
                      "\$${totalRevenue.toStringAsFixed(2)}",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// ================= PENDING TASKS =================
              const Text(
                "Pending Tasks (Requires Action)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              PendingTaskTile(
                icon: Icons.card_travel,
                title: "My Events",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const MyEventsScreen(),
                    ),
                  );
                },
              ),
              PendingTaskTile(
                icon: Icons.group,
                title:
                "Client Message Group",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const EventGroupsScreen(),
                    ),
                  );
                },
              ),
              PendingTaskTile(
                icon:
                Icons.shopping_cart_outlined,
                title: "Sales Information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const BusinessSalesScreen(),
                    ),
                  );
                },
              ),
              PendingTaskTile(
                icon:
                Icons.settings_outlined,
                title:
                "Profile Update Needed",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= STAT CARD =================
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0073e6),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= TASK TILE =================
class PendingTaskTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const PendingTaskTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(12),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(12),
            border: Border.all(
                color:
                const Color(0xFF0073e6)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                  const Color(0xFF0073e6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}