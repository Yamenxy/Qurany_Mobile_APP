import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';

interface VerseCardProps {
  arabicText: string;
  translation: string;
  surahName: string;
  surahNumber: number;
  ayahNumber: number;
  onPress?: () => void;
  highlighted?: boolean;
  highlightColor?: 'success' | 'error' | 'warning';
}

export const VerseCard: React.FC<VerseCardProps> = ({
  arabicText,
  translation,
  surahName,
  surahNumber,
  ayahNumber,
  onPress,
  highlighted = false,
  highlightColor = 'success',
}) => {
  const highlightColorMap = {
    success: Colors.success,
    error: Colors.error,
    warning: Colors.warning,
  };

  const containerStyle = highlighted && {
    borderColor: highlightColorMap[highlightColor],
    borderWidth: 2,
  };

  return (
    <TouchableOpacity
      style={[styles.container, containerStyle]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      {/* Arabic Text */}
      <Text style={styles.arabicText}>{arabicText}</Text>

      {/* Translation */}
      <Text style={styles.translation}>{translation}</Text>

      {/* Footer: Reference */}
      <View style={styles.footer}>
        <View style={styles.referenceBadge}>
          <Text style={styles.referenceText}>
            {surahNumber}:{ayahNumber}
          </Text>
        </View>
        <Text style={styles.surahName}>{surahName}</Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  arabicText: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size['4xl'],
    lineHeight: Typography.size['4xl'] * 2.2,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.md,
  },
  translation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: Spacing.md,
    paddingTop: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  referenceBadge: {
    backgroundColor: Colors.accent,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
  },
  referenceText: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.sm,
    fontWeight: '500',
    color: Colors.backgroundDark,
  },
  surahName: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
});
