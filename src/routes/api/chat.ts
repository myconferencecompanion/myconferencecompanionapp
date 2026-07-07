import { createFileRoute } from "@tanstack/react-router";
import { createLovableAiGatewayProvider } from "@/lib/ai-gateway.server";
import { convertToModelMessages, streamText, type UIMessage } from "ai";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";

export const Route = createFileRoute("/api/chat")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        try {
          const { messages } = (await request.json()) as { messages?: UIMessage[] };
          if (!Array.isArray(messages)) {
            return new Response("Messages required", { status: 400 });
          }

          const key = process.env.LOVABLE_API_KEY;
          if (!key) return new Response("Missing LOVABLE_API_KEY", { status: 500 });

          // Build event context from the database
          const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL;
          const anon = process.env.SUPABASE_PUBLISHABLE_KEY ?? process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
          let eventContext = "";
          if (url && anon) {
            const supabase = createClient<Database>(url, anon);
            const [speakersRes, sessionsRes, accomRes, emergencyRes, annRes] = await Promise.all([
              supabase.from("speakers").select("name, title, company, is_keynote"),
              supabase.from("sessions").select("title, day, starts_at, ends_at, room, track, description, session_speakers(speakers(name))").order("starts_at"),
              supabase.from("accommodations").select("name, distance_km, price_range, address"),
              supabase.from("emergency_contacts").select("label, phone, description"),
              supabase.from("announcements").select("title, body, priority, created_at").order("created_at", { ascending: false }).limit(5),
            ]);
            eventContext = buildContext({
              speakers: speakersRes.data ?? [],
              sessions: sessionsRes.data ?? [],
              accommodations: accomRes.data ?? [],
              emergency: emergencyRes.data ?? [],
              announcements: annRes.data ?? [],
            });
          }

          const gateway = createLovableAiGatewayProvider(key);
          const result = streamText({
            model: gateway("google/gemini-3-flash-preview"),
            system: `You are the friendly AI concierge for NaijaTech Summit 2026, an African tech conference in Lagos on June 10-11, 2026 at Eko Convention Centre.

Be concise, warm, and confident. Answer questions about the schedule, speakers, venue, hotels, and emergency contacts. When asked about timing or location, give specific answers. If the user asks something outside the conference, politely steer them back.

Use markdown formatting (bold, lists) when it helps readability.

EVENT KNOWLEDGE:
${eventContext}`,
            messages: await convertToModelMessages(messages),
          });

          return result.toUIMessageStreamResponse({ originalMessages: messages });
        } catch (err) {
          console.error("Chat error", err);
          const message = err instanceof Error ? err.message : "Unknown error";
          return new Response(JSON.stringify({ error: message }), { status: 500, headers: { "Content-Type": "application/json" } });
        }
      },
    },
  },
});

function buildContext(d: {
  speakers: Array<{ name: string; title: string | null; company: string | null; is_keynote: boolean }>;
  sessions: Array<{ title: string; day: number; starts_at: string; ends_at: string; room: string | null; track: string | null; description: string | null; session_speakers: Array<{ speakers: { name: string } | null }> }>;
  accommodations: Array<{ name: string; distance_km: number | null; price_range: string | null; address: string | null }>;
  emergency: Array<{ label: string; phone: string; description: string | null }>;
  announcements: Array<{ title: string; body: string; priority: string; created_at: string }>;
}) {
  const fmt = (iso: string) => new Date(iso).toLocaleString("en-NG", { weekday: "short", hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Africa/Lagos" });
  return `
SPEAKERS:
${d.speakers.map((s) => `- ${s.name}${s.is_keynote ? " (KEYNOTE)" : ""} — ${[s.title, s.company].filter(Boolean).join(", ")}`).join("\n")}

SESSIONS:
${d.sessions.map((s) => `- Day ${s.day}, ${fmt(s.starts_at)}-${fmt(s.ends_at)}: "${s.title}" in ${s.room ?? "TBA"} (${s.track ?? "-"})${s.session_speakers?.length ? ` — speakers: ${s.session_speakers.map(ss => ss.speakers?.name).filter(Boolean).join(", ")}` : ""}`).join("\n")}

HOTELS:
${d.accommodations.map((h) => `- ${h.name} — ${h.distance_km ?? "?"} km away, ${h.price_range ?? "ask"}, ${h.address ?? ""}`).join("\n")}

EMERGENCY CONTACTS:
${d.emergency.map((e) => `- ${e.label}: ${e.phone}${e.description ? ` (${e.description})` : ""}`).join("\n")}

LATEST ANNOUNCEMENTS:
${d.announcements.map((a) => `- [${a.priority}] ${a.title}: ${a.body}`).join("\n")}

WI-FI: NaijaTech-2026 / future2026
VENUE: Eko Convention Centre, Plot 1415 Adetokunbo Ademola St, Victoria Island, Lagos
`.trim();
}
