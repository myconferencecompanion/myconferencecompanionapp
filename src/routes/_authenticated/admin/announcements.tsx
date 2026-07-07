import { createFileRoute } from "@tanstack/react-router";
import { requireSubRole } from "@/lib/admin-guard";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { AdminListShell } from "@/components/admin/AdminListShell";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import type { Database } from "@/integrations/supabase/types";

type Ann = Database["public"]["Tables"]["announcements"]["Row"];

export const Route = createFileRoute("/_authenticated/admin/announcements")({
  beforeLoad: () => requireSubRole(["comms"]),
  component: AdminAnnouncements,
});

function AdminAnnouncements() {
  const qc = useQueryClient();
  const { data: announcements = [] } = useQuery({
    queryKey: ["admin-announcements"],
    queryFn: async () => {
      const { data } = await supabase.from("announcements").select("*").order("created_at", { ascending: false });
      return data ?? [];
    },
  });
  const del = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("announcements").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Deleted");
      qc.invalidateQueries({ queryKey: ["admin-announcements"] });
    },
  });

  return (
    <AdminListShell<Ann>
      title="Announcements"
      items={announcements}
      rowTitle={(a) => a.title}
      rowSubtitle={(a) => `${a.priority} · ${new Date(a.created_at).toLocaleString()}`}
      onDelete={(a) => del.mutateAsync(a.id)}
      renderForm={(close, editing) => <AnnouncementForm close={close} editing={editing} />}
    />
  );
}

function AnnouncementForm({ close, editing }: { close: () => void; editing: Ann | null }) {
  const qc = useQueryClient();
  const { user } = useAuth();
  const [form, setForm] = useState({ title: "", body: "", priority: "normal" });
  useEffect(() => {
    if (editing) setForm({ title: editing.title, body: editing.body, priority: editing.priority });
  }, [editing]);
  const save = useMutation({
    mutationFn: async () => {
      if (editing) {
        const { error } = await supabase.from("announcements").update(form).eq("id", editing.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("announcements").insert({ ...form, posted_by: user!.id });
        if (error) throw error;
      }
    },
    onSuccess: () => {
      toast.success("Posted");
      qc.invalidateQueries({ queryKey: ["admin-announcements"] });
      qc.invalidateQueries({ queryKey: ["announcements"] });
      qc.invalidateQueries({ queryKey: ["latest-announcement"] });
      qc.invalidateQueries({ queryKey: ["unread-announcements"] });
      close();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <div className="space-y-3">
      <div className="space-y-1"><Label>Title</Label><Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></div>
      <div className="space-y-1"><Label>Body</Label><Textarea rows={4} value={form.body} onChange={(e) => setForm({ ...form, body: e.target.value })} /></div>
      <div className="space-y-1"><Label>Priority</Label>
        <Input value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })} placeholder="normal or high" />
      </div>
      <Button className="w-full" onClick={() => save.mutate()} disabled={save.isPending || !form.title || !form.body}>
        {save.isPending ? "Saving…" : "Save"}
      </Button>
    </div>
  );
}
