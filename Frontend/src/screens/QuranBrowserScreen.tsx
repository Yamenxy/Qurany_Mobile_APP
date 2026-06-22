import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  FlatList,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { SurahListItem } from '../components';
import { Search, Filter } from 'lucide-react-native';

interface Surah {
  number: number;
  name: string;
  nameArabic: string;
  verseCount: number;
  juz: number;
  revelation: 'Meccan' | 'Medinan';
}

// Mock Surahs data (first 10)
const mockSurahs: Surah[] = [
  {
    number: 1,
    name: 'Al-Fatihah',
    nameArabic: 'الفاتحة',
    verseCount: 7,
    juz: 1,
    revelation: 'Meccan',
  },
  {
    number: 2,
    name: 'Al-Baqarah',
    nameArabic: 'البقرة',
    verseCount: 286,
    juz: 1,
    revelation: 'Medinan',
  },
  {
    number: 3,
    name: 'Ali Imran',
    nameArabic: 'آل عمران',
    verseCount: 200,
    juz: 3,
    revelation: 'Medinan',
  },
  {
    number: 4,
    name: 'An-Nisa',
    nameArabic: 'النساء',
    verseCount: 176,
    juz: 4,
    revelation: 'Medinan',
  },
  {
    number: 5,
    name: 'Al-Maidah',
    nameArabic: 'المائدة',
    verseCount: 120,
    juz: 6,
    revelation: 'Medinan',
  },
  {
    number: 6,
    name: 'Al-Anam',
    nameArabic: 'الأنعام',
    verseCount: 165,
    juz: 7,
    revelation: 'Meccan',
  },
  {
    number: 7,
    name: 'Al-Araf',
    nameArabic: 'الأعراف',
    verseCount: 206,
    juz: 8,
    revelation: 'Meccan',
  },
  {
    number: 8,
    name: 'Al-Anfal',
    nameArabic: 'الأنفال',
    verseCount: 75,
    juz: 9,
    revelation: 'Medinan',
  },
  {
    number: 9,
    name: 'At-Taubah',
    nameArabic: 'التوبة',
    verseCount: 129,
    juz: 10,
    revelation: 'Medinan',
  },
  {
    number: 10,
    name: 'Yunus',
    nameArabic: 'يونس',
    verseCount: 109,
    juz: 11,
    revelation: 'Meccan',
  },
];

type FilterType = 'all' | 'surah' | 'juz';

const QuranBrowserScreen: React.FC = () => {
  const navigation = useNavigation();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<FilterType>('surah');
  const [surahs, setSurahs] = useState<Surah[]>(mockSurahs);

  const handleSearch = (text: string) => {
    setSearchQuery(text);

    if (text.trim() === '') {
      setSurahs(mockSurahs);
    } else {
      const filtered = mockSurahs.filter(
        (surah) =>
          surah.name.toLowerCase().includes(text.toLowerCase()) ||
          surah.nameArabic.includes(text) ||
          surah.number.toString().includes(text)
      );
      setSurahs(filtered);
    }
  };

  const handleSurahPress = (surah: Surah) => {
    navigation.navigate('QuranPageViewer' as never, {
      surah: surah.number,
      page: 1,
    } as never);
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Quran</Text>
        <Text style={styles.headerSubtitle}>Choose a Surah or Juz</Text>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInputWrapper}>
          <Search size={20} color={Colors.textSecondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search surah or verse..."
            placeholderTextColor={Colors.textSecondary}
            value={searchQuery}
            onChangeText={handleSearch}
          />
        </View>

        <TouchableOpacity style={styles.filterButton}>
          <Filter size={20} color={Colors.accent} />
        </TouchableOpacity>
      </View>

      {/* Filter Pills */}
      <View style={styles.filterPills}>
        <TouchableOpacity
          style={[
            styles.filterPill,
            filterType === 'surah' && styles.filterPillActive,
          ]}
          onPress={() => setFilterType('surah')}
        >
          <Text
            style={[
              styles.filterPillText,
              filterType === 'surah' && styles.filterPillTextActive,
            ]}
          >
            By Surah
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.filterPill,
            filterType === 'juz' && styles.filterPillActive,
          ]}
          onPress={() => setFilterType('juz')}
        >
          <Text
            style={[
              styles.filterPillText,
              filterType === 'juz' && styles.filterPillTextActive,
            ]}
          >
            By Juz
          </Text>
        </TouchableOpacity>
      </View>

      {/* Surah List */}
      {surahs.length > 0 ? (
        <FlatList
          data={surahs}
          renderItem={({ item }) => (
            <SurahListItem
              surahNumber={item.number}
              arabicName={item.nameArabic}
              englishName={item.name}
              verseCount={item.verseCount}
              juzNumber={item.juz}
              onPress={() => handleSurahPress(item)}
            />
          )}
          keyExtractor={(item) => item.number.toString()}
          scrollEnabled={false}
          contentContainerStyle={styles.listContent}
        />
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateText}>📖</Text>
          <Text style={styles.emptyStateTitle}>No Results Found</Text>
          <Text style={styles.emptyStateSubtitle}>
            Try searching with different keywords
          </Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  headerTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  headerSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    gap: Spacing.md,
  },
  searchInputWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.medium,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
  },
  searchInput: {
    flex: 1,
    color: Colors.textPrimary,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    paddingVertical: Spacing.md,
  },
  filterButton: {
    width: 44,
    height: 44,
    borderRadius: BorderRadius.medium,
    backgroundColor: Colors.backgroundSurface,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  filterPills: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    gap: Spacing.md,
  },
  filterPill: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    borderWidth: 1,
    borderColor: Colors.borderLight,
  },
  filterPillActive: {
    backgroundColor: Colors.accent,
    borderColor: Colors.accent,
  },
  filterPillText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  filterPillTextActive: {
    color: Colors.backgroundDark,
  },
  listContent: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
  },
  emptyStateText: {
    fontSize: 48,
    marginBottom: Spacing.lg,
  },
  emptyStateTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  emptyStateSubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});

export default QuranBrowserScreen;
