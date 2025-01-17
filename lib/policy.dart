// policy_pages.dart
import 'package:flutter/material.dart';

// Base Policy Page Widget
class PolicyPage extends StatelessWidget {
  final String title;
  final List<PolicySection> sections;
  final String? contactEmail;
  final String? phoneNumber;
  final String lastUpdated;

  const PolicyPage({
    Key? key,
    required this.title,
    required this.sections,
    this.contactEmail,
    this.phoneNumber,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 20 ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: $lastUpdated',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Policy Sections
                ...sections.map((section) => _buildSection(context, section)),

                // Contact Information
                if (contactEmail != null || phoneNumber != null)
                  _buildContactInfo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, PolicySection section) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                section.title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ...section.content.map((item) => _buildContentItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildContentItem(BuildContext context, String content) {
    if (content.startsWith('•')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content.substring(1).trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (contactEmail != null)
            _buildContactRow(context, Icons.email_outlined, contactEmail!),
          if (phoneNumber != null)
            _buildContactRow(context, Icons.phone_outlined, phoneNumber!),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class PolicySection {
  final String? title;
  final List<String> content;

  PolicySection({
    this.title,
    required this.content,
  });
}

// Privacy Policy Page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: 'Privacy Policy',
      lastUpdated: 'December 1, 2024',
      sections: [
        PolicySection(
          content: [
            'This Privacy Policy describes Our values your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and share your information when you use our chat and call app',
          ],
        ),
        PolicySection(
          title: 'Information We Collect',
          content: [
            'We may collect the following types of information:',
          ],
        ),
        PolicySection(
          title: 'Personal Information You Provide',
          content: [
            'Account Information: Name, email address, phone number, and profile picture.',
            'Messages and Calls: Messages, voice calls, and video calls are encrypted end-to-end and not stored on our servers unless you specifically back them up.',
          ],
        ),
        PolicySection(
          title: 'Automatically Collected Information',
          content: [
            'Device Information: Device type, operating system, unique device identifiers, and app version.',
            'Usage Data: App usage statistics, features accessed, and settings used.',
            'Log Data: IP addresses, timestamps, and error reports.',
          ],
        ),
        PolicySection(
          title: 'Third-Party Information',
          content: [
            'If you link your account with third-party services, we may collect information from those services (e.g., contacts or profile details).',
          ],
        ),
        PolicySection(
          title: 'How We Use Your Information',
          content: [
            'We use your information for the following purposes:',
            '• To provide and improve the App\'s features.',
            '• To facilitate messaging, voice, and video calls.',
            '• To manage your account and provide customer support.',
            '• To ensure security and prevent misuse.',
            '• To comply with legal obligations.',
          ],
        ),
        PolicySection(
          title: 'How We Share Your Information',
          content: [
            'We do not sell your personal information. We may share your data in the following ways:',
            '• With Service Providers: For hosting, analytics, or support services.',
            '• With Other Users: Your name, profile picture, and status may be visible to other users.',
            '• For Legal Reasons: To comply with applicable laws, enforce our terms, or protect the rights and safety of our users.',
          ],
        ),
        PolicySection(
          title: 'Data Retention',
          content: [
            'We retain your information only as long as necessary to provide our services or comply with legal obligations. Messages and call data are encrypted and stored temporarily as required for delivery.',
          ],
        ),
        PolicySection(
          title: 'Data Security',
          content: [
            'We use industry-standard encryption and security measures to protect your data. However, no method of transmission over the internet is 100% secure.',
          ],
        ),
        PolicySection(
          title: 'Your Rights',
          content: [
            'Depending on your location, you may have the right to:',
            '• Access and review the information we hold about you.',
            '• Request correction or deletion of your personal data.',
            '• Opt-out of certain data processing activities.',
            'For requests, contact us at support@leochat.app.',
          ],
        ),
        PolicySection(
          title: 'Third-Party Links',
          content: [
            'Our App may contain links to third-party websites or services. We are not responsible for their privacy practices.',
          ],
        ),
        PolicySection(
          title: 'Children\'s Privacy',
          content: [
            'Our App is not intended for users under the age of [13/16, depending on jurisdiction]. We do not knowingly collect data from children without parental consent.',
          ],
        ),
        PolicySection(
          title: 'Changes to This Privacy Policy',
          content: [
            'We may update this Privacy Policy from time to time. Changes will be posted within the App and, where appropriate, notified via email.',
          ],
        ),
        PolicySection(
          title: 'Contact Us',
          content: [
            'If you have any questions or concerns about this Privacy Policy, contact us at:',
            '• Leo House Technology Pvt.Ltd',
            '• Email: Support@leochat.app',
            '• Phone: +94702000011',
          ],
        ),
      ],
      contactEmail: 'Support@leochat.app',
      phoneNumber: '+94702000011',
    );
  }
}

// [Continue with other policy pages in the next message...]

// Terms and Conditions Page
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: 'Terms & Conditions',
      lastUpdated: 'December 1, 2024',
      sections: [
        PolicySection(
          content: ['Welcome to Leo Chat! By using our services, you agree to these Terms and Conditions. Please read them carefully before using the app.'],
        ),
        PolicySection(
          title: 'Acceptance of Terms',
          content: ['By accessing or using Leo Chat, you agree to be bound by these terms and our Privacy Policy. If you do not agree, you must not use our services.'],
        ),
        PolicySection(
          title: 'Eligibility',
          content: [
            'To use Leo Chat, you must:',
            '• Be at least 18 years old or the legal age of majority in your jurisdiction.',
            '• Have the authority to agree to these Terms if using the app on behalf of an organization.',
          ],
        ),
        PolicySection(
          title: 'Account Registration',
          content: [
            'Users must create an account using accurate and complete information.',
            'You are responsible for maintaining the confidentiality of your account credentials.',
            'Notify us immediately of any unauthorized use of your account.',
          ],
        ),
        PolicySection(
          title: 'User Conduct',
          content: [
            'By using Leo Chat, you agree not to:',
            '• Use the app for any illegal, harmful, or unauthorized purposes.',
            '• Send spam, abusive, or offensive messages.',
            '• Harass, bully, or impersonate others.',
            '• Distribute malware or harmful content.',
            'We reserve the right to suspend or terminate accounts that violate these rules.',
          ],
        ),
        PolicySection(
          title: 'Virtual Diamonds and Purchases',
          content: [
            'Users can purchase virtual diamonds to send gifts or play games.',
            'Virtual items have no real-world monetary value and cannot be redeemed for cash.',
            'All purchases are final, and refunds are provided at our sole discretion.',
          ],
        ),
        PolicySection(
          title: 'Audio and Group Calls',
          content: [
            'We strive to provide secure and high-quality call services. However, we are not liable for call disruptions caused by technical issues or network problems.',
            'Recording calls without the consent of all participants is prohibited.',
          ],
        ),
        PolicySection(
          title: 'Content Ownership',
          content: [
            'You retain ownership of content you share but grant Leo Chat a non-exclusive, worldwide license to use, host, and display it for operational purposes.',
            'We do not monitor all user-generated content but reserve the right to remove content that violates these Terms.',
          ],
        ),
        PolicySection(
          title: 'Termination',
          content: [
            'We may terminate or suspend your access to Leo Chat without prior notice if you breach these Terms or engage in prohibited activities.',
          ],
        ),
        PolicySection(
          title: 'Limitation of Liability',
          content: [
            'Leo Chat is provided "as is" without warranties of any kind. We are not liable for:',
            '• Loss of data, profits, or damages resulting from your use of the app.',
            '• Unauthorized access to your account.',
          ],
        ),
        PolicySection(
          title: 'Changes to Terms',
          content: [
            'We reserve the right to modify these Terms at any time. We will notify you of significant changes via the app or email. Continued use of the app after updates signifies your acceptance of the revised Terms.',
          ],
        ),
      ],
      contactEmail: 'feedback@leochat.app',
      phoneNumber: '+94702000011',
    );
  }
}

