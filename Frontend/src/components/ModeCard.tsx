import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';
import {
  Eye,
  Mic,
  Headphones,
} from 'lucide-react-native';

interface ModeCardProps {
  mode: 'correcting' | 'ai_recitation' | 'teaching';
  title: string;
  arabicTitle: string;
  description: string;
  tag: string;
  onPress: () => void;
}

export const ModeCard: React.FC<ModeCardProps> = ({
  mode,
  title,
  arabicTitle,
  description,
  tag,
  onPress,
}) => {
  // Determine icon and accent color based on mode
  const modeConfig = {
    correcting: {
      icon: Eye,
      accentColor: '#9B6BA8', // Purple tint
    },
    ai_recitation: {
      icon: Mic,
      accentColor: '#4CAF7D', // Teal/green
    },
    teaching: {
      icon: Headphones,
      accentColor: '#F0A500', // Amber/gold
    },
  };

  const config = modeConfig[mode];
  const IconComponent = config.icon;

  return (
    <TouchableOpacity
      style={[styles.container, { borderColor: config.accentColor }]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      {/* Icon */}
      <View style={styles.iconContainer}>
        <IconComponent size={40} color={config.accentColor} strokeWidth={1.5} />
      </View>

      {/* Content */}
      <View style={styles.content}>
        {/* Titles */}
        <Text style={styles.arabicTitle}>{arabicTitle}</Text>
        <Text style={styles.title}>{title}</Text>

        {/* Description */}
        <Text style={styles.description}>{description}</Text>

        {/* Tag */}
        <View style={[styles.tag, { backgroundColor: config.accentColor + '20' }]}>
          <Text style={[styles.tagText, { color: config.accentColor }]}>
            {tag}
          </Text>
        </View>
      </View>

      {/* CTA Arrow */}
      <View style={styles.ctaContainer}>
        <Text style={styles.cta}>→</Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 2,
    padding: Spacing.lg,
    marginBottom: Spacing.lg,
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  iconContainer: {
    width: 60,
    height: 60,
    borderRadius: BorderRadius.large,
    backgroundColor: Colors.backgroundSurface,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.lg,
  },
  content: {
    flex: 1,
  },
  arabicTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.xs,
  },
  title: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  description: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  tag: {
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    alignSelf: 'flex-start',
  },
  tagText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    fontWeight: '500',
  },
  ctaContainer: {
    marginLeft: Spacing.md,
    justifyContent: 'center',
    alignItems: 'center',
    height: 60,
  },
  cta: {
    fontSize: 24,
    color: Colors.textGold,
    fontWeight: '300',
  },
});
