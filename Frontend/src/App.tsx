import React, { useEffect } from 'react';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import * as SplashScreen from 'expo-splash-screen';
import * as Font from 'expo-font';
import i18n from './config/i18n';
import { useAppStore } from './store/appStore';
import BottomTabNavigator from './navigation/BottomTabNavigator';
import { Colors } from './config/theme';

// Import screens
import OnboardingScreen from './screens/OnboardingScreen';
import LoginScreen from './screens/LoginScreen';
import RegisterScreen from './screens/RegisterScreen';
import NotificationsScreen from './screens/NotificationsScreen';
import AchievementsScreen from './screens/AchievementsScreen';
import PreSessionSetupScreen from './screens/PreSessionSetupScreen';
import AIRecitationScreen from './screens/AIRecitationScreen';
import CorrectingModeScreen from './screens/CorrectingModeScreen';
import TeachingModeScreen from './screens/TeachingModeScreen';
import SessionSummaryScreen from './screens/SessionSummaryScreen';
import QuranPageViewerScreen from './screens/QuranPageViewerScreen';
import TajweedReferenceScreen from './screens/TajweedReferenceScreen';
import DailyChallengesScreen from './screens/DailyChallengesScreen';
import SheikhAudioLibraryScreen from './screens/SheikhAudioLibraryScreen';

// Keep splash screen visible while loading resources
SplashScreen.preventAutoHideAsync();

const Stack = createNativeStackNavigator();
const AuthStack = createNativeStackNavigator();

function AuthNavigator() {
  return (
    <AuthStack.Navigator screenOptions={{ headerShown: false }}>
      <AuthStack.Screen name="Onboarding" component={OnboardingScreen} />
      <AuthStack.Screen name="Login" component={LoginScreen} />
      <AuthStack.Screen name="Register" component={RegisterScreen} />
    </AuthStack.Navigator>
  );
}

export default function App() {
  const [appReady, setAppReady] = React.useState(false);
  const isAuthenticated = useAppStore((state) => state.isAuthenticated);

  useEffect(() => {
    async function prepare() {
      try {
        // Initialize i18n
        await i18n.init;
        
        // Load custom fonts
        await Font.loadAsync({
          'DigitalKhattV1': require('../assets/fonts/Digital Khatt V1 Font.otf'),
          'DigitalKhattV2': require('../assets/fonts/Digital Khatt V2 Font.otf'),
          'DigitalKhattIndoPak': require('../assets/fonts/DigitalKhattIndoPak.otf'),
          'IndopakNastaleeq': require('../assets/fonts/Indopak Nastaleeq font.ttf'),
          'KFGQPCNastaleeq': require('../assets/fonts/KFGQPCNastaleeq-Regular.ttf'),
          'QPCHafs': require('../assets/fonts/QPC Hafs font.ttf'),
          'MeQuran': require('../assets/fonts/me_quran_volt_newmet.ttf'),
        });

        setAppReady(true);
      } catch (error) {
        console.error('Error initializing app:', error);
      } finally {
        await SplashScreen.hideAsync();
      }
    }

    prepare();
  }, []);

  if (!appReady) {
    return null;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <SafeAreaView style={{ flex: 1, backgroundColor: Colors.backgroundDark }}>
          <NavigationContainer
            theme={{
              dark: true,
              colors: {
                primary: Colors.primaryLight,
                background: Colors.backgroundDark,
                card: Colors.backgroundCard,
                text: Colors.textPrimary,
                border: Colors.divider,
                notification: Colors.error,
              },
            }}
          >
            <Stack.Navigator
              screenOptions={{
                headerShown: false,
              }}
            >
              {isAuthenticated ? (
                <>
                  <Stack.Screen name="Main" component={BottomTabNavigator} />
                  <Stack.Screen name="Notifications" component={NotificationsScreen} />
                  <Stack.Screen name="Achievements" component={AchievementsScreen} />
                  <Stack.Screen name="PreSessionSetup" component={PreSessionSetupScreen} />
                  <Stack.Screen name="AIRecitation" component={AIRecitationScreen} />
                  <Stack.Screen name="CorrectingMode" component={CorrectingModeScreen} />
                  <Stack.Screen name="TeachingMode" component={TeachingModeScreen} />
                  <Stack.Screen name="SessionSummary" component={SessionSummaryScreen} />
                  <Stack.Screen name="QuranPageViewer" component={QuranPageViewerScreen} />
                  <Stack.Screen name="TajweedReference" component={TajweedReferenceScreen} />
                  <Stack.Screen name="DailyChallenges" component={DailyChallengesScreen} />
                  <Stack.Screen name="SheikhAudioLibrary" component={SheikhAudioLibraryScreen} />
                </>
              ) : (
                <Stack.Screen name="Auth" component={AuthNavigator} />
              )}
            </Stack.Navigator>
          </NavigationContainer>
        </SafeAreaView>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
