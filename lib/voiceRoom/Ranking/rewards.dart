import 'package:flutter/material.dart';

class RankingRewardPopup extends StatelessWidget {
  const RankingRewardPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B0082),  // Indigo
            Color(0xFF8A2BE2),  // BlueViolet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Ranking Rewards',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4B0082).withOpacity(0.85),
            const Color(0xFF8A2BE2).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildRewardsHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: _buildBadgesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.emoji_events_rounded,
            color: Colors.white70,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Rewards for Top Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final badges = [
      {'image': 'assets/images/badge_1.png', 'name': 'Top Room'},
      {'image': 'assets/images/badge_2.png', 'name': 'Top Gifter'},
      {'image': 'assets/images/badge_3.png', 'name': 'Top Star'},
      {'image': 'assets/images/badge_4.png', 'name': 'Top Recharger'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 2; // Account for spacing
        final itemHeight = itemWidth * 1.4; // Increased height ratio
        final imageSize = itemWidth * 0.95; // Image takes 95% of item width

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) => _buildBadgeItem(
            badges[index]['image']!,
            badges[index]['name']!,
            imageSize,
          ),
        );
      },
    );
  }

  Widget _buildBadgeItem(String imagePath, String title, double imageSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth * 0.11; // Responsive font size

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            SizedBox(
              height: imageSize,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: imageSize * 0.08), // Proportional spacing
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: imageSize * 0.1,
                vertical: imageSize * 0.05,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4B0082).withOpacity(0.9),
                    const Color(0xFF8A2BE2).withOpacity(0.9),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(imageSize * 0.08),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}