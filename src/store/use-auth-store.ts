import { create } from "zustand";

type AuthStatus = "idle" | "loading" | "ready" | "error";

type AuthState = {
  userId?: string;
  status: AuthStatus;
  errorMessage?: string;
  setAuthState: (payload: Partial<Pick<AuthState, "userId" | "status" | "errorMessage">>) => void;
};

export const useAuthStore = create<AuthState>((set) => ({
  userId: undefined,
  status: "idle",
  errorMessage: undefined,
  setAuthState: (payload) =>
    set((state) => ({
      ...state,
      ...payload
    }))
}));
