import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronLeft, Trophy, Star, Medal } from 'lucide-react-native';

const mockAchievements = [
  { id: 1, title: 'First Recitation', description: 'Complete your first AI recitation session.', icon: <Star size={24} color={Colors.accent} />, unlocked: true },
  { id: 2, title: '7-Day Streak', description: 'Recite Quran for 7 consecutive days.', icon: <Trophy size={24} color={Colors.accent} />, unlocked: true },
  { id: 3, title: 'Hafiz Beginner', description: 'Memorize your first Surah.', icon: <Medal size={24} color={Colors.textSecondary} />, unlocked: false },
];

const AchievementsScreen: React.FC = () => {
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Achievements</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {mockAchievements.map((ach) => (
          <View key={ach.id} style={[styles.card, !ach.unlocked && styles.lockedCard]}>
            <View style={[styles.iconWrapper, !ach.unlocked && styles.lockedIconWrapper]}>
              {ach.icon}
            </View>
            <View style={styles.textContainer}>
              <Text style={[styles.title, !ach.unlocked && styles.lockedText]}>{ach.title}</Text>
              <Text style={styles.description}>{ach.description}</Text>
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
  card: {
    flexDirection: 'row',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
  },
  lockedCard: {
    opacity: 0.6,
  },
  iconWrapper: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: Colors.backgroundSurface,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  lockedIconWrapper: {
    backgroundColor: Colors.backgroundDark,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.xs,
  },
  lockedText: {
    color: Colors.textSecondary,
  },
  description: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    lineHeight: 20,
  },
});

export default AchievementsScreen;
