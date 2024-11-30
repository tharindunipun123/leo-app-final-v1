import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllAchievementsPage extends StatefulWidget {
  @override
  _AllAchievementsPageState createState() => _AllAchievementsPageState();
}

class _AllAchievementsPageState extends State<AllAchievementsPage> {
  bool isLoading = true;
  int dailyRecharge = 0;
  int totalRecharge = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndRechargeHistory();
  }

  Future<void> _loadUserDataAndRechargeHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _fetchRechargeHistory();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRechargeHistory() async {
    final baseUrl = 'http://145.223.21.62:8090';
    final today = DateTime.now().toUtc(); // Convert to UTC since API returns UTC dates

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/recharge_history/records?filter=(userId="$userId")'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['items'] as List;

        // Calculate total recharge
        totalRecharge = records.fold(0, (sum, record) =>
        sum + (record['diamond_amount'] as int? ?? 0));

        // Calculate daily recharge
        dailyRecharge = records.where((record) {
          final recordDate = DateTime.parse(record['created']).toUtc();
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        }).fold(0, (sum, record) =>
        sum + (record['diamond_amount'] as int? ?? 0));

        print('Daily Recharge: $dailyRecharge'); // Debug print
        print('Total Recharge: $totalRecharge'); // Debug print

        setState(() {});
      } else {
        throw Exception('Failed to load recharge history');
      }
    } catch (e) {
      print('Error fetching recharge history: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recharge history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateProgress(int current, List<int> stages) {
    // If current is larger than the maximum stage, return 1.0
    if (current >= stages.last) {
      return 1.0;
    }

    // Find the appropriate stage range
    for (int i = 0; i < stages.length; i++) {
      if (current < stages[i]) {
        // If it's the first stage
        if (i == 0) {
          return current / stages[i];
        }
        // For subsequent stages
        int rangeStart = stages[i - 1];
        int rangeEnd = stages[i];
        double segmentProgress = (current - rangeStart) / (rangeEnd - rangeStart);
        return (i + segmentProgress) / stages.length;
      }
    }

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final dailyStages = [50, 100, 150, 200, 300, 400, 500, 600];
    final totalStages = [50, 70, 100, 250, 500];

    return SingleChildScrollView(
      child: Column(
        children: [
          AchievementItem(
            title: 'Daily Recharge Diamond',
            subtitle: "Today's diamond recharge: $dailyRecharge",
            icon: Icons.diamond,
            progress: _calculateProgress(dailyRecharge, dailyStages),
            stages: dailyStages,
            currentValue: dailyRecharge,
          ),
          AchievementItem(
            title: 'Total Recharge Diamond',
            subtitle: "Total diamond recharge: $totalRecharge",
            icon: Icons.diamond,
            progress: _calculateProgress(totalRecharge, totalStages),
            stages: totalStages,
            currentValue: totalRecharge,
          ),
          // Keep the Item Received Times achievement
          AchievementItem(
            title: 'Item Received Times',
            subtitle: "Number of times you've received items",
            icon: Icons.card_giftcard,
            progress: 0.3,
            stages: [100, 2000],
            currentValue: 0,
          ),
        ],
      ),
    );
  }
}

class AchievementItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;
  final List<int> stages;
  final int currentValue;

  AchievementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.stages,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                SizedBox(height: 16),
                stages.length <= 5
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stages.map((stage) => _buildStageIndicator(stage)).toList(),
                )
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stages.map((stage) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildStageIndicator(stage),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(int stage) {
    final bool isCompleted = currentValue >= stage;
    final bool isCurrent = currentValue < stage;

    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : (isCurrent ? Icons.circle : Icons.circle_outlined),
          color: isCompleted ? Colors.blue : (isCurrent ? Colors.grey : Colors.grey[300]),
          size: 20,
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond,
              size: 16,
              color: Colors.orangeAccent,
            ),
            SizedBox(width: 2),
            Text(
              '$stage',
              style: TextStyle(
                color: isCompleted ? Colors.blue : Colors.grey[600],
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}