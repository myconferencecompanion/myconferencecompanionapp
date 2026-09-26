import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { MobileShell } from "@/components/app/MobileShell";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    // Strict members-only: every route under this layout requires an account.
    const { data } = await supabase.auth.getUser();
    if (!data.user) throw redirect({ to: "/auth" });
    return { user: { id: data.user.id } };
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
