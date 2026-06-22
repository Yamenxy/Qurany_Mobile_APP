import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronLeft, Info, Play } from 'lucide-react-native';

const tajweedRules = [
  { id: 1, name: 'Ghunnah', arabic: 'غنة', color: '#4CAF50', description: 'Nasal sound held for 2 beats. Applies to Noon and Meem with Shaddah.', example: 'إِنَّ', transliteration: 'Inna' },
  { id: 2, name: 'Ikhfa', arabic: 'إخفاء', color: '#2196F3', description: 'Concealing the Noon sound. Tongue floats without touching the roof.', example: 'مِن قَبْلِ', transliteration: 'Min Qabli' },
  { id: 3, name: 'Qalqalah', arabic: 'قلقلة', color: '#F44336', description: 'Echoing sound when a Qalqalah letter has Sukoon. (ق، ط، ب، ج، د)', example: 'أَحَدٌ', transliteration: 'Ahad' },
  { id: 4, name: 'Idgham', arabic: 'إدغام', color: '#FF9800', description: 'Merging of Noon Sakinah or Tanween into the following letter.', example: 'مَن يَقُولُ', transliteration: 'May-yaqoolu' },
  { id: 5, name: 'Iqlab', arabic: 'إقلاب', color: '#9C27B0', description: 'Converting Noon Sakinah or Tanween into a Meem before a Baa.', example: 'مِن بَعْدِ', transliteration: 'Mim-ba\'di' },
];

const TajweedReferenceScreen: React.FC = () => {
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Tajweed Rules</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.infoBox}>
          <Info size={20} color={Colors.accent} />
          <Text style={styles.infoText}>
            Colors in the Quran Page Viewer correspond to these rules to help you recite correctly.
          </Text>
        </View>

        {tajweedRules.map((rule) => (
          <View key={rule.id} style={styles.ruleCard}>
            <View style={styles.ruleHeader}>
              <View style={[styles.colorDot, { backgroundColor: rule.color }]} />
              <View style={styles.ruleNameContainer}>
                <Text style={styles.ruleName}>{rule.name}</Text>
                <Text style={styles.ruleArabic}>{rule.arabic}</Text>
              </View>
            </View>
            
            <Text style={styles.ruleDescription}>{rule.description}</Text>
            
            <View style={styles.exampleContainer}>
              <Text style={styles.exampleLabel}>Example:</Text>
              <View style={styles.exampleBox}>
                <Text style={styles.exampleArabic}>{rule.example}</Text>
                <Text style={styles.exampleTransliteration}>{rule.transliteration}</Text>
                <TouchableOpacity style={styles.playButton}>
                  <Play size={16} color={Colors.accent} />
                </TouchableOpacity>
              </View>
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
  infoBox: {
    flexDirection: 'row',
    backgroundColor: Colors.backgroundSurface,
    padding: Spacing.md,
    borderRadius: BorderRadius.medium,
    alignItems: 'center',
    marginBottom: Spacing.lg,
    gap: Spacing.md,
  },
  infoText: {
    flex: 1,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    lineHeight: 20,
  },
  ruleCard: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  ruleHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  colorDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    marginRight: Spacing.md,
  },
  ruleNameContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ruleName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  ruleArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textGold,
  },
  ruleDescription: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
    lineHeight: 20,
  },
  exampleContainer: {
    backgroundColor: Colors.backgroundDark,
    borderRadius: BorderRadius.medium,
    padding: Spacing.md,
  },
  exampleLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    marginBottom: Spacing.sm,
  },
  exampleBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  exampleArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.xl,
    color: Colors.textPrimary,
  },
  exampleTransliteration: {
    flex: 1,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginLeft: Spacing.md,
  },
  playButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.backgroundSurface,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default TajweedReferenceScreen;
