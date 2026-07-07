import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { ChevronLeft, Briefcase } from "lucide-react";
import { toast } from "sonner";

export const Route = createFileRoute("/_authenticated/concierge/errands")({
  component: ErrandsPage,
});

const CATEGORIES = [
  "Laundry",
  "Pharmacy run",
  "Grocery shopping",
  "Document / print",
  "Transport / ride",
  "Food delivery",
  "Other",
];

function ErrandsPage() {
  const { user } = useAuth();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [description, setDescription] = useState("");
  const [accommodationId, setAccommodationId] = useState<string>("");
  const [roomNumber, setRoomNumber] = useState("");
  const [urgency, setUrgency] = useState<"normal" | "urgent">("normal");
  const [preferredTime, setPreferredTime] = useState("");

  const { data: hotels = [] } = useQuery({
    queryKey: ["hotels-for-errands"],
    queryFn: async () => {
      const { data } = await supabase.from("accommodations").select("id, name").order("name");
      return data ?? [];
    },
  });

  const submit = useMutation({
    mutationFn: async () => {
      if (!description.trim()) throw new Error("Describe the errand");
      const { error } = await supabase.from("errand_requests").insert({
        user_id: user!.id,
        category,
        description,
        accommodation_id: accommodationId || null,
        room_number: roomNumber || null,
        urgency,
        preferred_time: preferredTime || null,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Errand submitted — a concierge will reach out shortly.");
      qc.invalidateQueries({ queryKey: ["my-errands"] });
      navigate({ to: "/concierge/orders" });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <div className="space-y-5 px-4 pt-5 pb-8">
      <Link to="/concierge" className="inline-flex items-center text-sm text-muted-foreground">
        <ChevronLeft className="h-4 w-4" /> Concierge
      </Link>
      <div>
        <h2 className="text-xl font-bold">Send an errand</h2>
        <p className="text-sm text-muted-foreground">
          Too tired after a long day? Tell us what you need and we'll arrange it.
        </p>
      </div>

      <Card className="space-y-3 border-0 p-4 shadow-card">
        <div className="space-y-1">
          <Label>What kind of errand?</Label>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
          >
            {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <Label>Describe what you need</Label>
          <Textarea
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="e.g. Paracetamol and bottled water from the nearest pharmacy"
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1">
            <Label>Your hotel</Label>
            <select
              value={accommodationId}
              onChange={(e) => setAccommodationId(e.target.value)}
              className="flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
            >
              <option value="">— Select —</option>
              {hotels.map((h) => <option key={h.id} value={h.id}>{h.name}</option>)}
            </select>
          </div>
          <div className="space-y-1">
            <Label>Room number</Label>
            <Input value={roomNumber} onChange={(e) => setRoomNumber(e.target.value)} placeholder="e.g. 214" />
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1">
            <Label>Urgency</Label>
            <select
              value={urgency}
              onChange={(e) => setUrgency(e.target.value as "normal" | "urgent")}
              className="flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
            >
              <option value="normal">Normal</option>
              <option value="urgent">Urgent</option>
            </select>
          </div>
          <div className="space-y-1">
            <Label>Preferred time</Label>
            <Input value={preferredTime} onChange={(e) => setPreferredTime(e.target.value)} placeholder="e.g. ASAP, 8pm" />
          </div>
        </div>
        <Button onClick={() => submit.mutate()} disabled={submit.isPending} className="w-full">
          <Briefcase className="h-4 w-4" /> {submit.isPending ? "Submitting…" : "Submit errand"}
        </Button>
        <p className="text-xs text-muted-foreground">
          Free for the demo. In-app payment for fees will be added soon.
        </p>
      </Card>
    </div>
  );
}
