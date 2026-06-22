import React from 'react';
import { View, StyleSheet } from 'react-native';
import {
  BottomTabNavigationProp,
  createBottomTabNavigator,
} from '@react-navigation/bottom-tabs';
import { Home, BookOpen, Mic2, BarChart3, User } from 'lucide-react-native';
import { Colors, Spacing, Typography } from '../config/theme';

// Screen components (to be created)
import HomeScreen from '../screens/HomeScreen';
import QuranBrowserScreen from '../screens/QuranBrowserScreen';
import AIModeSelectionScreen from '../screens/AIModeSelectionScreen';
import ProgressScreen from '../screens/ProgressScreen';
import ProfileScreen from '../screens/ProfileScreen';

export type BottomTabParamList = {
  Home: undefined;
  Quran: undefined;
  AIModes: undefined;
  Progress: undefined;
  Profile: undefined;
};

export type BottomTabNavigationProps = BottomTabNavigationProp<BottomTabParamList>;

const Tab = createBottomTabNavigator<BottomTabParamList>();

const BottomTabNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarStyle: {
          backgroundColor: Colors.backgroundCard,
          borderTopColor: Colors.divider,
          borderTopWidth: 1,
          paddingBottom: 8,
          paddingTop: 8,
          height: 70,
        },
        tabBarActiveTintColor: Colors.accent,
        tabBarInactiveTintColor: Colors.textSecondary,
        tabBarLabelStyle: {
          fontFamily: Typography.bodyFont,
          fontSize: Typography.size.xs,
          fontWeight: '500',
          marginTop: 4,
        },
        tabBarIcon: ({ color, size }) => {
          let icon;

          switch (route.name) {
            case 'Home':
              icon = <Home size={size} color={color} strokeWidth={2} />;
              break;
            case 'Quran':
              icon = <BookOpen size={size} color={color} strokeWidth={2} />;
              break;
            case 'AIModes':
              icon = <Mic2 size={size} color={color} strokeWidth={2} />;
              break;
            case 'Progress':
              icon = <BarChart3 size={size} color={color} strokeWidth={2} />;
              break;
            case 'Profile':
              icon = <User size={size} color={color} strokeWidth={2} />;
              break;
            default:
              icon = null;
          }

          return (
            <View style={styles.iconContainer}>
              {icon}
            </View>
          );
        },
      })}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{ title: 'Home' }}
      />
      <Tab.Screen
        name="Quran"
        component={QuranBrowserScreen}
        options={{ title: 'Quran' }}
      />
      <Tab.Screen
        name="AIModes"
        component={AIModeSelectionScreen}
        options={{
          title: 'AI Modes',
          tabBarIconStyle: {
            marginBottom: 4,
          },
        }}
      />
      <Tab.Screen
        name="Progress"
        component={ProgressScreen}
        options={{ title: 'Progress' }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ title: 'Profile' }}
      />
    </Tab.Navigator>
  );
};

const styles = StyleSheet.create({
  iconContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default BottomTabNavigator;
