import { create } from "zustand";

type AuthStatus = "idle" | "loading" | "ready" | "error";

type AuthState = {
  userId?: string;
  email?: string;
  fullName?: string;
  status: AuthStatus;
  errorMessage?: string;
  setAuthState: (payload: Partial<Pick<AuthState, "userId" | "email" | "fullName" | "status" | "errorMessage">>) => void;
  resetAuthState: () => void;
};

const initialState = {
  userId: undefined,
  email: undefined,
  fullName: undefined,
  status: "idle" as AuthStatus,
  errorMessage: undefined
};

export const useAuthStore = create<AuthState>((set) => ({
  ...initialState,
  setAuthState: (payload) =>
    set((state) => ({
      ...state,
      ...payload
    })),
  resetAuthState: () => set(initialState)
}));
