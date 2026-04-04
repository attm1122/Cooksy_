/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./src/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        cream: "#FFFDF7",
        ink: "#111111",
        "soft-ink": "#262626",
        "brand-yellow": "#F5C400",
        "brand-yellow-soft": "#FFF6CC",
        line: "#E9E2D1",
        muted: "#706B61",
        surface: "#FFFFFF",
        "surface-alt": "#F7F2E6",
        success: "#1D8F5F",
        danger: "#B94831"
      },
      fontFamily: {
        sans: ["Inter_500Medium"],
        medium: ["Inter_500Medium"],
        semibold: ["Inter_600SemiBold"],
        bold: ["Inter_700Bold"]
      },
      boxShadow: {
        card: "0px 6px 18px rgba(17, 17, 17, 0.08)",
        soft: "0px 2px 10px rgba(17, 17, 17, 0.05)"
      },
      borderRadius: {
        xl2: "28px"
      }
    }
  },
  plugins: []
};
