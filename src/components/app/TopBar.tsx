import { Link, useRouterState } from "@tanstack/react-router";
import { Bell, Search } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { EVENT_CONFIG } from "@/lib/event-config";

export function TopBar() {
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const { user } = useAuth();
  const isHome = pathname === "/home";

  const { data: unread = 0 } = useQuery({
    queryKey: ["unread-announcements", user?.id],
    enabled: !!user,
    queryFn: async () => {
      const [annRes, readRes] = await Promise.all([
        supabase.from("announcements").select("id"),
        supabase.from("announcement_reads").select("announcement_id").eq("user_id", user!.id),
      ]);
      const total = annRes.data?.length ?? 0;
      const readCount = readRes.data?.length ?? 0;
      return Math.max(0, total - readCount);
    },
    refetchInterval: 30_000,
  });

  return (
    <header
      className="sticky top-0 z-30 bg-brand-gradient text-white"
      style={{ paddingTop: "env(safe-area-inset-top)" }}
    >
      <div className="flex items-center justify-between gap-3 px-4 py-3">
        <div>
          {isHome ? (
            <>
              <p className="text-[11px] font-medium uppercase tracking-widest text-white/70">
                {EVENT_CONFIG.dates}
              </p>
              <h1 className="text-base font-semibold">{EVENT_CONFIG.name} {EVENT_CONFIG.year}</h1>
            </>
          ) : (
            <h1 className="text-base font-semibold">{EVENT_CONFIG.shortName}</h1>
          )}
        </div>
        <div className="flex items-center gap-1">
          <Link
            to="/chatbot"
            className="rounded-full p-2 text-white/90 transition hover:bg-white/10"
            aria-label="Open AI assistant"
          >
            <Search className="h-5 w-5" />
          </Link>
          <Link
            to="/announcements"
            className="relative rounded-full p-2 text-white/90 transition hover:bg-white/10"
            aria-label={`Announcements${unread > 0 ? ` (${unread} new)` : ""}`}
          >
            <Bell className="h-5 w-5" />
            {unread > 0 && (
              <span className="absolute right-1 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-accent-foreground">
                {unread > 9 ? "9+" : unread}
              </span>
            )}
          </Link>
        </div>
      </div>
    </header>
  );
}
