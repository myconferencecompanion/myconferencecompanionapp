import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { MobileShell } from "@/components/app/MobileShell";

/**
 * Route context: either a signed-in member or a guest.
 * Guests can browse all public conference content read-only; any write
 * action (agenda, orders, usher calls, chat, admin) requires sign-in and
 * is gated per-page via `useGuestGate()`.
 */
type RouteContext = { user: null | { id: string } };

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async (): Promise<RouteContext> => {
    const { data } = await supabase.auth.getUser();
    if (data.user) return { user: { id: data.user.id } };
    // Guests proceed — every member feature redirects them to /auth on use.
    return { user: null };
  },
  component: AuthenticatedLayout,
});

function AuthenticatedLayout() {
  return (
    <MobileShell>
      <Outlet />
    </MobileShell>
  );
}
