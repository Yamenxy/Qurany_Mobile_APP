import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles } from '../config/theme';

const MemorizeScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      {/* Top Bar */}
      <View style={styles.topBar}>
        <Text style={styles.title}>Memorize / القران المعلم</Text>
      </View>

      <View style={styles.content}>
        <Text style={styles.placeholderText}>
          Teaching Mode Content Coming Soon
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  topBar: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
    alignItems: 'center',
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textGold,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.lg,
  },
  placeholderText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});

export default MemorizeScreen;
