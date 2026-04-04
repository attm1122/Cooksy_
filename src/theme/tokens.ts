export const colors = {
  brand: "#F5C400",
  brandSoft: "#FFF6CC",
  background: "#FFFDF7",
  surface: "#FFFFFF",
  surfaceAlt: "#F7F2E6",
  ink: "#111111",
  softInk: "#262626",
  muted: "#706B61",
  border: "#E9E2D1",
  line: "#EEE7D6",
  success: "#1D8F5F",
  danger: "#B94831",
  overlay: "rgba(17, 17, 17, 0.06)",
  white: "#FFFFFF"
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
  jumbo: 40
} as const;

export const radius = {
  sm: 12,
  md: 18,
  lg: 22,
  xl: 28,
  pill: 999
} as const;

export const typography = {
  hero: 34,
  h1: 28,
  h2: 22,
  h3: 18,
  body: 15,
  bodyLg: 16,
  caption: 13,
  micro: 11
} as const;

export const shadows = {
  card: {
    shadowColor: "#111111",
    shadowOpacity: 0.08,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 6 },
    elevation: 4
  },
  soft: {
    shadowColor: "#111111",
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2
  }
} as const;

export const iconSizes = {
  sm: 16,
  md: 20,
  lg: 24,
  xl: 32
} as const;

export const layout = {
  maxContentWidth: 1120,
  contentGutter: 20
} as const;
