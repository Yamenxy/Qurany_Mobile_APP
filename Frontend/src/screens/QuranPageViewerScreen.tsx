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
import { BottomSheet, Button, QiraaSelector } from '../components';
import {
  ChevronLeft,
  ChevronRight,
  Bookmark,
  Play,
  Mic,
  Eye,
  EyeOff,
} from 'lucide-react-native';

// Import our pre-processed JSON layout
import quranLayoutData from '../../assets/data/quran_isra_layout.json';

const toArabicDigits = (num: number) => {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return num.toString().replace(/\d/g, x => digits[parseInt(x)]);
};

const QuranPageViewerScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const [currentPageIndex, setCurrentPageIndex] = useState(0);
  
  // States for Memorize / AI Mode
  const [isListening, setIsListening] = useState(false);
  const [isHidden, setIsHidden] = useState(false);
  const [qiraa, setQiraa] = useState<'hafs' | 'warsh' | 'qalun'>('hafs');
  const [showQiraaSheet, setShowQiraaSheet] = useState(false);

  const currentPage = quranLayoutData[currentPageIndex];

  const handlePreviousPage = () => {
    if (currentPageIndex > 0) {
      setCurrentPageIndex(currentPageIndex - 1);
    }
  };

  const handleNextPage = () => {
    if (currentPageIndex < quranLayoutData.length - 1) {
      setCurrentPageIndex(currentPageIndex + 1);
    }
  };

  const renderLine = (line: any, index: number) => {
    if (line.type === 'surah_name') {
      return (
        <View key={index} style={styles.surahHeaderFrameContainer}>
          <View style={styles.surahHeaderFrame}>
            <Text style={styles.surahNameDecorated}>سُورَةُ الإِسْرَاءِ</Text>
          </View>
        </View>
      );
    }
    
    if (line.type === 'basmallah') {
      return (
        <View key={index} style={styles.basmallahContainer}>
          <Text style={styles.basmallahText}>بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</Text>
        </View>
      );
    }

    return (
      <View key={index} style={[styles.ayahLine, line.centered && styles.centeredLine]}>
        <Text 
          style={[styles.mushafVerseText, isHidden && styles.hiddenText]}
          numberOfLines={1}
          adjustsFontSizeToFit={true}
        >
          {line.text}
        </Text>
      </View>
    );
  };

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
          <Text style={styles.topBarSurah}>Al-Isra</Text>
          <Text style={styles.topBarPage}>Page {currentPage.page_number} • Juz 15</Text>
        </View>

        <View style={styles.topBarIcons}>
          <TouchableOpacity
            style={[styles.qiraaBadge, { marginRight: Spacing.md }]}
            onPress={() => setShowQiraaSheet(true)}
          >
            <Text style={styles.qiraaBadgeText}>
              {qiraa === 'hafs' ? 'Hafs' : qiraa === 'warsh' ? 'Warsh' : 'Qalun'}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => {}}>
            <Bookmark size={24} color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Page Content - Mushaf Layout */}
      <ScrollView
        style={styles.verseContainer}
        contentContainerStyle={styles.verseContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.mushafPageContainer}>
          {currentPage.lines.map((line: any, index: number) => renderLine(line, index))}
        </View>
      </ScrollView>

      {/* Bottom Action Bar */}
      <View style={styles.bottomBar}>
        <TouchableOpacity
          onPress={handlePreviousPage}
          style={[styles.navButton, currentPageIndex === 0 && { opacity: 0.5 }]}
          disabled={currentPageIndex === 0}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <ChevronRight size={24} color={Colors.primaryLight} />
        </TouchableOpacity>

        <View style={styles.centerControls}>
          {/* Microphone Toggle (Corrective Mode / Recitation) */}
          <TouchableOpacity 
            style={[styles.micButton, isListening && styles.micButtonActive]}
            onPress={() => setIsListening(!isListening)}
          >
            <Mic size={28} color={isListening ? Colors.backgroundDark : Colors.accent} />
          </TouchableOpacity>

          {/* Eye Toggle (Free Recitation - hides verses) */}
          <TouchableOpacity 
            style={styles.eyeButton}
            onPress={() => setIsHidden(!isHidden)}
          >
            {isHidden ? (
               <EyeOff size={24} color={Colors.accent} />
            ) : (
               <Eye size={24} color={Colors.textSecondary} />
            )}
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          onPress={handleNextPage}
          style={[styles.navButton, currentPageIndex === quranLayoutData.length - 1 && { opacity: 0.5 }]}
          disabled={currentPageIndex === quranLayoutData.length - 1}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <ChevronLeft size={24} color={Colors.primaryLight} />
        </TouchableOpacity>
      </View>

      {/* Qira'a Selector Bottom Sheet */}
      <BottomSheet
        visible={showQiraaSheet}
        onClose={() => setShowQiraaSheet(false)}
        title="Select Qira'a"
        height={450}
      >
        <ScrollView style={{ paddingVertical: Spacing.md }} showsVerticalScrollIndicator={false}>
          <QiraaSelector
            selected={qiraa}
            onSelect={(selected) => {
              setQiraa(selected);
              setShowQiraaSheet(false);
            }}
          />
        </ScrollView>
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
  qiraaBadge: {
    backgroundColor: Colors.backgroundSurface,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.borderLight,
  },
  qiraaBadgeText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textGold,
    fontWeight: '600',
  },
  surahHeader: {
    alignItems: 'center',
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  surahNameArabic: {
    fontFamily: 'DigitalKhattV1', // User custom font
    fontSize: Typography.size['2xl'],
    color: Colors.textGold,
    marginBottom: Spacing.xs,
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
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.lg,
  },
  mushafPageContainer: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.md,
    minHeight: Dimensions.get('window').height * 0.7,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  ayahLine: {
    flexDirection: 'row',
    width: '100%',
    height: 38, // Fixed height per line for perfect layout
    justifyContent: 'center',
    alignItems: 'center',
  },
  centeredLine: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  surahHeaderFrameContainer: {
    paddingHorizontal: Spacing.md,
    marginBottom: 10,
  },
  surahHeaderFrame: {
    borderWidth: 2,
    borderColor: Colors.textGold,
    paddingVertical: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  surahNameDecorated: {
    fontFamily: 'QPCHafs',
    fontSize: 28,
    color: Colors.textGold,
    textAlign: 'center',
  },
  basmallahContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
  basmallahText: {
    fontFamily: 'QPCHafs', 
    fontSize: 24,
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  mushafVerseText: {
    flex: 1,
    fontFamily: 'QPCHafs', 
    fontSize: 26, // Starts at 26, scales down to fit
    color: Colors.textPrimary,
    textAlign: 'justify',
    writingDirection: 'rtl',
    includeFontPadding: false,
  },
  hiddenText: {
    color: 'transparent',
  },
  bottomBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  navButton: {
    width: 48,
    height: 48,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.primaryLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  centerControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.lg,
  },
  micButton: {
    width: 56,
    height: 56,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    borderWidth: 2,
    borderColor: Colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  micButtonActive: {
    backgroundColor: Colors.accent,
  },
  eyeButton: {
    width: 48,
    height: 48,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default QuranPageViewerScreen;
