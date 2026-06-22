/**
 * Qurany Design System
 * Complete color palette, typography, spacing, and reusable style constants
 */

export const Colors = {
  // Primary colors
  primary: '#1A6B4A', // Primary Green
  primaryLight: '#2D9E72', // Primary Green Light
  accent: '#C9A84C', // Accent Gold
  accentDark: '#A88A3A', // Darker gold for hover states

  // Backgrounds
  backgroundDark: '#0D1F17', // Main background
  backgroundCard: '#152A1E', // Card background
  backgroundSurface: '#1E3828', // Input field / secondary surfaces
  backgroundOverlay: 'rgba(13, 31, 23, 0.8)', // Modal overlay

  // Text colors
  textPrimary: '#F0EDE4', // Warm off-white
  textSecondary: '#9BB5A4', // Muted labels
  textGold: '#C9A84C', // Verse references
  textError: '#E05252', // Error/wrong

  // Semantic colors
  success: '#4CAF7D', // Correct recitation highlight
  error: '#E05252', // Wrong recitation highlight
  warning: '#F0A500', // Partial/needs improvement

  // UI elements
  divider: '#243D2E', // Subtle separators
  border: '#C9A84C15', // Gold border with transparency (15%)
  borderLight: '#9BB5A41F', // Light muted border
};

export const Typography = {
  // Font families
  arabicFont: 'Amiri', // For Quranic Arabic text
  headingFont: 'Cairo', // For headings
  bodyFont: 'Inter', // For UI body text

  // Font sizes (in pixels)
  size: {
    xs: 11,
    sm: 12,
    base: 15,
    lg: 18,
    xl: 22,
    '2xl': 24,
    '3xl': 28,
    '4xl': 32,
  },

  // Text styles
  styles: {
    // Arabic verse text (large, readable)
    arabicVerse: {
      fontFamily: 'Amiri',
      fontSize: 32,
      lineHeight: 2.2,
      color: Colors.textPrimary,
    },

    // Arabic headings
    arabicHeading: {
      fontFamily: 'Cairo',
      fontSize: 22,
      fontWeight: '700',
      color: Colors.textPrimary,
    },

    // English H1
    h1: {
      fontFamily: 'Inter',
      fontSize: 24,
      fontWeight: '600',
      color: Colors.textPrimary,
    },

    // English H2
    h2: {
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: '600',
      color: Colors.textPrimary,
    },

    // Body text
    body: {
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: '400',
      color: Colors.textPrimary,
    },

    // Caption / label
    caption: {
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: '400',
      color: Colors.textSecondary,
    },

    // Verse reference badge
    badge: {
      fontFamily: 'Cairo',
      fontSize: 12,
      fontWeight: '500',
      color: Colors.textGold,
    },
  },
};

export const Spacing = {
  // Base unit: 8px
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  '2xl': 24,
  '3xl': 32,
  '4xl': 40,
  '5xl': 48,

  // Common screen padding
  screenPadding: 20,
  screenPaddingHorizontal: 20,
  screenPaddingVertical: 16,
};

export const BorderRadius = {
  small: 8,
  medium: 12,
  large: 16,
  full: 999,
};

export const Shadows = {
  // Subtle elevation with border instead of harsh shadow
  card: {
    backgroundColor: Colors.backgroundCard,
    borderColor: Colors.border,
    borderWidth: 1,
  },

  // Elevated card
  elevated: {
    backgroundColor: Colors.backgroundCard,
    borderColor: Colors.border,
    borderWidth: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
};

export const AnimationTimings = {
  fast: 200,
  normal: 300,
  slow: 500,
};

// Reusable style objects
export const GlobalStyles = {
  screenContainer: {
    flex: 1,
    backgroundColor: Colors.backgroundDark,
  },

  screenPadding: {
    paddingHorizontal: Spacing.screenPaddingHorizontal,
    paddingVertical: Spacing.screenPaddingVertical,
  },

  cardBase: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    padding: Spacing.lg,
  },

  inputBase: {
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    color: Colors.textPrimary,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
  },

  buttonPrimary: {
    backgroundColor: Colors.primaryLight,
    borderRadius: BorderRadius.medium,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },

  buttonSecondary: {
    backgroundColor: 'transparent',
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.primaryLight,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },

  centeredContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },

  divider: {
    height: 1,
    backgroundColor: Colors.divider,
    marginVertical: Spacing.lg,
  },
};

// Theme object for easy context usage
export const theme = {
  colors: Colors,
  typography: Typography,
  spacing: Spacing,
  borderRadius: BorderRadius,
  shadows: Shadows,
  animationTimings: AnimationTimings,
  globalStyles: GlobalStyles,
};

export default theme;
