/**
 * Upgrade Prompt Component
 * Shows when user hits a premium feature limit
 */

import React from 'react';
import { View, Text, TouchableOpacity, Modal } from 'react-native';
import { Crown, Lock } from 'lucide-react-native';
import { useRouter } from 'expo-router';

interface UpgradePromptProps {
  isVisible: boolean;
  onClose: () => void;
  feature: 'upload' | 'delete' | 'books' | 'platform';
  platform?: 'tiktok' | 'instagram';
}

const MESSAGES = {
  upload: {
    title: 'Upload Limit Reached',
    message: 'You\'ve used all 3 free uploads. Upgrade to Premium for unlimited recipes.',
    icon: 'upload',
  },
  delete: {
    title: 'Premium Feature',
    message: 'Recipe deletion is a Premium feature. Upgrade to organize your collection.',
    icon: 'trash',
  },
  books: {
    title: 'Premium Feature',
    message: 'Create unlimited recipe books with Premium. Organize your favorites!',
    icon: 'book',
  },
  platform: {
    title: 'Premium Feature',
    message: 'Import from TikTok and Instagram with Premium. YouTube imports are free!',
    icon: 'video',
  },
};

export function UpgradePrompt({ isVisible, onClose, feature, platform }: UpgradePromptProps) {
  const router = useRouter();
  const message = MESSAGES[feature];

  const handleUpgrade = () => {
    onClose();
    router.push('/subscription/paywall' as never);
  };

  return (
    <Modal
      visible={isVisible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View className="flex-1 bg-black/50 justify-center items-center p-6">
        <View className="bg-white rounded-3xl p-6 w-full max-w-sm">
          {/* Header */}
          <View className="items-center mb-4">
            <View className="w-16 h-16 bg-amber-100 rounded-2xl items-center justify-center mb-3">
              <Lock size={28} color="#F59E0B" />
            </View>
            <Text className="text-xl font-bold text-gray-900 text-center">
              {message.title}
            </Text>
          </View>

          {/* Message */}
          <Text className="text-gray-600 text-center mb-6">
            {message.message}
          </Text>

          {/* CTA */}
          <TouchableOpacity
            onPress={handleUpgrade}
            className="bg-amber-500 rounded-xl py-4 items-center mb-3"
          >
            <View className="flex-row items-center">
              <Crown size={18} color="white" />
              <Text className="text-white font-semibold text-lg ml-2">
                Upgrade to Premium
              </Text>
            </View>
          </TouchableOpacity>

          {/* Close */}
          <TouchableOpacity onPress={onClose} className="items-center py-2">
            <Text className="text-gray-500">Maybe Later</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

// Inline upgrade banner for embedding in lists
interface UpgradeBannerProps {
  onPress: () => void;
  variant?: 'uploads' | 'books' | 'general';
}

export function UpgradeBanner({ onPress, variant = 'general' }: UpgradeBannerProps) {
  const content = {
    uploads: {
      title: '3 uploads used',
      subtitle: 'Upgrade for unlimited',
    },
    books: {
      title: 'Unlock Recipe Books',
      subtitle: 'Organize with Premium',
    },
    general: {
      title: 'Go Premium',
      subtitle: 'Unlock all features',
    },
  }[variant];

  return (
    <TouchableOpacity
      onPress={onPress}
      className="bg-amber-50 border border-amber-200 rounded-2xl p-4 mx-4 my-2"
    >
      <View className="flex-row items-center justify-between">
        <View className="flex-row items-center">
          <View className="w-10 h-10 bg-amber-100 rounded-xl items-center justify-center">
            <Crown size={20} color="#F59E0B" />
          </View>
          <View className="ml-3">
            <Text className="font-semibold text-amber-900">{content.title}</Text>
            <Text className="text-amber-700 text-sm">{content.subtitle}</Text>
          </View>
        </View>
        <View className="bg-amber-500 px-3 py-1.5 rounded-full">
          <Text className="text-white text-sm font-medium">Upgrade</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}
