import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';

interface StreakWidgetProps {
  days: number;
  goalDays?: number;
}

export const StreakWidget: React.FC<StreakWidgetProps> = ({
  days,
  goalDays = 30,
}) => {
  const progress = Math.min(days / goalDays, 1);

  return (
    <View style={styles.container}>
      {/* Flame and Count */}
      <View style={styles.header}>
        <Text style={styles.flame}>🔥</Text>
        <View>
          <Text style={styles.count}>{days}</Text>
          <Text style={styles.label}>Day Streak</Text>
        </View>
      </View>

      {/* Progress Bar */}
      <View style={styles.progressBarContainer}>
        <View
          style={[
            styles.progressBarFill,
            { width: `${progress * 100}%` },
          ]}
        />
      </View>

      {/* Milestone info */}
      <Text style={styles.milestone}>
        {goalDays - days > 0
          ? `${goalDays - days} days to ${goalDays} day milestone!`
          : 'Milestone reached! 🎉'}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.accent,
    padding: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  flame: {
    fontSize: 40,
    marginRight: Spacing.md,
  },
  count: {
    fontFamily: Typography.headingFont,
    fontSize: 28,
    fontWeight: '700',
    color: Colors.textGold,
  },
  label: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  progressBarContainer: {
    height: 8,
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    marginBottom: Spacing.md,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: Colors.primaryLight,
  },
  milestone: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});
