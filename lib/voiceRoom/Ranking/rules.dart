import 'package:flutter/material.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({Key? key}) : super(key: key);

  Widget _buildRuleCard(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ranking Rules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Types of Rankings',
              [
                _buildRuleCard(
                  'Top Gifters',
                  'Ranked based on the total number of diamonds sent by each user.',
                ),
                _buildRuleCard(
                  'Top Stars',
                  'Ranked based on the total number of diamonds received by each user.',
                ),
                _buildRuleCard(
                  'Top Rooms',
                  'Ranked based on the total number of diamonds received by each room.',
                ),
                _buildRuleCard(
                  'Top Recharges',
                  'Ranked based on the total number of diamonds recharged by each user.',
                ),
              ],
            ),
            _buildSection(
              'Ranking Updates',
              [
                _buildRuleCard(
                  'Weekly Updates',
                  'Rankings are refreshed every Sunday at 00:00 AM (GMT +05:30).',
                ),
              ],
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }
}