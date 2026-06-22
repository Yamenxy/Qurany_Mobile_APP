import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated } from 'react-native';
import { Colors, Spacing } from '../config/theme';

interface MicWaveformProps {
  isActive: boolean;
  color?: string;
}

export const MicWaveform: React.FC<MicWaveformProps> = ({
  isActive,
  color = Colors.primaryLight,
}) => {
  const bars = Array.from({ length: 5 }, (_, i) => i);
  const animatedValues = useRef(
    bars.map(() => new Animated.Value(0.3))
  );

  useEffect(() => {
    if (isActive) {
      const animations = animatedValues.current.map((value) =>
        Animated.loop(
          Animated.sequence([
            Animated.timing(value, {
              toValue: 1,
              duration: 300,
              useNativeDriver: false,
            }),
            Animated.timing(value, {
              toValue: 0.3,
              duration: 300,
              useNativeDriver: false,
            }),
          ])
        )
      );

      animations.forEach((anim, idx) => {
        setTimeout(() => anim.start(), idx * 60);
      });

      return () => {
        animations.forEach((anim) => anim.stop());
      };
    }
  }, [isActive]);

  return (
    <View style={styles.container}>
      {bars.map((i) => (
        <Animated.View
          key={i}
          style={[
            styles.bar,
            {
              backgroundColor: color,
              height: animatedValues.current[i].interpolate({
                inputRange: [0.3, 1],
                outputRange: ['30%', '100%'],
              }),
            },
          ]}
        />
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 60,
    gap: Spacing.sm,
  },
  bar: {
    width: 4,
    borderRadius: 2,
    minHeight: '30%',
  },
});
