import "@testing-library/jest-native/extend-expect";

jest.mock("expo-router", () => ({
  Link: ({ children }: { children: React.ReactNode }) => children,
  router: {
    push: jest.fn(),
    replace: jest.fn()
  },
  useLocalSearchParams: jest.fn(() => ({}))
}));
