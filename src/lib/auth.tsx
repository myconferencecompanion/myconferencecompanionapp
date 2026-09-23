import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { useQueryClient } from "@tanstack/react-query";
import { useRouter } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { isSupabaseConfigured, DEMO_MESSAGE } from "@/lib/supabase-stub";
import { toast } from "sonner";

export type AppRole =
  | "attendee"
  | "admin"
  | "super_admin"
  | "front_desk"
  | "kitchen"
  | "program"
  | "logistics"
  | "comms";

type AuthContextValue = {
  user: User | null;
  session: Session | null;
  loading: boolean;
  isAdmin: boolean;
  roles: AppRole[];
  hasRole: (role: AppRole) => boolean;
  hasAnyAdminRole: (roles: AppRole[]) => boolean;
  refreshRoles: () => Promise<void>;
  signOut: () => Promise<void>;
  /** Non-null when running without a backend (demo mode). */
  demoMessage: string | null;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

const PENDING_CODE_KEY = "pending_role_code";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [roles, setRoles] = useState<AppRole[]>([]);
  const router = useRouter();
  const queryClient = useQueryClient();

  async function loadRoles(userId: string) {
    const { data } = await supabase.from("user_roles").select("role").eq("user_id", userId);
    setRoles(((data ?? []).map((r) => r.role)) as AppRole[]);
  }

  async function tryRedeemPendingCode() {
    if (typeof window === "undefined") return;
    const code = window.localStorage.getItem(PENDING_CODE_KEY);
    if (!code) return;
    const { data, error } = await supabase.rpc("redeem_signup_code", { _code: code });
    window.localStorage.removeItem(PENDING_CODE_KEY);
    if (error) {
      toast.error(`Role code: ${error.message}`);
      return;
    }
    const label = Array.isArray(data) && data[0]?.label;
    if (label) toast.success(`Role granted: ${label}`);
  }

  useEffect(() => {
    let mounted = true;

    if (!isSupabaseConfigured()) {
      // Demo mode: no backend — stay "signed out" without crashing.
      setLoading(false);
      return;
    }

    const { data: subscription } = supabase.auth.onAuthStateChange((event, newSession) => {
      if (!mounted) return;
      setSession(newSession);
      if (newSession?.user) {
        setTimeout(async () => {
          if (event === "SIGNED_IN") {
            await tryRedeemPendingCode();
          }
          await loadRoles(newSession.user.id);
        }, 0);
      } else {
        setRoles([]);
      }
      void router.invalidate();
      void queryClient.invalidateQueries();
    });

    supabase.auth.getSession().then(({ data: { session: existing } }) => {
      if (!mounted) return;
      setSession(existing);
      if (existing?.user) {
        void loadRoles(existing.user.id);
      }
      setLoading(false);
    });

    return () => {
      mounted = false;
      subscription.subscription.unsubscribe();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const isAdmin = roles.includes("admin") || roles.includes("super_admin");

  const value: AuthContextValue = {
    user: session?.user ?? null,
    session,
    loading,
    isAdmin,
    roles,
    hasRole: (role) => roles.includes(role),
    hasAnyAdminRole: (rs) => roles.includes("super_admin") || rs.some((r) => roles.includes(r)),
    refreshRoles: async () => {
      if (session?.user) await loadRoles(session.user.id);
    },
    signOut: async () => {
      await supabase.auth.signOut();
    },
    demoMessage: isSupabaseConfigured() ? null : DEMO_MESSAGE,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}

export function stashPendingRoleCode(code: string) {
  if (typeof window !== "undefined") {
    window.localStorage.setItem(PENDING_CODE_KEY, code.trim());
  }
}
