import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
} from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { Book, Check } from 'lucide-react-native';

interface Juz {
  number: number;
  surahs: string;
  status: 'not-started' | 'in-progress' | 'completed';
  progress: number;
  accuracy: number;
}

const mockJuzs: Juz[] = Array.from({ length: 30 }, (_, i) => ({
  number: i + 1,
  surahs: `Surah ${i + 1}...`,
  status: i < 5 ? 'completed' : i < 7 ? 'in-progress' : 'not-started',
  progress: i < 5 ? 100 : i < 7 ? Math.random() * 60 + 20 : 0,
  accuracy: i < 5 ? 92 + Math.random() * 8 : i < 7 ? 85 + Math.random() * 10 : 0,
}));

const HifzTrackerScreen: React.FC = () => {
  const completedJuzs = mockJuzs.filter((j) => j.status === 'completed').length;
  const totalProgress = Math.round(
    mockJuzs.reduce((sum, j) => sum + j.progress, 0) / mockJuzs.length
  );

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Hifz Tracker</Text>
        <Text style={styles.subtitle}>Your memorization journey</Text>
      </View>

      {/* Overall Progress */}
      <View style={styles.section}>
        <View style={styles.progressCard}>
          <View style={styles.progressHeader}>
            <View>
              <Text style={styles.progressLabel}>Overall Progress</Text>
              <Text style={styles.progressValue}>{totalProgress}%</Text>
            </View>
            <Text style={styles.progressIcon}>📖</Text>
          </View>

          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${totalProgress}%` }]} />
          </View>

          <Text style={styles.progressSubtitle}>
            {completedJuzs} of 30 Juzs completed
          </Text>
        </View>
      </View>

      {/* Stats */}
      <View style={styles.statsRow}>
        <StatBadge icon="🎯" label="Current Juz" value="7" />
        <StatBadge icon="✅" label="Completed" value={`${completedJuzs}/30`} />
        <StatBadge icon="⏳" label="Est. Completion" value="8 months" />
      </View>

      {/* Juzs Grid */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>All Juzs</Text>
        <FlatList
          data={mockJuzs}
          renderItem={({ item }) => <JuzCard juz={item} />}
          keyExtractor={(item) => item.number.toString()}
          scrollEnabled={false}
          numColumns={3}
          columnWrapperStyle={styles.gridRow}
          contentContainerStyle={styles.gridContent}
        />
      </View>
    </ScrollView>
  );
};

interface JuzCardProps {
  juz: Juz;
}

const JuzCard: React.FC<JuzCardProps> = ({ juz }) => {
  const statusColor =
    juz.status === 'completed'
      ? Colors.success
      : juz.status === 'in-progress'
        ? Colors.warning
        : Colors.borderLight;

  return (
    <TouchableOpacity
      style={[
        styles.juzCard,
        {
          borderColor: statusColor,
          borderWidth: juz.status === 'completed' ? 2 : 1,
        },
      ]}
      activeOpacity={0.7}
    >
      {juz.status === 'completed' && (
        <View style={styles.completedBadge}>
          <Check size={16} color={Colors.backgroundDark} />
        </View>
      )}

      <Text style={styles.juzNumber}>Juz {juz.number}</Text>

      {juz.status === 'in-progress' && (
        <View style={styles.miniProgressBar}>
          <View
            style={[styles.miniProgressFill, { width: `${juz.progress}%` }]}
          />
        </View>
      )}

      {juz.accuracy > 0 && (
        <Text style={styles.accuracy}>{Math.round(juz.accuracy)}%</Text>
      )}

      <Text
        style={[
          styles.status,
          {
            color:
              juz.status === 'completed'
                ? Colors.success
                : juz.status === 'in-progress'
                  ? Colors.warning
                  : Colors.textSecondary,
          },
        ]}
      >
        {juz.status === 'completed'
          ? 'Done'
          : juz.status === 'in-progress'
            ? 'In Progress'
            : 'Locked'}
      </Text>
    </TouchableOpacity>
  );
};

interface StatBadgeProps {
  icon: string;
  label: string;
  value: string;
}

const StatBadge: React.FC<StatBadgeProps> = ({ icon, label, value }) => (
  <View style={styles.statBadge}>
    <Text style={styles.statIcon}>{icon}</Text>
    <Text style={styles.statLabel}>{label}</Text>
    <Text style={styles.statValue}>{value}</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  subtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  section: {
    paddingHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
  },
  progressCard: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.accent,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  progressLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  progressValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '700',
    color: Colors.accent,
  },
  progressIcon: {
    fontSize: 40,
  },
  progressBar: {
    height: 8,
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    overflow: 'hidden',
    marginBottom: Spacing.lg,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.accent,
  },
  progressSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  statsRow: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  statBadge: {
    flex: 1,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  statIcon: {
    fontSize: 24,
    marginBottom: Spacing.sm,
  },
  statLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  statValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  gridContent: {
    paddingBottom: Spacing.lg,
  },
  gridRow: {
    justifyContent: 'space-between',
    marginBottom: Spacing.md,
  },
  juzCard: {
    width: '32%',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
    position: 'relative',
  },
  completedBadge: {
    position: 'absolute',
    top: Spacing.md,
    right: Spacing.md,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: Colors.success,
    justifyContent: 'center',
    alignItems: 'center',
  },
  juzNumber: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '700',
    color: Colors.textGold,
    marginBottom: Spacing.sm,
  },
  miniProgressBar: {
    width: '100%',
    height: 4,
    backgroundColor: Colors.backgroundSurface,
    borderRadius: 2,
    overflow: 'hidden',
    marginVertical: Spacing.sm,
  },
  miniProgressFill: {
    height: '100%',
    backgroundColor: Colors.warning,
  },
  accuracy: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.accent,
    marginBottom: Spacing.sm,
  },
  status: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    fontWeight: '500',
  },
});

export default HifzTrackerScreen;
