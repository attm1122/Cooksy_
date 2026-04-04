import { zodResolver } from "@hookform/resolvers/zod";
import { useLocalSearchParams } from "expo-router";
import { Controller, useForm } from "react-hook-form";
import { ScrollView, Text, TextInput, View } from "react-native";

import { PrimaryButton } from "@/components/common/Buttons";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { recipeSchema, type RecipeFormValues } from "@/lib/schemas";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function EditRecipeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);

  const { control, handleSubmit } = useForm<RecipeFormValues>({
    resolver: zodResolver(recipeSchema),
    values: recipe
  });

  if (!recipe) {
    return null;
  }

  const onSubmit = handleSubmit((values) => updateRecipe(values));

  return (
    <ScreenContainer scroll={false}>
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-4 text-[28px] font-bold text-ink">Edit recipe</Text>

        <View style={{ gap: 14 }}>
          <Controller
            control={control}
            name="title"
            render={({ field: { onChange, value } }) => (
              <TextInput
                value={value}
                onChangeText={onChange}
                className="rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
              />
            )}
          />

          <View className="flex-row" style={{ gap: 12 }}>
            <Controller
              control={control}
              name="servings"
              render={({ field: { onChange, value } }) => (
                <TextInput
                  value={String(value)}
                  onChangeText={(nextValue) => onChange(Number(nextValue) || 0)}
                  keyboardType="numeric"
                  className="flex-1 rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
                  placeholder="Servings"
                />
              )}
            />
            <Controller
              control={control}
              name="prepTimeMinutes"
              render={({ field: { onChange, value } }) => (
                <TextInput
                  value={String(value)}
                  onChangeText={(nextValue) => onChange(Number(nextValue) || 0)}
                  keyboardType="numeric"
                  className="flex-1 rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
                  placeholder="Prep"
                />
              )}
            />
            <Controller
              control={control}
              name="cookTimeMinutes"
              render={({ field: { onChange, value } }) => (
                <TextInput
                  value={String(value)}
                  onChangeText={(nextValue) => onChange(Number(nextValue) || 0)}
                  keyboardType="numeric"
                  className="flex-1 rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
                  placeholder="Cook"
                />
              )}
            />
          </View>

          <Controller
            control={control}
            name="description"
            render={({ field: { onChange, value } }) => (
              <TextInput
                multiline
                value={value}
                onChangeText={onChange}
                className="min-h-[120px] rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
              />
            )}
          />

          <Controller
            control={control}
            name="heroNote"
            render={({ field: { onChange, value } }) => (
              <TextInput
                multiline
                value={value}
                onChangeText={onChange}
                className="min-h-[100px] rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
              />
            )}
          />

          <View>
            <Text className="mb-3 text-[20px] font-bold text-ink">Ingredients</Text>
            <View style={{ gap: 10 }}>
              {recipe.ingredients.map((ingredient, index) => (
                <View key={ingredient.id} className="flex-row" style={{ gap: 10 }}>
                  <Controller
                    control={control}
                    name={`ingredients.${index}.name`}
                    render={({ field: { onChange, value } }) => (
                      <TextInput
                        value={value}
                        onChangeText={onChange}
                        className="flex-1 rounded-[20px] border border-line bg-white px-4 py-3 text-[14px] text-soft-ink"
                      />
                    )}
                  />
                  <Controller
                    control={control}
                    name={`ingredients.${index}.quantity`}
                    render={({ field: { onChange, value } }) => (
                      <TextInput
                        value={value}
                        onChangeText={onChange}
                        className="w-[120px] rounded-[20px] border border-line bg-white px-4 py-3 text-[14px] text-soft-ink"
                      />
                    )}
                  />
                </View>
              ))}
            </View>
          </View>

          <View>
            <Text className="mb-3 text-[20px] font-bold text-ink">Steps</Text>
            <View style={{ gap: 10 }}>
              {recipe.steps.map((step, index) => (
                <Controller
                  key={step.id}
                  control={control}
                  name={`steps.${index}.instruction`}
                  render={({ field: { onChange, value } }) => (
                    <TextInput
                      multiline
                      value={value}
                      onChangeText={onChange}
                      className="min-h-[100px] rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
                    />
                  )}
                />
              ))}
            </View>
          </View>
        </View>

        <View className="mt-6">
          <PrimaryButton onPress={onSubmit}>Save Changes</PrimaryButton>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}
