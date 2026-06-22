import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Colors, Spacing, Typography, GlobalStyles, BorderRadius } from '../config/theme';
import { ChevronLeft, Play, Pause, CheckCircle } from 'lucide-react-native';

const mockSheikhs = [
  { id: 1, name: 'Mahmoud Khalil Al-Husary', nameArabic: 'محمود خليل الحصري', qiraa: 'Hafs', style: 'Tarteel / Muallim', image: '👤', selected: true },
  { id: 2, name: 'Mishary Rashid Alafasy', nameArabic: 'مشاري راشد العفاسي', qiraa: 'Hafs', style: 'Tarteel', image: '👤', selected: false },
  { id: 3, name: "Abdul Basit 'Abd us-Samad", nameArabic: 'عبد الباسط عبد الصمد', qiraa: 'Warsh', style: 'Tajweed', image: '👤', selected: false },
  { id: 4, name: 'Ali Al-Hudhaifi', nameArabic: 'علي بن عبد الرحمن الحذيفي', qiraa: 'Qalun', style: 'Tarteel', image: '👤', selected: false },
];

const SheikhAudioLibraryScreen: React.FC = () => {
  const navigation = useNavigation();
  const [playingId, setPlayingId] = useState<number | null>(null);

  const togglePlay = (id: number) => {
    if (playingId === id) setPlayingId(null);
    else setPlayingId(id);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <ChevronLeft size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Audio Library</Text>
        <View style={{ width: 24 }} />
      </View>

      <View style={styles.filterBar}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <TouchableOpacity style={[styles.filterChip, styles.filterChipActive]}>
            <Text style={[styles.filterText, styles.filterTextActive]}>All Qira'at</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.filterChip}>
            <Text style={styles.filterText}>Hafs</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.filterChip}>
            <Text style={styles.filterText}>Warsh</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.filterChip}>
            <Text style={styles.filterText}>Qalun</Text>
          </TouchableOpacity>
        </ScrollView>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        {mockSheikhs.map((sheikh) => (
          <View key={sheikh.id} style={[styles.sheikhCard, sheikh.selected && styles.selectedCard]}>
            <View style={styles.avatarContainer}>
              <Text style={styles.avatarEmoji}>{sheikh.image}</Text>
              {sheikh.selected && (
                <View style={styles.checkIcon}>
                  <CheckCircle size={16} color={Colors.success} fill={Colors.backgroundDark} />
                </View>
              )}
            </View>
            
            <View style={styles.infoContainer}>
              <Text style={styles.sheikhNameArabic}>{sheikh.nameArabic}</Text>
              <Text style={styles.sheikhName}>{sheikh.name}</Text>
              <View style={styles.tagsContainer}>
                <View style={styles.tag}>
                  <Text style={styles.tagText}>{sheikh.qiraa}</Text>
                </View>
                <View style={styles.tag}>
                  <Text style={styles.tagText}>{sheikh.style}</Text>
                </View>
              </View>
            </View>

            <TouchableOpacity style={styles.playButton} onPress={() => togglePlay(sheikh.id)}>
              {playingId === sheikh.id ? (
                <Pause size={24} color={Colors.accent} />
              ) : (
                <Play size={24} color={Colors.accent} />
              )}
            </TouchableOpacity>
          </View>
        ))}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...GlobalStyles.screenContainer,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  headerTitle: {
    fontFamily: Typography.headingFont,
    fontSize: Typography.size.lg,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  filterBar: {
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
  filterChip: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.full,
    backgroundColor: Colors.backgroundSurface,
    marginRight: Spacing.sm,
  },
  filterChipActive: {
    backgroundColor: Colors.accent,
  },
  filterText: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
  },
  filterTextActive: {
    color: Colors.backgroundDark,
    fontWeight: '600',
  },
  content: {
    padding: Spacing.lg,
  },
  sheikhCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.backgroundCard,
    borderRadius: BorderRadius.large,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  selectedCard: {
    borderColor: Colors.accent,
    backgroundColor: Colors.backgroundSurface,
  },
  avatarContainer: {
    position: 'relative',
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: Colors.backgroundDark,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  avatarEmoji: {
    fontSize: 32,
  },
  checkIcon: {
    position: 'absolute',
    bottom: -4,
    right: -4,
    backgroundColor: Colors.backgroundDark,
    borderRadius: 10,
  },
  infoContainer: {
    flex: 1,
    marginRight: Spacing.sm,
  },
  sheikhNameArabic: {
    fontFamily: Typography.arabicFont,
    fontSize: Typography.size.lg,
    color: Colors.textPrimary,
  },
  sheikhName: {
    fontFamily: Typography.bodyFont,
    fontSize: Typography.size.sm,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  tagsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.xs,
  },
  tag: {
    backgroundColor: Colors.backgroundDark,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
    borderRadius: BorderRadius.small,
  },
  tagText: {
    fontFamily: Typography.bodyFont,
    fontSize: 10,
    color: Colors.textGold,
  },
  playButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: Colors.backgroundDark,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default SheikhAudioLibraryScreen;
