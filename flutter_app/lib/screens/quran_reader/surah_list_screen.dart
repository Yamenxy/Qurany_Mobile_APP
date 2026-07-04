import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../services/qiraat_service.dart';
import '../../utils/recitation_modes.dart';
import '../../widgets/app_icons.dart';

class SurahListScreen extends StatefulWidget {
  final bool embeddedInTab;

  const SurahListScreen({super.key, this.embeddedInTab = false});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Check if this screen is used for selecting surah for recitation
  bool _selectForRecitation = false;
  String _recitationMode = 'free';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _selectForRecitation = args['selectForRecitation'] ?? false;
      _recitationMode = args['mode'] ?? 'free';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    final qiraatService = context.watch<QiraatService>();
    final isBazzi = qiraatService.selectedQiraat == 'البزي';

    List<int> allIndices;
    if (_recitationMode == RecitationModes.aiAnalysis) {
      allIndices = AppConstants.serverSupportedSurahs
          .map((n) => n - 1)
          .toList();
    } else if (isBazzi) {
      allIndices = [1];
    } else {
      allIndices = List.generate(114, (i) => i);
    }

    if (_searchQuery.isEmpty) {
      return allIndices;
    }
    return allIndices.where((i) {
      return AppConstants.surahNames[i].contains(_searchQuery) ||
          '${i + 1}'.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuranyTheme.background,
      appBar: AppBar(
        title: Text(_selectForRecitation ? 'اختر السورة' : 'فهرس السور'),
        automaticallyImplyLeading: !widget.embeddedInTab,
        leading: widget.embeddedInTab
            ? null
            : AppIcons.backButton(context: context),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer<QiraatService>(
                builder: (context, qiraatService, child) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: qiraatService.selectedQiraat,
                      icon: const Icon(Icons.arrow_drop_down, color: QuranyTheme.primaryGreen),
                      style: const TextStyle(color: QuranyTheme.primaryGreen, fontWeight: FontWeight.bold, fontFamily: 'MeQuran'),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          qiraatService.setQiraat(newValue);
                        }
                      },
                      items: <String>['حفص','البزي']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Surah list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredIndices.length,
              itemBuilder: (context, index) {
                final i = _filteredIndices[index];
                final surahNumber = i + 1;
                final surahName = AppConstants.surahNames[i];
                final verseCount = AppConstants.surahVerseCount[i];
                final revelationType = AppConstants.surahRevelationType[i];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: QuranyTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$surahNumber',
                          style: const TextStyle(
                            color: QuranyTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      surahName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$verseCount آية • $revelationType',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: _selectForRecitation
                        ? const Icon(
                            Icons.mic_rounded,
                            size: 18,
                            color: QuranyTheme.primaryGreen,
                          )
                        : AppIcons.forwardChevron(
                            color: QuranyTheme.primaryGreen,
                            size: 18,
                          ),
                    onTap: () {
                      if (_selectForRecitation) {
                        final qiraat = context.read<QiraatService>().selectedQiraat;
                        if (_recitationMode == 'tahfeez') {
                          _showAyahRangeSelector(context, surahNumber, surahName);
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.recitation,
                            arguments: {
                              'surahNumber': surahNumber,
                              'surahName': surahName,
                              'mode': _recitationMode,
                              'qiraat': qiraat,
                            },
                          );
                        }
                      } else {
                        final qiraat = context.read<QiraatService>().selectedQiraat;
                        if (qiraat == 'البزي') {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.quranReader,
                            arguments: {
                              'surahNumber': surahNumber,
                              'surahName': surahName,
                              'qiraat': 'البزي',
                            },
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.mushafReader,
                            arguments: {'surahNumber': surahNumber},
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAyahRangeSelector(BuildContext context, int surahNumber, String surahName) {
    int totalVerses = AppConstants.surahVerseCount[surahNumber - 1];
    int startAyah = 1;
    int endAyah = totalVerses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: QuranyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تحديد نطاق الآيات - سورة $surahName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: QuranyTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('من آية:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: QuranyTheme.primaryGreen.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: startAyah,
                                  isExpanded: true,
                                  items: List.generate(totalVerses, (i) {
                                    return DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}'),
                                    );
                                  }),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() {
                                        startAyah = v;
                                        if (startAyah > endAyah) {
                                          endAyah = startAyah;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إلى آية:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: QuranyTheme.primaryGreen.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: endAyah,
                                  isExpanded: true,
                                  items: List.generate(totalVerses, (i) {
                                    bool disabled = (i + 1) < startAyah;
                                    return DropdownMenuItem(
                                      value: i + 1,
                                      enabled: !disabled,
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          color: disabled ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() {
                                        endAyah = v;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        final qiraat = context.read<QiraatService>().selectedQiraat;
                        Navigator.pushNamed(
                          context,
                          AppRoutes.recitation,
                          arguments: {
                            'surahNumber': surahNumber,
                            'surahName': surahName,
                            'mode': _recitationMode,
                            'qiraat': qiraat,
                            'startAyah': startAyah,
                            'endAyah': endAyah,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QuranyTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ابدأ التعلم',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
