import { Text, View } from "react-native";
import Svg, { Circle, Path } from "react-native-svg";

type CooksyLogoProps = {
  variant?: "horizontal" | "icon";
  theme?: "light" | "dark";
  size?: "sm" | "md" | "lg";
};

const sizeMap = {
  sm: 30,
  md: 40,
  lg: 52
} as const;

export const CooksyLogo = ({ variant = "horizontal", theme = "light", size = "md" }: CooksyLogoProps) => {
  const iconSize = sizeMap[size];
  const wordColor = theme === "dark" ? "#FFFDF7" : "#111111";
  const iconBg = theme === "dark" ? "#F5C400" : "#F5C400";
  const glyph = theme === "dark" ? "#111111" : "#111111";

  return (
    <View className="flex-row items-center" style={{ gap: 10 }}>
      <Svg width={iconSize} height={iconSize} viewBox="0 0 64 64" fill="none">
        <Circle cx="32" cy="32" r="32" fill={iconBg} />
        <Path
          d="M32 14c-7 0-12 5.2-12 12.1 0 4.7 2.5 8.8 5.9 11.8-3.4 2.7-5.9 6.4-5.9 11.2C20 56 25.2 61 32 61s12-5 12-11.9c0-4.8-2.5-8.5-5.9-11.2 3.4-3 5.9-7.1 5.9-11.8C44 19.2 39 14 32 14Zm0 5.1c4 0 6.8 2.9 6.8 7.1 0 4.8-3.2 8.2-6.8 10.6-3.6-2.4-6.8-5.8-6.8-10.6 0-4.2 2.8-7.1 6.8-7.1Zm0 23c3.5 2.4 6.5 5.4 6.5 9.2 0 3.4-2.7 5.6-6.5 5.6s-6.5-2.2-6.5-5.6c0-3.8 3-6.8 6.5-9.2Z"
          fill={glyph}
        />
        <Path d="M25 36.5h14" stroke={glyph} strokeWidth="3.5" strokeLinecap="round" />
      </Svg>
      {variant === "horizontal" ? (
        <Text
          className="font-bold tracking-tight"
          style={{
            color: wordColor,
            fontSize: size === "lg" ? 30 : size === "md" ? 24 : 19
          }}
        >
          Cooksy
        </Text>
      ) : null}
    </View>
  );
};
