import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Phone, ShieldAlert, Stethoscope, Lock, Megaphone, AlertTriangle } from "lucide-react";
import { EVENT_CONFIG } from "@/lib/event-config";

const ICON_BY_CATEGORY: Record<string, typeof Phone> = {
  medical: Stethoscope,
  security: Lock,
  organizer: Megaphone,
  emergency: AlertTriangle,
  general: ShieldAlert,
};

export const Route = createFileRoute("/_authenticated/emergency")({
  component: EmergencyPage,
});

function EmergencyPage() {
  const { data: contacts = [] } = useQuery({
    queryKey: ["emergency-contacts"],
    queryFn: async () => {
      const { data } = await supabase.from("emergency_contacts").select("*").order("sort_order");
      return data ?? [];
    },
  });

  return (
    <div className="space-y-5 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">Emergency</h2>
        <p className="text-sm text-muted-foreground">Tap to call. Stay safe.</p>
      </div>

      <div className="space-y-3">
        {contacts.map((c) => {
          const Icon = ICON_BY_CATEGORY[c.category] ?? Phone;
          const isCritical = c.category === "emergency";
          return (
            <a key={c.id} href={`tel:${c.phone}`} className="block">
              <Card
                className={`flex items-center gap-4 border-0 p-4 shadow-card ${
                  isCritical ? "bg-destructive text-destructive-foreground" : ""
                }`}
              >
                <div
                  className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${
                    isCritical ? "bg-destructive-foreground/20" : "bg-primary-soft"
                  }`}
                >
                  <Icon className={`h-6 w-6 ${isCritical ? "" : "text-primary"}`} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold">{c.label}</p>
                  <p className={`text-lg font-bold ${isCritical ? "" : "text-primary"}`}>
                    {c.phone}
                  </p>
                  {c.description && (
                    <p className={`mt-0.5 text-xs ${isCritical ? "text-destructive-foreground/80" : "text-muted-foreground"}`}>
                      {c.description}
                    </p>
                  )}
                </div>
                <Phone className="h-5 w-5 shrink-0" />
              </Card>
            </a>
          );
        })}
      </div>

      <Card className="border-0 bg-accent-soft p-4 shadow-card">
        <h3 className="mb-2 text-sm font-semibold">Emergency procedures</h3>
        <ul className="space-y-1.5 text-xs text-muted-foreground">
          <li>• Stay calm and alert staff immediately if you witness anything unsafe.</li>
          <li>• First-aid station is located next to Hall A (8am–10pm daily).</li>
          <li>• Exit routes are marked with green signs. Follow staff instructions during any drill.</li>
          <li>• Lost & found: report at the registration desk in the Main Lobby.</li>
          <li>• Conference hotline: {EVENT_CONFIG.primaryHotline}</li>
        </ul>
      </Card>
    </div>
  );
}
