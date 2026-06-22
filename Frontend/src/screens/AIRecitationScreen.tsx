import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Dimensions,
  ScrollView,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import * as Haptics from 'expo-haptics';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { MicWaveform, BottomSheet, Button, VerseCard } from '../components';
import { useAppStore } from '../store/appStore';
import { X, Play, Pause } from 'lucide-react-native';

interface Verse {
  surah: number;
  ayah: number;
  text: string;
  translation: string;
  surahName: string;
}

// Mock data - will be replaced with real data
const mockVerses: Verse[] = [
  {
    surah: 1,
    ayah: 1,
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
    surahName: 'Al-Fatihah',
  },
  {
    surah: 1,
    ayah: 2,
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    translation: 'All praise is due to Allah, Lord of the worlds',
    surahName: 'Al-Fatihah',
  },
  {
    surah: 1,
    ayah: 3,
    text: 'الرَّحْمَٰنِ الرَّحِيمِ',
    translation: 'The Most Gracious, the Most Merciful',
    surahName: 'Al-Fatihah',
  },
  {
    surah: 1,
    ayah: 4,
    text: 'مَالِكِ يَوْمِ الدِّينِ',
    translation: 'Master of the Day of Judgment',
    surahName: 'Al-Fatihah',
  },
];

const AIRecitationScreen: React.FC = () => {
  const navigation = useNavigation();
  const endSession = useAppStore((state) => state.endSession);

  const [currentVerseIndex, setCurrentVerseIndex] = useState(0);
  const [isListening, setIsListening] = useState(false);
  const [accuracy, setAccuracy] = useState(0);
  const [sessionActive, setSessionActive] = useState(true);
  const [showErrorSheet, setShowErrorSheet] = useState(false);
  const [errorDetails, setErrorDetails] = useState<{
    said: string;
    correct: string;
  } | null>(null);
  const [isPaused, setIsPaused] = useState(false);

  const currentVerse = mockVerses[currentVerseIndex];
  const progressPercentage = ((currentVerseIndex + 1) / mockVerses.length) * 100;
  const fadeAnim = React.useRef(new Animated.Value(1)).current;

  // Auto-start listening when screen loads
  useEffect(() => {
    startListening();
  }, []);

  const startListening = () => {
    setIsListening(true);
    // Simulate mic listening
    setTimeout(() => {
      // Randomly simulate correct or incorrect recitation
      const isCorrect = Math.random() > 0.3;
      handleRecitationResult(isCorrect);
    }, 2000);
  };

  const handleRecitationResult = (isCorrect: boolean) => {
    if (isCorrect) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setAccuracy((prev) => Math.min(prev + 10, 100));

      // Fade out current verse, advance to next
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }).start(() => {
        if (currentVerseIndex < mockVerses.length - 1) {
          setCurrentVerseIndex((prev) => prev + 1);
          fadeAnim.setValue(1);
          startListening();
        } else {
          // Session complete
          endSessionHandler();
        }
      });

      setIsListening(false);
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      setErrorDetails({
        said: 'وَإِيَّاكَ نَسْتَعِينُ',
        correct: currentVerse.text,
      });
      setShowErrorSheet(true);
      setIsListening(false);
    }
  };

  const handleRetry = () => {
    setShowErrorSheet(false);
    setErrorDetails(null);
    startListening();
  };

  const handleSkip = () => {
    setShowErrorSheet(false);
    setErrorDetails(null);
    if (currentVerseIndex < mockVerses.length - 1) {
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }).start(() => {
        setCurrentVerseIndex((prev) => prev + 1);
        fadeAnim.setValue(1);
        startListening();
      });
    } else {
      endSessionHandler();
    }
  };

  const endSessionHandler = () => {
    endSession(accuracy, currentVerseIndex + 1);
    navigation.navigate('SessionSummary' as never, {
      mode: 'ai_recitation',
      accuracy,
      versesCompleted: currentVerseIndex + 1,
    } as never);
  };

  return (
    <View style={styles.container}>
      {/* Top Bar */}
      <View style={styles.topBar}>
        <View>
          <Text style={styles.modeName}>AI Recitation</Text>
          <Text style={styles.surahInfo}>
            {currentVerse.surahName} • Ayah {currentVerseIndex + 1}/{mockVerses.length}
          </Text>
        </View>

        <View style={styles.topRight}>
          <View style={styles.accuracyBadge}>
            <Text style={styles.accuracyText}>{Math.round(accuracy)}%</Text>
          </View>

          <TouchableOpacity
            onPress={() => {
              endSessionHandler();
            }}
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

      {/* Main Content - Focused on Current Verse */}
      <ScrollView style={styles.mainContent} contentContainerStyle={styles.mainContentScroll}>
        <View style={styles.verseContainer}>
          {/* Previous Verse (Dimmed) */}
          {currentVerseIndex > 0 && (
            <View style={styles.previousVerse}>
              <Text style={styles.previousVerseText}>
                {mockVerses[currentVerseIndex - 1].text}
              </Text>
            </View>
          )}

          {/* Current Verse (Large, Animated) */}
          <Animated.View style={{ opacity: fadeAnim }}>
            <Text style={styles.currentVerseText}>{currentVerse.text}</Text>
            <Text style={styles.verseTranslation}>{currentVerse.translation}</Text>
          </Animated.View>

          {/* Listening Status */}
          <View style={styles.listeningStatus}>
            {isListening ? (
              <>
                <Text style={styles.listeningLabel}>Listening...</Text>
                <MicWaveform isActive={true} color={Colors.primaryLight} />
              </>
            ) : (
              <>
                <Text style={styles.listeningLabel}>Your turn — repeat this verse</Text>
                <MicWaveform isActive={false} color={Colors.textSecondary} />
              </>
            )}
          </View>
        </View>
      </ScrollView>

      {/* Bottom Controls */}
      <View style={styles.bottomControls}>
        <TouchableOpacity
          style={styles.controlButton}
          onPress={() => setIsPaused(!isPaused)}
        >
          {isPaused ? (
            <Play size={24} color={Colors.textPrimary} />
          ) : (
            <Pause size={24} color={Colors.textPrimary} />
          )}
        </TouchableOpacity>

        <View style={styles.spacer} />

        <TouchableOpacity
          style={styles.controlButton}
          onPress={() => {
            endSessionHandler();
          }}
        >
          <Text style={styles.endButtonText}>End</Text>
        </TouchableOpacity>
      </View>

      {/* Error Bottom Sheet */}
      <BottomSheet
        visible={showErrorSheet}
        onClose={() => setShowErrorSheet(false)}
        title="Let's Try Again"
        height={300}
      >
        {errorDetails && (
          <View>
            <View style={styles.errorBox}>
              <Text style={styles.errorLabel}>You said:</Text>
              <Text style={styles.errorText}>{errorDetails.said}</Text>
            </View>

            <View style={styles.errorBox}>
              <Text style={styles.correctLabel}>Correct:</Text>
              <Text style={styles.correctText}>{errorDetails.correct}</Text>
            </View>

            <TouchableOpacity style={styles.playButton}>
              <Play size={20} color={Colors.textGold} />
              <Text style={styles.playButtonText}>Play Correct Pronunciation</Text>
            </TouchableOpacity>

            <View style={styles.errorButtonContainer}>
              <Button
                title="Try Again"
                onPress={handleRetry}
                variant="primary"
                fullWidth
              />
              <Button
                title="Skip"
                onPress={handleSkip}
                variant="secondary"
                fullWidth
                style={{ marginTop: Spacing.md }}
              />
            </View>
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
    paddingVertical: Spacing.xl,
    paddingHorizontal: Spacing.lg,
  },
  verseContainer: {
    alignItems: 'center',
  },
  previousVerse: {
    marginBottom: Spacing.xl,
  },
  previousVerseText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.xl,
    lineHeight: Typography.size.xl * 2,
    color: Colors.textSecondary,
    opacity: 0.5,
    textAlign: 'center',
  },
  currentVerseText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['4xl'],
    lineHeight: Typography.size['4xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  verseTranslation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.xl,
  },
  listeningStatus: {
    alignItems: 'center',
    marginTop: Spacing.xl,
    paddingTop: Spacing.xl,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  listeningLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
  bottomControls: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
    gap: Spacing.lg,
  },
  controlButton: {
    width: 56,
    height: 56,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundCard,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.accent,
  },
  spacer: {
    flex: 1,
  },
  endButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.error,
  },
  errorBox: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    padding: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  errorLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.error,
    marginBottom: Spacing.xs,
  },
  errorText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textPrimary,
    textAlign: 'right',
  },
  correctLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.success,
    marginBottom: Spacing.xs,
  },
  correctText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textPrimary,
    textAlign: 'right',
  },
  playButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    paddingVertical: Spacing.md,
    marginBottom: Spacing.lg,
    gap: Spacing.sm,
  },
  playButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textGold,
  },
  errorButtonContainer: {
    marginTop: Spacing.lg,
  },
});

export default AIRecitationScreen;
