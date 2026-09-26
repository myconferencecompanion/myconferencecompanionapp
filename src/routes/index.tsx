import { createFileRoute, Link } from "@tanstack/react-router";
import { EVENT_CONFIG } from "@/lib/event-config";
import { Button } from "@/components/ui/button";
import { Calendar, MapPin, Sparkles, Users, ShieldAlert, MessageCircle } from "lucide-react";

export const Route = createFileRoute("/")({
  ssr: false,
  head: () => ({
    meta: [
      { title: `${EVENT_CONFIG.name} ${EVENT_CONFIG.year} — Your Conference Companion` },
      { name: "description", content: `Schedule, speakers, venue map, networking, and live directions for ${EVENT_CONFIG.name} ${EVENT_CONFIG.year}.` },
    ],
  }),
  component: LandingPage,
});

const features = [
  { icon: Calendar, label: "Full 7-day programme" },
  { icon: MapPin, label: "Venue & city maps" },
  { icon: Users, label: "Attendee networking" },
  { icon: Sparkles, label: "AI conference assistant" },
  { icon: MessageCircle, label: "Group chat rooms" },
  { icon: ShieldAlert, label: "Emergency one-tap" },
];

/** "7 days of talks" derived from EVENT_CONFIG so copy never goes stale. */
function durationPhrase() {
  const days = Math.max(
    1,
    Math.round(
      (EVENT_CONFIG.end.getTime() - EVENT_CONFIG.start.getTime()) / 86_400_000,
    ),
  );
  return `${days} days`;
}

function LandingPage() {
  return (
    <div className="mx-auto flex min-h-screen w-full max-w-[640px] flex-col bg-brand-gradient text-white">
      <div className="flex flex-1 flex-col justify-between px-6 py-10">
        <header>
          <p className="text-xs font-medium uppercase tracking-[0.3em] text-white/70">
            {EVENT_CONFIG.dates}
          </p>
          <h1 className="mt-2 text-4xl font-bold leading-tight">
            {EVENT_CONFIG.name}
            <br />
            <span className="text-accent">{EVENT_CONFIG.year}</span>
          </h1>
          <p className="mt-3 max-w-sm text-base text-white/80">
            {EVENT_CONFIG.tagline}. Your companion for {durationPhrase()} of talks, ideas, and connections at{" "}
            {EVENT_CONFIG.venue.name}, Maiduguri.
          </p>
        </header>

        <div className="my-10 grid grid-cols-2 gap-3">
          {features.map(({ icon: Icon, label }) => (
            <div key={label} className="rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
              <Icon className="h-5 w-5 text-accent" />
              <p className="mt-2 text-sm font-medium leading-tight">{label}</p>
            </div>
          ))}
        </div>

        <div className="space-y-3">
          <Button asChild size="lg" className="h-12 w-full bg-white text-primary hover:bg-white/90">
            <Link to="/home">Explore the app</Link>
          </Button>
          <Button
            asChild
            size="lg"
            variant="outline"
            className="h-12 w-full border-white/40 bg-transparent text-white hover:bg-white/10 hover:text-white"
          >
            <Link to="/auth">Sign in</Link>
          </Button>
          <p className="text-center text-xs text-white/60">
            Browse freely as a guest — sign in to build your agenda, order meals, and network.
          </p>
        </div>
      </div>
    </div>
  );
}
