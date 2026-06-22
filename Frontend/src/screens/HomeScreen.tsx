import React from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles } from '../config/theme';
import { StreakWidget, Button, ModeCard } from '../components';
import { useAppStore } from '../store/appStore';

const HomeScreen: React.FC = () => {
  const user = useAppStore((state) => state.user);
  const navigation = useNavigation<any>();

  return (
    <ScrollView style={styles.container}>
      {/* Top bar */}
      <View style={styles.topBar}>
        <View style={styles.greeting}>
          <Text style={styles.greetingText}>
            السلام عليكم، {user?.name || 'Guest'}
          </Text>
        </View>
        <TouchableOpacity 
          style={styles.notificationIcon}
          onPress={() => navigation.navigate('Notifications')}
        >
          <Text style={styles.bell}>🔔</Text>
        </TouchableOpacity>
      </View>

      {/* Daily Streak Widget */}
      <View style={styles.section}>
        <StreakWidget days={14} goalDays={30} />
      </View>

      {/* Resume Reading Card */}
      <View style={styles.section}>
        <View style={GlobalStyles.cardBase}>
          <Text style={styles.cardLabel}>Continue reading</Text>
          <View style={styles.resumeContent}>
            <View style={styles.resumeText}>
              <Text style={styles.surahName}>سورة البقرة</Text>
              <Text style={styles.page}>Page 45 · Juz 1</Text>
            </View>
            <Button
              title="Resume"
              onPress={() => {}}
              size="small"
              variant="primary"
            />
          </View>
        </View>
      </View>

      {/* Daily Verse */}
      <View style={styles.section}>
        <View style={GlobalStyles.cardBase}>
          <Text style={styles.dailyVerseLabel}>Daily Verse</Text>
          <Text style={styles.arabicVerse}>
            بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
          </Text>
          <Text style={styles.translation}>
            In the name of Allah, the Most Gracious, the Most Merciful
          </Text>
          <View style={styles.verseReference}>
            <Text style={styles.referenceText}>Surah Al-Fatihah 1:1</Text>
          </View>
        </View>
      </View>

      {/* AI Modes Quick Access */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>AI Practice Modes</Text>
        
        <ModeCard
          mode="correcting"
          title="Correcting Mode"
          arabicTitle="وضع التصحيح"
          description="See the page, recite aloud"
          tag="For all levels"
          onPress={() => navigation.navigate('PreSessionSetup', { mode: 'correcting' })}
        />
        
        <ModeCard
          mode="ai_recitation"
          title="AI Recitation"
          arabicTitle="وضع الاستظهار"
          description="Recite from memory"
          tag="For memorizers"
          onPress={() => navigation.navigate('PreSessionSetup', { mode: 'ai_recitation' })}
        />
      </View>
    </ScrollView>
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
    paddingHorizontal: Spacing.screenPaddingHorizontal,
    paddingVertical: Spacing.lg,
  },
  greeting: {
    flex: 1,
  },
  greetingText: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textGold,
  },
  notificationIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.backgroundCard,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bell: {
    fontSize: 20,
  },
  section: {
    paddingHorizontal: Spacing.screenPaddingHorizontal,
    marginBottom: Spacing.lg,
  },
  cardLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  resumeContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  resumeText: {
    flex: 1,
  },
  surahName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  page: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  dailyVerseLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  arabicVerse: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['3xl'],
    lineHeight: Typography.size['3xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.md,
  },
  translation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  verseReference: {
    paddingTop: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  referenceText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textGold,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.md,
  },
});

export default HomeScreen;
