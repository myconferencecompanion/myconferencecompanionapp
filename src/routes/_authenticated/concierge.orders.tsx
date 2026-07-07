import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ChevronLeft } from "lucide-react";
import { formatRelative } from "@/lib/format";

export const Route = createFileRoute("/_authenticated/concierge/orders")({
  component: OrdersPage,
});

function OrdersPage() {
  const { user } = useAuth();
  const qc = useQueryClient();

  const { data: orders = [] } = useQuery({
    queryKey: ["my-orders", user?.id],
    enabled: !!user,
    queryFn: async () => {
      const { data } = await supabase
        .from("food_orders")
        .select("*, food_order_items(*)")
        .eq("user_id", user!.id)
        .order("created_at", { ascending: false });
      return data ?? [];
    },
  });

  const { data: errands = [] } = useQuery({
    queryKey: ["my-errands", user?.id],
    enabled: !!user,
    queryFn: async () => {
      const { data } = await supabase
        .from("errand_requests")
        .select("*")
        .eq("user_id", user!.id)
        .order("created_at", { ascending: false });
      return data ?? [];
    },
  });

  useEffect(() => {
    if (!user) return;
    const ch = supabase
      .channel("my-orders-errands")
      .on("postgres_changes",
        { event: "*", schema: "public", table: "food_orders", filter: `user_id=eq.${user.id}` },
        () => qc.invalidateQueries({ queryKey: ["my-orders", user.id] }))
      .on("postgres_changes",
        { event: "*", schema: "public", table: "errand_requests", filter: `user_id=eq.${user.id}` },
        () => qc.invalidateQueries({ queryKey: ["my-errands", user.id] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [user, qc]);

  return (
    <div className="space-y-5 px-4 pt-5 pb-8">
      <Link to="/concierge" className="inline-flex items-center text-sm text-muted-foreground">
        <ChevronLeft className="h-4 w-4" /> Concierge
      </Link>
      <h2 className="text-xl font-bold">My orders & requests</h2>

      <section>
        <h3 className="mb-2 text-sm font-semibold uppercase tracking-wider text-muted-foreground">Food orders</h3>
        {orders.length === 0 ? (
          <p className="text-sm text-muted-foreground">No food orders yet.</p>
        ) : (
          <div className="space-y-2">
            {orders.map((o) => (
              <Card key={o.id} className="border-0 p-3 shadow-card">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{o.food_order_items?.reduce((s, i) => s + i.quantity, 0) ?? 0} items · Complimentary</p>
                    {o.pickup_location && <p className="text-xs text-muted-foreground">📍 {o.pickup_location}</p>}
                    <p className="mt-1 text-[11px] text-muted-foreground">{formatRelative(o.created_at)}</p>
                    {o.food_order_items && o.food_order_items.length > 0 && (
                      <p className="mt-1 text-xs">
                        {o.food_order_items.map((i) => `${i.quantity}× ${i.item_name_snapshot}`).join(", ")}
                      </p>
                    )}
                  </div>
                  <OrderStatusBadge status={o.status} />
                </div>
              </Card>
            ))}
          </div>
        )}
      </section>

      <section>
        <div className="mb-2 flex items-center justify-between">
          <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">Errands</h3>
          <Link to="/concierge/errands" className="text-xs font-medium text-primary">New errand →</Link>
        </div>
        {errands.length === 0 ? (
          <p className="text-sm text-muted-foreground">No errands yet.</p>
        ) : (
          <div className="space-y-2">
            {errands.map((e) => (
              <Card key={e.id} className="border-0 p-3 shadow-card">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{e.category}</p>
                    <p className="text-xs text-muted-foreground">{e.description}</p>
                    {e.room_number && <p className="text-[11px] text-muted-foreground">Room {e.room_number}</p>}
                    <p className="mt-1 text-[11px] text-muted-foreground">{formatRelative(e.created_at)}</p>
                  </div>
                  <ErrandStatusBadge status={e.status} urgency={e.urgency} />
                </div>
              </Card>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function OrderStatusBadge({ status }: { status: string }) {
  const tone: Record<string, string> = {
    pending: "bg-accent-soft text-warning-foreground",
    preparing: "bg-primary-soft text-primary",
    ready: "bg-primary text-primary-foreground",
    delivered: "bg-muted text-muted-foreground",
    cancelled: "bg-destructive/10 text-destructive",
  };
  return <Badge className={tone[status] ?? "bg-muted"}>{status}</Badge>;
}

function ErrandStatusBadge({ status, urgency }: { status: string; urgency: string }) {
  const tone: Record<string, string> = {
    requested: "bg-accent-soft text-warning-foreground",
    accepted: "bg-primary-soft text-primary",
    in_progress: "bg-primary text-primary-foreground",
    completed: "bg-muted text-muted-foreground",
    cancelled: "bg-destructive/10 text-destructive",
  };
  return (
    <div className="flex flex-col items-end gap-1">
      <Badge className={tone[status] ?? "bg-muted"}>{status.replace("_", " ")}</Badge>
      {urgency === "urgent" && <Badge variant="destructive">urgent</Badge>}
    </div>
  );
}
