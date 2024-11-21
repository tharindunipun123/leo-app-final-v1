import 'package:flutter/material.dart';

class AllAchievementsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AchievementItem(
            title: 'Daily Recharge Diamond',
            subtitle: "Total amount of diamond you've recharged....",
            icon: Icons.diamond,
            progress: 0.5,
            stages: [50, 100, 150, 200, 300, 400, 500, 600],
          ),
          AchievementItem(
            title: 'Total Recharge Diamond',
            subtitle: "Total amount of diamond you've recharged....",
            icon: Icons.diamond,
            progress: 0.5,
            stages: [50, 70, 100, 250, 500],
          ),
          AchievementItem(
            title: 'Item Received Times',
            subtitle: "Number of times you've received items",
            icon: Icons.card_giftcard,
            progress: 0.3,
            stages: [100, 2000],
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

  AchievementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: MediaQuery.of(context).size.width * progress,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                stages.length <= 5
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: stages.map((stage) {
                          return Column(
                            children: [
                              Icon(
                                stage == stages.last
                                    ? Icons.circle
                                    : Icons.check_circle,
                                color: stage == stages.last
                                    ? Colors.grey
                                    : Colors.blue,
                                size: 18,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    size: 16,
                                    color: Colors.orangeAccent,
                                  ),
                                  Text('$stage'),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: stages.map((stage) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  Icon(
                                    stage == stages.last
                                        ? Icons.circle
                                        : Icons.check_circle,
                                    color: stage == stages.last
                                        ? Colors.grey
                                        : Colors.blue,
                                    size: 18,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.diamond,
                                        size: 16,
                                        color: Colors.orangeAccent,
                                      ),
                                      Text('$stage'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
