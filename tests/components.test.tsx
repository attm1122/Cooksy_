import { render } from "@testing-library/react-native";

import { CooksyLogo } from "@/components/common/CooksyLogo";
import { PlatformBadge } from "@/components/common/PlatformBadge";

describe("component smoke tests", () => {
  it("renders the Cooksy wordmark", () => {
    const screen = render(<CooksyLogo />);
    expect(screen.getByText("Cooksy")).toBeTruthy();
  });

  it("renders a supported platform badge", () => {
    const screen = render(<PlatformBadge platform="youtube" />);
    expect(screen.getByText("YouTube")).toBeTruthy();
  });
});
