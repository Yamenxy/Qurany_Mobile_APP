import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ViewStyle,
} from 'react-native';
import { Colors, Spacing, BorderRadius, Typography } from '../config/theme';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'small' | 'medium' | 'large';
  fullWidth?: boolean;
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
}

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'medium',
  fullWidth = false,
  disabled = false,
  loading = false,
  style,
}) => {
  const variantStyles = {
    primary: {
      backgroundColor: Colors.primaryLight,
      borderWidth: 0,
    },
    secondary: {
      backgroundColor: 'transparent',
      borderWidth: 1,
      borderColor: Colors.primaryLight,
    },
    ghost: {
      backgroundColor: 'transparent',
      borderWidth: 0,
    },
  };

  const sizeStyles = {
    small: {
      paddingVertical: Spacing.sm,
      paddingHorizontal: Spacing.md,
    },
    medium: {
      paddingVertical: Spacing.lg,
      paddingHorizontal: Spacing.xl,
    },
    large: {
      paddingVertical: Spacing.lg + 4,
      paddingHorizontal: Spacing.xl,
    },
  };

  const textSizes = {
    small: Typography.size.sm,
    medium: Typography.size.base,
    large: Typography.size.lg,
  };

  const textColors = {
    primary: Colors.textPrimary,
    secondary: Colors.primaryLight,
    ghost: Colors.textPrimary,
  };

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.7}
      style={[
        styles.button,
        variantStyles[variant],
        sizeStyles[size],
        fullWidth && styles.fullWidth,
        disabled && styles.disabled,
        style,
      ]}
    >
      <Text
        style={[
          styles.text,
          {
            fontSize: textSizes[size],
            color: disabled ? Colors.textSecondary : textColors[variant],
          },
        ]}
      >
        {loading ? 'Loading...' : title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    borderRadius: BorderRadius.medium,
    justifyContent: 'center',
    alignItems: 'center',
  },
  fullWidth: {
    width: '100%',
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    fontFamily: Typography.bodyFont,
    fontWeight: '600',
  },
});
