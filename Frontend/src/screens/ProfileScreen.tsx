import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { useAppStore } from '../store/appStore';
import {
  ChevronRight,
  Edit2,
  Settings,
  HelpCircle,
  LogOut,
  Trophy,
} from 'lucide-react-native';

const ProfileScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user, logout } = useAppStore((state) => ({
    user: state.user,
    logout: state.logout,
  }));

  const handleLogout = () => {
    logout();
    navigation.navigate('Login' as never);
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Profile Header */}
      <View style={styles.profileHeader}>
        <View style={styles.avatar}>
          <Text style={styles.avatarEmoji}>👤</Text>
        </View>

        <View style={styles.profileInfo}>
          <Text style={styles.profileName}>{user?.name || 'User'}</Text>
          <Text style={styles.profileEmail}>{user?.email}</Text>
        </View>

        <TouchableOpacity
          style={styles.editButton}
          onPress={() => navigation.navigate('Settings' as never)}
        >
          <Edit2 size={20} color={Colors.accent} />
        </TouchableOpacity>
      </View>

      {/* Stats Section */}
      <View style={styles.section}>
        <View style={styles.statsGrid}>
          <StatCard
            icon="🔥"
            label="Current Streak"
            value={`${user?.streak || 0} days`}
          />
          <StatCard
            icon="📊"
            label="Total Sessions"
            value={`${user?.totalSessions || 0}`}
          />
          <StatCard
            icon="📖"
            label="Verses Memorized"
            value={`${user?.versesMemorized || 0}`}
          />
        </View>
      </View>

      {/* Quick Stats */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>This Month</Text>
        <View style={styles.quickStatRow}>
          <QuickStat label="Sessions" value="12" icon="📋" />
          <QuickStat label="Time Spent" value="8h 32m" icon="⏱️" />
          <QuickStat label="Accuracy" value="89%" icon="🎯" />
        </View>
      </View>

      {/* Learning Preferences */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Learning Preferences</Text>

        <MenuItem
          icon="🎙️"
          label="Default Qira'a"
          value={user?.defaultQiraa === 'hafs' ? 'Hafs' : user?.defaultQiraa}
          onPress={() => navigation.navigate('Settings' as never)}
        />

        <MenuItem
          icon="🎂"
          label="Age Group"
          value={user?.ageGroup || 'Adult'}
          onPress={() => navigation.navigate('Settings' as never)}
        />

        <MenuItem
          icon="🌍"
          label="Language"
          value="English"
          onPress={() => navigation.navigate('Settings' as never)}
        />
      </View>

      {/* Actions */}
      <View style={styles.section}>
        <MenuLink
          icon={<Settings size={20} color={Colors.textSecondary} />}
          label="Settings"
          onPress={() => navigation.navigate('Settings' as never)}
        />

        <MenuLink
          icon={<Trophy size={20} color={Colors.textSecondary} />}
          label="Achievements"
          onPress={() => navigation.navigate('Achievements' as never)}
        />

        <MenuLink
          icon={<HelpCircle size={20} color={Colors.textSecondary} />}
          label="Help & Support"
          onPress={() => {}}
        />

        <MenuLink
          icon={<LogOut size={20} color={Colors.error} />}
          label="Sign Out"
          onPress={handleLogout}
          isDangerous
        />
      </View>

      {/* App Version */}
      <View style={styles.footer}>
        <Text style={styles.versionText}>Qurany v1.0.0</Text>
        <Text style={styles.footerLinks}>
          Privacy Policy • Terms of Service
        </Text>
      </View>
    </ScrollView>
  );
};

interface StatCardProps {
  icon: string;
  label: string;
  value: string;
}

const StatCard: React.FC<StatCardProps> = ({ icon, label, value }) => (
  <View style={styles.statCard}>
    <Text style={styles.statIcon}>{icon}</Text>
    <Text style={styles.statValue}>{value}</Text>
    <Text style={styles.statLabel}>{label}</Text>
  </View>
);

interface QuickStatProps {
  icon: string;
  label: string;
  value: string;
}

const QuickStat: React.FC<QuickStatProps> = ({ icon, label, value }) => (
  <View style={styles.quickStat}>
    <Text style={styles.quickIcon}>{icon}</Text>
    <Text style={styles.quickLabel}>{label}</Text>
    <Text style={styles.quickValue}>{value}</Text>
  </View>
);

interface MenuItemProps {
  icon: string;
  label: string;
  value: string;
  onPress: () => void;
}

const MenuItem: React.FC<MenuItemProps> = ({ icon, label, value, onPress }) => (
  <TouchableOpacity style={styles.menuItem} onPress={onPress}>
    <Text style={styles.menuIcon}>{icon}</Text>
    <View style={styles.menuContent}>
      <Text style={styles.menuLabel}>{label}</Text>
      <Text style={styles.menuValue}>{value}</Text>
    </View>
    <ChevronRight size={20} color={Colors.textSecondary} />
  </TouchableOpacity>
);

interface MenuLinkProps {
  icon: React.ReactNode;
  label: string;
  onPress: () => void;
  isDangerous?: boolean;
}

const MenuLink: React.FC<MenuLinkProps> = ({
  icon,
  label,
  onPress,
  isDangerous,
}) => (
  <TouchableOpacity style={styles.menuLink} onPress={onPress}>
    {icon}
    <Text style={[styles.menuLinkText, isDangerous && { color: Colors.error }]}>
      {label}
    </Text>
    <ChevronRight
      size={20}
      color={isDangerous ? Colors.error : Colors.textSecondary}
    />
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  profileHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
    gap: Spacing.lg,
  },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: Colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarEmoji: {
    fontSize: 32,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  profileEmail: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  editButton: {
    width: 40,
    height: 40,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  section: {
    paddingHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  statCard: {
    flex: 1,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  statIcon: {
    fontSize: 28,
    marginBottom: Spacing.sm,
  },
  statValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  statLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  sectionTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  quickStatRow: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  quickStat: {
    flex: 1,
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  quickIcon: {
    fontSize: 24,
    marginBottom: Spacing.sm,
  },
  quickLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  quickValue: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
    gap: Spacing.lg,
  },
  menuIcon: {
    fontSize: 24,
  },
  menuContent: {
    flex: 1,
  },
  menuLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  menuValue: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  menuLink: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
    gap: Spacing.lg,
  },
  menuLinkText: {
    flex: 1,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: Spacing.xl,
    gap: Spacing.md,
  },
  versionText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  footerLinks: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
});

export default ProfileScreen;