// Copyright Policy Page
class CopyrightPolicyPage extends StatelessWidget {
  const CopyrightPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: 'Copyright Policy',
      lastUpdated: 'December 1, 2024',
      sections: [
        PolicySection(
          content: [
            'Leo Chat ("we", "us", or "our") respects the intellectual property rights of others and expects its users to do the same. This Copyright Policy outlines our policy regarding copyrighted materials and content shared within the Leo Chat platform.',
          ],
        ),
        PolicySection(
          title: 'Ownership of Content',
          content: [
            'All content, features, and functionality on Leo Chat, including but not limited to text, graphics, logos, images, audio, video, and software, are the exclusive property of Leo House Technology Pvt.Ltd and are protected under copyright, trademark, and other applicable intellectual property laws.',
            'Users retain ownership of any content they create and share on Leo Chat. However, by posting content, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and display the content as necessary to operate and promote the platform.',
          ],
        ),
        PolicySection(
          title: 'User Responsibilities',
          content: [
            'Users may only share content on Leo Chat that they have the right to use, reproduce, and distribute.',
            'Users are prohibited from uploading, sharing, or distributing any content that infringes on the copyrights, trademarks, or other intellectual property rights of third parties.',
          ],
        ),
        PolicySection(
          title: 'Reporting Copyright Infringement',
          content: [
            'If you believe that any content on Leo Chat infringes your copyright, please provide a written notice with the following details to our designated copyright agent:',
            '• A description of the copyrighted work that you claim has been infringed.',
            '• A description of where the infringing material is located on the platform.',
            '• Your contact information, including your full name, email address, and phone number.',
            '• A statement that you have a good faith belief that the disputed use is not authorized by the copyright owner, its agent, or the law.',
            '• A statement that the information in the notice is accurate and that you are authorized to act on behalf of the copyright owner.',
          ],
        ),
        PolicySection(
          title: 'Counter-Notice by User',
          content: [
            'If your content has been removed due to a copyright claim, and you believe this removal was in error, you may submit a counter-notice. Your counter-notice should include:',
            '• Identification of the material that was removed and where it was previously located.',
            '• A statement under penalty of perjury that you have a good faith belief the material was removed as a result of a mistake or misidentification.',
            '• Your contact information, and a statement consenting to the jurisdiction of the federal court in your district (or your location if outside the U.S.).',
            'Send your counter-notice to: Email: info@leochat.app',
          ],
        ),
        PolicySection(
          title: 'Repeat Infringements',
          content: [
            'We reserve the right to terminate user accounts that are found to be repeat infringers of copyright or other intellectual property rights.',
          ],
        ),
        PolicySection(
          title: 'Changes to This Policy',
          content: [
            'We may update this Copyright Policy from time to time. Changes will be effective immediately upon posting the revised policy on the platform.',
          ],
        ),
      ],
      contactEmail: 'feedback@leochat.app',
      phoneNumber: '+94702000011',
    );
  }
}

