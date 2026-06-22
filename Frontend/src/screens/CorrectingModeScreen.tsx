import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Dimensions,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import * as Haptics from 'expo-haptics';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { MicWaveform, BottomSheet, Button } from '../components';
import { useAppStore } from '../store/appStore';
import { X, Volume2, AlertCircle } from 'lucide-react-native';

interface VerseWord {
  word: string;
  status: 'correct' | 'incorrect' | 'pending' | 'skipped';
  translation?: string;
}

interface VerseData {
  surah: number;
  ayah: number;
  text: string;
  translation: string;
  words: VerseWord[];
  surahName: string;
}

// Mock data
const mockVerses: VerseData[] = [
  {
    surah: 1,
    ayah: 1,
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
    surahName: 'Al-Fatihah',
    words: [
      { word: 'بِسْمِ', status: 'pending' },
      { word: 'اللَّهِ', status: 'pending' },
      { word: 'الرَّحْمَٰنِ', status: 'pending' },
      { word: 'الرَّحِيمِ', status: 'pending' },
    ],
  },
  {
    surah: 1,
    ayah: 2,
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    translation: 'All praise is due to Allah, Lord of the worlds',
    surahName: 'Al-Fatihah',
    words: [
      { word: 'الْحَمْدُ', status: 'pending' },
      { word: 'لِلَّهِ', status: 'pending' },
      { word: 'رَبِّ', status: 'pending' },
      { word: 'الْعَالَمِينَ', status: 'pending' },
    ],
  },
];

