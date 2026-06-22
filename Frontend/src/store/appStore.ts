import { create } from 'zustand';

// Types
export interface RecitationSession {
  id: string;
  mode: 'correcting' | 'ai_recitation' | 'teaching';
  surah: number;
  ayah: number;
  startTime: number;
  endTime?: number;
  accuracy: number;
  verses_completed: number;
}

export interface User {
  id: string;
  name: string;
  email: string;
  ageGroup: 'child' | 'teen' | 'adult';
  defaultQiraa: 'hafs' | 'warsh' | 'qalun';
  streak: number;
  totalSessions: number;
  versesMemorized: number;
}

// App Store
interface AppStore {
  // Auth
  user: User | null;
  isAuthenticated: boolean;
  login: (user: User) => void;
  logout: () => void;

  // Session
  currentSession: RecitationSession | null;
  sessionHistory: RecitationSession[];
  startSession: (session: Omit<RecitationSession, 'id' | 'startTime'>) => void;
  endSession: (accuracy: number, versesCompleted: number) => void;

  // Settings
  language: 'en' | 'ar';
  setLanguage: (lang: 'en' | 'ar') => void;
  theme: 'dark' | 'light';
  setTheme: (theme: 'dark' | 'light') => void;
  defaultQiraa: 'hafs' | 'warsh' | 'qalun';
  setDefaultQiraa: (qiraa: 'hafs' | 'warsh' | 'qalun') => void;

  // UI State
  isLoading: boolean;
  setIsLoading: (loading: boolean) => void;
  error: string | null;
  setError: (error: string | null) => void;
}

export const useAppStore = create<AppStore>((set) => ({
  // Auth state
  user: null,
  isAuthenticated: false,
  login: (user: User) =>
    set({
      user,
      isAuthenticated: true,
    }),
  logout: () =>
    set({
      user: null,
      isAuthenticated: false,
      currentSession: null,
    }),

  // Session state
  currentSession: null,
  sessionHistory: [],
  startSession: (sessionData) =>
    set({
      currentSession: {
        ...sessionData,
        id: Math.random().toString(36),
        startTime: Date.now(),
      },
    }),
  endSession: (accuracy: number, versesCompleted: number) =>
    set((state) => {
      if (!state.currentSession) return state;

      const completedSession = {
        ...state.currentSession,
        endTime: Date.now(),
        accuracy,
        verses_completed: versesCompleted,
      };

      return {
        currentSession: null,
        sessionHistory: [...state.sessionHistory, completedSession],
      };
    }),

  // Settings
  language: 'en',
  setLanguage: (lang: 'en' | 'ar') => set({ language: lang }),
  theme: 'dark',
  setTheme: (theme: 'dark' | 'light') => set({ theme }),
  defaultQiraa: 'hafs',
  setDefaultQiraa: (qiraa: 'hafs' | 'warsh' | 'qalun') =>
    set({ defaultQiraa: qiraa }),

  // UI State
  isLoading: false,
  setIsLoading: (loading: boolean) => set({ isLoading: loading }),
  error: null,
  setError: (error: string | null) => set({ error }),
}));

export default useAppStore;
