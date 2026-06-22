import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';
import { Check } from 'lucide-react-native';

interface QiraaSelectorProps {
  selected: 'hafs' | 'warsh' | 'qalun';
  onSelect: (qiraa: 'hafs' | 'warsh' | 'qalun') => void;
}

const qiraaOptions = [
  {
    id: 'hafs',
    name: 'Hafs',
    arabicName: 'حفص عن عاصم',
    description: 'Most widely used',
  },
  {
    id: 'warsh',
    name: 'Warsh',
    arabicName: 'ورش عن نافع',
    description: 'North African tradition',
  },
  {
    id: 'qalun',
    name: 'Qalun',
    arabicName: 'قالون عن نافع',
    description: 'Classical tradition',
  },
];

export const QiraaSelector: React.FC<QiraaSelectorProps> = ({
  selected,
  onSelect,
}) => {
  return (
    <View style={styles.container}>
      {qiraaOptions.map((option) => (
        <TouchableOpacity
          key={option.id}
          style={[
            styles.card,
            selected === option.id && styles.cardSelected,
          ]}
          onPress={() => onSelect(option.id as 'hafs' | 'warsh' | 'qalun')}
          activeOpacity={0.8}
        >
          {/* Checkmark */}
          {selected === option.id && (
            <View style={styles.checkmark}>
              <Check size={20} color={Colors.textGold} strokeWidth={3} />
            </View>
          )}

          {/* Content */}
          <View style={styles.content}>
            <Text style={styles.arabicName}>{option.arabicName}</Text>
            <Text style={styles.name}>{option.name}</Text>
            <Text style={styles.description}>{option.description}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  card: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    borderWidth: 2,
    borderColor: Colors.borderLight,
    padding: Spacing.lg,
    position: 'relative',
  },
  cardSelected: {
    borderColor: Colors.accent,
    backgroundColor: Colors.backgroundCard,
  },
  checkmark: {
    position: 'absolute',
    top: Spacing.md,
    right: Spacing.md,
    width: 28,
    height: 28,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.accent + '20',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    paddingRight: Spacing.lg,
  },
  arabicName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.xs,
  },
  name: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  description: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
});
