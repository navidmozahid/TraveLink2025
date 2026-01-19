import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/navigation_service.dart';
import 'business_login_screen.dart';

class BusinessHomeScreen extends StatelessWidget {
  final User user;
  final Map<String, dynamic> businessAccount;

  const BusinessHomeScreen({
    super.key,
    required this.user,
    required this.businessAccount,
  });

  @override
  Widget build(BuildContext context) {
    final agencyName = businessAccount['agency_name'] ?? 'Your Agency';
    final email = user.email ?? 'No email';
    final status = businessAccount['status'] ?? 'unknown';
    final phone = businessAccount['phone'] ?? 'Not provided';
    final address = businessAccount['address'] ?? 'Not provided';
    final agencyType = businessAccount['agency_type'] ?? 'Not specified';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Dashboard"),
        backgroundColor: const Color(0xFF023e8a),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BusinessLoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card with Status
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF023e8a),
                          child: Text(
                            agencyName.isNotEmpty ? agencyName[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agencyName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF023e8a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                agencyType,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.email, "Email", email),
                    _buildInfoRow(Icons.phone, "Phone", phone),
                    _buildInfoRow(Icons.location_on, "Address", address),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Status: ${status.toUpperCase()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023e8a),
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildActionCard(
                  icon: Icons.business,
                  title: "Agency Profile",
                  subtitle: "Manage profile",
                  color: Colors.blue,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                _buildActionCard(
                  icon: Icons.people,
                  title: "Manage Clients",
                  subtitle: "View clients",
                  color: Colors.green,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                _buildActionCard(
                  icon: Icons.travel_explore,
                  title: "Tours",
                  subtitle: "Manage tours",
                  color: Colors.orange,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                _buildActionCard(
                  icon: Icons.analytics,
                  title: "Analytics",
                  subtitle: "View reports",
                  color: Colors.purple,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                _buildActionCard(
                  icon: Icons.calendar_today,
                  title: "Bookings",
                  subtitle: "Manage bookings",
                  color: Colors.teal,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                _buildActionCard(
                  icon: Icons.settings,
                  title: "Settings",
                  subtitle: "App settings",
                  color: Colors.grey,
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF023e8a),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      "Account Created",
                      "Your agency account was created successfully",
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildActivityItem(
                      "Profile Setup",
                      "Basic information added",
                      Icons.person,
                      Colors.blue,
                    ),
                    if (status == 'pending')
                      _buildActivityItem(
                        "Under Review",
                        "Your account is pending approval",
                        Icons.pending,
                        Colors.orange,
                      ),
                    if (status == 'approved')
                      _buildActivityItem(
                        "Account Approved",
                        "Your account is now active",
                        Icons.verified,
                        Colors.green,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF023e8a),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      case 'suspended':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("This feature is coming soon!"),
        backgroundColor: Color(0xFF023e8a),
        duration: Duration(seconds: 2),
      ),
    );
  }
}