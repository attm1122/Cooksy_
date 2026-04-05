/**
 * Paywall Component
 * Displays subscription plans and handles purchases
 */

import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  Alert,
  Linking,
} from 'react-native';
import { Check, X, Crown, ChefHat, BookOpen, Trash2, Infinity, Sparkles } from 'lucide-react-native';
import { useSubscriptionStore, useCanUpload } from '@/stores/subscription-store';
import { purchasePackage, restorePurchases } from '@/lib/subscription';
import { PurchasesPackage } from 'react-native-purchases';

interface PaywallProps {
  onClose?: () => void;
  onSubscribe?: () => void;
  source?: string; // For analytics
}

const FEATURES = [
  { icon: ChefHat, text: 'Unlimited recipe imports', premium: true },
  { icon: Trash2, text: 'Delete and edit recipes', premium: true },
  { icon: BookOpen, text: 'Create recipe books', premium: true },
  { icon: Infinity, text: 'TikTok & Instagram imports', premium: true },
  { icon: Sparkles, text: 'Priority support', premium: true },
];

const FREE_FEATURES = [
  '3 recipe imports (YouTube only)',
  'No recipe books',
  'Cannot delete recipes',
];

export function Paywall({ onClose, onSubscribe, source }: PaywallProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('yearly');
  const [restoring, setRestoring] = useState(false);
  
  const store = useSubscriptionStore();
  const { remaining } = useCanUpload();
  
  const monthlyPackage = store.getMonthlyPackage();
  const yearlyPackage = store.getYearlyPackage();

  const handlePurchase = useCallback(async () => {
    const pkg = selectedPlan === 'yearly' ? yearlyPackage : monthlyPackage;
    
    if (!pkg) {
      Alert.alert('Error', 'Pricing information not available. Please try again.');
      return;
    }

    setIsLoading(true);
    
    try {
      const result = await purchasePackage(pkg);
      
      if (result.success) {
        onSubscribe?.();
      } else if (result.error) {
        Alert.alert('Purchase Failed', result.error);
      }
    } catch {
      Alert.alert('Error', 'Something went wrong. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [selectedPlan, monthlyPackage, yearlyPackage, onSubscribe]);

  const handleRestore = useCallback(async () => {
    setRestoring(true);
    
    try {
      const result = await restorePurchases();
      
      if (result.success && result.isPremium) {
        Alert.alert('Success', 'Your purchases have been restored!');
        onSubscribe?.();
      } else if (result.success) {
        Alert.alert('No Purchases', 'No previous purchases found.');
      } else if (result.error) {
        Alert.alert('Restore Failed', result.error);
      }
    } catch {
      Alert.alert('Error', 'Failed to restore purchases. Please try again.');
    } finally {
      setRestoring(false);
    }
  }, [onSubscribe]);

  const handleTerms = () => {
    Linking.openURL('/legal/terms');
  };

  const handlePrivacy = () => {
    Linking.openURL('/legal/privacy');
  };

  // Format price display
  const formatPrice = (pkg?: PurchasesPackage) => {
    if (!pkg) return selectedPlan === 'yearly' ? '$60' : '$5.99';
    
    const price = pkg.product.price;
    const currency = pkg.product.currencyCode;
    
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency,
    }).format(Number(price));
  };

  const getYearlySavings = () => {
    if (!monthlyPackage || !yearlyPackage) return 17;
    
    const monthly = Number(monthlyPackage.product.price) * 12;
    const yearly = Number(yearlyPackage.product.price);
    
    return Math.round(((monthly - yearly) / monthly) * 100);
  };

  return (
    <View className="flex-1 bg-white">
      {/* Header */}
      <View className="flex-row items-center justify-between px-4 py-3 border-b border-gray-100">
        <View className="w-10" />
        <Text className="text-lg font-semibold text-gray-900">Go Premium</Text>
        <TouchableOpacity 
          onPress={onClose}
          className="w-10 h-10 items-center justify-center"
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <X size={24} color="#6B7280" />
        </TouchableOpacity>
      </View>

      <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
        {/* Hero Section */}
        <View className="px-6 py-8 items-center">
          <View className="w-20 h-20 bg-amber-100 rounded-3xl items-center justify-center mb-4">
            <Crown size={40} color="#F59E0B" />
          </View>
          <Text className="text-2xl font-bold text-gray-900 text-center mb-2">
            Unlock Cooksy Premium
          </Text>
          <Text className="text-gray-600 text-center">
            Get unlimited access to all features
          </Text>
          
          {/* Free Limit Warning */}
          {remaining === 0 && (
            <View className="mt-4 bg-red-50 px-4 py-3 rounded-xl">
              <Text className="text-red-700 text-center text-sm">
                You've reached your 3 free upload limit
              </Text>
            </View>
          )}
        </View>

        {/* Feature Comparison */}
        <View className="px-6 mb-8">
          {/* Free Tier */}
          <View className="bg-gray-50 rounded-2xl p-4 mb-4">
            <Text className="text-gray-900 font-semibold mb-3">Free</Text>
            {FREE_FEATURES.map((feature, index) => (
              <View key={index} className="flex-row items-center mb-2">
                <View className="w-5 h-5 rounded-full bg-gray-200 items-center justify-center mr-3">
                  <Text className="text-gray-500 text-xs">×</Text>
                </View>
                <Text className="text-gray-500 text-sm">{feature}</Text>
              </View>
            ))}
          </View>

          {/* Premium Tier */}
          <View className="bg-amber-50 rounded-2xl p-4 border-2 border-amber-200">
            <View className="flex-row items-center mb-3">
              <Crown size={20} color="#F59E0B" />
              <Text className="text-amber-900 font-semibold ml-2">Premium</Text>
            </View>
            {FEATURES.map((feature, index) => (
              <View key={index} className="flex-row items-center mb-2">
                <View className="w-5 h-5 rounded-full bg-amber-100 items-center justify-center mr-3">
                  <Check size={12} color="#F59E0B" />
                </View>
                <Text className="text-gray-900 text-sm">{feature.text}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Plan Selection */}
        <View className="px-6 mb-8">
          <Text className="text-gray-900 font-semibold mb-4">Choose your plan</Text>
          
          {/* Yearly Plan */}
          <TouchableOpacity
            onPress={() => setSelectedPlan('yearly')}
            className={`rounded-2xl p-4 mb-3 border-2 ${
              selectedPlan === 'yearly' 
                ? 'border-amber-500 bg-amber-50' 
                : 'border-gray-200 bg-white'
            }`}
          >
            <View className="flex-row items-center justify-between">
              <View className="flex-row items-center">
                <View className={`w-6 h-6 rounded-full border-2 mr-3 items-center justify-center ${
                  selectedPlan === 'yearly' ? 'border-amber-500' : 'border-gray-300'
                }`}>
                  {selectedPlan === 'yearly' && (
                    <View className="w-3 h-3 rounded-full bg-amber-500" />
                  )}
                </View>
                <View>
                  <Text className={`font-semibold ${
                    selectedPlan === 'yearly' ? 'text-amber-900' : 'text-gray-900'
                  }`}>
                    Yearly
                  </Text>
                  <Text className="text-gray-500 text-sm">
                    {formatPrice(yearlyPackage)}/year
                  </Text>
                </View>
              </View>
              <View className="bg-amber-100 px-3 py-1 rounded-full">
                <Text className="text-amber-700 text-xs font-medium">
                  Save {getYearlySavings()}%
                </Text>
              </View>
            </View>
          </TouchableOpacity>

          {/* Monthly Plan */}
          <TouchableOpacity
            onPress={() => setSelectedPlan('monthly')}
            className={`rounded-2xl p-4 border-2 ${
              selectedPlan === 'monthly' 
                ? 'border-amber-500 bg-amber-50' 
                : 'border-gray-200 bg-white'
            }`}
          >
            <View className="flex-row items-center">
              <View className={`w-6 h-6 rounded-full border-2 mr-3 items-center justify-center ${
                selectedPlan === 'monthly' ? 'border-amber-500' : 'border-gray-300'
              }`}>
                {selectedPlan === 'monthly' && (
                  <View className="w-3 h-3 rounded-full bg-amber-500" />
                )}
              </View>
              <View>
                <Text className={`font-semibold ${
                  selectedPlan === 'monthly' ? 'text-amber-900' : 'text-gray-900'
                }`}>
                  Monthly
                </Text>
                <Text className="text-gray-500 text-sm">
                  {formatPrice(monthlyPackage)}/month
                </Text>
              </View>
            </View>
          </TouchableOpacity>
        </View>

        {/* CTA Button */}
        <View className="px-6 pb-4">
          <TouchableOpacity
            onPress={handlePurchase}
            disabled={isLoading}
            className="bg-amber-500 rounded-2xl py-4 items-center"
            style={{ opacity: isLoading ? 0.7 : 1 }}
          >
            {isLoading ? (
              <ActivityIndicator color="white" />
            ) : (
              <Text className="text-white font-semibold text-lg">
                Start Free Trial
              </Text>
            )}
          </TouchableOpacity>
          
          <Text className="text-gray-400 text-xs text-center mt-3">
            7-day free trial. Cancel anytime.
          </Text>
        </View>

        {/* Restore & Legal */}
        <View className="px-6 pb-8">
          <TouchableOpacity 
            onPress={handleRestore}
            disabled={restoring}
            className="items-center py-2"
          >
            <Text className="text-amber-600 text-sm">
              {restoring ? 'Restoring...' : 'Restore Purchases'}
            </Text>
          </TouchableOpacity>
          
          <View className="flex-row justify-center mt-4">
            <TouchableOpacity onPress={handleTerms}>
              <Text className="text-gray-400 text-xs">Terms of Service</Text>
            </TouchableOpacity>
            <Text className="text-gray-400 text-xs mx-2">•</Text>
            <TouchableOpacity onPress={handlePrivacy}>
              <Text className="text-gray-400 text-xs">Privacy Policy</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
