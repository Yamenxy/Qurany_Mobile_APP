import React from 'react';
import { View, StyleSheet, Image } from 'react-native';
import {
  BottomTabNavigationProp,
  createBottomTabNavigator,
} from '@react-navigation/bottom-tabs';
import { Home, BookOpen, Mic2, BarChart3, User } from 'lucide-react-native';
import { Colors, Spacing, Typography } from '../config/theme';

// Screen components (to be created)
import HomeScreen from '../screens/HomeScreen';
import QuranBrowserScreen from '../screens/QuranBrowserScreen';
import MemorizeScreen from '../screens/MemorizeScreen';
import ProgressScreen from '../screens/ProgressScreen';
import ProfileScreen from '../screens/ProfileScreen';

export type BottomTabParamList = {
  Quran: undefined;
  Memorize: undefined;
  Home: undefined;
  Progress: undefined;
  Profile: undefined;
};

export type BottomTabNavigationProps = BottomTabNavigationProp<BottomTabParamList>;

const Tab = createBottomTabNavigator<BottomTabParamList>();

const BottomTabNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      initialRouteName="Home"
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
        tabBarIcon: ({ color, size, focused }) => {
          let icon;

          switch (route.name) {
            case 'Home':
              // Render the logo
              icon = (
                <View style={[styles.centerLogoContainer, focused && styles.centerLogoFocused]}>
                  <Image 
                    source={require('../../assets/theLogo.png')} 
                    style={styles.tabLogo} 
                  />
                </View>
              );
              break;
            case 'Quran':
              icon = <BookOpen size={size} color={color} strokeWidth={2} />;
              break;
            case 'Memorize':
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
        name="Quran"
        component={QuranBrowserScreen}
        options={{ title: 'Quran' }}
      />
      <Tab.Screen
        name="Memorize"
        component={MemorizeScreen}
        options={{
          title: 'Memorize',
          tabBarIconStyle: {
            marginBottom: 4,
          },
        }}
      />
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{ 
          title: 'Home',
          tabBarLabelStyle: { display: 'none' }, // Hide label for the center logo
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
  centerLogoContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: Colors.backgroundDark,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.border,
    marginBottom: 16, // Lift it slightly more
  },
  centerLogoFocused: {
    borderColor: Colors.accent,
  },
  tabLogo: {
    width: 44,
    height: 44,
    resizeMode: 'contain',
  },
});

export default BottomTabNavigator;