const CorrectingModeScreen: React.FC = () => {
  const navigation = useNavigation();
  const endSession = useAppStore((state) => state.endSession);

  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const [verses, setVerses] = useState<VerseData[]>(mockVerses);
  const [isListening, setIsListening] = useState(true);
  const [accuracy, setAccuracy] = useState(100);
  const [errorCount, setErrorCount] = useState(0);
  const [showErrorSheet, setShowErrorSheet] = useState(false);
  const [errorDetails, setErrorDetails] = useState<{
    word: string;
    correction: string;
    count: number;
  } | null>(null);

  const currentVerse = verses[currentVerseIndex];
  const progressPercentage = ((currentVerseIndex + 1) / verses.length) * 100;
  const errorWords = currentVerse.words.filter((w) => w.status === 'incorrect');

  // Simulate listening
  useEffect(() => {
    const interval = setInterval(() => {
      simulateRecognition();
    }, 1500);

    return () => clearInterval(interval);
  }, [currentVerseIndex]);

  const simulateRecognition = () => {
    if (!isListening) return;

    // Randomly find a word to process
    const verseClone = { ...verses[currentVerseIndex] };
    const pendingWords = verseClone.words.filter((w) => w.status === 'pending');

    if (pendingWords.length === 0) {
      // Verse complete, move to next
      moveToNextVerse();
      return;
    }

    const randomWord = pendingWords[Math.floor(Math.random() * pendingWords.length)];
    const isCorrect = Math.random() > 0.2; // 80% correct

    if (isCorrect) {
      randomWord.status = 'correct';
      setAccuracy((prev) => Math.max(prev, (prev + 5) / 2));
    } else {
      randomWord.status = 'incorrect';
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);

      // Show error after 3 occurrences of the same error (as per spec)
      const errorCount = verseClone.words.filter(
        (w) => w.word === randomWord.word && w.status === 'incorrect'
      ).length;

      if (errorCount >= 3) {
        setErrorDetails({
          word: randomWord.word,
          correction: randomWord.word,
          count: errorCount,
        });
        setShowErrorSheet(true);
      }

      setErrorCount((prev) => prev + 1);
      setAccuracy((prev) => Math.max(prev - 10, 0));
    }

    // Update verses
    const updatedVerses = [...verses];
    updatedVerses[currentVerseIndex] = verseClone;
    setVerses(updatedVerses);
  };

  const moveToNextVerse = () => {
    if (currentVerseIndex < verses.length - 1) {
      setCurrentVerseIndex((prev) => prev + 1);
    } else {
      endSessionHandler();
    }
  };

  const endSessionHandler = () => {
    endSession(accuracy, currentVerseIndex + 1);
    navigation.navigate('SessionSummary' as never, {
      mode: 'correcting',
      accuracy: Math.round(accuracy),
      versesCompleted: currentVerseIndex + 1,
    } as never);
  };

  const getWordColor = (status: VerseWord['status']) => {
    switch (status) {
      case 'correct':
        return Colors.success;
      case 'incorrect':
        return Colors.error;
      default:
        return Colors.textPrimary;
    }
  };

  return (
    <View style={styles.container}>
      {/* Top Bar */}
      <View style={styles.topBar}>
        <View>
          <Text style={styles.modeName}>Correcting Mode</Text>
          <Text style={styles.surahInfo}>
            {currentVerse.surahName} • Ayah {currentVerseIndex + 1}/{verses.length}
          </Text>
        </View>

        <View style={styles.topRight}>
          <View style={styles.accuracyBadge}>
            <Text style={styles.accuracyText}>{Math.round(accuracy)}%</Text>
          </View>

          <TouchableOpacity
            onPress={() => endSessionHandler()}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <X size={24} color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Progress Bar */}
      <View style={styles.progressContainer}>
        <View
          style={[styles.progressBar, { width: `${progressPercentage}%` }]}
        />
      </View>

      {/* Main Content - Mushaf Page View */}
      <ScrollView style={styles.mainContent} contentContainerStyle={styles.mainContentScroll}>
        <View style={styles.verseContainer}>
          {/* Surah and Ayah Info */}
          <View style={styles.verseHeader}>
            <Text style={styles.surahName}>{currentVerse.surahName}</Text>
            <View style={styles.ayahBadge}>
              <Text style={styles.ayahNumber}>{currentVerse.ayah}</Text>
            </View>
          </View>

          {/* Verse Text with Word Status */}
          <View style={styles.verseTextContainer}>
            <Text style={styles.verseText}>
              {currentVerse.words.map((w, idx) => (
                <Text
                  key={idx}
                  style={{
                    color: getWordColor(w.status),
                    backgroundColor:
                      w.status === 'incorrect' ? Colors.error + '15' : 'transparent',
                  }}
                >
                  {w.word}
                  {idx < currentVerse.words.length - 1 ? ' ' : ''}
                </Text>
              ))}
            </Text>
          </View>

          {/* Translation */}
          <Text style={styles.translation}>{currentVerse.translation}</Text>

          {/* Listening Status */}
          <View style={styles.listeningStatus}>
            {isListening ? (
              <>
                <Text style={styles.listeningLabel}>Listening to your recitation...</Text>
                <MicWaveform isActive={true} color={Colors.primaryLight} />
              </>
            ) : (
              <>
                <Text style={styles.listeningLabel}>Paused</Text>
                <MicWaveform isActive={false} color={Colors.textSecondary} />
              </>
            )}
          </View>

          {/* Error Summary */}
          {errorCount > 0 && (
            <View style={styles.errorSummary}>
              <AlertCircle size={20} color={Colors.warning} />
              <Text style={styles.errorSummaryText}>
                {errorCount} error{errorCount !== 1 ? 's' : ''} detected in this verse
              </Text>
            </View>
          )}
        </View>
      </ScrollView>

      {/* Bottom Controls */}
      <View style={styles.bottomControls}>
        <Button
          title={isListening ? 'Pause' : 'Resume'}
          onPress={() => setIsListening(!isListening)}
          variant={isListening ? 'secondary' : 'primary'}
          size="medium"
        />

        <Button
          title="Skip Verse"
          onPress={moveToNextVerse}
          variant="ghost"
          size="medium"
          style={{ marginLeft: Spacing.md }}
        />

        <View style={styles.spacer} />

        <TouchableOpacity
          onPress={() => endSessionHandler()}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <X size={24} color={Colors.error} />
        </TouchableOpacity>
      </View>

      {/* Error Details Bottom Sheet */}
      <BottomSheet
        visible={showErrorSheet}
        onClose={() => setShowErrorSheet(false)}
        title="Word Repeated 3 Times"
        height={280}
      >
        {errorDetails && (
          <View>
            <View style={styles.errorBox}>
              <Text style={styles.errorLabel}>Word:</Text>
              <Text style={styles.errorWord}>{errorDetails.word}</Text>
            </View>

            <View style={styles.correctionBox}>
              <Text style={styles.correctionLabel}>Check this word</Text>
              <TouchableOpacity style={styles.playButton}>
                <Volume2 size={18} color={Colors.accent} />
                <Text style={styles.playButtonText}>Listen to Correct Pronunciation</Text>
              </TouchableOpacity>
            </View>

            <Button
              title="Continue Listening"
              onPress={() => setShowErrorSheet(false)}
              variant="primary"
              fullWidth
              style={{ marginTop: Spacing.lg }}
            />
          </View>
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
  modeName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textGold,
  },
  surahInfo: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  topRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.lg,
  },
  accuracyBadge: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderWidth: 1,
    borderColor: Colors.accent,
  },
  accuracyText: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '700',
    color: Colors.accent,
  },
  progressContainer: {
    height: 4,
    backgroundColor: Colors.backgroundSurface,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: Colors.primaryLight,
  },
  mainContent: {
    flex: 1,
  },
  mainContentScroll: {
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  verseContainer: {
    alignItems: 'center',
  },
  verseHeader: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  surahName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.sm,
  },
  ayahBadge: {
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  ayahNumber: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '700',
    color: Colors.backgroundDark,
  },
  verseTextContainer: {
    marginBottom: Spacing.lg,
    paddingHorizontal: Spacing.md,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    paddingVertical: Spacing.lg,
    borderWidth: 1,
    borderColor: Colors.accent,
  },
  verseText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['3xl'],
    lineHeight: Typography.size['3xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'right',
  },
  translation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  listeningStatus: {
    alignItems: 'center',
    marginVertical: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
    width: '100%',
  },
  listeningLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
  errorSummary: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    backgroundColor: Colors.warning + '15',
    borderRadius: BorderRadius.large,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    marginTop: Spacing.lg,
  },
  errorSummaryText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.warning,
  },
  bottomControls: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
    gap: Spacing.md,
  },
  spacer: {
    flex: 1,
  },
  errorBox: {
    backgroundColor: Colors.error + '15',
    borderRadius: BorderRadius.medium,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  errorLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.error,
    marginBottom: Spacing.xs,
  },
  errorWord: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.xl,
    color: Colors.textPrimary,
    textAlign: 'right',
  },
  correctionBox: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  correctionLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  playButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  playButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.accent,
  },
});

export default CorrectingModeScreen;
