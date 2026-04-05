/**
 * Subscription Management Screen
 * View and manage subscription status
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { useRouter } from 'expo-router';
import { 
  ChevronLeft, 
  Crown, 
  Calendar, 
  CreditCard, 
  RefreshCcw,
  ExternalLink,
  HelpCircle,
  Check,
} from 'lucide-react-native';
import { useSubscriptionStore, selectIsPremium, selectCurrentPlan, selectWillRenew } from '@/src/stores/subscription-store';
import { getCustomerInfo, restorePurchases, getManagementURL } from '@/src/lib/subscription';

export default function SubscriptionManagementScreen() {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);
  const [managementUrl, setManagementUrl] = useState<string | null>(null);
  
  const isPremium = useSubscriptionStore(selectIsPremium);
  const currentPlan = useSubscriptionStore(selectCurrentPlan);
  const willRenew = useSubscriptionStore(selectWillRenew);
  const store = useSubscriptionStore();

  useEffect(() => {
    loadManagementUrl();
  }, []);

  const loadManagementUrl = async () => {
    const url = await getManagementURL();
    setManagementUrl(url);
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await store.refresh();
    setRefreshing(false);
  };

  const handleRestore = async () => {
    const result = await restorePurchases();
    
    if (result.success && result.isPremium) {
      Alert.alert('Success', 'Your purchases have been restored!');
    } else if (result.success) {
      Alert.alert('No Purchases', 'No previous purchases found.');
    } else if (result.error) {
      Alert.alert('Restore Failed', result.error);
    }
  };

  const handleManageSubscription = () => {
    if (managementUrl) {
      Linking.openURL(managementUrl);
    } else {
      Alert.alert(
        'Manage Subscription',
        'Please manage your subscription through the App Store or Play Store settings on your device.'
      );
    }
  };

  const handleContactSupport = () => {
    Linking.openURL('mailto:support@cooksy.app?subject=Subscription%20Support');
  };

  const formatExpiryDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  if (!isPremium) {
    return (
      <View className="flex-1 bg-white">
        {/* Header */}
        <View className="flex-row items-center px-4 py-3 border-b border-gray-100">
          <TouchableOpacity onPress={() => router.back()} className="p-2 -ml-2">
            <ChevronLeft size={24} color="#111827" />
          </TouchableOpacity>
          <Text className="flex-1 text-lg font-semibold text-gray-900 text-center mr-8">
            Subscription
          </Text>
        </View>

        <ScrollView className="flex-1">
          <View className="px-6 py-8 items-center">
            <View className="w-20 h-20 bg-gray-100 rounded-3xl items-center justify-center mb-4">
              <Crown size={40} color="#9CA3AF" />
            </View>
            <Text className="text-xl font-bold text-gray-900 mb-2">
              Free Plan
            </Text>
            <Text className="text-gray-500 text-center mb-6">
              You're on the free plan with limited features
            </Text>

            {/* Current Limits */}
            <View className="w-full bg-gray-50 rounded-2xl p-4 mb-6">
              <Text className="font-semibold text-gray-900 mb-3">Your Plan Includes:</Text>
              <View className="space-y-2">
                <View className="flex-row items-center">
                  <View className="w-5 h-5 rounded-full bg-green-100 items-center justify-center mr-3">
                    <Check size={12} color="#22C55E" />
                  </View>
                  <Text className="text-gray-700">3 recipe imports (YouTube)</Text>
                </View>
                <View className="flex-row items-center">
                  <View className="w-5 h-5 rounded-full bg-gray-200 items-center justify-center mr-3">
                    <Text className="text-gray-400 text-xs">×</Text>
                  </View>
                  <Text className="text-gray-400">No recipe books</Text>
                </View>
                <View className="flex-row items-center">
                  <View className="w-5 h-5 rounded-full bg-gray-200 items-center justify-center mr-3">
                    <Text className="text-gray-400 text-xs">×</Text>
                  </View>
                  <Text className="text-gray-400">Cannot delete recipes</Text>
                </View>
              </View>
            </View>

            <TouchableOpacity
              onPress={() => router.push('/subscription/paywall')}
              className="w-full bg-amber-500 rounded-2xl py-4 items-center"
            >
              <Text className="text-white font-semibold text-lg">
                Upgrade to Premium
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={handleRestore}
              className="mt-4 py-2"
            >
              <Text className="text-amber-600">Restore Purchases</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-white">
      {/* Header */}
      <View className="flex-row items-center px-4 py-3 border-b border-gray-100">
        <TouchableOpacity onPress={() => router.back()} className="p-2 -ml-2">
          <ChevronLeft size={24} color="#111827" />
        </TouchableOpacity>
        <Text className="flex-1 text-lg font-semibold text-gray-900 text-center mr-8">
          Subscription
        </Text>
        {refreshing && <ActivityIndicator size="small" color="#F59E0B" />}
      </View>

      <ScrollView className="flex-1">
        {/* Premium Status Card */}
        <View className="px-6 py-8 items-center">
          <View className="w-20 h-20 bg-amber-100 rounded-3xl items-center justify-center mb-4">
            <Crown size={40} color="#F59E0B" />
          </View>
          <Text className="text-2xl font-bold text-gray-900 mb-1">
            Premium Active
          </Text>
          <Text className="text-gray-500 capitalize">
            {currentPlan || 'Monthly'} Plan
          </Text>
        </View>

        {/* Subscription Details */}
        <View className="px-6 mb-6">
          <Text className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
            Subscription Details
          </Text>
          
          <View className="bg-gray-50 rounded-2xl overflow-hidden">
            {/* Plan Type */}
            <View className="flex-row items-center px-4 py-4 border-b border-gray-100">
              <CreditCard size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">Plan</Text>
              <Text className="font-semibold text-gray-900 capitalize">
                {currentPlan || 'Monthly'}
              </Text>
            </View>

            {/* Expiry Date */}
            <View className="flex-row items-center px-4 py-4 border-b border-gray-100">
              <Calendar size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">
                {willRenew ? 'Renews on' : 'Expires on'}
              </Text>
              <Text className="font-semibold text-gray-900">
                {formatExpiryDate(store.expiresDate)}
              </Text>
            </View>

            {/* Auto-Renew Status */}
            <View className="flex-row items-center px-4 py-4">
              <RefreshCcw size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">Auto-renew</Text>
              <View className={`px-2.5 py-1 rounded-full ${willRenew ? 'bg-green-100' : 'bg-red-100'}`}>
                <Text className={`text-xs font-medium ${willRenew ? 'text-green-700' : 'text-red-700'}`}>
                  {willRenew ? 'On' : 'Off'}
                </Text>
              </View>
            </View>
          </View>
        </View>

        {/* Premium Features */}
        <View className="px-6 mb-6">
          <Text className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
            Your Premium Benefits
          </Text>
          
          <View className="bg-amber-50 rounded-2xl p-4">
            <View className="space-y-3">
              <View className="flex-row items-center">
                <View className="w-5 h-5 rounded-full bg-amber-100 items-center justify-center mr-3">
                  <Check size={12} color="#F59E0B" />
                </View>
                <Text className="text-gray-900">Unlimited recipe imports</Text>
              </View>
              <View className="flex-row items-center">
                <View className="w-5 h-5 rounded-full bg-amber-100 items-center justify-center mr-3">
                  <Check size={12} color="#F59E0B" />
                </View>
                <Text className="text-gray-900">Delete and edit recipes</Text>
              </View>
              <View className="flex-row items-center">
                <View className="w-5 h-5 rounded-full bg-amber-100 items-center justify-center mr-3">
                  <Check size={12} color="#F59E0B" />
                </View>
                <Text className="text-gray-900">Create recipe books</Text>
              </View>
              <View className="flex-row items-center">
                <View className="w-5 h-5 rounded-full bg-amber-100 items-center justify-center mr-3">
                  <Check size={12} color="#F59E0B" />
                </View>
                <Text className="text-gray-900">TikTok & Instagram imports</Text>
              </View>
            </View>
          </View>
        </View>

        {/* Actions */}
        <View className="px-6 pb-8">
          <Text className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
            Actions
          </Text>

          <View className="bg-gray-50 rounded-2xl overflow-hidden">
            {/* Manage Subscription */}
            <TouchableOpacity
              onPress={handleManageSubscription}
              className="flex-row items-center px-4 py-4 border-b border-gray-100"
            >
              <ExternalLink size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">Manage Subscription</Text>
              <ChevronLeft size={20} color="#9CA3AF" style={{ transform: [{ rotate: '180deg' }] }} />
            </TouchableOpacity>

            {/* Restore Purchases */}
            <TouchableOpacity
              onPress={handleRestore}
              className="flex-row items-center px-4 py-4 border-b border-gray-100"
            >
              <RefreshCcw size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">Restore Purchases</Text>
              <ChevronLeft size={20} color="#9CA3AF" style={{ transform: [{ rotate: '180deg' }] }} />
            </TouchableOpacity>

            {/* Contact Support */}
            <TouchableOpacity
              onPress={handleContactSupport}
              className="flex-row items-center px-4 py-4"
            >
              <HelpCircle size={20} color="#6B7280" />
              <Text className="flex-1 ml-3 text-gray-700">Contact Support</Text>
              <ChevronLeft size={20} color="#9CA3AF" style={{ transform: [{ rotate: '180deg' }] }} />
            </TouchableOpacity>
          </View>
        </View>

        {/* Refresh Button */}
        <TouchableOpacity
          onPress={handleRefresh}
          disabled={refreshing}
          className="items-center pb-8"
        >
          <Text className="text-gray-400 text-sm">
            {refreshing ? 'Refreshing...' : 'Refresh Subscription Status'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}
