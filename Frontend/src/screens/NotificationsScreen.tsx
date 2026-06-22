import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronLeft, Bell } from 'lucide-react-native';

const mockNotifications = [
  { id: 1, title: 'Daily Reminder', message: 'It is time for your daily recitation session. Keep your streak alive!', time: '10:00 AM', read: false },
  { id: 2, title: 'Achievement Unlocked', message: 'You have reached a 7-day streak! Mashallah!', time: 'Yesterday', read: true },
  { id: 3, title: 'New Feature', message: 'Try our new AI Teaching Mode to perfect your pronunciation.', time: '2 days ago', read: true },
];

const NotificationsScreen: React.FC = () => {
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Notifications</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {mockNotifications.map((notif) => (
          <View key={notif.id} style={[styles.notificationCard, !notif.read && styles.unreadCard]}>
            <View style={styles.iconContainer}>
              <Bell size={20} color={notif.read ? Colors.textSecondary : Colors.accent} />
            </View>
            <View style={styles.textContainer}>
              <Text style={styles.title}>{notif.title}</Text>
              <Text style={styles.message}>{notif.message}</Text>
              <Text style={styles.time}>{notif.time}</Text>
            </View>
          </View>
        ))}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  headerTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  content: {
    padding: Spacing.lg,
  },
  notificationCard: {
    flexDirection: 'row',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  unreadCard: {
    borderColor: Colors.accent,
    backgroundColor: Colors.backgroundSurface,
  },
  iconContainer: {
    marginRight: Spacing.md,
    justifyContent: 'center',
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  message: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.sm,
    lineHeight: 20,
  },
  time: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textGold,
  },
});

export default NotificationsScreen;
