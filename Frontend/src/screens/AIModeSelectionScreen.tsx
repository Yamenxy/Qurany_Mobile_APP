import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles } from '../config/theme';
import { ModeCard } from '../components';

const AIModeSelectionScreen: React.FC = () => {
  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>AI Modes</Text>
        <Text style={styles.subtitle}>Choose how you want to practice</Text>

        {/* Correcting Mode */}
        <ModeCard
          mode="correcting"
          title="Correcting Mode"
          arabicTitle="وضع التصحيح"
          description="See the page, recite aloud — AI corrects you in real time"
          tag="For all levels"
          onPress={() => {}}
        />

        {/* AI Recitation */}
        <ModeCard
          mode="ai_recitation"
          title="AI Recitation"
          arabicTitle="وضع الاستظهار"
          description="Recite from memory — verse appears as you recite correctly"
          tag="For memorizers"
          onPress={() => {}}
        />

        {/* Teaching Mode */}
        <ModeCard
          mode="teaching"
          title="Teaching Mode"
          arabicTitle="وضع المعلم"
          description="Sheikh recites, you repeat — AI decides when to move forward"
          tag="For beginners & children"
          onPress={() => {}}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: GlobalStyles.screenContainer,
  content: {
    ...GlobalStyles.screenPadding,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  subtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
});

export default AIModeSelectionScreen;
