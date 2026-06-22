import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
} from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronRight } from 'lucide-react-native';

const SettingsScreen: React.FC = () => {
  const [notifications, setNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(true);
  const [reminders, setReminders] = useState(true);
  const [offlineMode, setOfflineMode] = useState(false);

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Settings</Text>
      </View>

      {/* Account Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>

        <SettingsItem
          label="Email Address"
          value="user@example.com"
          onPress={() => {}}
        />

        <SettingsItem label="Change Password" onPress={() => {}} />

        <SettingsItem label="Delete Account" isDangerous onPress={() => {}} />
      </View>

      {/* Learning Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Learning</Text>

        <SettingsItem label="Default Qira'a" value="Hafs" onPress={() => {}} />

        <SettingsItem
          label="Preferred Sheikh"
          value="Al-Husary"
          onPress={() => {}}
        />

        <SettingsItem
          label="Daily Target (minutes)"
          value="30"
          onPress={() => {}}
        />
      </View>

      {/* Notifications Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Notifications</Text>

        <SettingsToggle
          icon="🔔"
          label="Push Notifications"
          value={notifications}
          onToggle={setNotifications}
        />

        <SettingsToggle
          icon="⏰"
          label="Daily Reminders"
          value={reminders}
          onToggle={setReminders}
        />
      </View>

      {/* App Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>App</Text>

        <SettingsToggle
          icon="🌙"
          label="Dark Mode"
          value={darkMode}
          onToggle={setDarkMode}
        />

        <SettingsToggle
          icon="📱"
          label="Offline Mode"
          value={offlineMode}
          onToggle={setOfflineMode}
        />

        <SettingsItem label="Language" value="English" onPress={() => {}} />

        <SettingsItem label="Text Size" value="Normal" onPress={() => {}} />
      </View>

      {/* About Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>

        <SettingsItem label="App Version" value="1.0.0" />

        <SettingsItem label="Check for Updates" onPress={() => {}} />

        <SettingsItem label="Terms of Service" onPress={() => {}} />

        <SettingsItem label="Privacy Policy" onPress={() => {}} />
      </View>
    </ScrollView>
  );
};

interface SettingsItemProps {
  label: string;
  value?: string;
  onPress?: () => void;
  isDangerous?: boolean;
}

const SettingsItem: React.FC<SettingsItemProps> = ({
  label,
  value,
  onPress,
  isDangerous,
}) => (
  <TouchableOpacity
    style={styles.settingsItem}
    onPress={onPress}
    activeOpacity={onPress ? 0.7 : 1}
  >
    <Text style={[styles.settingsLabel, isDangerous && { color: Colors.error }]}>
      {label}
    </Text>
    <View style={styles.settingsItemRight}>
      {value && (
        <Text
          style={[
            styles.settingsValue,
            isDangerous && { color: Colors.error },
          ]}
        >
          {value}
        </Text>
      )}
      {onPress && (
        <ChevronRight
          size={20}
          color={isDangerous ? Colors.error : Colors.textSecondary}
        />
      )}
    </View>
  </TouchableOpacity>
);

interface SettingsToggleProps {
  icon: string;
  label: string;
  value: boolean;
  onToggle: (value: boolean) => void;
}

const SettingsToggle: React.FC<SettingsToggleProps> = ({
  icon,
  label,
  value,
  onToggle,
}) => (
  <View style={styles.settingsItem}>
    <View style={styles.toggleLeft}>
      <Text style={styles.toggleIcon}>{icon}</Text>
      <Text style={styles.settingsLabel}>{label}</Text>
    </View>
    <Switch
      value={value}
      onValueChange={onToggle}
      trackColor={{
        false: Colors.backgroundSurface,
        true: Colors.primaryLight,
      }}
      thumbColor={Colors.accent}
    />
  </View>
);

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  section: {
    paddingHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.sm,
    fontWeight: '700',
    color: Colors.textGold,
    marginBottom: Spacing.lg,
    textTransform: 'uppercase',
  },
  settingsItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
  },
  settingsLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textPrimary,
  },
  settingsItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  settingsValue: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
  },
  toggleLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.lg,
  },
  toggleIcon: {
    fontSize: 20,
  },
});

export default SettingsScreen;
