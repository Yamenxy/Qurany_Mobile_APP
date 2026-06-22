import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { BottomSheet, Button } from '../components';
import {
  ChevronLeft,
  ChevronRight,
  Bookmark,
  Share2,
  Settings,
  Play,
  Info,
} from 'lucide-react-native';

interface Verse {
  ayah: number;
  text: string;
  translation: string;
}

interface QuranPage {
  surah: number;
  surahName: string;
  surahNameArabic: string;
  page: number;
  juz: number;
  verses: Verse[];
  revelation: 'Meccan' | 'Medinan';
}

// Mock Quran page data
const mockPage: QuranPage = {
  surah: 1,
  surahName: 'Al-Fatihah',
  surahNameArabic: 'الفاتحة',
  page: 1,
  juz: 1,
  revelation: 'Meccan',
  verses: [
    {
      ayah: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
    },
    {
      ayah: 2,
      text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      translation: 'All praise is due to Allah, Lord of the worlds',
    },
    {
      ayah: 3,
      text: 'الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'The Most Gracious, the Most Merciful',
    },
    {
      ayah: 4,
      text: 'مَالِكِ يَوْمِ الدِّينِ',
      translation: 'Master of the Day of Judgment',
    },
    {
      ayah: 5,
      text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      translation: 'You alone we worship, and You alone we ask for help',
    },
    {
      ayah: 6,
      text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      translation: 'Guide us on the Straight Path',
    },
    {
      ayah: 7,
      text: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      translation:
        'The path of those whom You have blessed; not of those who earned Your wrath, nor of those who have gone astray',
    },
  ],
};

const QuranPageViewerScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const [page, setPage] = useState<QuranPage>(mockPage);
  const [showVerseDetails, setShowVerseDetails] = useState(false);
  const [selectedVerse, setSelectedVerse] = useState<Verse | null>(null);
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [highlightedVerse, setHighlightedVerse] = useState<number | null>(null);

  const handleVersePress = (verse: Verse) => {
    setSelectedVerse(verse);
    setShowVerseDetails(true);
  };

  const handlePreviousPage = () => {
    // In real app, fetch previous page
    console.log('Previous page');
  };

  const handleNextPage = () => {
    // In real app, fetch next page
    console.log('Next page');
  };

  const screenWidth = Dimensions.get('window').width;

  return (
    <View style={styles.container}>
      {/* Top Bar */}
      <View style={styles.topBar}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>

        <View style={styles.topBarCenter}>
          <Text style={styles.topBarSurah}>{page.surahName}</Text>
          <Text style={styles.topBarPage}>Page {page.page} • Juz {page.juz}</Text>
        </View>

        <View style={styles.topBarIcons}>
          <TouchableOpacity
            onPress={() => setIsBookmarked(!isBookmarked)}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <Bookmark
              size={20}
              color={isBookmarked ? Colors.accent : Colors.textSecondary}
              fill={isBookmarked ? Colors.accent : 'none'}
            />
          </TouchableOpacity>

          <TouchableOpacity
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            style={{ marginLeft: Spacing.md }}
            onPress={() => navigation.navigate('TajweedReference')}
          >
            <Info size={20} color={Colors.textSecondary} />
          </TouchableOpacity>

          <TouchableOpacity
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            style={{ marginLeft: Spacing.md }}
          >
            <Settings size={20} color={Colors.textSecondary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Surah Header */}
      <View style={styles.surahHeader}>
        <Text style={styles.surahNameArabic}>{page.surahNameArabic}</Text>
        <Text style={styles.surahInfo}>
          {page.revelation === 'Meccan' ? '☪️ Meccan' : '☪️ Medinan'} • {page.surahName}
        </Text>
      </View>

      {/* Page Content - Scrollable Verses */}
      <ScrollView
        style={styles.verseContainer}
        contentContainerStyle={styles.verseContent}
        showsVerticalScrollIndicator={false}
      >
        {page.verses.map((verse, index) => (
          <TouchableOpacity
            key={index}
            style={[
              styles.verseBlock,
              highlightedVerse === verse.ayah && styles.verseHighlighted,
            ]}
            onPress={() => handleVersePress(verse)}
            activeOpacity={0.7}
          >
            {/* Verse Number */}
            <View style={styles.verseNumberContainer}>
              <View style={styles.verseNumberBadge}>
                <Text style={styles.verseNumber}>{verse.ayah}</Text>
              </View>
            </View>

            {/* Verse Text (Arabic) */}
            <Text style={styles.verseTextArabic}>{verse.text}</Text>

            {/* Verse Translation (English) */}
            <Text style={styles.verseTranslation}>{verse.translation}</Text>
          </TouchableOpacity>
        ))}

        {/* Page End Ornament */}
        <View style={styles.pageEnd}>
          <Text style={styles.ornament}>۞</Text>
        </View>
      </ScrollView>

      {/* Bottom Action Bar */}
      <View style={styles.bottomBar}>
        <TouchableOpacity
          onPress={handlePreviousPage}
          style={styles.navButton}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <ChevronLeft size={24} color={Colors.primaryLight} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.playButton}>
          <Play size={24} color={Colors.backgroundDark} fill={Colors.backgroundDark} />
          <Text style={styles.playText}>Play Audio</Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={handleNextPage}
          style={styles.navButton}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <ChevronRight size={24} color={Colors.primaryLight} />
        </TouchableOpacity>
      </View>

      {/* Verse Details Bottom Sheet */}
      <BottomSheet
        visible={showVerseDetails}
        onClose={() => setShowVerseDetails(false)}
        title={`Ayah ${selectedVerse?.ayah}`}
        height="70%"
      >
        {selectedVerse && (
          <ScrollView contentContainerStyle={styles.sheetContent} showsVerticalScrollIndicator={false}>
            {/* Arabic Text */}
            <View style={styles.sheetSection}>
              <Text style={styles.sheetLabel}>Arabic Text</Text>
              <Text style={styles.sheetArabic}>{selectedVerse.text}</Text>
            </View>

            {/* Translation */}
            <View style={styles.sheetSection}>
              <Text style={styles.sheetLabel}>English Translation</Text>
              <Text style={styles.sheetTranslation}>{selectedVerse.translation}</Text>
            </View>

            {/* Audio Play */}
            <View style={styles.sheetSection}>
              <TouchableOpacity style={styles.audioPlayButton}>
                <Play size={20} color={Colors.textPrimary} />
                <Text style={styles.audioPlayText}>Listen to This Verse</Text>
              </TouchableOpacity>
            </View>

            {/* Tafsir (placeholder) */}
            <View style={styles.sheetSection}>
              <Text style={styles.sheetLabel}>Tafsir</Text>
              <Text style={styles.tafsirText}>
                Tafsir content will appear here explaining the context and meaning of this verse.
                This is a placeholder for the full Tafsir content.
              </Text>
            </View>

            {/* Actions */}
            <View style={styles.sheetActions}>
              <Button
                title="Add Bookmark"
                onPress={() => {
                  setShowVerseDetails(false);
                  setIsBookmarked(true);
                }}
                variant="primary"
                fullWidth
              />

              <TouchableOpacity style={styles.shareButton}>
                <Share2 size={20} color={Colors.accent} />
                <Text style={styles.shareText}>Share This Verse</Text>
              </TouchableOpacity>
            </View>
          </ScrollView>
        )}
      </BottomSheet>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  topBarCenter: {
    flex: 1,
    alignItems: 'center',
    marginHorizontal: Spacing.lg,
  },
  topBarSurah: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  topBarPage: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  topBarIcons: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  surahHeader: {
    alignItems: 'center',
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  surahNameArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['2xl'],
    color: Colors.textGold,
    marginBottom: Spacing.sm,
  },
  surahInfo: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  verseContainer: {
    flex: 1,
  },
  verseContent: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  verseBlock: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  verseHighlighted: {
    borderColor: Colors.accent,
    borderWidth: 2,
    backgroundColor: Colors.accent + '10',
  },
  verseNumberContainer: {
    alignItems: 'flex-end',
    marginBottom: Spacing.md,
  },
  verseNumberBadge: {
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  verseNumber: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.sm,
    fontWeight: '700',
    color: Colors.backgroundDark,
  },
  verseTextArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['2xl'],
    lineHeight: Typography.size['2xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.md,
  },
  verseTranslation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    lineHeight: Typography.size.sm * 1.8,
  },
  pageEnd: {
    alignItems: 'center',
    paddingVertical: Spacing.xl,
  },
  ornament: {
    fontFamily: Typography.arabicFont,
    fontSize: 32,
    color: Colors.accent,
  },
  bottomBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
    gap: Spacing.md,
  },
  navButton: {
    width: 48,
    height: 48,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.primaryLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  playButton: {
    flex: 1,
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.medium,
    paddingVertical: Spacing.lg,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  playText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.backgroundDark,
  },
  sheetContent: {
    paddingVertical: Spacing.lg,
  },
  sheetSection: {
    marginBottom: Spacing.lg,
  },
  sheetLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  sheetArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.xl,
    lineHeight: Typography.size.xl * 2.2,
    color: Colors.textPrimary,
    textAlign: 'right',
  },
  sheetTranslation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    lineHeight: Typography.size.base * 1.8,
  },
  audioPlayButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    gap: Spacing.md,
  },
  audioPlayText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textPrimary,
  },
  tafsirText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    lineHeight: Typography.size.sm * 1.8,
  },
  sheetActions: {
    marginTop: Spacing.lg,
    gap: Spacing.md,
  },
  shareButton: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: Spacing.md,
    gap: Spacing.sm,
  },
  shareText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.accent,
  },
});

export default QuranPageViewerScreen;
