import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: AppIcons.backButton(context: context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: QuranyTheme.primaryGreen,
                    child: Text(
                      auth.userName.isNotEmpty
                          ? auth.userName[0].toUpperCase()
                          : 'ض',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName.isNotEmpty ? auth.userName : 'ضيف',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (auth.userEmail.isNotEmpty)
                          Text(
                            auth.userEmail,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App info
          const _SectionHeader(title: 'عن التطبيق'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading:
                      Icon(Icons.info_outline, color: QuranyTheme.primaryGreen),
                  title: Text('الإصدار'),
                  trailing: Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: QuranyTheme.primaryGreen),
                  title: const Text('وصف'),
                  subtitle: const Text(
                    'تطبيق قُرآنِي لتقييم تلاوة القرآن الكريم وكشف الأخطاء في الوقت الفعلي.',
                  ),
                  isThreeLine: true,
                  onTap: () {},
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.school_outlined,
                      color: QuranyTheme.primaryGreen),
                  title: Text('المشروع'),
                  subtitle: Text(
                    'مشروع التخرج - كلية الحاسبات والذكاء الاصطناعي\n'
                    'جامعة القاهرة - العام الأكاديمي 2025-2026',
                  ),
                  isThreeLine: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Supervised by
          const _SectionHeader(title: 'الفريق'),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.supervisor_account,
                      color: QuranyTheme.primaryGold),
                  title: Text('إشراف'),
                  subtitle: Text('د. فاطمة عمارة'),
                ),
                Divider(height: 1),
                ListTile(
                  leading:
                      Icon(Icons.group, color: QuranyTheme.primaryGreen),
                  title: Text('فريق التطوير'),
                  subtitle: Text(
                    'عبدالرحمن حسام الدين\n'
                    'أحمد نسال\n'
                    'عبدالرحمن زكريا فضل\n'
                    'أحمد عز الدين\n'
                    'يامن ياسر',
                  ),
                  isThreeLine: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: QuranyTheme.darkGreen,
        ),
      ),
    );
  }
}
