import { useNavigate, redirect } from "@tanstack/react-router";
import type { ReactNode } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { LogIn } from "lucide-react";

/**
 * Guest access helpers. A guest is a signed-out visitor browsing the
 * conference content. Reading is free; member actions (agenda, orders,
 * usher calls, chat, networking, admin) prompt them to sign in first.
 */

export function useIsGuest(): boolean {
  const { user, loading } = useAuth();
  return !loading && !user;
}

/**
 * beforeLoad guard for member-only routes (chat rooms, DMs, own orders,
 * profile, waitlist, AI chat). Guests are sent to /auth.
 */
export async function requireUser() {
  const { data } = await supabase.auth.getUser();
  if (!data.user) throw redirect({ to: "/auth" });
}

/**
 * Wrap any member-only action. Guests are redirected to /auth (with a
 * toast) instead of running the action; members run it as normal.
 *
 * const gate = useGuestGate();
 * onClick={gate(() => save.mutate(), "the concierge")}
 */
export function useGuestGate() {
  const navigate = useNavigate();
  const { user } = useAuth();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return function gate(action: (...args: any[]) => void, what = "that") {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return (...args: any[]) => {
      // Always swallow the DOM event so a guest's blocked tap doesn't also
      // trigger a parent onClick (e.g. navigating to the session detail).
      const ev = args[0] as { stopPropagation?: () => void } | undefined;
      if (ev && typeof ev.stopPropagation === "function") ev.stopPropagation();
      if (!user) {
        toast.info(`Sign in to use ${what}`);
        void navigate({ to: "/auth" });
        return;
      }
      action(...args);
    };
  };
}

/** Banner shown on member-only pages when a guest lands there. */
export function GuestCta({ message }: { message: ReactNode }) {
  const navigate = useNavigate();
  return (
    <div className="rounded-2xl bg-primary-soft p-4 shadow-card">
      <div className="flex items-start gap-3">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/15">
          <LogIn className="h-5 w-5 text-primary" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-bold">You're browsing as a guest</p>
          <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">{message}</p>
          <Button size="sm" className="mt-3" onClick={() => void navigate({ to: "/auth" })}>
            Sign in / Create account
          </Button>
        </div>
      </div>
    </div>
  );
}
