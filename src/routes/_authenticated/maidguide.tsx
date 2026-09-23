import { createFileRoute, Link } from "@tanstack/react-router";
import { Card } from "@/components/ui/card";
import { MapPin, Hotel, Coffee, Navigation, Bus, HelpCircle } from "lucide-react";
import { EVENT_CONFIG } from "@/lib/event-config";

export const Route = createFileRoute("/_authenticated/maidguide")({
  component: MaidguidePage,
});

const tiles = [
  {
    to: "/map",
    label: "Venue & Outdoor Map",
    description: "Floor plan, hotspots, and 24 researched places on the map.",
    icon: MapPin,
    tone: "bg-primary-soft text-primary",
  },
  {
    to: "/directions",
    label: "Live Directions",
    description: "Turn-by-turn directions around Maiduguri.",
    icon: Navigation,
    tone: "bg-accent-soft text-warning-foreground",
  },
  {
    to: "/accommodation",
    label: "Hotels",
    description: "The full 46-hotel delegate masterlist with rates.",
    icon: Hotel,
    tone: "bg-primary-soft text-primary",
  },
  {
    to: "/nearby",
    label: "Nearby Places",
    description: "Security, hospitals, government offices & more.",
    icon: Coffee,
    tone: "bg-accent-soft text-warning-foreground",
  },
  {
    to: "/transport",
    label: "Shuttle Transport",
    description: "10 delegate buses, marshals and daily schedule.",
    icon: Bus,
    tone: "bg-primary-soft text-primary",
  },
  {
    to: "/faq",
    label: "Conference Guide",
    description: "40 searchable answers — wifi, badges, meals…",
    icon: HelpCircle,
    tone: "bg-accent-soft text-warning-foreground",
  },
] as const;

function MaidguidePage() {
  return (
    <div className="space-y-5 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">Maidguide</h2>
        <p className="text-sm text-muted-foreground">
          Your guide to {EVENT_CONFIG.venue.name} and Maiduguri.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-3">
        {tiles.map(({ to, label, description, icon: Icon, tone }) => (
          <Link key={to} to={to}>
            <Card className="flex items-center gap-4 border-0 p-4 shadow-card transition active:scale-[0.99]">
              <span className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${tone}`}>
                <Icon className="h-6 w-6" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{label}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">{description}</p>
              </div>
              <span className="text-muted-foreground">›</span>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
