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

export const Route = createFileRoute("/_authenticated/admin/ushers")({
  beforeLoad: () => requireSubRole(["front_desk"]),
  component: AdminUshers,
});

function AdminUshers() {
  const qc = useQueryClient();
  const { data: requests = [] } = useQuery({
    queryKey: ["admin-usher-requests"],
    queryFn: async () => {
      const { data } = await supabase
        .from("usher_requests")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(100);
      return data ?? [];
    },
  });

  useEffect(() => {
    const ch = supabase
      .channel("admin-ushers")
      .on("postgres_changes", { event: "*", schema: "public", table: "usher_requests" },
        () => qc.invalidateQueries({ queryKey: ["admin-usher-requests"] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [qc]);

  const update = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const patch: { status: string; acknowledged_at?: string; resolved_at?: string } = { status };
      if (status === "acknowledged") patch.acknowledged_at = new Date().toISOString();
      if (status === "resolved") patch.resolved_at = new Date().toISOString();
      const { error } = await supabase.from("usher_requests").update(patch).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-usher-requests"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const active = requests.filter((r) => r.status === "pending" || r.status === "acknowledged");
  const done = requests.filter((r) => r.status === "resolved" || r.status === "cancelled");

  return (
    <div className="space-y-5">
      <div>
        <h2 className="mb-2 text-base font-semibold">Active queue ({active.length})</h2>
        {active.length === 0 ? (
          <p className="text-sm text-muted-foreground">No active requests.</p>
        ) : (
          <div className="space-y-2">
            {active.map((r) => (
              <Card key={r.id} className="border-0 p-3 shadow-card">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{r.reason}</p>
                    {r.location_label && <p className="text-xs">📍 {r.location_label}</p>}
                    {r.note && <p className="text-xs text-muted-foreground">{r.note}</p>}
                    <p className="mt-1 text-[11px] text-muted-foreground">{formatRelative(r.created_at)}</p>
                  </div>
                  <Badge className={r.status === "pending" ? "bg-accent text-accent-foreground" : "bg-primary text-primary-foreground"}>
                    {r.status}
                  </Badge>
                </div>
                <div className="mt-3 flex gap-2">
                  {r.status === "pending" && (
                    <Button size="sm" variant="outline" onClick={() => update.mutate({ id: r.id, status: "acknowledged" })}>
                      Acknowledge
                    </Button>
                  )}
                  <Button size="sm" onClick={() => update.mutate({ id: r.id, status: "resolved" })}>
                    Mark resolved
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>

      <div>
        <h2 className="mb-2 text-base font-semibold">Resolved ({done.length})</h2>
        <div className="space-y-1">
          {done.slice(0, 20).map((r) => (
            <Card key={r.id} className="flex items-center gap-2 border-0 p-2 text-xs shadow-card">
              <span className="flex-1 truncate">{r.reason} · {r.location_label ?? "—"}</span>
              <span className="text-muted-foreground">{formatRelative(r.created_at)}</span>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
