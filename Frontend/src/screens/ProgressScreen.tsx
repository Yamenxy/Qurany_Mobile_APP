import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { AccuracyRing, StreakWidget, Button } from '../components';
import { useNavigation } from '@react-navigation/native';
import { BarChart3, Calendar, Flame, BookOpen } from 'lucide-react-native';

interface SessionStat {
  date: string;
  accuracy: number;
  duration: number;
  versesCompleted: number;
}

const ProgressScreen: React.FC = () => {
  const [timeFrame, setTimeFrame] = useState<'week' | 'month' | 'year'>('week');
  const navigation = useNavigation<any>();

  // Mock data
  const stats: SessionStat[] = [
    { date: 'Mon', accuracy: 92, duration: 15, versesCompleted: 5 },
    { date: 'Tue', accuracy: 88, duration: 12, versesCompleted: 4 },
    { date: 'Wed', accuracy: 95, duration: 18, versesCompleted: 6 },
    { date: 'Thu', accuracy: 87, duration: 10, versesCompleted: 3 },
    { date: 'Fri', accuracy: 91, duration: 14, versesCompleted: 5 },
    { date: 'Sat', accuracy: 94, duration: 20, versesCompleted: 7 },
    { date: 'Sun', accuracy: 89, duration: 11, versesCompleted: 4 },
  ];

  const averageAccuracy = Math.round(stats.reduce((sum, s) => sum + s.accuracy, 0) / stats.length);
  const totalSessions = stats.length;
  const totalDuration = stats.reduce((sum, s) => sum + s.duration, 0);
  const totalVerses = stats.reduce((sum, s) => sum + s.versesCompleted, 0);

  const maxAccuracy = Math.max(...stats.map((s) => s.accuracy));

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Progress</Text>
        <Text style={styles.subtitle}>Your Quranic journey</Text>
      </View>

      {/* Streak Widget & Daily Challenges */}
      <View style={styles.section}>
        <StreakWidget days={14} goalDays={30} />
        <View style={{ marginTop: Spacing.md }}>
          <Button
            title="View Daily Challenges"
            variant="secondary"
            onPress={() => navigation.navigate('DailyChallenges')}
          />
        </View>
      </View>

      {/* Main Stats Cards */}
      <View style={styles.statsGrid}>
        <StatCard
          icon="📊"
          label="Average Accuracy"
          value={`${averageAccuracy}%`}
          color={Colors.primaryLight}
        />
        <StatCard
          icon="⏱️"
          label="Total Time"
          value={`${totalDuration}h`}
          color={Colors.warning}
        />
        <StatCard
          icon="📖"
          label="Verses Completed"
          value={totalVerses.toString()}
          color={Colors.success}
        />
        <StatCard
          icon="🎯"
          label="Sessions"
          value={totalSessions.toString()}
          color={Colors.accent}
        />
      </View>

      {/* Weekly Accuracy Chart */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Weekly Performance</Text>
          <View style={styles.timeFramePills}>
            {(['week', 'month', 'year'] as const).map((tf) => (
              <TouchableOpacity
                key={tf}
                style={[
                  styles.timeFramePill,
                  timeFrame === tf && styles.timeFramePillActive,
                ]}
                onPress={() => setTimeFrame(tf)}
              >
                <Text
                  style={[
                    styles.timeFrameText,
                    timeFrame === tf && styles.timeFrameTextActive,
                  ]}
                >
                  {tf === 'week' ? 'W' : tf === 'month' ? 'M' : 'Y'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Chart */}
        <View style={styles.chartContainer}>
          <View style={styles.chartYAxis}>
            <Text style={styles.yAxisLabel}>100%</Text>
            <Text style={styles.yAxisLabel}>75%</Text>
            <Text style={styles.yAxisLabel}>50%</Text>
            <Text style={styles.yAxisLabel}>0%</Text>
          </View>

          <View style={styles.chartBars}>
            {stats.map((stat, idx) => (
              <View key={idx} style={styles.barContainer}>
                <View style={styles.barBackground}>
                  <View
                    style={[
                      styles.bar,
                      {
                        height: `${(stat.accuracy / 100) * 120}%`,
                        backgroundColor:
                          stat.accuracy >= 90
                            ? Colors.success
                            : stat.accuracy >= 80
                              ? Colors.primaryLight
                              : Colors.warning,
                      },
                    ]}
                  />
                </View>
                <Text style={styles.barLabel}>{stat.date}</Text>
              </View>
            ))}
          </View>
        </View>
      </View>

      {/* Session Details */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>This Week</Text>
        {stats.map((stat, idx) => (
          <View key={idx} style={styles.sessionItem}>
            <View>
              <Text style={styles.sessionDay}>{stat.date}</Text>
              <Text style={styles.sessionAccuracy}>{stat.accuracy}% accuracy</Text>
            </View>
            <View style={styles.sessionDetails}>
              <View style={styles.detailBadge}>
                <Text style={styles.detailText}>{stat.duration}m</Text>
              </View>
              <View style={styles.detailBadge}>
                <Text style={styles.detailText}>{stat.versesCompleted}</Text>
              </View>
            </View>
          </View>
        ))}
      </View>
    </ScrollView>
  );
};

interface StatCardProps {
  icon: string;
  label: string;
  value: string;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ icon, label, value, color }) => (
  <View
    style={[
      styles.statCard,
      {
        borderColor: color,
        borderWidth: 1,
      },
    ]}
  >
    <Text style={styles.statIcon}>{icon}</Text>
    <Text style={styles.statValue}>{value}</Text>
    <Text style={styles.statLabel}>{label}</Text>
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
    marginTop: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  statIcon: {
    fontSize: 28,
    marginBottom: Spacing.sm,
  },
  statValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  statLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  timeFramePills: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  timeFramePill: {
    width: 32,
    height: 32,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  timeFramePillActive: {
    backgroundColor: Colors.accent,
    borderColor: Colors.accent,
  },
  timeFrameText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  timeFrameTextActive: {
    color: Colors.backgroundDark,
  },
  chartContainer: {
    flexDirection: 'row',
    height: 160,
    marginBottom: Spacing.lg,
    gap: Spacing.md,
  },
  chartYAxis: {
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    paddingVertical: Spacing.sm,
    marginRight: Spacing.md,
  },
  yAxisLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
  chartBars: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    borderLeftWidth: 1,
    borderBottomWidth: 1,
    borderColor: Colors.divider,
    paddingLeft: Spacing.md,
    paddingBottom: Spacing.md,
  },
  barContainer: {
    flex: 1,
    alignItems: 'center',
    gap: Spacing.sm,
  },
  barBackground: {
    flex: 1,
    width: '70%',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.small,
    overflow: 'hidden',
    justifyContent: 'flex-end',
  },
  bar: {
    width: '100%',
    borderRadius: BorderRadius.small,
  },
  barLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
  sessionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  sessionDay: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  sessionAccuracy: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  sessionDetails: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  detailBadge: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  detailText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
});

export default ProgressScreen;
