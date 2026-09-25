import { createFileRoute, Link } from "@tanstack/react-router";
import { Card } from "@/components/ui/card";
import { BellRing, UtensilsCrossed, ReceiptText } from "lucide-react";

export const Route = createFileRoute("/_authenticated/concierge/")({
  component: ConciergeHub,
});

const tiles = [
  {
    to: "/concierge/usher",
    label: "Beckon an Usher",
    desc: "Need help in your session? Call an usher to your seat.",
    icon: BellRing,
    tone: "bg-primary-soft text-primary",
  },
  {
    to: "/concierge/food",
    label: "Food Menu & Orders",
    desc: "Browse the menu, place an order, track status.",
    icon: UtensilsCrossed,
    tone: "bg-accent-soft text-warning-foreground",
  },
  {
    to: "/concierge/orders",
    label: "My Orders & Requests",
    desc: "View status of food orders.",
    icon: ReceiptText,
    tone: "bg-accent-soft text-warning-foreground",
  },
] as const;

function ConciergeHub() {
  return (
    <div className="space-y-5 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">Concierge</h2>
        <p className="text-sm text-muted-foreground">
          Convenience services for attendees.
        </p>
      </div>
      <div className="space-y-3">
        {tiles.map(({ to, label, desc, icon: Icon, tone }) => (
          <Link key={to} to={to}>
            <Card className="flex items-center gap-3 border-0 p-4 shadow-card transition active:scale-[0.99]">
              <span className={`flex h-11 w-11 items-center justify-center rounded-xl ${tone}`}>
                <Icon className="h-5 w-5" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{label}</p>
                <p className="truncate text-xs text-muted-foreground">{desc}</p>
              </div>
              <span className="text-muted-foreground">›</span>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
