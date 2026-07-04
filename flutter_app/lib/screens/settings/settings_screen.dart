import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/qiraat_service.dart';
import '../../services/recitation_api_service.dart';
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

          // Analysis server (LAN IPs change per network, so the address must
          // be editable on the device rather than baked into the APK).
          const _SectionHeader(title: 'خادم التحليل'),
          const _ServerAddressCard(),
          const SizedBox(height: 12),
          Card(
            child: Consumer<QiraatService>(
              builder: (context, qiraat, _) => ListTile(
                leading: const Icon(Icons.menu_book_outlined,
                    color: QuranyTheme.primaryGreen),
                title: const Text('القراءة للتحليل بالذكاء الاصطناعي'),
                subtitle: Text(
                  qiraat.isBazzi
                      ? 'البزي (سورة البقرة)'
                      : 'حفص',
                ),
                trailing: DropdownButton<String>(
                  value: qiraat.selectedQiraat,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'حفص', child: Text('حفص')),
                    DropdownMenuItem(value: 'البزي', child: Text('البزي')),
                  ],
                  onChanged: (v) {
                    if (v != null) qiraat.setQiraat(v);
                  },
                ),
              ),
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

class _ServerAddressCard extends StatefulWidget {
  const _ServerAddressCard();

  @override
  State<_ServerAddressCard> createState() => _ServerAddressCardState();
}

class _ServerAddressCardState extends State<_ServerAddressCard> {
  late final TextEditingController _controller;
  bool _testing = false;
  bool? _healthy;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: AppConstants.recitationApiUserOverride ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    final value =
        raw.isEmpty ? raw : AppConstants.normalizeApiBaseUrl(raw);
    if (value.isNotEmpty) {
      _controller.text = value;
    }
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(AppConstants.recitationApiPrefsKey);
      AppConstants.recitationApiUserOverride = null;
    } else {
      await prefs.setString(AppConstants.recitationApiPrefsKey, value);
      AppConstants.recitationApiUserOverride = value;
    }
    setState(() => _healthy = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value.isEmpty
              ? 'تمت إعادة العنوان الافتراضي'
              : 'تم حفظ عنوان الخادم'),
          backgroundColor: QuranyTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final api = context.read<RecitationApiService>();
    await _save();
    setState(() => _testing = true);
    final ok = await api.isHealthy(timeout: const Duration(seconds: 5));
    if (mounted) {
      setState(() {
        _testing = false;
        _healthy = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'عنوان الخادم',
                hintText: AppConstants.recitationApiDefaultUrl,
                hintTextDirection: TextDirection.ltr,
                helperText:
                    'مثال: http://192.168.1.5:8000 — اتركه فارغًا للافتراضي',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _testing ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('اختبار الاتصال'),
                ),
                const SizedBox(width: 12),
                if (_healthy != null)
                  Icon(
                    _healthy! ? Icons.check_circle : Icons.error,
                    color: _healthy!
                        ? QuranyTheme.primaryGreen
                        : QuranyTheme.errorRed,
                  ),
              ],
            ),
          ],
        ),
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
