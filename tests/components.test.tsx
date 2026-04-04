import { render } from "@testing-library/react-native";

import { CooksyLogo } from "@/components/common/CooksyLogo";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { SourceEvidenceSummary } from "@/components/recipe/SourceEvidenceSummary";
import { mockRecipes } from "@/mocks/recipes";

describe("component smoke tests", () => {
  it("renders the Cooksy wordmark", () => {
    const screen = render(<CooksyLogo />);
    expect(screen.getByText("Cooksy")).toBeTruthy();
  });

  it("renders a supported platform badge", () => {
    const screen = render(<PlatformBadge platform="youtube" />);
    expect(screen.getByText("YouTube")).toBeTruthy();
  });

  it("renders the recipe thumbnail overlay content", () => {
    const screen = render(<RecipeThumbnail recipe={mockRecipes[0]} />);
    expect(screen.getByText(mockRecipes[0].title)).toBeTruthy();
    expect(screen.getByText(`@${mockRecipes[0].source.creator}`)).toBeTruthy();
  });

  it("renders a readable source evidence summary", () => {
    const screen = render(<SourceEvidenceSummary rawExtraction={mockRecipes[0].rawExtraction} />);
    expect(screen.getByText("Why Cooksy trusts this")).toBeTruthy();
    expect(screen.getByText("Quantity mentions")).toBeTruthy();
    expect(screen.getByText("Source text captured")).toBeTruthy();
  });
});
