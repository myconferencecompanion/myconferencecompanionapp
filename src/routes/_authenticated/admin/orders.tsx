import { createFileRoute } from "@tanstack/react-router";
import { requireSubRole } from "@/lib/admin-guard";
import { useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { formatRelative } from "@/lib/format";
import { toast } from "sonner";

export const Route = createFileRoute("/_authenticated/admin/orders")({
  beforeLoad: () => requireSubRole(["kitchen"]),
  component: AdminOrders,
});

const NEXT: Record<string, { label: string; status: string } | null> = {
  pending: { label: "Mark preparing", status: "preparing" },
  preparing: { label: "Mark ready", status: "ready" },
  ready: { label: "Mark delivered", status: "delivered" },
  delivered: null,
  cancelled: null,
};

function AdminOrders() {
  const qc = useQueryClient();
  const { data: orders = [] } = useQuery({
    queryKey: ["admin-food-orders"],
    queryFn: async () => {
      const { data } = await supabase
        .from("food_orders")
        .select("*, food_order_items(*), profiles:user_id(display_name)")
        .order("created_at", { ascending: false })
        .limit(100);
      return data ?? [];
    },
  });

  useEffect(() => {
    const ch = supabase.channel("admin-orders")
      .on("postgres_changes", { event: "*", schema: "public", table: "food_orders" },
        () => qc.invalidateQueries({ queryKey: ["admin-food-orders"] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [qc]);

  const update = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const { error } = await supabase.from("food_orders").update({ status }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-food-orders"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const active = orders.filter((o) => o.status !== "delivered" && o.status !== "cancelled");
  const done = orders.filter((o) => o.status === "delivered" || o.status === "cancelled");

  return (
    <div className="space-y-5">
      <div>
        <h2 className="mb-2 text-base font-semibold">Active orders ({active.length})</h2>
        {active.length === 0 ? (
          <p className="text-sm text-muted-foreground">No active orders.</p>
        ) : (
          <div className="space-y-2">
            {active.map((o) => {
              const next = NEXT[o.status];
              return (
                <Card key={o.id} className="border-0 p-3 shadow-card">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold">
                        {(o as { profiles?: { display_name?: string } }).profiles?.display_name ?? "Attendee"} · {o.food_order_items?.reduce((s, i) => s + i.quantity, 0) ?? 0} items
                      </p>
                      {o.pickup_location && <p className="text-xs">📍 {o.pickup_location}</p>}
                      {o.notes && <p className="text-xs text-muted-foreground">Note: {o.notes}</p>}
                      <p className="mt-1 text-xs">
                        {o.food_order_items?.map((i) => `${i.quantity}× ${i.item_name_snapshot}`).join(", ")}
                      </p>
                      <p className="mt-1 text-[11px] text-muted-foreground">{formatRelative(o.created_at)}</p>
                    </div>
                    <Badge>{o.status}</Badge>
                  </div>
                  <div className="mt-3 flex gap-2">
                    {next && (
                      <Button size="sm" onClick={() => update.mutate({ id: o.id, status: next.status })}>
                        {next.label}
                      </Button>
                    )}
                    <Button size="sm" variant="outline" onClick={() => update.mutate({ id: o.id, status: "cancelled" })}>
                      Cancel
                    </Button>
                  </div>
                </Card>
              );
            })}
          </div>
        )}
      </div>

      <div>
        <h2 className="mb-2 text-base font-semibold">Completed ({done.length})</h2>
        <div className="space-y-1">
          {done.slice(0, 20).map((o) => (
            <Card key={o.id} className="flex items-center gap-2 border-0 p-2 text-xs shadow-card">
              <span className="flex-1 truncate">{o.food_order_items?.reduce((s, i) => s + i.quantity, 0) ?? 0} items · {o.status}</span>
              <span className="text-muted-foreground">{formatRelative(o.created_at)}</span>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
