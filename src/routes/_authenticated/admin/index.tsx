import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";
import { useAuth, type AppRole } from "@/lib/auth";
import {
  Calendar,
  Mic,
  Hotel,
  Phone,
  Megaphone,
  Users,
  UtensilsCrossed,
  ClipboardList,
  ConciergeBell,
  ShoppingBag,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/")({
  component: AdminOverview,
});

type CardDef = {
  label: string;
  icon: typeof Calendar;
  value: number | "—";
  to:
    | "/admin/sessions"
    | "/admin/speakers"
    | "/admin/accommodations"
    | "/admin/emergency"
    | "/admin/announcements"
    | "/admin/menu"
    | "/admin/orders"
    | "/admin/ushers"
    | "/admin/errands";
  roles: AppRole[];
};

function AdminOverview() {
  const { roles, hasAnyAdminRole } = useAuth();
  const isSuper = roles.includes("super_admin");

  const { data: counts } = useQuery({
    queryKey: ["admin-counts"],
    queryFn: async () => {
      const [s, sp, a, e, an, p, m, o, u, er] = await Promise.all([
        supabase.from("sessions").select("id", { count: "exact", head: true }),
        supabase.from("speakers").select("id", { count: "exact", head: true }),
        supabase.from("accommodations").select("id", { count: "exact", head: true }),
        supabase.from("emergency_contacts").select("id", { count: "exact", head: true }),
        supabase.from("announcements").select("id", { count: "exact", head: true }),
        supabase.from("profiles").select("id", { count: "exact", head: true }),
        supabase.from("menu_items").select("id", { count: "exact", head: true }),
        supabase.from("food_orders").select("id", { count: "exact", head: true }).in("status", ["pending", "preparing", "ready"]),
        supabase.from("usher_requests").select("id", { count: "exact", head: true }).in("status", ["pending", "acknowledged"]),
        supabase.from("errand_requests").select("id", { count: "exact", head: true }).in("status", ["requested", "accepted", "in_progress"]),
      ]);
      return {
        sessions: s.count ?? 0,
        speakers: sp.count ?? 0,
        accommodations: a.count ?? 0,
        emergency: e.count ?? 0,
        announcements: an.count ?? 0,
        attendees: p.count ?? 0,
        menu: m.count ?? 0,
        openOrders: o.count ?? 0,
        openUshers: u.count ?? 0,
        openErrands: er.count ?? 0,
      };
    },
  });

  const cards: CardDef[] = [
    { label: "Sessions", icon: Calendar, value: counts?.sessions ?? "—", to: "/admin/sessions", roles: ["program"] },
    { label: "Speakers", icon: Mic, value: counts?.speakers ?? "—", to: "/admin/speakers", roles: ["program"] },
    { label: "Hotels", icon: Hotel, value: counts?.accommodations ?? "—", to: "/admin/accommodations", roles: ["logistics"] },
    { label: "Emergency", icon: Phone, value: counts?.emergency ?? "—", to: "/admin/emergency", roles: ["logistics"] },
    { label: "Announcements", icon: Megaphone, value: counts?.announcements ?? "—", to: "/admin/announcements", roles: ["comms"] },
    { label: "Menu items", icon: UtensilsCrossed, value: counts?.menu ?? "—", to: "/admin/menu", roles: ["kitchen"] },
    { label: "Open orders", icon: ShoppingBag, value: counts?.openOrders ?? "—", to: "/admin/orders", roles: ["kitchen"] },
    { label: "Usher queue", icon: ConciergeBell, value: counts?.openUshers ?? "—", to: "/admin/ushers", roles: ["front_desk"] },
    { label: "Errands queue", icon: ClipboardList, value: counts?.openErrands ?? "—", to: "/admin/errands", roles: ["front_desk"] },
  ];

  const visible = cards.filter((c) => isSuper || hasAnyAdminRole(c.roles));

  return (
    <div>
      <h2 className="mb-3 text-base font-semibold">At a glance</h2>
      <div className="grid grid-cols-2 gap-3">
        {isSuper && (
          <Card className="col-span-2 border-0 p-4 shadow-card">
            <Users className="h-5 w-5 text-primary" />
            <p className="mt-2 text-2xl font-bold">{counts?.attendees ?? "—"}</p>
            <p className="text-xs text-muted-foreground">Total attendees</p>
          </Card>
        )}
        {visible.map(({ label, icon: Icon, value, to }) => (
          <Link key={label} to={to}>
            <Card className="border-0 p-4 shadow-card transition active:scale-[0.98]">
              <Icon className="h-5 w-5 text-primary" />
              <p className="mt-2 text-2xl font-bold">{value}</p>
              <p className="text-xs text-muted-foreground">{label}</p>
            </Card>
          </Link>
        ))}
      </div>
      <p className="mt-6 text-xs text-muted-foreground">
        {isSuper
          ? "Super Admin: you can manage every section."
          : "You're seeing only the sections assigned to your role. Tap a card to manage it."}
      </p>
    </div>
  );
}
