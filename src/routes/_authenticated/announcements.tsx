import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatRelative } from "@/lib/format";
import { Megaphone, AlertCircle } from "lucide-react";
import { useEffect } from "react";

export const Route = createFileRoute("/_authenticated/announcements")({
  component: AnnouncementsPage,
});

function AnnouncementsPage() {
  const { user } = useAuth();
  const qc = useQueryClient();

  const { data: announcements = [] } = useQuery({
    queryKey: ["announcements"],
    queryFn: async () => {
      const { data } = await supabase
        .from("announcements")
        .select("*")
        .order("created_at", { ascending: false });
      return data ?? [];
    },
  });

  const { data: reads = [] } = useQuery({
    queryKey: ["announcement-reads", user?.id],
    enabled: !!user,
    queryFn: async () => {
      const { data } = await supabase
        .from("announcement_reads")
        .select("announcement_id")
        .eq("user_id", user!.id);
      return data ?? [];
    },
  });

  const readSet = new Set(reads.map((r) => r.announcement_id));

  const markAllRead = useMutation({
    mutationFn: async () => {
      const unread = announcements.filter((a) => !readSet.has(a.id));
      if (unread.length === 0) return;
      await supabase.from("announcement_reads").insert(
        unread.map((a) => ({ user_id: user!.id, announcement_id: a.id })),
      );
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["announcement-reads"] });
      qc.invalidateQueries({ queryKey: ["unread-announcements"] });
    },
  });

  // Auto-mark visible announcements as read on mount
  useEffect(() => {
    if (announcements.length > 0 && reads.length < announcements.length && user) {
      markAllRead.mutate();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [announcements.length, reads.length, user?.id]);

  return (
    <div className="space-y-4 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">Announcements</h2>
        <p className="text-sm text-muted-foreground">Latest updates from organizers</p>
      </div>

      <div className="space-y-3">
        {announcements.length === 0 && (
          <p className="py-12 text-center text-sm text-muted-foreground">No announcements yet.</p>
        )}
        {announcements.map((a) => (
          <Card key={a.id} className="border-0 p-4 shadow-card">
            <div className="flex items-start gap-3">
              <div
                className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full ${
                  a.priority === "high" ? "bg-destructive/15 text-destructive" : "bg-accent-soft text-warning-foreground"
                }`}
              >
                {a.priority === "high" ? <AlertCircle className="h-4 w-4" /> : <Megaphone className="h-4 w-4" />}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-start justify-between gap-2">
                  <h3 className="text-sm font-semibold leading-snug">{a.title}</h3>
                  {a.priority === "high" && (
                    <Badge variant="destructive" className="shrink-0 text-[10px]">Important</Badge>
                  )}
                </div>
                <p className="mt-1 text-xs text-muted-foreground">{formatRelative(a.created_at)}</p>
                <p className="mt-2 text-sm leading-relaxed">{a.body}</p>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
