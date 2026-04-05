/* eslint-disable @typescript-eslint/no-require-imports */
import type {
  createJSONStorage as createJSONStorageType,
  persist as persistType,
  subscribeWithSelector as subscribeWithSelectorType
} from "zustand/middleware";

const middleware = require("zustand/middleware.js") as {
  createJSONStorage: typeof createJSONStorageType;
  persist: typeof persistType;
  subscribeWithSelector: typeof subscribeWithSelectorType;
};

export const { createJSONStorage, persist, subscribeWithSelector } = middleware;
