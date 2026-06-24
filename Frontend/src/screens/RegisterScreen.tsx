import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { Button, QiraaSelector } from '../components';
import { Mail, Lock, User } from 'lucide-react-native';

type AgeGroup = 'child' | 'teen' | 'adult';
type Qiraa = 'hafs' | 'warsh' | 'qalun';

const RegisterScreen: React.FC = () => {
  const navigation = useNavigation();

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [ageGroup, setAgeGroup] = useState<AgeGroup>('adult');
  const [selectedQiraa, setSelectedQiraa] = useState<Qiraa>('hafs');
  const [isLoading, setIsLoading] = useState(false);

  const handleRegister = () => {
    if (!fullName || !email || !password || !confirmPassword) {
      alert('Please fill in all fields');
      return;
    }

    if (password !== confirmPassword) {
      alert('Passwords do not match');
      return;
    }

    setIsLoading(true);

    // Simulate API call
    setTimeout(() => {
      setIsLoading(false);
      alert('Account created successfully!');
      navigation.navigate('Login' as never);
    }, 1500);
  };

  const ageGroupOptions = [
    { label: 'Child (under 12)', value: 'child' },
    { label: 'Teen (12–17)', value: 'teen' },
    { label: 'Adult (18+)', value: 'adult' },
  ];

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.container}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Back Button */}
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backButtonText}>← Back</Text>
        </TouchableOpacity>

        {/* Title */}
        <View style={styles.titleSection}>
          <Text style={styles.title}>Create your account</Text>
          <Text style={styles.subtitle}>Join millions learning Quran</Text>
        </View>

        {/* Form */}
        <View style={styles.form}>
          {/* Full Name */}
          <View style={styles.inputContainer}>
            <User size={20} color={Colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Full Name"
              placeholderTextColor={Colors.textSecondary}
              value={fullName}
              onChangeText={setFullName}
            />
          </View>

          {/* Email */}
          <View style={styles.inputContainer}>
            <Mail size={20} color={Colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Email"
              placeholderTextColor={Colors.textSecondary}
              keyboardType="email-address"
              autoCapitalize="none"
              value={email}
              onChangeText={setEmail}
            />
          </View>

          {/* Password */}
          <View style={styles.inputContainer}>
            <Lock size={20} color={Colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Password"
              placeholderTextColor={Colors.textSecondary}
              secureTextEntry
              value={password}
              onChangeText={setPassword}
            />
          </View>

          {/* Confirm Password */}
          <View style={styles.inputContainer}>
            <Lock size={20} color={Colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Confirm Password"
              placeholderTextColor={Colors.textSecondary}
              secureTextEntry
              value={confirmPassword}
              onChangeText={setConfirmPassword}
            />
          </View>

          {/* Age Group */}
          <View style={styles.sectionContainer}>
            <Text style={styles.sectionLabel}>Age Group</Text>
            <View style={styles.ageGroupOptions}>
              {ageGroupOptions.map((option) => (
                <TouchableOpacity
                  key={option.value}
                  style={[
                    styles.agePill,
                    ageGroup === option.value && styles.agePillActive,
                  ]}
                  onPress={() => setAgeGroup(option.value as AgeGroup)}
                >
                  <Text
                    style={[
                      styles.agePillText,
                      ageGroup === option.value && styles.agePillTextActive,
                    ]}
                  >
                    {option.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>



          {/* Sign Up Button */}
          <Button
            title="Create Account"
            onPress={handleRegister}
            variant="primary"
            fullWidth
            size="large"
            loading={isLoading}
            style={{ marginTop: Spacing.lg }}
          />
        </View>

        {/* Divider */}
        <View style={styles.divider}>
          <View style={styles.dividerLine} />
          <Text style={styles.dividerText}>or</Text>
          <View style={styles.dividerLine} />
        </View>

        {/* Google Sign Up */}
        <TouchableOpacity style={styles.googleButton}>
          <Text style={styles.googleIcon}>🔵</Text>
          <Text style={styles.googleText}>Continue with Google</Text>
        </TouchableOpacity>

        {/* Terms */}
        <Text style={styles.termsText}>
          By signing up, you agree to our Terms of Service and Privacy Policy
        </Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  backButton: {
    marginBottom: Spacing.lg,
  },
  backButtonText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.primaryLight,
  },
  titleSection: {
    marginBottom: Spacing.lg,
  },
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  subtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textSecondary,
  },
  form: {
    marginBottom: Spacing.lg,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    marginBottom: Spacing.lg,
    gap: Spacing.md,
  },
  input: {
    flex: 1,
    color: Colors.textPrimary,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
  },
  sectionContainer: {
    marginBottom: Spacing.lg,
  },
  sectionLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  ageGroupOptions: {
    flexDirection: 'row',
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  agePill: {
    flex: 1,
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.sm,
    alignItems: 'center',
  },
  agePillActive: {
    backgroundColor: Colors.accent,
    borderColor: Colors.accent,
  },
  agePillText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  agePillTextActive: {
    color: Colors.backgroundDark,
    fontWeight: '600',
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: Spacing.lg,
    gap: Spacing.md,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: Colors.divider,
  },
  dividerText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  googleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
    gap: Spacing.md,
  },
  googleIcon: {
    fontSize: 20,
  },
  googleText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  termsText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});

export default RegisterScreen;
