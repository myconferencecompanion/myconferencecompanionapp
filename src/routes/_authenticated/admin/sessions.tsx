import { createFileRoute } from "@tanstack/react-router";
import { requireSubRole } from "@/lib/admin-guard";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { AdminListShell } from "@/components/admin/AdminListShell";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { formatTimeRange } from "@/lib/format";
import type { Database } from "@/integrations/supabase/types";

type Session = Database["public"]["Tables"]["sessions"]["Row"];

export const Route = createFileRoute("/_authenticated/admin/sessions")({
  beforeLoad: () => requireSubRole(["program"]),
  component: AdminSessions,
});

function AdminSessions() {
  const qc = useQueryClient();
  const { data: sessions = [] } = useQuery({
    queryKey: ["admin-sessions"],
    queryFn: async () => {
      const { data } = await supabase.from("sessions").select("*, session_speakers(speakers(id, name))").order("starts_at");
      return data ?? [];
    },
  });

  const del = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("sessions").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Deleted");
      qc.invalidateQueries({ queryKey: ["admin-sessions"] });
    },
  });

  return (
    <AdminListShell<Session & { session_speakers?: { speakers: { id: string; name: string } | null }[] }>
      title="Sessions"
      items={sessions}
      rowTitle={(s) => s.title}
      rowSubtitle={(s) => {
        const speakers = (s.session_speakers ?? []).map((ss) => ss.speakers?.name).filter(Boolean).join(", ");
        return `Day ${s.day} · ${formatTimeRange(s.starts_at, s.ends_at)}${s.room ? " · " + s.room : ""}${speakers ? " · " + speakers : ""}`;
      }}
      onDelete={(s) => del.mutateAsync(s.id)}
      renderForm={(close, editing) => <SessionForm close={close} editing={editing} />}
    />
  );
}

function toLocalInput(iso: string) {
  const d = new Date(iso);
  const pad = (n: number) => n.toString().padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function SessionForm({ close, editing }: { close: () => void; editing: Session | null }) {
  const qc = useQueryClient();
  const [form, setForm] = useState({
    title: "", description: "", day: 1, starts_at: "", ends_at: "", room: "", track: "", session_type: "talk",
  });
  const [speakerIds, setSpeakerIds] = useState<string[]>([]);

  const { data: speakers = [] } = useQuery({
    queryKey: ["admin-speakers"],
    queryFn: async () => {
      const { data } = await supabase.from("speakers").select("id, name").order("name");
      return data ?? [];
    },
  });

  useEffect(() => {
    if (editing) {
      setForm({
        title: editing.title,
        description: editing.description ?? "",
        day: editing.day,
        starts_at: toLocalInput(editing.starts_at),
        ends_at: toLocalInput(editing.ends_at),
        room: editing.room ?? "",
        track: editing.track ?? "",
        session_type: editing.session_type,
      });
      void supabase
        .from("session_speakers")
        .select("speaker_id")
        .eq("session_id", editing.id)
        .then(({ data }) => setSpeakerIds((data ?? []).map((r) => r.speaker_id)));
    }
  }, [editing]);

  const save = useMutation({
    mutationFn: async () => {
      const payload = {
        ...form,
        starts_at: new Date(form.starts_at).toISOString(),
        ends_at: new Date(form.ends_at).toISOString(),
      };
      let sessionId = editing?.id;
      if (editing) {
        const { error } = await supabase.from("sessions").update(payload).eq("id", editing.id);
        if (error) throw error;
      } else {
        const { data: inserted, error } = await supabase.from("sessions").insert(payload).select("id").single();
        if (error) throw error;
        sessionId = inserted!.id;
      }
      // Sync the speaker lineup.
      await supabase.from("session_speakers").delete().eq("session_id", sessionId!);
      if (speakerIds.length > 0) {
        const { error: linkErr } = await supabase
          .from("session_speakers")
          .insert(speakerIds.map((speaker_id) => ({ session_id: sessionId!, speaker_id })));
        if (linkErr) throw linkErr;
      }
    },
    onSuccess: () => {
      toast.success("Saved");
      qc.invalidateQueries({ queryKey: ["admin-sessions"] });
      qc.invalidateQueries({ queryKey: ["sessions"] });
      close();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  function toggleSpeaker(id: string) {
    setSpeakerIds((cur) => (cur.includes(id) ? cur.filter((x) => x !== id) : [...cur, id]));
  }

  return (
    <div className="space-y-3">
      <div className="space-y-1"><Label>Title</Label><Input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></div>
      <div className="space-y-1"><Label>Description</Label><Textarea rows={3} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1"><Label>Day</Label>
          <Input type="number" min={1} max={7} value={form.day} onChange={(e) => setForm({ ...form, day: Number(e.target.value) })} />
        </div>
        <div className="space-y-1"><Label>Type</Label>
          <Input value={form.session_type} onChange={(e) => setForm({ ...form, session_type: e.target.value })} placeholder="talk, keynote, panel…" />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1"><Label>Starts</Label><Input type="datetime-local" value={form.starts_at} onChange={(e) => setForm({ ...form, starts_at: e.target.value })} /></div>
        <div className="space-y-1"><Label>Ends</Label><Input type="datetime-local" value={form.ends_at} onChange={(e) => setForm({ ...form, ends_at: e.target.value })} /></div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1"><Label>Room</Label><Input value={form.room} onChange={(e) => setForm({ ...form, room: e.target.value })} /></div>
        <div className="space-y-1"><Label>Track</Label><Input value={form.track} onChange={(e) => setForm({ ...form, track: e.target.value })} /></div>
      </div>
      <div className="space-y-1.5">
        <Label>Speakers (tap to include)</Label>
        {speakers.length === 0 && (
          <p className="text-xs text-muted-foreground">No speakers yet — add them on the Speakers tab first.</p>
        )}
        <div className="flex flex-wrap gap-1.5">
          {speakers.map((sp) => {
            const on = speakerIds.includes(sp.id);
            return (
              <button
                key={sp.id}
                type="button"
                onClick={() => toggleSpeaker(sp.id)}
                className={`rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                  on ? "border-primary bg-primary text-primary-foreground" : "border-border bg-surface text-muted-foreground"
                }`}
              >
                {on ? "✓ " : ""}{sp.name}
              </button>
            );
          })}
        </div>
      </div>
      <Button className="w-full" onClick={() => save.mutate()} disabled={save.isPending || !form.title || !form.starts_at || !form.ends_at}>
        {save.isPending ? "Saving…" : "Save"}
      </Button>
    </div>
  );
}
