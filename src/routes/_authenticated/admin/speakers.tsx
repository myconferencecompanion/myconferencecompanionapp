import { createFileRoute } from "@tanstack/react-router";
import { requireSubRole } from "@/lib/admin-guard";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { AdminListShell } from "@/components/admin/AdminListShell";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import type { Database } from "@/integrations/supabase/types";

type Speaker = Database["public"]["Tables"]["speakers"]["Row"];

export const Route = createFileRoute("/_authenticated/admin/speakers")({
  beforeLoad: () => requireSubRole(["program"]),
  component: AdminSpeakers,
});

function AdminSpeakers() {
  const qc = useQueryClient();
  const { data: speakers = [] } = useQuery({
    queryKey: ["admin-speakers"],
    queryFn: async () => {
      const { data } = await supabase.from("speakers").select("*").order("name");
      return data ?? [];
    },
  });

  const del = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("speakers").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Deleted");
      qc.invalidateQueries({ queryKey: ["admin-speakers"] });
    },
  });

  return (
    <AdminListShell<Speaker>
      title="Speakers"
      items={speakers}
      rowTitle={(s) => s.name}
      rowSubtitle={(s) => [s.title, s.company].filter(Boolean).join(" · ")}
      onDelete={(s) => del.mutateAsync(s.id)}
      renderForm={(close, editing) => <SpeakerForm close={close} editing={editing} />}
    />
  );
}

function SpeakerForm({ close, editing }: { close: () => void; editing: Speaker | null }) {
  const qc = useQueryClient();
  const [form, setForm] = useState({
    name: "", title: "", company: "", bio: "", avatar_url: "", is_keynote: false,
  });
  useEffect(() => {
    if (editing) setForm({
      name: editing.name,
      title: editing.title ?? "",
      company: editing.company ?? "",
      bio: editing.bio ?? "",
      avatar_url: editing.avatar_url ?? "",
      is_keynote: editing.is_keynote,
    });
  }, [editing]);

  const save = useMutation({
    mutationFn: async () => {
      if (editing) {
        const { error } = await supabase.from("speakers").update(form).eq("id", editing.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("speakers").insert(form);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      toast.success("Saved");
      qc.invalidateQueries({ queryKey: ["admin-speakers"] });
      qc.invalidateQueries({ queryKey: ["speakers"] });
      close();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <div className="space-y-3">
      <div className="space-y-1"><Label>Name</Label><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
      <div className="space-y-1"><Label>Title</Label><Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></div>
      <div className="space-y-1"><Label>Company</Label><Input value={form.company} onChange={(e) => setForm({ ...form, company: e.target.value })} /></div>
      <div className="space-y-1"><Label>Avatar URL</Label><Input value={form.avatar_url} onChange={(e) => setForm({ ...form, avatar_url: e.target.value })} /></div>
      <div className="space-y-1"><Label>Bio</Label><Textarea rows={4} value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} /></div>
      <label className="flex items-center justify-between rounded-lg border border-border p-3">
        <span className="text-sm font-medium">Keynote speaker</span>
        <Switch checked={form.is_keynote} onCheckedChange={(v) => setForm({ ...form, is_keynote: v })} />
      </label>
      <Button className="w-full" onClick={() => save.mutate()} disabled={save.isPending || !form.name}>
        {save.isPending ? "Saving…" : "Save"}
      </Button>
    </div>
  );
}
