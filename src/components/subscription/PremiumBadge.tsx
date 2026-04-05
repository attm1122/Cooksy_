/**
 * Premium Badge Component
 * Displays premium status badge
 */

import React from 'react';
import { View, Text } from 'react-native';
import { Crown } from 'lucide-react-native';
import { useIsPremium } from '@/stores/subscription-store';

interface PremiumBadgeProps {
  size?: 'sm' | 'md';
}

export function PremiumBadge({ size = 'md' }: PremiumBadgeProps) {
  const isPremium = useIsPremium();

  if (!isPremium) return null;

  const iconSize = size === 'sm' ? 12 : 14;
  const textSize = size === 'sm' ? 'text-xs' : 'text-sm';
  const padding = size === 'sm' ? 'px-2 py-0.5' : 'px-2.5 py-1';

  return (
    <View className={`flex-row items-center bg-amber-100 rounded-full ${padding}`}>
      <Crown size={iconSize} color="#F59E0B" />
      <Text className={`${textSize} font-medium text-amber-700 ml-1`}>
        Premium
      </Text>
    </View>
  );
}

export function PremiumIcon() {
  const isPremium = useIsPremium();

  if (!isPremium) return null;

  return (
    <View className="w-5 h-5 bg-amber-100 rounded-full items-center justify-center">
      <Crown size={12} color="#F59E0B" />
    </View>
  );
}
