/**
 * Paywall Screen
 * Full-screen paywall for subscription
 */

import React from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { Paywall } from '@/components/subscription/Paywall';

export default function PaywallScreen() {
  const router = useRouter();

  return (
    <View className="flex-1">
      <Paywall
        onClose={() => router.back()}
        onSubscribe={() => {
          // Successfully subscribed
          router.back();
        }}
        source="paywall_screen"
      />
    </View>
  );
}
