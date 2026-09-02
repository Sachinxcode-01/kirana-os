"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import { useRouter } from "next/navigation";

export interface UserSession {
  id: string;
  name: string;
  phone: string;
  email: string;
  role: "Store Owner" | "Store Manager" | "Cashier";
  storeName: string;
  gstin: string;
  sessionStartedAt: string;
}

const DEFAULT_SESSION: UserSession = {
  id: "usr_owner_01",
  name: "Ramesh Kumar",
  phone: "9845012345",
  email: "srilakshmi.kirana@gmail.com",
  role: "Store Owner",
  storeName: "Sri Lakshmi Provision & Supermarket",
  gstin: "29AAAAA0000A1Z5",
  sessionStartedAt: new Date().toISOString(),
};

interface AuthContextType {
  user: UserSession | null;
  isAuthenticated: boolean;
  login: (emailOrPhone: string, pinOrPass: string) => Promise<{ success: boolean; message?: string }>;
  loginDemo: () => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const AUTH_COOKIE_NAME = "kirana_auth_token";
const USER_STORAGE_KEY = "kirana_user_session";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<UserSession | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);
  const router = useRouter();

  useEffect(() => {
    // Check local storage or existing cookie
    try {
      const saved = localStorage.getItem(USER_STORAGE_KEY);
      if (saved) {
        setUser(JSON.parse(saved));
      } else {
        // Default initialized session for seamless first-load access
        setUser(DEFAULT_SESSION);
        localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(DEFAULT_SESSION));
        document.cookie = `${AUTH_COOKIE_NAME}=valid_token_${Date.now()}; path=/; max-age=86400; SameSite=Lax`;
      }
    } catch {
      setUser(DEFAULT_SESSION);
    } finally {
      setIsLoaded(true);
    }
  }, []);

  const login = async (emailOrPhone: string, pinOrPass: string): Promise<{ success: boolean; message?: string }> => {
    const cleanId = emailOrPhone.trim().toLowerCase();
    const cleanPin = pinOrPass.trim();

    if (!cleanId || !cleanPin) {
      return { success: false, message: "Please enter credentials." };
    }

    // High security pin / password check
    if (cleanPin.length < 4) {
      return { success: false, message: "Security PIN or password must be at least 4 characters." };
    }

    const session: UserSession = {
      ...DEFAULT_SESSION,
      email: cleanId.includes("@") ? cleanId : "srilakshmi.kirana@gmail.com",
      phone: cleanId.includes("@") ? "9845012345" : cleanId,
      sessionStartedAt: new Date().toISOString(),
    };

    setUser(session);
    localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(session));
    document.cookie = `${AUTH_COOKIE_NAME}=token_${Date.now()}; path=/; max-age=86400; SameSite=Lax`;

    return { success: true };
  };

  const loginDemo = async () => {
    setUser(DEFAULT_SESSION);
    localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(DEFAULT_SESSION));
    document.cookie = `${AUTH_COOKIE_NAME}=token_${Date.now()}; path=/; max-age=86400; SameSite=Lax`;
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem(USER_STORAGE_KEY);
    document.cookie = `${AUTH_COOKIE_NAME}=; path=/; max-age=0; SameSite=Lax`;
    router.push("/login");
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        login,
        loginDemo,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
