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
import { Search as SearchIcon, Clock, X } from 'lucide-react-native';

interface SearchResult {
  id: string;
  text: string;
  surah: string;
  ayah: number;
  translation: string;
}

const mockResults: SearchResult[] = [
  {
    id: '1',
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    surah: 'Al-Fatihah',
    ayah: 1,
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
  },
  {
    id: '2',
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    surah: 'Al-Fatihah',
    ayah: 2,
    translation: 'All praise is due to Allah, Lord of the worlds',
  },
  {
    id: '3',
    text: 'مَالِكِ يَوْمِ الدِّينِ',
    surah: 'Al-Fatihah',
    ayah: 4,
    translation: 'Master of the Day of Judgment',
  },
];

const searchHistory = ['Al-Fatihah', 'Allah', 'mercy', 'guidance'];

const SearchScreen: React.FC = () => {
  const navigation = useNavigation();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [showResults, setShowResults] = useState(false);

  const handleSearch = (text: string) => {
    setQuery(text);

    if (text.trim().length > 0) {
      // Simulate search
      setResults(mockResults);
      setShowResults(true);
    } else {
      setShowResults(false);
    }
  };

  const handleResultPress = (result: SearchResult) => {
    navigation.navigate('QuranPageViewer' as never, {
      surah: result.surah,
      ayah: result.ayah,
    } as never);
  };

  const handleClearHistory = () => {
    // In real app, clear search history
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Search</Text>
        <Text style={styles.subtitle}>Find verses and surahs</Text>
      </View>

      {/* Search Input */}
      <View style={styles.searchBar}>
        <SearchIcon size={20} color={Colors.textSecondary} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search verses, surahs, Arabic text..."
          placeholderTextColor={Colors.textSecondary}
          value={query}
          onChangeText={handleSearch}
          autoFocus
        />
        {query && (
          <TouchableOpacity
            onPress={() => {
              setQuery('');
              setShowResults(false);
            }}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <X size={20} color={Colors.textSecondary} />
          </TouchableOpacity>
        )}
      </View>

      {/* Results or History */}
      {showResults ? (
        <FlatList
          data={results}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.resultItem}
              onPress={() => handleResultPress(item)}
            >
              <View>
                <Text style={styles.resultArabic}>{item.text}</Text>
                <Text style={styles.resultInfo}>
                  {item.surah} {item.ayah}
                </Text>
              </View>
              <Text style={styles.resultTranslation}>{item.translation}</Text>
            </TouchableOpacity>
          )}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.resultsList}
          scrollEnabled={false}
        />
      ) : (
        <ScrollView
          style={styles.historyContainer}
          contentContainerStyle={styles.historyContent}
          showsVerticalScrollIndicator={false}
        >
          <View>
            <View style={styles.historyHeader}>
              <Text style={styles.historyTitle}>Recent Searches</Text>
              <TouchableOpacity onPress={handleClearHistory}>
                <Text style={styles.clearButton}>Clear</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.historyGrid}>
              {searchHistory.map((item, idx) => (
                <TouchableOpacity
                  key={idx}
                  style={styles.historyItem}
                  onPress={() => handleSearch(item)}
                >
                  <Clock size={16} color={Colors.textSecondary} />
                  <Text style={styles.historyText}>{item}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Suggested Searches */}
          <View>
            <Text style={styles.suggestedTitle}>Popular Searches</Text>

            <SuggestionItem label="Mercy (الرحمة)" count="45 verses" />
            <SuggestionItem label="Guidance (الهداية)" count="38 verses" />
            <SuggestionItem label="Knowledge (العلم)" count="52 verses" />
            <SuggestionItem label="Patience (الصبر)" count="29 verses" />
          </View>
        </ScrollView>
      )}
    </View>
  );
};

interface SuggestionItemProps {
  label: string;
  count: string;
}

const SuggestionItem: React.FC<SuggestionItemProps> = ({ label, count }) => (
  <TouchableOpacity style={styles.suggestionItem}>
    <View>
      <Text style={styles.suggestionLabel}>{label}</Text>
      <Text style={styles.suggestionCount}>{count}</Text>
    </View>
  </TouchableOpacity>
);

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
  title: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size['2xl'],
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  subtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    borderColor: Colors.borderLight,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    marginHorizontal: Spacing.lg,
    marginVertical: Spacing.lg,
    gap: Spacing.md,
  },
  searchInput: {
    flex: 1,
    color: Colors.textPrimary,
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
  },
  resultsList: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  resultItem: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
  },
  resultArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.sm,
  },
  resultInfo: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
    marginBottom: Spacing.sm,
  },
  resultTranslation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  historyContainer: {
    flex: 1,
  },
  historyContent: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  historyTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  clearButton: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.error,
  },
  historyGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
    marginBottom: Spacing.xl,
  },
  historyItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundSurface,
    borderRadius: BorderRadius.full,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    gap: Spacing.sm,
  },
  historyText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  suggestedTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  suggestionItem: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.md,
  },
  suggestionLabel: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.base,
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  suggestionCount: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
});

export default SearchScreen;
