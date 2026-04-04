import { act } from "@testing-library/react-native";

import { useCooksyStore } from "@/store/use-cooksy-store";

describe("useCooksyStore", () => {
  afterEach(() => {
    useCooksyStore.setState({
      recipes: [...useCooksyStore.getInitialState().recipes],
      books: [...useCooksyStore.getInitialState().books],
      selectedRecipeId: useCooksyStore.getInitialState().selectedRecipeId
    });
  });

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

  it("removes a recipe from library and books", () => {
    act(() => {
      useCooksyStore.getState().addRecipeToBook("one-pan-tuscan-pasta", "date-night");
      useCooksyStore.getState().removeRecipe("one-pan-tuscan-pasta");
    });

    const removedRecipe = useCooksyStore.getState().recipes.find((recipe) => recipe.id === "one-pan-tuscan-pasta");
    const updatedBook = useCooksyStore.getState().books.find((book) => book.id === "date-night");

    expect(removedRecipe).toBeUndefined();
    expect(updatedBook?.recipeIds).not.toContain("one-pan-tuscan-pasta");
  });
});
