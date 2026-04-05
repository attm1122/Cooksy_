import { zodResolver } from "@hookform/resolvers/zod";
import { Controller, useForm } from "react-hook-form";
import { useEffect } from "react";
import { Text, TextInput, View } from "react-native";

import { PrimaryButton } from "@/components/common/Buttons";
import { recipeSchema, type RecipeFormValues } from "@/lib/schemas";
import type { Recipe } from "@/types/recipe";

type RecipeEditorFormProps = {
  recipe: Recipe;
  onSubmit: (recipe: Recipe) => void;
  submitLabel?: string;
  compact?: boolean;
};

export const RecipeEditorForm = ({
  recipe,
  onSubmit,
  submitLabel = "Save Changes",
  compact = false
}: RecipeEditorFormProps) => {
  const { control, handleSubmit, reset } = useForm<RecipeFormValues>({
    resolver: zodResolver(recipeSchema),
    defaultValues: recipe
  });

  useEffect(() => {
    reset(recipe);
  }, [recipe, reset]);

  const save = handleSubmit((values) =>
    onSubmit({
      ...values,
      totalTimeMinutes: values.prepTimeMinutes + values.cookTimeMinutes
    })
  );
  const reviewItems = recipe.editableFields ?? [];
  const needsIngredientReview = (name: string) => reviewItems.some((item) => item.toLowerCase().includes(name.toLowerCase()) || item.toLowerCase().includes("ingredient"));
  const needsStepReview = (index: number, instruction: string) =>
    reviewItems.some(
      (item) =>
        item.toLowerCase().includes(`step ${index + 1}`) ||
        item.toLowerCase().includes(instruction.toLowerCase().slice(0, 18)) ||
        item.toLowerCase().includes("steps")
    );

  return (
    <View style={{ gap: 14 }}>
      {reviewItems.length ? (
        <View className="rounded-[20px] border border-[#F0D96B] bg-brand-yellow-soft px-4 py-3">
          <Text className="text-[13px] font-bold uppercase tracking-[0.8px] text-ink">Review first</Text>
          <Text className="mt-1 text-[14px] leading-5 text-soft-ink">{reviewItems.slice(0, 4).join(" · ")}</Text>
        </View>
      ) : null}
      <Controller
        control={control}
        name="title"
        render={({ field: { onChange, value } }) => (
          <TextInput
            value={value}
            onChangeText={onChange}
            className="rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
            placeholder="Recipe title"
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

      {!compact ? (
        <>
          <Controller
            control={control}
            name="description"
            render={({ field: { onChange, value } }) => (
              <TextInput
                multiline
                value={value}
                onChangeText={onChange}
                className="min-h-[100px] rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
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
                className="min-h-[92px] rounded-[22px] border border-line bg-white px-4 py-4 text-[15px] text-soft-ink"
              />
            )}
          />
        </>
      ) : null}

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
                    className={`flex-1 rounded-[20px] border bg-white px-4 py-3 text-[14px] text-soft-ink ${
                      needsIngredientReview(ingredient.name) ? "border-[#F0D96B]" : "border-line"
                    }`}
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
                    className={`w-[120px] rounded-[20px] border bg-white px-4 py-3 text-[14px] text-soft-ink ${
                      needsIngredientReview(ingredient.name) ? "border-[#F0D96B]" : "border-line"
                    }`}
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
            <View key={step.id} style={{ gap: 8 }}>
              <Controller
                control={control}
                name={`steps.${index}.title`}
                render={({ field: { onChange, value } }) => (
                  <TextInput
                    value={value}
                    onChangeText={onChange}
                    className={`rounded-[18px] border bg-white px-4 py-3 text-[14px] font-semibold text-soft-ink ${
                      needsStepReview(index, step.instruction) ? "border-[#F0D96B]" : "border-line"
                    }`}
                  />
                )}
              />
              <Controller
                control={control}
                name={`steps.${index}.instruction`}
                render={({ field: { onChange, value } }) => (
                  <TextInput
                    multiline
                    value={value}
                    onChangeText={onChange}
                    className={`min-h-[90px] rounded-[22px] border bg-white px-4 py-4 text-[15px] text-soft-ink ${
                      needsStepReview(index, step.instruction) ? "border-[#F0D96B]" : "border-line"
                    }`}
                  />
                )}
              />
            </View>
          ))}
        </View>
      </View>

      <PrimaryButton onPress={save}>{submitLabel}</PrimaryButton>
    </View>
  );
};
