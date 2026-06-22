# Qurany Frontend

A premium mobile-first React Native app for AI-powered Quran learning and recitation. Built with React Navigation, Zustand state management, and a custom design system inspired by modern meditation apps combined with Islamic reverence.

## Features

- **3 AI-Powered Recitation Modes:**
  - Correcting Mode: See the page, recite aloud — AI corrects in real time
  - AI Recitation: Recite from memory — verse appears as you recite correctly
  - Teaching Mode: Sheikh recites, you repeat — AI auto-validates

- **Full Quran Reading Experience:**
  - Mushaf-style Quran browser with search and filtering
  - Multiple Qira'a support (Hafs, Warsh, Qalun)
  - Bookmarks, history, and progress tracking

- **Personalized Learning:**
  - Daily streak tracking with milestone celebrations
  - Hifz (memorization) progress tracker
  - Per-session accuracy metrics
  - Achievement badges and milestones

- **Modern Islamic Design:**
  - Dark theme optimized for evening learning
  - Carefully curated color palette (deep green primary, gold accents)
  - Arabic typography with Amiri font for Quranic text
  - Minimal, spiritual interface

## Tech Stack

- **Framework:** React Native (Expo or bare workflow)
- **Navigation:** React Navigation (stack + bottom tabs)
- **State Management:** Zustand
- **Animations:** Reanimated 2
- **Localization:** i18next + react-i18next
- **UI Icons:** Lucide React Native
- **Typography:** Amiri (Arabic), Cairo (headings), Inter (UI)

## Project Structure

```
Frontend/
├── src/
│   ├── App.tsx                 # Root app component
│   ├── index.tsx               # Entry point
│   ├── config/
│   │   ├── theme.ts            # Design system (colors, typography, spacing)
│   │   └── i18n.ts             # Internationalization (AR/EN)
│   ├── components/             # Reusable UI components
│   │   ├── VerseCard.tsx
│   │   ├── AccuracyRing.tsx
│   │   ├── ModeCard.tsx
│   │   ├── StreakWidget.tsx
│   │   ├── QiraaSelector.tsx
│   │   ├── MicWaveform.tsx
│   │   ├── BottomSheet.tsx
│   │   ├── Button.tsx
│   │   ├── SurahListItem.tsx
│   │   └── index.ts            # Component barrel export
│   ├── screens/
│   │   ├── HomeScreen.tsx
│   │   ├── QuranBrowserScreen.tsx
│   │   ├── AIModeSelectionScreen.tsx
│   │   ├── PreSessionSetupScreen.tsx
│   │   ├── CorrectingModeScreen.tsx
│   │   ├── AIRecitationScreen.tsx
│   │   ├── TeachingModeScreen.tsx
│   │   ├── SessionSummaryScreen.tsx
│   │   ├── ProgressScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   └── [others]
│   ├── navigation/
│   │   └── BottomTabNavigator.tsx
│   └── store/
│       └── appStore.ts         # Zustand global state
├── app.json                    # Expo app configuration
└── package.json                # Dependencies

```

## Key Components

### Design System (theme.ts)
- **Colors:** Primary green (#1A6B4A), accent gold (#C9A84C), semantic colors
- **Typography:** Amiri (Arabic), Cairo (headings), Inter (body)
- **Spacing:** 8px base unit with standardized scale
- **Animations:** Fast (200ms), Normal (300ms), Slow (500ms)

### Reusable Components
- `VerseCard` — Displays Quranic verse with translation and reference
- `ModeCard` — AI mode selection card with icon, description, CTA
- `AccuracyRing` — Circular progress ring for accuracy display
- `StreakWidget` — Flame icon + count + progress bar
- `QiraaSelector` — 3-option Qira'a picker
- `MicWaveform` — Animated waveform during recitation
- `BottomSheet` — Reusable sliding bottom sheet with backdrop
- `Button` — Primary/secondary/ghost variants with size options

### State Management (Zustand)
Global app state including:
- User authentication and profile
- Current recitation session
- Session history
- Settings (language, theme, default Qira'a)
- Loading and error states

## Screens (Priority Order)

1. ✅ **Home** — Dashboard with streak, daily verse, resume reading, AI modes quick access
2. ✅ **AI Mode Selection** — 3 mode cards with descriptions and CTAs
3. **Pre-Session Setup** — Qira'a selection, sheikh selection, starting point
4. **Mode 1: Correcting Mode** — Live Mushaf with error highlighting
5. **Mode 2: AI Recitation** — Memorization mode with verse reveal
6. **Mode 3: Teaching Mode** — Sheikh recitation + user repetition
7. **Session Summary** — Accuracy metrics, mistakes to review
8. **Quran Browser** — Surah/Juz filtering, search, page viewer
9. **Progress Dashboard** — Weekly stats, streaks, session history
10. **Hifz Tracker** — Memorization progress, Juz completion
11. **Auth Screens** — Login, register, onboarding
12. **Profile** — Avatar, stats, achievements
13. **Settings** — Language, font size, notifications, Qira'a preference
14. **Notifications** — Streak alerts, reminders, achievements
15. **Bookmarks** — Saved verses
16. **Search** — Surah/verse search with history
17. **Khatma Tracker** — Full Quran reading progress

## Design Principles

1. **RTL Support:** Full RTL layout for Arabic with mirrored navigation
2. **Dark Mode Only:** Intentionally dark theme optimized for evening learning
3. **Spiritual Minimalism:** No unnecessary decoration; every element serves a purpose
4. **Accessibility:** 44pt minimum touch targets, icon labels, haptic feedback
5. **Performance:** Optimized rendering, lazy loading for long lists
6. **Localization:** Full AR/EN support with per-screen translations

## Running the App

```bash
# Install dependencies
npm install

# Start Expo server
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android

# Run on web
npm run web
```

## Font Setup

The app uses Google Fonts loaded at runtime:
- **Amiri:** Quranic Arabic text (serif, traditional)
- **Cairo:** Arabic headings (modern, bold)
- **Inter:** English UI text (clean, readable)

These fonts are loaded automatically via Expo and don't require local font files.

## Future Enhancements

- [ ] WebRTC audio streaming for real-time AI feedback
- [ ] On-device Whisper model for offline transcription
- [ ] Multi-user sync with cloud backend
- [ ] Offline mode with local Quran content
- [ ] Video tutorials and guided lessons
- [ ] Leaderboards and social features
- [ ] Teacher/parent dashboards for tracking children's progress
- [ ] AI-generated pronunciation analysis
- [ ] Tajweed rule highlighting during recitation

---

**Design Language:** Modern meditation app (Calm, Headspace) meets Islamic reverence. Clean, focused, spiritual.

**Target Users:** Children learning Quran, adults, Hafiz-level reciters, teachers, parents.

**Status:** MVP in active development. Screens 1-3 complete, AI session screens in progress.
