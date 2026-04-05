import { Redirect } from "expo-router";
import { Platform } from "react-native";

import { WebLandingPage } from "@/components/marketing/WebLandingPage";

export default function RootIndexScreen() {
  if (Platform.OS !== "web") {
    return <Redirect href={"/auth" as never} />;
  }

  return <WebLandingPage />;
}