// Refund Policy Page
class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolicyPage(
      title: 'Refund Policy',
      lastUpdated: 'December 1, 2024',
      sections: [
        PolicySection(
          title: 'Overview',
          content: [
            'Virtual diamonds purchased in our app are non-refundable. By making a purchase, you agree to this policy and confirm your understanding of the non-refundable nature of the transaction.',
          ],
        ),
        PolicySection(
          title: 'Exceptions',
          content: [
            'We may provide refunds in specific situations, including but not limited to:',
            '• Unauthorized transactions.',
            '• Technical errors resulting in undelivered diamonds.',
            '• Accidental duplicate purchases.',
            'To request a refund, users must contact our support team within [specific time, e.g., 7 days] of the transaction and provide all necessary proof, including transaction IDs and relevant screenshots.',
          ],
        ),
        PolicySection(
          title: 'In-App Usage',
          content: [
            'Once virtual diamonds are used to send gifts, play games, or engage in any other app-related activities, refunds will not be considered under any circumstances.',
          ],
        ),
        PolicySection(
          title: 'Restrictions',
          content: [
            'Refunds will only be processed through the original payment method and may take [specific timeframe, e.g., 5–10 business days] to appear in your account, depending on your payment provider.',
          ],
        ),
        PolicySection(
          title: 'Abuse of Refund Policy',
          content: [
            'We reserve the right to deny refund requests if we detect patterns of abuse or fraudulent behavior.',
          ],
        ),
        PolicySection(
          title: 'Changes to the Policy',
          content: [
            'We reserve the right to modify or update this policy at any time. Users will be notified of significant changes through in-app notifications or email.',
            'If you have any questions about this policy or need assistance, please contact our support team at feedback@leochat.app.',
          ],
        ),
      ],
      contactEmail: 'feedback@leochat.app',
    );
  }
}