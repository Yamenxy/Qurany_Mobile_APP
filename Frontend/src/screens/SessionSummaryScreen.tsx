import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { AccuracyRing, Button, VerseCard } from '../components';
import { Flame, Share2 } from 'lucide-react-native';

type SessionSummaryRouteProps = RouteProp<
  {
    SessionSummary: {
      mode: 'correcting' | 'ai_recitation' | 'teaching';
      accuracy: number;
      versesCompleted: number;
    };
  },
  'SessionSummary'
>;

interface MistakeVerse {
  surah: number;
  ayah: number;
  text: string;
  errorType: 'substitution' | 'omission' | 'addition';
}

const SessionSummaryScreen: React.FC = () => {
  const navigation = useNavigation();
  const route = useRoute<SessionSummaryRouteProps>();

  const {
    mode = 'ai_recitation',
    accuracy = 87,
    versesCompleted = 4,
  } = route.params || {};

  // Mock mistake verses
  const mistakeVerses: MistakeVerse[] = [
    {
      surah: 1,
      ayah: 2,
      text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      errorType: 'substitution',
    },
    {
      surah: 1,
      ayah: 4,
      text: 'مَالِكِ يَوْمِ الدِّينِ',
      errorType: 'omission',
    },
  ];

  const timeSpent = Math.floor(Math.random() * 20) + 5; // 5-25 minutes
  const streakIncreased = Math.random() > 0.5;
  const modeLabel =
    mode === 'correcting'
      ? 'Correcting Mode'
      : mode === 'ai_recitation'
        ? 'AI Recitation'
        : 'Teaching Mode';

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Session Complete!</Text>
        <Text style={styles.modeLabel}>{modeLabel}</Text>
      </View>

      {/* Accuracy Ring */}
      <View style={styles.accuracySection}>
        <AccuracyRing percentage={accuracy} size={220} label="Overall Accuracy" />
      </View>

      {/* Streak Update */}
      {streakIncreased && (
        <View style={styles.streakBanner}>
          <Flame size={24} color={Colors.accent} />
          <Text style={styles.streakText}>Streak updated to 15 days! 🎉</Text>
        </View>
      )}

      {/* Stats Cards */}
      <View style={styles.statsContainer}>
        <StatCard label="Verses Completed" value={versesCompleted.toString()} />
        <StatCard
          label="Time Spent"
          value={`${timeSpent}m`}
          accent={Colors.warning}
        />
        <StatCard label="Errors" value={mistakeVerses.length.toString()} />
      </View>

      {/* Mistakes Section */}
      {mistakeVerses.length > 0 && (
        <View style={styles.mistakesSection}>
          <Text style={styles.sectionTitle}>Mistakes to Review</Text>
          <Text style={styles.sectionSubtitle}>
            Work on these verses to improve
          </Text>

          {mistakeVerses.map((mistake, idx) => (
            <View key={idx} style={styles.mistakeItem}>
              <View style={styles.mistakeHeader}>
                <Text style={styles.mistakeRef}>
                  {mistake.surah}:{mistake.ayah}
                </Text>
                <View style={styles.errorTypeBadge}>
                  <Text style={styles.errorTypeText}>{mistake.errorType}</Text>
                </View>
              </View>
              <Text style={styles.mistakeText}>{mistake.text}</Text>
              <TouchableOpacity style={styles.playMistake}>
                <Text style={styles.playIcon}>🔊</Text>
                <Text style={styles.playText}>Play Correct</Text>
              </TouchableOpacity>
            </View>
          ))}
        </View>
      )}

      {/* Action Buttons */}
      <View style={styles.actionContainer}>
        <Button
          title="Retry Mistakes"
          onPress={() => navigation.navigate('Home' as never)}
          variant="primary"
          fullWidth
          size="large"
        />

        <Button
          title="Continue from Here"
          onPress={() => navigation.navigate('Home' as never)}
          variant="secondary"
          fullWidth
          size="large"
          style={{ marginTop: Spacing.md }}
        />

        <TouchableOpacity style={styles.shareButton}>
          <Share2 size={20} color={Colors.accent} />
          <Text style={styles.shareText}>Share Session</Text>
        </TouchableOpacity>
      </View>

      {/* Return Home Button */}
      <TouchableOpacity
        style={styles.homeButton}
        onPress={() => navigation.navigate('Home' as never)}
      >
        <Text style={styles.homeButtonText}>← Back to Home</Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

interface StatCardProps {
  label: string;
  value: string;
  accent?: string;
}

const StatCard: React.FC<StatCardProps> = ({
  label,
  value,
  accent = Colors.primaryLight,
}) => (
  <View style={styles.statCard}>
    <Text style={styles.statValue}>{value}</Text>
    <Text style={styles.statLabel}>{label}</Text>
    <View style={[styles.statAccent, { backgroundColor: accent }]} />
  </View>
);

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  headerTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '700',
    color: Colors.textGold,
    marginBottom: Spacing.sm,
  },
  modeLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
  },
  accuracySection: {
    paddingVertical: Spacing.xl,
    alignItems: 'center',
  },
  streakBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.accent,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    gap: Spacing.md,
  },
  streakText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.accent,
    flex: 1,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.xl,
    gap: Spacing.md,
  },
  statCard: {
    flex: 1,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: Spacing.lg,
    alignItems: 'center',
  },
  statValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  statLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  statAccent: {
    width: 24,
    height: 4,
    borderRadius: 2,
  },
  mistakesSection: {
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.xl,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  sectionSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
  mistakeItem: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.error + '30',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
  },
  mistakeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  mistakeRef: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.error,
    fontWeight: '600',
  },
  errorTypeBadge: {
    backgroundColor: Colors.error + '20',
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  errorTypeText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.error,
    fontWeight: '500',
  },
  mistakeText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.md,
    lineHeight: Typography.size.lg * 2,
  },
  playMistake: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  playIcon: {
    fontSize: 18,
  },
  playText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.accent,
  },
  actionContainer: {
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.xl,
  },
  shareButton: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.lg,
    paddingVertical: Spacing.md,
    gap: Spacing.sm,
  },
  shareText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.accent,
  },
  homeButton: {
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
    paddingVertical: Spacing.lg,
    alignItems: 'center',
  },
  homeButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.primaryLight,
  },
});

export default SessionSummaryScreen;
