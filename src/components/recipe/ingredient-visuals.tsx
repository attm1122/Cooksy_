import type { ImageSourcePropType } from "react-native";
import type { LucideIcon } from "lucide-react-native";
import {
  Bean,
  ChefHat,
  Cherry,
  Cookie,
  Ham,
  Milk,
  Nut,
  Sprout,
  Vegan,
  Wheat
} from "lucide-react-native";

const ingredientIllustrations = {
  apple: require("../../../assets/ingredient-icons/apple.png"),
  broccoli: require("../../../assets/ingredient-icons/broccoli.png"),
  carrot: require("../../../assets/ingredient-icons/carrot.png"),
  drumstick: require("../../../assets/ingredient-icons/drumstick.png"),
  egg: require("../../../assets/ingredient-icons/egg.png"),
  fish: require("../../../assets/ingredient-icons/fish.png"),
  garlic: require("../../../assets/ingredient-icons/garlic.png"),
  lemon: require("../../../assets/ingredient-icons/lemon.png"),
  pantryCan: require("../../../assets/ingredient-icons/pantry_can.png"),
  pepper: require("../../../assets/ingredient-icons/pepper.png"),
  shrimp: require("../../../assets/ingredient-icons/shrimp.png"),
  steak: require("../../../assets/ingredient-icons/steak.png")
} as const;

type BaseIngredientVisual = {
  label: string;
};

type IllustrationVisual = BaseIngredientVisual & {
  kind: "illustration";
  asset: ImageSourcePropType;
};

type IconVisual = BaseIngredientVisual & {
  kind: "icon";
  Icon: LucideIcon;
  backgroundColor: string;
  borderColor: string;
  iconColor: string;
};

export type IngredientVisual = IllustrationVisual | IconVisual;

type IngredientMatcher = IngredientVisual & {
  keywords: string[];
};

const ingredientMatchers: IngredientMatcher[] = [
  {
    kind: "illustration",
    asset: ingredientIllustrations.drumstick,
    label: "Chicken",
    keywords: ["chicken", "thigh", "breast", "drumstick", "wing", "turkey"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.steak,
    label: "Meat",
    keywords: ["beef", "steak", "mince", "ground beef", "lamb", "veal"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.shrimp,
    label: "Seafood",
    keywords: ["shrimp", "prawn", "scampi"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.fish,
    label: "Seafood",
    keywords: ["salmon", "fish", "cod", "tuna", "trout", "tilapia", "anchovy", "sardine"],
  },
  {
    kind: "icon",
    Icon: Ham,
    label: "Meat",
    keywords: ["ham", "pork", "bacon", "sausage", "prosciutto", "salami"],
    backgroundColor: "#FFF1ED",
    borderColor: "#F1D8D1",
    iconColor: "#9D5A4B"
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.egg,
    label: "Eggs",
    keywords: ["egg", "eggs"],
  },
  {
    kind: "icon",
    Icon: Milk,
    label: "Dairy",
    keywords: ["milk", "cream", "butter", "yogurt", "parmesan", "mozzarella", "cheddar", "ricotta", "feta", "cheese"],
    backgroundColor: "#FFF8E8",
    borderColor: "#F1E0BF",
    iconColor: "#966D26"
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.lemon,
    label: "Citrus",
    keywords: ["lime", "lemon", "orange", "citrus"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.apple,
    label: "Fruit",
    keywords: ["apple", "pear", "banana", "mango", "peach", "pineapple"],
  },
  {
    kind: "icon",
    Icon: Cherry,
    label: "Fruit",
    keywords: ["berry", "berries", "strawberry", "blueberry", "raspberry", "grape", "cherry"],
    backgroundColor: "#FFF0F3",
    borderColor: "#F0D6DE",
    iconColor: "#A34A67"
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.broccoli,
    label: "Greens",
    keywords: ["spinach", "kale", "lettuce", "rocket", "arugula", "bok choy", "cabbage", "greens"],
  },
  {
    kind: "icon",
    Icon: Sprout,
    label: "Herbs",
    keywords: ["basil", "parsley", "cilantro", "coriander", "mint", "dill", "chives", "rosemary", "thyme", "oregano", "sage"],
    backgroundColor: "#EDF7F0",
    borderColor: "#D4E6D8",
    iconColor: "#39724A"
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.pepper,
    label: "Produce",
    keywords: ["tomato", "pepper", "capsicum", "chili", "chilli"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.garlic,
    label: "Garlic",
    keywords: ["garlic"],
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.carrot,
    label: "Produce",
    keywords: ["onion", "shallot", "ginger", "carrot", "potato", "mushroom", "celery", "leek", "cucumber", "zucchini", "courgette", "broccoli", "cauliflower", "avocado"],
  },
  {
    kind: "icon",
    Icon: Wheat,
    label: "Grain",
    keywords: ["pasta", "rigatoni", "spaghetti", "linguine", "noodle", "orzo", "rice", "flour", "bread", "breadcrumb", "tortilla", "bun", "oats", "quinoa", "couscous"],
    backgroundColor: "#F7F0DF",
    borderColor: "#E7DBC0",
    iconColor: "#8C6A2F"
  },
  {
    kind: "icon",
    Icon: Bean,
    label: "Beans",
    keywords: ["bean", "lentil", "chickpea", "pea", "peas", "edamame"],
    backgroundColor: "#F4EEE9",
    borderColor: "#E3D7CF",
    iconColor: "#775744"
  },
  {
    kind: "icon",
    Icon: Nut,
    label: "Nuts",
    keywords: ["nut", "almond", "peanut", "cashew", "walnut", "pecan", "pistachio", "hazelnut"],
    backgroundColor: "#F6EFE6",
    borderColor: "#E8DAC8",
    iconColor: "#7A5A35"
  },
  {
    kind: "icon",
    Icon: Cookie,
    label: "Sweet",
    keywords: ["honey", "sugar", "chocolate", "cocoa", "vanilla", "maple", "jam", "caramel"],
    backgroundColor: "#FFF1E7",
    borderColor: "#F0DACB",
    iconColor: "#9A5F2E"
  },
  {
    kind: "icon",
    Icon: Vegan,
    label: "Plant protein",
    keywords: ["tofu", "tempeh", "seitan"],
    backgroundColor: "#EDF7ED",
    borderColor: "#D5E7D5",
    iconColor: "#3D7A49"
  },
  {
    kind: "illustration",
    asset: ingredientIllustrations.pantryCan,
    label: "Pantry",
    keywords: ["stock", "broth", "sauce", "soy", "vinegar", "oil", "wine", "chili crisp", "paste", "syrup", "water"],
  }
];

const defaultVisual: IngredientVisual = {
  kind: "icon",
  Icon: ChefHat,
  label: "Ingredient",
  backgroundColor: "#FFF6CC",
  borderColor: "#EAD784",
  iconColor: "#111111"
};

const normalizeIngredientName = (name: string) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

export const getIngredientVisual = (ingredientName: string): IngredientVisual => {
  const normalizedName = normalizeIngredientName(ingredientName);

  return ingredientMatchers.find((matcher) => matcher.keywords.some((keyword) => normalizedName.includes(keyword))) ?? defaultVisual;
};
