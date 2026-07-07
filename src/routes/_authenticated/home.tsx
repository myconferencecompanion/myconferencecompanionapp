import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatTimeRange, formatTime, initials } from "@/lib/format";
import {
  ShieldAlert,
  MessageSquare,
  Megaphone,
  ConciergeBell,
  Compass,
  Calendar,
} from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

export const Route = createFileRoute("/_authenticated/home")({
  component: HomePage,
});

const quickActions = [
  { to: "/maidguide", label: "Maidguide", icon: Compass, tone: "bg-primary-soft text-primary" },
  { to: "/schedule", label: "Schedule", icon: Calendar, tone: "bg-accent-soft text-warning-foreground" },
  { to: "/network", label: "Networking", icon: MessageSquare, tone: "bg-primary-soft text-primary" },
  { to: "/concierge", label: "Concierge", icon: ConciergeBell, tone: "bg-accent-soft text-warning-foreground" },
  { to: "/announcements", label: "News", icon: Megaphone, tone: "bg-primary-soft text-primary" },
  { to: "/emergency", label: "Emergency", icon: ShieldAlert, tone: "bg-destructive/10 text-destructive" },
] as const;

function HomePage() {
  const { user } = useAuth();

  const { data: profile } = useQuery({
    queryKey: ["my-profile", user?.id],
    enabled: !!user,
    queryFn: async () => {
      const { data } = await supabase.from("profiles").select("*").eq("id", user!.id).maybeSingle();
      return data;
    },
  });

  const { data: nextSession } = useQuery({
    queryKey: ["next-session"],
    queryFn: async () => {
      const now = new Date().toISOString();
      const { data } = await supabase
        .from("sessions")
        .select("*, session_speakers(speakers(*))")
        .gte("ends_at", now)
        .order("starts_at")
        .limit(1)
        .maybeSingle();
      return data;
    },
    refetchInterval: 60_000,
  });

  const { data: announcement } = useQuery({
    queryKey: ["latest-announcement"],
    queryFn: async () => {
      const { data } = await supabase
        .from("announcements")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      return data;
    },
  });

  const { data: featuredSpeakers = [] } = useQuery({
    queryKey: ["featured-speakers"],
    queryFn: async () => {
      const { data } = await supabase
        .from("speakers")
        .select("*")
        .order("is_keynote", { ascending: false })
        .limit(6);
      return data ?? [];
    },
  });

  const greeting = greetingText();
  const firstName = profile?.display_name?.split(" ")[0] ?? "there";

  return (
    <div className="space-y-5 px-4 pt-5">
      <section>
        <p className="text-sm text-muted-foreground">{greeting},</p>
        <h2 className="text-2xl font-bold tracking-tight">{firstName} 👋</h2>
      </section>

      {announcement && (
        <Link to="/announcements" className="block">
          <div className="flex items-start gap-3 rounded-2xl border border-accent/30 bg-accent-soft px-4 py-3">
            <Megaphone className="mt-0.5 h-4 w-4 shrink-0 text-warning-foreground" />
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium uppercase tracking-wider text-warning-foreground/70">
                Latest announcement
              </p>
              <p className="truncate text-sm font-semibold text-warning-foreground">{announcement.title}</p>
            </div>
          </div>
        </Link>
      )}

      {nextSession && (
        <Card className="overflow-hidden border-0 shadow-card">
          <Link to="/schedule/$sessionId" params={{ sessionId: nextSession.id }} className="block">
            <div className="bg-brand-gradient p-4 text-white">
              <p className="text-xs font-medium uppercase tracking-wider text-white/70">
                {isLive(nextSession) ? "🔴 Happening now" : "Up next"}
              </p>
              <h3 className="mt-1 text-lg font-bold leading-tight">{nextSession.title}</h3>
              <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-white/80">
                <span>⏱ {formatTimeRange(nextSession.starts_at, nextSession.ends_at)}</span>
                {nextSession.room && <span>📍 {nextSession.room}</span>}
                {nextSession.track && (
                  <Badge variant="secondary" className="bg-white/15 text-white hover:bg-white/20">
                    {nextSession.track}
                  </Badge>
                )}
              </div>
            </div>
            {nextSession.session_speakers && nextSession.session_speakers.length > 0 && (
              <div className="flex items-center gap-2 bg-surface px-4 py-3">
                <div className="flex -space-x-2">
                  {nextSession.session_speakers.slice(0, 3).map((ss) => (
                    <Avatar key={ss.speakers?.id} className="h-7 w-7 border-2 border-surface">
                      <AvatarImage src={ss.speakers?.avatar_url ?? undefined} />
                      <AvatarFallback className="text-[10px]">
                        {initials(ss.speakers?.name ?? "?")}
                      </AvatarFallback>
                    </Avatar>
                  ))}
                </div>
                <p className="truncate text-xs text-muted-foreground">
                  {nextSession.session_speakers
                    .map((ss) => ss.speakers?.name)
                    .filter(Boolean)
                    .join(" · ")}
                </p>
              </div>
            )}
          </Link>
        </Card>
      )}

      <section>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
          Quick access
        </h3>
        <div className="grid grid-cols-3 gap-2.5">
          {quickActions.map(({ to, label, icon: Icon, tone }) => (
            <Link
              key={to}
              to={to}
              className="group flex flex-col items-center gap-2 rounded-2xl border border-border bg-surface p-3 text-center transition active:scale-[0.97]"
            >
              <span className={`flex h-11 w-11 items-center justify-center rounded-xl ${tone}`}>
                <Icon className="h-5 w-5" />
              </span>
              <span className="text-xs font-medium leading-tight">{label}</span>
            </Link>
          ))}
        </div>
      </section>

      {featuredSpeakers.length > 0 && (
        <section>
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Featured speakers
            </h3>
            <Link to="/speakers" className="text-xs font-medium text-primary">See all →</Link>
          </div>
          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {featuredSpeakers.map((sp) => (
              <Link
                key={sp.id}
                to="/speakers/$speakerId"
                params={{ speakerId: sp.id }}
                className="w-32 shrink-0"
              >
                <Card className="overflow-hidden border-0 p-3 shadow-card">
                  <Avatar className="mx-auto h-16 w-16">
                    <AvatarImage src={sp.avatar_url ?? undefined} />
                    <AvatarFallback>{initials(sp.name)}</AvatarFallback>
                  </Avatar>
                  <p className="mt-2 text-center text-xs font-semibold leading-tight">{sp.name}</p>
                  {sp.company && (
                    <p className="mt-0.5 text-center text-[10px] text-muted-foreground">{sp.company}</p>
                  )}
                  {sp.is_keynote && (
                    <Badge className="mt-2 w-full justify-center bg-accent text-accent-foreground hover:bg-accent">
                      Keynote
                    </Badge>
                  )}
                </Card>
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

function greetingText() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

function isLive(s: { starts_at: string; ends_at: string }) {
  const now = Date.now();
  return new Date(s.starts_at).getTime() <= now && new Date(s.ends_at).getTime() >= now;
}
