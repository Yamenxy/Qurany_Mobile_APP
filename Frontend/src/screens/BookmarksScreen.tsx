import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
} from 'react-native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { VerseCard } from '../components';
import { Trash2, Filter } from 'lucide-react-native';

interface BookmarkedVerse {
  id: string;
  surah: string;
  ayah: number;
  text: string;
  translation: string;
  dateBookmarked: string;
  category: 'general' | 'memorizing' | 'tafsir' | 'reflection';
}

const mockBookmarks: BookmarkedVerse[] = [
  {
    id: '1',
    surah: 'Al-Fatihah',
    ayah: 1,
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful',
    dateBookmarked: '2 days ago',
    category: 'general',
  },
  {
    id: '2',
    surah: 'Al-Fatihah',
    ayah: 2,
    text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    translation: 'All praise is due to Allah, Lord of the worlds',
    dateBookmarked: '1 week ago',
    category: 'memorizing',
  },
  {
    id: '3',
    surah: 'Al-Fatihah',
    ayah: 5,
    text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    translation: 'You alone we worship, and You alone we ask for help',
    dateBookmarked: '3 days ago',
    category: 'reflection',
  },
];

type CategoryFilter = 'all' | 'general' | 'memorizing' | 'tafsir' | 'reflection';

const BookmarksScreen: React.FC = () => {
  const [filterCategory, setFilterCategory] = useState<CategoryFilter>('all');
  const [bookmarks, setBookmarks] = useState<BookmarkedVerse[]>(mockBookmarks);

  const filteredBookmarks =
    filterCategory === 'all'
      ? bookmarks
      : bookmarks.filter((b) => b.category === filterCategory);

  const handleDeleteBookmark = (id: string) => {
    setBookmarks(bookmarks.filter((b) => b.id !== id));
  };

  const categoryLabels: Record<BookmarkedVerse['category'], string> = {
    general: 'General',
    memorizing: 'Memorizing',
    tafsir: 'Tafsir',
    reflection: 'Reflection',
  };

  const categoryColors: Record<BookmarkedVerse['category'], string> = {
    general: Colors.primaryLight,
    memorizing: Colors.warning,
    tafsir: Colors.accent,
    reflection: Colors.success,
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>Bookmarks</Text>
          <Text style={styles.subtitle}>
            {filteredBookmarks.length} saved verse{filteredBookmarks.length !== 1 ? 's' : ''}
          </Text>
        </View>

        <TouchableOpacity style={styles.filterButton}>
          <Filter size={20} color={Colors.accent} />
        </TouchableOpacity>
      </View>

      {/* Category Filter */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.filterScroll}
        contentContainerStyle={styles.filterContent}
      >
        {(['all', 'general', 'memorizing', 'tafsir', 'reflection'] as const).map((cat) => (
          <TouchableOpacity
            key={cat}
            style={[
              styles.filterPill,
              filterCategory === cat && styles.filterPillActive,
            ]}
            onPress={() => setFilterCategory(cat)}
          >
            <Text
              style={[
                styles.filterPillText,
                filterCategory === cat && styles.filterPillTextActive,
              ]}
            >
              {cat === 'all' ? 'All' : categoryLabels[cat]}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Bookmarks List */}
      {filteredBookmarks.length > 0 ? (
        <FlatList
          data={filteredBookmarks}
          renderItem={({ item }) => (
            <View style={styles.bookmarkItem}>
              <View style={styles.bookmarkContent}>
                {/* Category Badge */}
                <View
                  style={[
                    styles.categoryBadge,
                    {
                      backgroundColor: categoryColors[item.category] + '20',
                      borderColor: categoryColors[item.category],
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.categoryBadgeText,
                      { color: categoryColors[item.category] },
                    ]}
                  >
                    {categoryLabels[item.category]}
                  </Text>
                </View>

                {/* Verse Info */}
                <Text style={styles.verseRef}>
                  {item.surah} {item.ayah}
                </Text>

                {/* Arabic Text */}
                <Text style={styles.verseArabic}>{item.text}</Text>

                {/* Translation */}
                <Text style={styles.verseTranslation}>{item.translation}</Text>

                {/* Date Bookmarked */}
                <Text style={styles.dateBookmarked}>Bookmarked {item.dateBookmarked}</Text>
              </View>

              {/* Delete Button */}
              <TouchableOpacity
                style={styles.deleteButton}
                onPress={() => handleDeleteBookmark(item.id)}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Trash2 size={18} color={Colors.error} />
              </TouchableOpacity>
            </View>
          )}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          scrollEnabled={false}
        />
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyIcon}>📖</Text>
          <Text style={styles.emptyTitle}>No Bookmarks</Text>
          <Text style={styles.emptySubtitle}>
            Bookmark verses to save them for later
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
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
  filterScroll: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  filterContent: {
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
  bookmarkItem: {
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginBottom: Spacing.lg,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  bookmarkContent: {
    flex: 1,
  },
  categoryBadge: {
    alignSelf: 'flex-start',
    borderRadius: BorderRadius.full,
    borderWidth: 1,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    marginBottom: Spacing.md,
  },
  categoryBadgeText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    fontWeight: '600',
  },
  verseRef: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.sm,
  },
  verseArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    lineHeight: Typography.size.lg * 2,
    color: Colors.textPrimary,
    textAlign: 'right',
    marginBottom: Spacing.md,
  },
  verseTranslation: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  dateBookmarked: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.xs,
    color: Colors.textSecondary,
  },
  deleteButton: {
    padding: Spacing.md,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: Spacing.lg,
  },
  emptyTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  emptySubtitle: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});

export default BookmarksScreen;
