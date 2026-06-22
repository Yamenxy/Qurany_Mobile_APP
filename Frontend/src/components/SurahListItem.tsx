import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';

interface SurahListItemProps {
  surahNumber: number;
  arabicName: string;
  englishName: string;
  verseCount: number;
  juzNumber: number;
  onPress: () => void;
}

export const SurahListItem: React.FC<SurahListItemProps> = ({
  surahNumber,
  arabicName,
  englishName,
  verseCount,
  juzNumber,
  onPress,
}) => {
  return (
    <TouchableOpacity
      style={styles.container}
      onPress={onPress}
      activeOpacity={0.7}
    >
      {/* Number Badge */}
      <View style={styles.numberBadge}>
        <Text style={styles.number}>{surahNumber}</Text>
      </View>

      {/* Content */}
      <View style={styles.content}>
        <Text style={styles.arabicName}>{arabicName}</Text>
        <View style={styles.metadata}>
          <Text style={styles.englishName}>{englishName}</Text>
          <Text style={styles.verseCount}>{verseCount} verses</Text>
        </View>
      </View>

      {/* Juz Info */}
      <View style={styles.juzInfo}>
        <Text style={styles.juzLabel}>Juz {juzNumber}</Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  numberBadge: {
    width: 50,
    height: 50,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.lg,
  },
  number: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '700',
    color: Colors.backgroundDark,
  },
  content: {
    flex: 1,
  },
  arabicName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.xs,
  },
  metadata: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  englishName: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textPrimary,
  },
  verseCount: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  juzInfo: {
    marginLeft: Spacing.lg,
  },
  juzLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
});
