import { Search } from "lucide-react-native";
import { TextInput, View } from "react-native";

type SearchInputProps = {
  value: string;
  onChangeText: (value: string) => void;
  placeholder?: string;
};

export const SearchInput = ({ value, onChangeText, placeholder = "Search" }: SearchInputProps) => (
  <View className="flex-row items-center rounded-full border border-line bg-white px-4 py-3" style={{ gap: 10 }}>
    <Search size={18} color="#706B61" />
    <TextInput
      value={value}
      onChangeText={onChangeText}
      placeholder={placeholder}
      placeholderTextColor="#8A8478"
      className="flex-1 text-[15px] text-soft-ink"
    />
  </View>
);
