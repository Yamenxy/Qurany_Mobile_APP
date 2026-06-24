import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Dimensions,
  ScrollView,
  FlatList,
  Image,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { Button } from '../components';
import { ChevronRight } from 'lucide-react-native';

interface OnboardingSlide {
  id: string;
  icon: string;
  title: string;
  titleArabic: string;
  description: string;
  color: string;
}

const slides: OnboardingSlide[] = [
  {
    id: '1',
    icon: '📖',
    title: 'Learn Quran',
    titleArabic: 'تعلم القرآن',
    description:
      'Master Quranic recitation with AI-powered guidance. Learn at your own pace with multiple Qira\'a options.',
    color: Colors.primaryLight,
  },
  {
    id: '2',
    icon: '🎙️',
    title: 'Instant Feedback',
    titleArabic: 'تصحيح فوري',
    description:
      'Real-time AI correction identifies pronunciation errors. Get immediate feedback to improve faster.',
    color: '#9B6BA8',
  },
  {
    id: '3',
    icon: '🏆',
    title: 'Track Progress',
    titleArabic: 'تتبع التقدم',
    description:
      'Monitor your Hifz journey with daily streaks, accuracy stats, and achievement badges.',
    color: Colors.accent,
  },
];

const screenWidth = Dimensions.get('window').width;

const OnboardingScreen: React.FC = () => {
  const navigation = useNavigation();
  const [currentSlide, setCurrentSlide] = useState(0);

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      flatListRef?.current?.scrollToIndex({
        index: currentSlide + 1,
        animated: true,
      });
      setCurrentSlide(currentSlide + 1);
    } else {
      // Done with onboarding
      navigation.navigate('Login' as never);
    }
  };

  const handleSkip = () => {
    navigation.navigate('Login' as never);
  };

  let flatListRef: any;
  const slide = slides[currentSlide];

  return (
    <View style={styles.container}>
      {/* Header - Skip Button */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={handleSkip}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <Text style={styles.skipText}>Skip</Text>
        </TouchableOpacity>

        {/* Progress Dots */}
        <View style={styles.dotsContainer}>
          {slides.map((_, index) => (
            <View
              key={index}
              style={[
                styles.dot,
                index === currentSlide ? styles.dotActive : styles.dotInactive,
              ]}
            />
          ))}
        </View>

        <View style={{ width: 40 }} />
      </View>

      {/* FlatList for slides */}
      <FlatList
        ref={(ref) => (flatListRef = ref)}
        data={slides}
        renderItem={({ item }) => (
          <View style={[styles.slide, { width: screenWidth }]}>
            {/* Icon */}
            <View style={[styles.iconContainer, { backgroundColor: item.color + '20' }]}>
              <Text style={styles.icon}>{item.icon}</Text>
            </View>

            {/* Title Arabic */}
            <Text style={styles.titleArabic}>{item.titleArabic}</Text>

            {/* Title English */}
            <Text style={styles.titleEn}>{item.title}</Text>

            {/* Description */}
            <Text style={styles.description}>{item.description}</Text>
          </View>
        )}
        keyExtractor={(item) => item.id}
        horizontal
        pagingEnabled
        scrollEnabled={false}
        showsHorizontalScrollIndicator={false}
      />

      {/* Bottom Section */}
      <View style={styles.footer}>
        <Button
          title={currentSlide === slides.length - 1 ? 'Get Started' : 'Next'}
          onPress={handleNext}
          variant="primary"
          fullWidth
          size="large"
        />

        {currentSlide < slides.length - 1 && (
          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={handleSkip}
          >
            <Text style={styles.secondaryButtonText}>Or continue as guest</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
    paddingVertical: Spacing.lg,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  logo: {
    width: 120,
    height: 120,
    resizeMode: 'contain',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.xl,
  },
  skipText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    width: 40,
  },
  dotsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.sm,
    flex: 1,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  dotActive: {
    backgroundColor: Colors.accent,
    width: 24,
  },
  dotInactive: {
    backgroundColor: Colors.divider,
  },
  slide: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
  },
  iconContainer: {
    width: 120,
    height: 120,
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xl,
  },
  icon: {
    fontSize: 64,
  },
  titleArabic: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.sm,
  },
  titleEn: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  description: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: Typography.size.base * 1.8,
    marginBottom: Spacing.xl,
  },
  footer: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
  },
  secondaryButton: {
    paddingVertical: Spacing.md,
    alignItems: 'center',
  },
  secondaryButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.primaryLight,
  },
});

export default OnboardingScreen;
