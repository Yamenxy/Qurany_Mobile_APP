import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backendAvailable = false;
  bool _checkingBackend = true;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _checkingBackend = true);
    final available = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _backendAvailable = available;
        _checkingBackend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
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

          // Backend status
          const _SectionHeader(title: 'حالة الخادم'),
          Card(
            child: ListTile(
              leading: Icon(
                _checkingBackend
                    ? Icons.hourglass_top
                    : _backendAvailable
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                color: _checkingBackend
                    ? Colors.grey
                    : _backendAvailable
                        ? QuranyTheme.correctGreen
                        : QuranyTheme.errorRed,
              ),
              title: Text(
                _checkingBackend
                    ? 'جاري التحقق...'
                    : _backendAvailable
                        ? 'الخادم متصل'
                        : 'الخادم غير متوفر',
              ),
              subtitle: Text(
                'الخادم: ${AppConstants.apiBaseUrl}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _checkBackend,
              ),
            ),
          ),
          if (!_backendAvailable && !_checkingBackend)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'لاستخدام ميزة تحليل التلاوة بالذكاء الاصطناعي، شغّل الخادم الخلفي (backend/app.py)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
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
                    'تطبيق قُرآنِي يستخدم الذكاء الاصطناعي لتقييم تلاوة القرآن الكريم وكشف الأخطاء في الوقت الفعلي.',
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
