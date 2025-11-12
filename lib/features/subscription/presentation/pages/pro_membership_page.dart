import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/widgets/pro_badge.dart';
import '../../../../shared/services/pro_status_service.dart';
import '../../../../core/theme/app_theme.dart';

class ProMembershipPage extends StatefulWidget {
  const ProMembershipPage({super.key});

  @override
  State<ProMembershipPage> createState() => _ProMembershipPageState();
}

class _ProMembershipPageState extends State<ProMembershipPage> {
  bool _isLoading = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await ProStatusService.isProUser();
    if (mounted) {
      setState(() {
        _isPro = isPro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('PRO Membership'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                      AppTheme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status
                  if (_isPro)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'You are PRO!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enjoying all premium features',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isPro) const SizedBox(height: 24),

                  // Features Section
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feature List
                  ...ProStatusService.getProFeatures().map((feature) {
                    final parts = feature.split(' ');
                    final emoji = parts[0];
                    final text = parts.length > 1 ? parts[1] : feature;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Pricing Section
                  if (!_isPro) ...[
                    Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Monthly Plan
                    _buildPlanCard(
                      title: 'Monthly',
                      price: '\$4.99',
                      period: '/month',
                      features: ['Cancel anytime', 'All PRO features'],
                      onTap: () => _handlePurchase('monthly'),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Yearly Plan (Popular)
                    _buildPlanCard(
                      title: 'Yearly',
                      price: '\$39.99',
                      period: '/year',
                      features: ['Save 33%', 'All PRO features', 'Best value'],
                      isPopular: true,
                      onTap: () => _handlePurchase('yearly'),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),
                  ],

                  // Terms
                  Text(
                    'By purchasing PRO membership, you agree to our Terms of Service and Privacy Policy. Subscription will auto-renew unless canceled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required VoidCallback onTap,
    required bool isDark,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                )
              : null,
          color: isPopular ? null : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: isPopular
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 2,
                ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA500),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 16,
                    color: isPopular
                        ? Colors.white.withOpacity(0.9)
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Features
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: isPopular ? Colors.white : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPopular
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(String plan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual in-app purchase flow here
      // For now, just enable pro status for testing
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase Simulation'),
          content: Text('This would purchase the $plan plan.\nFor testing, PRO status will be enabled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Enable pro status for testing
                await ProStatusService.setProStatus(true);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _isPro = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PRO membership activated! 🎉'),
                      backgroundColor: Color(0xFFFFD700),
                    ),
                  );
                }
              },
              child: const Text('Activate PRO (Test)'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
