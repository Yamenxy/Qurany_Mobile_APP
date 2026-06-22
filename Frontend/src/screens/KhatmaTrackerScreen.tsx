import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { BookOpen, Plus } from 'lucide-react-native';

interface Khatma {
  id: string;
  name: string;
  startDate: string;
  progress: number;
  status: 'active' | 'completed' | 'paused';
  accuracy: number;
  daysSpent: number;
}

const mockKhatmas: Khatma[] = [
  {
    id: '1',
    name: 'My First Khatma',
    startDate: 'Jan 15, 2026',
    progress: 45,
    status: 'active',
    accuracy: 89,
    daysSpent: 32,
  },
  {
    id: '2',
    name: 'Tajweed Focus',
    startDate: 'Dec 1, 2025',
    progress: 100,
    status: 'completed',
    accuracy: 94,
    daysSpent: 78,
  },
  {
    id: '3',
    name: 'Daily Practice',
    startDate: 'Feb 1, 2026',
    progress: 20,
    status: 'paused',
    accuracy: 85,
    daysSpent: 15,
  },
];

const KhatmaTrackerScreen: React.FC = () => {
  const completedKhatmas = mockKhatmas.filter((k) => k.status === 'completed').length;

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>Khatma Tracker</Text>
          <Text style={styles.subtitle}>Complete Quran reading cycles</Text>
        </View>

        <TouchableOpacity style={styles.addButton}>
          <Plus size={24} color={Colors.backgroundDark} />
        </TouchableOpacity>
      </View>

      {/* Summary */}
      <View style={styles.section}>
        <View style={styles.summaryCard}>
          <View style={styles.summaryItem}>
            <Text style={styles.summaryLabel}>Completed Khatmas</Text>
            <Text style={styles.summaryValue}>{completedKhatmas}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryItem}>
            <Text style={styles.summaryLabel}>Current</Text>
            <Text style={styles.summaryValue}>1</Text>
          </View>
        </View>
      </View>

      {/* Active Khatma */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Active Khatma</Text>
        {mockKhatmas
          .filter((k) => k.status === 'active')
          .map((khatma) => (
            <KhatmaCard key={khatma.id} khatma={khatma} />
          ))}
      </View>

      {/* Other Khatmas */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Other Cycles</Text>
        {mockKhatmas
          .filter((k) => k.status !== 'active')
          .map((khatma) => (
            <KhatmaCard key={khatma.id} khatma={khatma} />
          ))}
      </View>
    </ScrollView>
  );
};

interface KhatmaCardProps {
  khatma: Khatma;
}

const KhatmaCard: React.FC<KhatmaCardProps> = ({ khatma }) => {
  const statusColors = {
    active: Colors.primaryLight,
    completed: Colors.success,
    paused: Colors.warning,
  };

  return (
    <TouchableOpacity style={styles.khatmaCard} activeOpacity={0.7}>
      <View style={styles.khatmaHeader}>
        <View>
          <Text style={styles.khatmaName}>{khatma.name}</Text>
          <Text style={styles.khatmaDate}>{khatma.startDate}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: statusColors[khatma.status] }]}>
          <Text style={styles.statusText}>
            {khatma.status === 'active' ? '📖' : khatma.status === 'completed' ? '✅' : '⏸️'}
          </Text>
        </View>
      </View>

      {/* Progress Bar */}
      <View style={styles.progressBar}>
        <View
          style={[
            styles.progressFill,
            { width: `${khatma.progress}%`, backgroundColor: statusColors[khatma.status] },
          ]}
        />
      </View>

      {/* Stats */}
      <View style={styles.khatmaStats}>
        <StatItem label="Progress" value={`${khatma.progress}%`} />
        <StatItem label="Accuracy" value={`${khatma.accuracy}%`} />
        <StatItem label="Days" value={khatma.daysSpent.toString()} />
      </View>
    </TouchableOpacity>
  );
};

interface StatItemProps {
  label: string;
  value: string;
}

const StatItem: React.FC<StatItemProps> = ({ label, value }) => (
  <View style={styles.statItem}>
    <Text style={styles.statLabel}>{label}</Text>
    <Text style={styles.statValue}>{value}</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
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
  addButton: {
    width: 44,
    height: 44,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  section: {
    paddingHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
  },
  summaryCard: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.lg,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  summaryItem: {
    flex: 1,
    alignItems: 'center',
  },
  summaryLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.sm,
  },
  summaryValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '700',
    color: Colors.accent,
  },
  divider: {
    width: 1,
    height: 40,
    backgroundColor: Colors.divider,
    marginHorizontal: Spacing.lg,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  khatmaCard: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  khatmaHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  khatmaName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  khatmaDate: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
  statusBadge: {
    width: 36,
    height: 36,
    borderRadius: BorderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statusText: {
    fontSize: 16,
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
    borderRadius: BorderRadius.full,
  },
  khatmaStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
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
});

export default KhatmaTrackerScreen;
