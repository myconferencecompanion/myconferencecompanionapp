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
import type { Database } from "@/integrations/supabase/types";

type Hotel = Database["public"]["Tables"]["accommodations"]["Row"];

export const Route = createFileRoute("/_authenticated/admin/accommodations")({
  beforeLoad: () => requireSubRole(["logistics"]),
  component: AdminHotels,
});

function AdminHotels() {
  const qc = useQueryClient();
  const { data: hotels = [] } = useQuery({
    queryKey: ["admin-hotels"],
    queryFn: async () => {
      const { data } = await supabase.from("accommodations").select("*").order("name");
      return data ?? [];
    },
  });
  const del = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("accommodations").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Deleted");
      qc.invalidateQueries({ queryKey: ["admin-hotels"] });
    },
  });

  return (
    <AdminListShell<Hotel>
      title="Hotels"
      items={hotels}
      rowTitle={(h) => h.name}
      rowSubtitle={(h) => `${h.distance_km ?? "?"} km · ${"₦".repeat(h.price_tier)}`}
      onDelete={(h) => del.mutateAsync(h.id)}
      renderForm={(close, editing) => <HotelForm close={close} editing={editing} />}
    />
  );
}

function HotelForm({ close, editing }: { close: () => void; editing: Hotel | null }) {
  const qc = useQueryClient();
  const [form, setForm] = useState({
    name: "", description: "", image_url: "", address: "",
    distance_km: 0, price_tier: 3, price_range: "", rating: 0,
    latitude: 0, longitude: 0, booking_url: "",
  });
  useEffect(() => {
    if (editing) setForm({
      name: editing.name,
      description: editing.description ?? "",
      image_url: editing.image_url ?? "",
      address: editing.address ?? "",
      distance_km: Number(editing.distance_km ?? 0),
      price_tier: editing.price_tier,
      price_range: editing.price_range ?? "",
      rating: Number(editing.rating ?? 0),
      latitude: Number(editing.latitude ?? 0),
      longitude: Number(editing.longitude ?? 0),
      booking_url: editing.booking_url ?? "",
    });
  }, [editing]);

  const save = useMutation({
    mutationFn: async () => {
      if (editing) {
        const { error } = await supabase.from("accommodations").update(form).eq("id", editing.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("accommodations").insert(form);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      toast.success("Saved");
      qc.invalidateQueries({ queryKey: ["admin-hotels"] });
      qc.invalidateQueries({ queryKey: ["accommodations"] });
      close();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <div className="space-y-3">
      <div className="space-y-1"><Label>Name</Label><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
      <div className="space-y-1"><Label>Description</Label><Textarea rows={2} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
      <div className="space-y-1"><Label>Image URL</Label><Input value={form.image_url} onChange={(e) => setForm({ ...form, image_url: e.target.value })} /></div>
      <div className="space-y-1"><Label>Address</Label><Input value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} /></div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1"><Label>Distance (km)</Label><Input type="number" step="0.1" value={form.distance_km} onChange={(e) => setForm({ ...form, distance_km: Number(e.target.value) })} /></div>
        <div className="space-y-1"><Label>Price tier (1-5)</Label><Input type="number" min={1} max={5} value={form.price_tier} onChange={(e) => setForm({ ...form, price_tier: Number(e.target.value) })} /></div>
      </div>
      <div className="space-y-1"><Label>Price range</Label><Input value={form.price_range} onChange={(e) => setForm({ ...form, price_range: e.target.value })} /></div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1"><Label>Latitude</Label><Input type="number" step="0.000001" value={form.latitude} onChange={(e) => setForm({ ...form, latitude: Number(e.target.value) })} /></div>
        <div className="space-y-1"><Label>Longitude</Label><Input type="number" step="0.000001" value={form.longitude} onChange={(e) => setForm({ ...form, longitude: Number(e.target.value) })} /></div>
      </div>
      <div className="space-y-1"><Label>Booking URL</Label><Input value={form.booking_url} onChange={(e) => setForm({ ...form, booking_url: e.target.value })} /></div>
      <Button className="w-full" onClick={() => save.mutate()} disabled={save.isPending || !form.name}>
        {save.isPending ? "Saving…" : "Save"}
      </Button>
    </div>
  );
}
