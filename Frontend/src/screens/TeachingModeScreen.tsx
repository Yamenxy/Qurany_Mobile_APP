import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import * as Haptics from 'expo-haptics';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { MicWaveform, BottomSheet, Button } from '../components';
import { useAppStore } from '../store/appStore';
import { X, Volume2, Check, RotateCcw } from 'lucide-react-native';

interface TeachingVerse {
  surah: number;
  ayah: number;
  text: string;
  translation: string;
  surahName: string;
  isComplete: boolean;
}

// Mock data
const mockVerses: TeachingVerse[] = [
  {
    surah: 1,
    ayah: 1,
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
    surahName: 'Al-Fatihah',
    isComplete: false,
  },
  {
    surah: 1,
    ayah: 2,
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    translation: 'All praise is due to Allah, Lord of the worlds',
    surahName: 'Al-Fatihah',
    isComplete: false,
  },
];

type SessionPhase = 'sheikh-intro' | 'sheikh-reciting' | 'user-listening' | 'user-repeating' | 'result';

const TeachingModeScreen: React.FC = () => {
  const navigation = useNavigation();
  const endSession = useAppStore((state) => state.endSession);

  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const [verses, setVerses] = useState<TeachingVerse[]>(mockVerses);
  const [phase, setPhase] = useState<SessionPhase>('sheikh-intro');
  const [accuracy, setAccuracy] = useState(100);
  const [retryCount, setRetryCount] = useState(0);
  const [showResult, setShowResult] = useState(false);
  const [resultStatus, setResultStatus] = useState<'correct' | 'incorrect'>('correct');

  const currentVerse = verses[currentVerseIndex];
  const progressPercentage = ((currentVerseIndex + 1) / verses.length) * 100;

  // Simulate phase transitions
  useEffect(() => {
    if (phase === 'sheikh-intro') {
      const timer = setTimeout(() => setPhase('sheikh-reciting'), 1000);
      return () => clearTimeout(timer);
    }

    if (phase === 'sheikh-reciting') {
      const timer = setTimeout(() => setPhase('user-listening'), 3000);
      return () => clearTimeout(timer);
    }

    if (phase === 'user-listening') {
      const timer = setTimeout(() => setPhase('user-repeating'), 1500);
      return () => clearTimeout(timer);
    }

    if (phase === 'user-repeating') {
      const timer = setTimeout(() => {
        // Simulate recognition result
        const isCorrect = Math.random() > 0.4;
        setResultStatus(isCorrect ? 'correct' : 'incorrect');
        setShowResult(true);

        if (isCorrect) {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          setAccuracy((prev) => Math.max(prev - retryCount * 5, 60));
        } else {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
        }

        setPhase('result');
      }, 2500);

      return () => clearTimeout(timer);
    }
  }, [phase, retryCount]);

  const handleContinue = () => {
    if (resultStatus === 'correct') {
      // Mark verse as complete and move to next
      const updatedVerses = [...verses];
      updatedVerses[currentVerseIndex].isComplete = true;
      setVerses(updatedVerses);

      if (currentVerseIndex < verses.length - 1) {
        setCurrentVerseIndex((prev) => prev + 1);
        setRetryCount(0);
        setShowResult(false);
        setPhase('sheikh-intro');
      } else {
        endSessionHandler();
      }
    } else {
      // Incorrect - offer retry
      if (retryCount < 1) {
        // Allow one more retry
        setRetryCount((prev) => prev + 1);
        setShowResult(false);
        setPhase('sheikh-reciting');
      } else {
        // Max retries reached, show correction and move on
        setPhase('sheikh-reciting');
        const timer = setTimeout(() => {
          if (currentVerseIndex < verses.length - 1) {
            setCurrentVerseIndex((prev) => prev + 1);
            setRetryCount(0);
            setShowResult(false);
            setPhase('sheikh-intro');
          } else {
            endSessionHandler();
          }
        }, 3500);

        return () => clearTimeout(timer);
      }
    }
  };

  const endSessionHandler = () => {
    endSession(accuracy, currentVerseIndex + 1);
    navigation.navigate('SessionSummary' as never, {
      mode: 'teaching',
      accuracy: Math.round(accuracy),
      versesCompleted: currentVerseIndex + 1,
    } as never);
  };

  return (
    <View style={styles.container}>
      {/* Top Bar */}
      <View style={styles.topBar}>
        <View>
          <Text style={styles.modeName}>Teaching Mode</Text>
          <Text style={styles.sheikhInfo}>
            Sheikh Al-Husary • Verse {currentVerseIndex + 1}/{verses.length}
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

      {/* Main Content */}
      <ScrollView style={styles.mainContent} contentContainerStyle={styles.mainContentScroll}>
        <View style={styles.verseContainer}>
          {/* Phase Indicator */}
          <View style={styles.phaseIndicator}>
            {phase === 'sheikh-intro' && (
              <Text style={styles.phaseText}>Preparing Sheikh Al-Husary...</Text>
            )}
            {phase === 'sheikh-reciting' && (
              <View style={styles.sheikhRecitingContainer}>
                <View
                  style={[
                    styles.sheikhAvatar,
                    { opacity: 1, transform: [{ scale: 1.1 }] },
                  ]}
                >
                  <Text style={styles.avatar}>👨‍🎓</Text>
                </View>
                <Text style={styles.phaseText}>Sheikh Al-Husary is reciting...</Text>
                <MicWaveform isActive={true} color={Colors.accent} />
              </View>
            )}
            {phase === 'user-listening' && (
              <Text style={styles.phaseText}>Listen carefully...</Text>
            )}
            {(phase === 'user-repeating' || phase === 'result') && (
              <View style={styles.userRecitingContainer}>
                <Text style={styles.phaseText}>Your turn — repeat this verse</Text>
                <MicWaveform isActive={phase === 'user-repeating'} color={Colors.primaryLight} />
              </View>
            )}
          </View>

          {/* Verse Display */}
          <View style={styles.verseDisplay}>
            <Text style={styles.verseText}>{currentVerse.text}</Text>
            <Text style={styles.translation}>{currentVerse.translation}</Text>
          </View>

          {/* Result Feedback */}
          {showResult && (
            <View
              style={[
                styles.resultCard,
                resultStatus === 'correct'
                  ? styles.resultCorrect
                  : styles.resultIncorrect,
              ]}
            >
              {resultStatus === 'correct' ? (
                <>
                  <Check size={40} color={Colors.success} />
                  <Text style={styles.resultTitle}>Excellent!</Text>
                  <Text style={styles.resultMessage}>
                    You recited it perfectly. Let's continue!
                  </Text>
                </>
              ) : (
                <>
                  <RotateCcw size={40} color={Colors.warning} />
                  <Text style={styles.resultTitle}>Let's Try Again</Text>
                  <Text style={styles.resultMessage}>
                    {retryCount < 1
                      ? 'You can retry once more'
                      : 'Here is the correct pronunciation:'}
                  </Text>
                </>
              )}
            </View>
          )}

          {/* Retry Count */}
          {retryCount > 0 && (
            <Text style={styles.retryInfo}>Retry {retryCount} of 2</Text>
          )}
        </View>
      </ScrollView>

      {/* Bottom Action */}
      {phase === 'result' && showResult && (
        <View style={styles.actionContainer}>
          <Button
            title={resultStatus === 'correct' ? 'Next Verse →' : 'Continue'}
            onPress={handleContinue}
            variant="primary"
            fullWidth
            size="large"
          />

          {resultStatus === 'incorrect' && (
            <TouchableOpacity style={styles.playCorrectButton}>
              <Volume2 size={20} color={Colors.accent} />
              <Text style={styles.playCorrectText}>Play Correct Pronunciation</Text>
            </TouchableOpacity>
          )}
        </View>
      )}
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
  sheikhInfo: {
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
    paddingVertical: Spacing.xl,
    paddingHorizontal: Spacing.lg,
  },
  verseContainer: {
    alignItems: 'center',
  },
  phaseIndicator: {
    width: '100%',
    marginBottom: Spacing.xl,
    alignItems: 'center',
  },
  phaseText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.lg,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  sheikhRecitingContainer: {
    alignItems: 'center',
    gap: Spacing.lg,
  },
  userRecitingContainer: {
    alignItems: 'center',
    gap: Spacing.lg,
  },
  sheikhAvatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatar: {
    fontSize: 48,
  },
  verseDisplay: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 2,
    borderColor: Colors.accent,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.xl,
    marginBottom: Spacing.xl,
    width: '100%',
  },
  verseText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['3xl'],
    lineHeight: Typography.size['3xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  translation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  resultCard: {
    width: '100%',
    borderRadius: BorderRadius.large,
    paddingVertical: Spacing.xl,
    paddingHorizontal: Spacing.lg,
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  resultCorrect: {
    backgroundColor: Colors.success + '15',
    borderWidth: 1,
    borderColor: Colors.success,
  },
  resultIncorrect: {
    backgroundColor: Colors.warning + '15',
    borderWidth: 1,
    borderColor: Colors.warning,
  },
  resultTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginTop: Spacing.md,
    marginBottom: Spacing.sm,
  },
  resultMessage: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  retryInfo: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.warning,
  },
  actionContainer: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  playCorrectButton: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTopmarginTop: Spacing.lg,
    gap: Spacing.md,
  },
  playCorrectText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.accent,
  },
});

export default TeachingModeScreen;
