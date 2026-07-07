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

export const Route = createFileRoute("/_authenticated/admin/errands")({
  beforeLoad: () => requireSubRole(["front_desk"]),
  component: AdminErrands,
});

const NEXT: Record<string, { label: string; status: string } | null> = {
  requested: { label: "Accept", status: "accepted" },
  accepted: { label: "Start", status: "in_progress" },
  in_progress: { label: "Complete", status: "completed" },
  completed: null,
  cancelled: null,
};

function AdminErrands() {
  const qc = useQueryClient();
  const { data: errands = [] } = useQuery({
    queryKey: ["admin-errands"],
    queryFn: async () => {
      const { data } = await supabase
        .from("errand_requests")
        .select("*, accommodations:accommodation_id(name), profiles:user_id(display_name)")
        .order("urgency", { ascending: false })
        .order("created_at", { ascending: false })
        .limit(100);
      return data ?? [];
    },
  });

  useEffect(() => {
    const ch = supabase.channel("admin-errands")
      .on("postgres_changes", { event: "*", schema: "public", table: "errand_requests" },
        () => qc.invalidateQueries({ queryKey: ["admin-errands"] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [qc]);

  const update = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const patch: { status: string; completed_at?: string } = { status };
      if (status === "completed") patch.completed_at = new Date().toISOString();
      const { error } = await supabase.from("errand_requests").update(patch).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-errands"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const active = errands.filter((e) => e.status !== "completed" && e.status !== "cancelled");
  const done = errands.filter((e) => e.status === "completed" || e.status === "cancelled");

  return (
    <div className="space-y-5">
      <div>
        <h2 className="mb-2 text-base font-semibold">Active errands ({active.length})</h2>
        {active.length === 0 ? (
          <p className="text-sm text-muted-foreground">No active errands.</p>
        ) : (
          <div className="space-y-2">
            {active.map((e) => {
              const next = NEXT[e.status];
              const accName = (e as { accommodations?: { name?: string } }).accommodations?.name;
              const userName = (e as { profiles?: { display_name?: string } }).profiles?.display_name;
              return (
                <Card key={e.id} className="border-0 p-3 shadow-card">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold">{e.category} · {userName ?? "Attendee"}</p>
                      <p className="text-xs">{e.description}</p>
                      {(accName || e.room_number) && (
                        <p className="text-xs text-muted-foreground">
                          📍 {accName ?? "—"}{e.room_number ? ` · Room ${e.room_number}` : ""}
                        </p>
                      )}
                      {e.preferred_time && <p className="text-xs text-muted-foreground">⏱ {e.preferred_time}</p>}
                      <p className="mt-1 text-[11px] text-muted-foreground">{formatRelative(e.created_at)}</p>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                      <Badge>{e.status.replace("_", " ")}</Badge>
                      {e.urgency === "urgent" && <Badge variant="destructive">urgent</Badge>}
                    </div>
                  </div>
                  <div className="mt-3 flex gap-2">
                    {next && (
                      <Button size="sm" onClick={() => update.mutate({ id: e.id, status: next.status })}>
                        {next.label}
                      </Button>
                    )}
                    <Button size="sm" variant="outline" onClick={() => update.mutate({ id: e.id, status: "cancelled" })}>
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
          {done.slice(0, 20).map((e) => (
            <Card key={e.id} className="flex items-center gap-2 border-0 p-2 text-xs shadow-card">
              <span className="flex-1 truncate">{e.category} · {e.status}</span>
              <span className="text-muted-foreground">{formatRelative(e.created_at)}</span>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
