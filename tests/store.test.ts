import { act } from "@testing-library/react-native";

import { useCooksyStore } from "@/store/use-cooksy-store";

describe("useCooksyStore", () => {
  it("adds a recipe to a book without duplicating it", () => {
    const initial = useCooksyStore.getState().books.find((book) => book.id === "date-night");
    expect(initial?.recipeIds).not.toContain("one-pan-tuscan-pasta");

    act(() => {
      useCooksyStore.getState().addRecipeToBook("one-pan-tuscan-pasta", "date-night");
      useCooksyStore.getState().addRecipeToBook("one-pan-tuscan-pasta", "date-night");
    });

    const updated = useCooksyStore.getState().books.find((book) => book.id === "date-night");
    expect(updated?.recipeIds.filter((id) => id === "one-pan-tuscan-pasta")).toHaveLength(1);
  });
});
