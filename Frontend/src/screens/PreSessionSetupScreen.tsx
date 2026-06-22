import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { QiraaSelector, Button } from '../components';

type PreSessionSetupRouteProps = RouteProp<
  { PreSessionSetup: { mode: 'correcting' | 'ai_recitation' | 'teaching' } },
  'PreSessionSetup'
>;

const PreSessionSetupScreen: React.FC = () => {
  const route = useRoute<PreSessionSetupRouteProps>();
  const navigation = useNavigation();
  const mode = route.params?.mode || 'ai_recitation';

  const [currentStep, setCurrentStep] = useState<'qiraa' | 'sheikh' | 'start'>(
    'qiraa'
  );
  const [selectedQiraa, setSelectedQiraa] = useState<
    'hafs' | 'warsh' | 'qalun'
  >('hafs');
  const [selectedSheikh, setSelectedSheikh] = useState<string>('al-husary');
  const [startingPoint, setStartingPoint] = useState<'last' | 'custom'>(
    'last'
  );
  const [customSurah, setCustomSurah] = useState<number>(1);
  const [customAyah, setCustomAyah] = useState<number>(1);

  const sheikhs = [
    { id: 'al-husary', name: 'Al-Husary', arabicName: 'الحصري' },
    { id: 'abdul-basit', name: 'Abdul-Basit', arabicName: 'عبد الباسط' },
    { id: 'minshawi', name: 'Al-Minshawi', arabicName: 'المنشاوي' },
  ];

  const handleNext = () => {
    if (currentStep === 'qiraa') {
      setCurrentStep(mode === 'teaching' ? 'sheikh' : 'start');
    } else if (currentStep === 'sheikh') {
      setCurrentStep('start');
    } else {
      handleBeginSession();
    }
  };

  const handleBeginSession = () => {
    // Navigate to the appropriate session screen based on mode
    switch (mode) {
      case 'correcting':
        navigation.navigate('CorrectingMode' as never);
        break;
      case 'ai_recitation':
        navigation.navigate('AIRecitation' as never);
        break;
      case 'teaching':
        navigation.navigate('TeachingMode' as never);
        break;
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backButtonText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.mode}>
          {mode === 'correcting'
            ? 'Correcting Mode'
            : mode === 'ai_recitation'
              ? 'AI Recitation'
              : 'Teaching Mode'}
        </Text>
      </View>

      {/* Step Indicator */}
      <View style={styles.stepIndicator}>
        {['qiraa', 'sheikh', 'start'].map((step, idx) => (
          <View key={step} style={styles.stepContainer}>
            <View
              style={[
                styles.stepCircle,
                (step === 'sheikh' && mode !== 'teaching') || idx > 1
                  ? styles.stepHidden
                  : currentStep === step
                    ? styles.stepActive
                    : styles.stepInactive,
              ]}
            >
              <Text style={styles.stepNumber}>{idx + 1}</Text>
            </View>
            {idx < 2 && (
              <View
                style={[
                  styles.stepLine,
                  (step === 'sheikh' && mode !== 'teaching') || idx > 0
                    ? styles.stepLineHidden
                    : styles.stepLineVisible,
                ]}
              />
            )}
          </View>
        ))}
      </View>

      {/* Content */}
      <View style={styles.content}>
        {/* STEP 1: Qiraa Selection */}
        {currentStep === 'qiraa' && (
          <View>
            <Text style={styles.stepTitle}>Select Qira'a</Text>
            <Text style={styles.stepSubtitle}>
              Choose your preferred Qiraa'h recitation
            </Text>
            <QiraaSelector selected={selectedQiraa} onSelect={setSelectedQiraa} />
          </View>
        )}

        {/* STEP 2: Sheikh Selection (Teaching Mode Only) */}
        {currentStep === 'sheikh' && mode === 'teaching' && (
          <View>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: Spacing.lg }}>
              <View>
                <Text style={styles.stepTitle}>Select Sheikh</Text>
                <Text style={styles.stepSubtitle}>
                  Choose who will teach you
                </Text>
              </View>
              <Button
                title="Audio Library"
                variant="secondary"
                size="small"
                onPress={() => navigation.navigate('SheikhAudioLibrary' as never)}
              />
            </View>
            <View style={styles.sheikhGrid}>
              {sheikhs.map((sheikh) => (
                <TouchableOpacity
                  key={sheikh.id}
                  style={[
                    styles.sheikhCard,
                    selectedSheikh === sheikh.id && styles.sheikhCardSelected,
                  ]}
                  onPress={() => setSelectedSheikh(sheikh.id)}
                >
                  <View style={styles.sheikhAvatar}>
                    <Text style={styles.avatar}>👨‍🎓</Text>
                  </View>
                  <Text style={styles.sheikhName}>{sheikh.arabicName}</Text>
                  <Text style={styles.sheikhEnglish}>{sheikh.name}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        {/* STEP 3: Starting Point */}
        {currentStep === 'start' && (
          <View>
            <Text style={styles.stepTitle}>Choose Starting Point</Text>
            <Text style={styles.stepSubtitle}>
              Where would you like to begin?
            </Text>

            {/* From Last */}
            <TouchableOpacity
              style={[
                styles.startOption,
                startingPoint === 'last' && styles.startOptionSelected,
              ]}
              onPress={() => setStartingPoint('last')}
            >
              <View style={styles.optionRadio}>
                {startingPoint === 'last' && (
                  <View style={styles.optionRadioDot} />
                )}
              </View>
              <View>
                <Text style={styles.optionTitle}>From where I left off</Text>
                <Text style={styles.optionSubtitle}>
                  Surah Al-Baqarah, Ayah 45
                </Text>
              </View>
            </TouchableOpacity>

            {/* Custom Start */}
            <TouchableOpacity
              style={[
                styles.startOption,
                startingPoint === 'custom' && styles.startOptionSelected,
              ]}
              onPress={() => setStartingPoint('custom')}
            >
              <View style={styles.optionRadio}>
                {startingPoint === 'custom' && (
                  <View style={styles.optionRadioDot} />
                )}
              </View>
              <View>
                <Text style={styles.optionTitle}>Choose custom starting point</Text>
                <Text style={styles.optionSubtitle}>
                  Select Surah and Ayah
                </Text>
              </View>
            </TouchableOpacity>
          </View>
        )}
      </View>

      {/* Navigation Buttons */}
      <View style={styles.footer}>
        {currentStep !== 'qiraa' && (
          <Button
            title="Back"
            onPress={() => {
              if (currentStep === 'start') {
                setCurrentStep(mode === 'teaching' ? 'sheikh' : 'qiraa');
              } else {
                setCurrentStep('qiraa');
              }
            }}
            variant="secondary"
            fullWidth
            size="large"
          />
        )}

        <Button
          title={currentStep === 'start' ? 'Begin Session' : 'Next →'}
          onPress={handleNext}
          variant="primary"
          fullWidth
          size="large"
          style={{ marginTop: currentStep !== 'qiraa' ? Spacing.md : 0 }}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  backButton: {
    marginRight: Spacing.lg,
  },
  backButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.primaryLight,
  },
  mode: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  stepIndicator: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: Spacing.xl,
  },
  stepContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  stepCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: Spacing.sm,
  },
  stepNumber: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.base,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  stepActive: {
    backgroundColor: Colors.primaryLight,
  },
  stepInactive: {
    backgroundColor: Colors.backgroundSurface,
    borderWidth: 2,
    borderColor: Colors.accent,
  },
  stepHidden: {
    opacity: 0,
    width: 0,
    height: 0,
    margin: 0,
  },
  stepLine: {
    width: 30,
    height: 2,
    backgroundColor: Colors.accent,
    marginHorizontal: Spacing.xs,
  },
  stepLineHidden: {
    opacity: 0,
    width: 0,
  },
  stepLineVisible: {
    opacity: 1,
  },
  content: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    flex: 1,
  },
  stepTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.xl,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  stepSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
  sheikhGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: Spacing.md,
  },
  sheikhCard: {
    flex: 1,
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.large,
    borderWidth: 2,
    borderColor: Colors.borderLight,
    paddingVertical: Spacing.lg,
    paddingHorizontal: Spacing.md,
    alignItems: 'center',
  },
  sheikhCardSelected: {
    borderColor: Colors.accent,
    backgroundColor: Colors.backgroundCard,
  },
  sheikhAvatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: Colors.backgroundCard,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  avatar: {
    fontSize: 32,
  },
  sheikhName: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.sm,
    fontWeight: '600',
    color: Colors.textGold,
    marginBottom: Spacing.xs,
  },
  sheikhEnglish: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
  startOption: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.large,
    borderWidth: 2,
    borderColor: Colors.borderLight,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
  },
  startOptionSelected: {
    borderColor: Colors.accent,
    backgroundColor: Colors.backgroundCard,
  },
  optionRadio: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: Colors.accent,
    marginRight: Spacing.lg,
    justifyContent: 'center',
    alignItems: 'center',
  },
  optionRadioDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: Colors.accent,
  },
  optionTitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  optionSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  footer: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    gap: Spacing.md,
  },
});

export default PreSessionSetupScreen;
