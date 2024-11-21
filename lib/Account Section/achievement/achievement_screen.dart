import 'package:flutter/material.dart';
import 'active_achievements_page.dart';
import 'all_achievements_page.dart';
import 'charm_achievements_page.dart';
import 'consumption_achievements_page.dart';
import 'recharge_achievements_page.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({Key? key}) : super(key: key);

  @override
  _AchievementPageState createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade200,
            Colors.blue.shade800,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Achievement',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          margin: EdgeInsets.all(16),
          child: Column(
            children: [
              AchievementHeader(),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Active'),
                  Tab(text: 'Charm'),
                  Tab(text: 'Recharge'),
                  Tab(text: 'Consumption'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
              SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AllAchievementsPage(),
                    ActiveAchievementsPage(),
                    CharmAchievementsPage(),
                    RechargeAchievementsPage(),
                    ConsumptionAchievementsPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Image(
              image: AssetImage('assets/images/Trophy.png'),
              width: 60,
              height: 60,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Apprentice',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    Text('Need ', style: TextStyle(color: Colors.white)),
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
                    Text(' 150 to upgrade',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
