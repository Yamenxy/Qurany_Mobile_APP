import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronLeft, Flame, Target, Award, CheckCircle } from 'lucide-react-native';

const mockChallenges = [
  { id: 1, title: 'Recite 5 Verses', progress: 5, total: 5, reward: '10 Streak Points', completed: true },
  { id: 2, title: 'Listen to 10 Verses', progress: 3, total: 10, reward: 'Audio Learner Badge', completed: false },
  { id: 3, title: 'Use AI Teaching Mode', progress: 0, total: 1, reward: 'Perfect Pronunciation', completed: false },
];

const DailyChallengesScreen: React.FC = () => {
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Daily Challenges</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.streakBanner}>
          <Flame size={32} color={Colors.accent} />
          <View style={styles.streakTextContainer}>
            <Text style={styles.streakTitle}>14 Day Streak!</Text>
            <Text style={styles.streakSubtitle}>Complete challenges to keep it going.</Text>
          </View>
        </View>

        <Text style={styles.sectionTitle}>Today's Goals</Text>

        {mockChallenges.map((challenge) => (
          <View key={challenge.id} style={[styles.challengeCard, challenge.completed && styles.completedCard]}>
            <View style={styles.cardHeader}>
              <View style={styles.iconContainer}>
                {challenge.completed ? (
                  <CheckCircle size={24} color={Colors.success} />
                ) : (
                  <Target size={24} color={Colors.accent} />
                )}
              </View>
              <View style={styles.challengeInfo}>
                <Text style={styles.challengeTitle}>{challenge.title}</Text>
                <Text style={styles.challengeReward}>
                  <Award size={12} color={Colors.textGold} /> {challenge.reward}
                </Text>
              </View>
              <Text style={styles.progressText}>
                {challenge.progress}/{challenge.total}
              </Text>
            </View>
            
            <View style={styles.progressBarBg}>
              <View 
                style={[
                  styles.progressBarFill, 
                  { width: `${(challenge.progress / challenge.total) * 100}%` },
                  challenge.completed && { backgroundColor: Colors.success }
                ]} 
              />
            </View>
          </View>
        ))}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  headerTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  content: {
    padding: Spacing.lg,
  },
  streakBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    padding: Spacing.xl,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.accent,
    marginBottom: Spacing.xl,
  },
  streakTextContainer: {
    marginLeft: Spacing.lg,
  },
  streakTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  streakSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.md,
  },
  challengeCard: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  completedCard: {
    borderColor: Colors.success + '40', // 40 opacity
    backgroundColor: Colors.backgroundSurface,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.backgroundDark,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  challengeInfo: {
    flex: 1,
  },
  challengeTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  challengeReward: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textGold,
    marginTop: Spacing.xs,
    flexDirection: 'row',
    alignItems: 'center',
  },
  progressText: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.sm,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  progressBarBg: {
    height: 8,
    backgroundColor: Colors.backgroundDark,
    borderRadius: BorderRadius.full,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
  },
});

export default DailyChallengesScreen;
