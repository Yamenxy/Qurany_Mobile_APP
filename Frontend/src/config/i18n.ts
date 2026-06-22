import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import * as Localization from 'expo-localization';
import { NativeModules } from 'react-native';

// English translations
const en = {
  common: {
    appName: 'Qurany',
    welcome: 'Welcome',
    signIn: 'Sign In',
    signUp: 'Sign Up',
    getStarted: 'Get Started',
    skip: 'Skip',
    next: 'Next',
    back: 'Back',
    close: 'Close',
    cancel: 'Cancel',
    save: 'Save',
    delete: 'Delete',
    edit: 'Edit',
    loading: 'Loading...',
    error: 'Error',
    success: 'Success',
  },
  home: {
    greeting: 'Assalamu Alaikum, {{name}}',
    continueReading: 'Continue reading',
    chooseYourSession: 'Choose your session',
    dailyVerse: 'Daily Verse',
    hifzProgress: 'Hifz Progress',
    resumeButton: 'Resume',
  },
  modes: {
    correctingMode: 'Correcting Mode',
    aiRecitation: 'AI Recitation',
    teachingMode: 'Teaching Mode',
    correctingDesc: 'See the page, recite aloud — AI corrects you in real time',
    aiRecitationDesc: 'Recite from memory — verse appears as you recite correctly',
    teachingDesc: 'Sheikh recites, you repeat — AI decides when to move forward',
  },
  quran: {
    searchSurah: 'Search surah or verse...',
    bySurah: 'By Surah',
    byJuz: 'By Juz',
    verses: 'verses',
  },
  session: {
    endSession: 'End Session',
    accuracy: 'Accuracy',
    versesCompleted: 'Verses completed',
    timeSpent: 'Time spent',
    retryMistakes: 'Retry mistakes',
    continueFrom: 'Continue from here',
    mistakesToReview: 'Mistakes to Review',
  },
  profile: {
    myProfile: 'My Profile',
    settings: 'Settings',
    achievements: 'My Achievements',
    changePassword: 'Change Password',
    signOut: 'Sign Out',
    deleteAccount: 'Delete Account',
  },
};

// Arabic translations
const ar = {
  common: {
    appName: 'قرآني',
    welcome: 'أهلا وسهلا',
    signIn: 'تسجيل الدخول',
    signUp: 'إنشاء حساب',
    getStarted: 'ابدأ الآن',
    skip: 'تخطي',
    next: 'التالي',
    back: 'رجوع',
    close: 'إغلاق',
    cancel: 'إلغاء',
    save: 'حفظ',
    delete: 'حذف',
    edit: 'تعديل',
    loading: 'جاري التحميل...',
    error: 'خطأ',
    success: 'نجح',
  },
  home: {
    greeting: 'السلام عليكم، {{name}}',
    continueReading: 'استكمل القراءة',
    chooseYourSession: 'اختر جلستك',
    dailyVerse: 'الآية اليومية',
    hifzProgress: 'متابعة الحفظ',
    resumeButton: 'استئنف',
  },
  modes: {
    correctingMode: 'وضع التصحيح',
    aiRecitation: 'وضع الاستظهار',
    teachingMode: 'وضع المعلم',
    correctingDesc: 'شايف الصفحة وتقرأ ولو غلطت البرنامج ينبهك',
    aiRecitationDesc: 'مش شايف الصفحة تقرأ والاية تظهر',
    teachingDesc: 'الشيخ الحصري يقرأ وانت تقرأ بعده',
  },
  quran: {
    searchSurah: 'ابحث عن سورة أو آية...',
    bySurah: 'حسب السورة',
    byJuz: 'حسب الجزء',
    verses: 'آيات',
  },
  session: {
    endSession: 'إنهاء الجلسة',
    accuracy: 'الدقة',
    versesCompleted: 'الآيات المكتملة',
    timeSpent: 'الوقت المستغرق',
    retryMistakes: 'إعادة الأخطاء',
    continueFrom: 'المتابعة من هنا',
    mistakesToReview: 'الأخطاء للمراجعة',
  },
  profile: {
    myProfile: 'ملفي الشخصي',
    settings: 'الإعدادات',
    achievements: 'إنجازاتي',
    changePassword: 'تغيير كلمة المرور',
    signOut: 'تسجيل الخروج',
    deleteAccount: 'حذف الحساب',
  },
};

const deviceLanguage = Localization.getLocales()[0]?.languageCode || 'en';
const defaultLanguage = deviceLanguage === 'ar' ? 'ar' : 'en';

i18n.use(initReactI18next).init({
  compatibilityJSON: 'v3',
  resources: {
    en: { translation: en },
    ar: { translation: ar },
  },
  lng: defaultLanguage,
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
