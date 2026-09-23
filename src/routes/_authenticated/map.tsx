import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useGoogleMaps } from "@/lib/google-maps";
import { EVENT_CONFIG } from "@/lib/event-config";
import { Card } from "@/components/ui/card";
import { MapPin, ExternalLink } from "lucide-react";
import { VENUE_DATA, HOTELS, hotelDistanceKm, type NearbyPoi } from "@/lib/reference";

type Search = { room?: string };

export const Route = createFileRoute("/_authenticated/map")({
  validateSearch: (s: Record<string, unknown>): Search => ({
    room: typeof s.room === "string" ? s.room : undefined,
  }),
  component: MapPage,
});

// Pre-positioned hotspots on the floor plan (percentages)
const HOTSPOTS = [
  { id: "lobby", name: "Main Lobby", x: 50, y: 12, tone: "bg-accent" },
  { id: "grand", name: "Grand Hall", x: 50, y: 38, tone: "bg-primary" },
  { id: "hallA", name: "Hall A", x: 20, y: 55, tone: "bg-primary" },
  { id: "hallB", name: "Hall B", x: 80, y: 55, tone: "bg-primary" },
  { id: "workshop", name: "Workshop Room 1", x: 22, y: 78, tone: "bg-primary" },
  { id: "courtyard", name: "Courtyard", x: 50, y: 65, tone: "bg-success" },
  { id: "rooftop", name: "Rooftop Terrace", x: 78, y: 88, tone: "bg-accent" },
];

function MapPage() {
  const { room } = Route.useSearch();
  const [tab, setTab] = useState<"venue" | "outdoor">("venue");
  const [selected, setSelected] = useState<string | null>(null);

  useEffect(() => {
    if (room) {
      const hit = HOTSPOTS.find((h) => h.name === room);
      if (hit) setSelected(hit.id);
    }
  }, [room]);

  return (
    <div className="px-4 pt-5">
      <h2 className="text-xl font-bold">Map</h2>
      <p className="text-sm text-muted-foreground">{EVENT_CONFIG.venue.name}</p>

      <Tabs value={tab} onValueChange={(v) => setTab(v as "venue" | "outdoor")} className="mt-4">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="venue">Venue</TabsTrigger>
          <TabsTrigger value="outdoor">Outdoor</TabsTrigger>
        </TabsList>

        <TabsContent value="venue" className="mt-4">
          <Card className="overflow-hidden border-0 shadow-card">
            <div className="relative aspect-[3/4] w-full bg-gradient-to-br from-primary-soft via-accent-soft to-primary-soft">
              {/* Simple stylized floor plan */}
              <svg className="absolute inset-0 h-full w-full opacity-40" viewBox="0 0 300 400">
                <rect x="20" y="20" width="260" height="360" rx="14" fill="none" stroke="currentColor" strokeWidth="2" className="text-primary" />
                <rect x="80" y="50" width="140" height="80" rx="6" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-primary" />
                <rect x="40" y="180" width="100" height="60" rx="6" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-primary" />
                <rect x="160" y="180" width="100" height="60" rx="6" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-primary" />
                <rect x="100" y="250" width="100" height="50" rx="6" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-success" strokeDasharray="4" />
                <rect x="40" y="290" width="80" height="50" rx="6" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-primary" />
              </svg>

              {HOTSPOTS.map((h) => (
                <button
                  key={h.id}
                  onClick={() => setSelected(h.id)}
                  className="absolute -translate-x-1/2 -translate-y-1/2 transition active:scale-95"
                  style={{ left: `${h.x}%`, top: `${h.y}%` }}
                >
                  <span className={`flex h-6 w-6 items-center justify-center rounded-full ${h.tone} text-white shadow-elevated ring-2 ring-white ${selected === h.id ? "scale-125" : ""}`}>
                    <MapPin className="h-3.5 w-3.5" />
                  </span>
                  <span className={`absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-md px-1.5 py-0.5 text-[10px] font-semibold ${selected === h.id ? "bg-foreground text-background" : "bg-white/90 text-foreground"}`}>
                    {h.name}
                  </span>
                </button>
              ))}
            </div>
          </Card>
          {selected && (
            <Card className="mt-3 border-0 p-4 shadow-card">
              <p className="text-xs uppercase tracking-wider text-muted-foreground">Selected</p>
              <p className="text-lg font-bold">{HOTSPOTS.find((h) => h.id === selected)?.name}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Inside {EVENT_CONFIG.venue.name}. Follow venue signage from the Main Lobby.
              </p>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="outdoor" className="mt-4">
          <OutdoorMap />
          <Card className="mt-3 border-0 p-4 shadow-card">
            <p className="text-sm font-semibold">{EVENT_CONFIG.venue.name}</p>
            <p className="mt-1 text-xs text-muted-foreground">{EVENT_CONFIG.venue.address}</p>
          </Card>
          <PoiList />
        </TabsContent>
      </Tabs>
    </div>
  );
}

const POI_PIN_TINTS: Record<string, string> = {
  Airport: "bg-primary",
  Security: "bg-destructive",
  Government: "bg-primary",
  Culture: "bg-accent",
  Hospital: "bg-success",
  Restaurant: "bg-accent",
  Pharmacy: "bg-success",
  ATM: "bg-primary",
  Shopping: "bg-accent",
  "Spouses visit": "bg-accent",
};

function poiPinTint(category: string) {
  return POI_PIN_TINTS[category] ?? "bg-muted-foreground";
}

function OutdoorMap() {
  const ref = useRef<HTMLDivElement>(null);
  const { ready, error } = useGoogleMaps();

  useEffect(() => {
    if (!ready || !ref.current) return;
    const map = new window.google.maps.Map(ref.current, {
      center: { lat: EVENT_CONFIG.venue.latitude, lng: EVENT_CONFIG.venue.longitude },
      zoom: 13,
      disableDefaultUI: false,
      zoomControl: true,
      streetViewControl: false,
      mapTypeControl: false,
      fullscreenControl: false,
    });
    new window.google.maps.Marker({
      position: { lat: EVENT_CONFIG.venue.latitude, lng: EVENT_CONFIG.venue.longitude },
      map,
      title: EVENT_CONFIG.venue.name,
    });
    // Nearby POIs
    for (const poi of VENUE_DATA.nearby) {
      if (poi.latitude == null || poi.longitude == null) continue;
      new window.google.maps.Marker({
        position: { lat: poi.latitude, lng: poi.longitude },
        map,
        title: `${poi.name} (${poi.category})`,
      });
    }
    // Geocoded hotels
    for (const h of HOTELS) {
      if (h.latitude == null || h.longitude == null) continue;
      new window.google.maps.Marker({
        position: { lat: h.latitude, lng: h.longitude },
        map,
        title: `${h.name} — delegate hotel`,
        icon: {
          path: window.google.maps.SymbolPath.BACKWARD_CLOSED_ARROW,
          scale: 5.5,
          fillColor: "#c9a227",
          fillOpacity: 1,
          strokeColor: "#1f2a56",
          strokeWeight: 2,
        },
      });
    }
  }, [ready]);

  if (error) {
    return (
      <div className="space-y-3">
        <Card className="border-0 p-6 text-center shadow-card">
          <p className="text-sm text-muted-foreground">
            Interactive map unavailable ({error}).
          </p>
          <a
            href={`https://www.google.com/maps/search/?api=1&query=${EVENT_CONFIG.venue.latitude},${EVENT_CONFIG.venue.longitude}`}
            target="_blank"
            rel="noreferrer"
            className="mt-2 inline-flex items-center gap-1 text-sm font-medium text-primary"
          >
            Open venue in Google Maps <ExternalLink className="h-3.5 w-3.5" />
          </a>
        </Card>
        <PoiList />
      </div>
    );
  }

  return (
    <Card className="overflow-hidden border-0 shadow-card">
      <div ref={ref} className="aspect-[4/5] w-full bg-muted" />
    </Card>
  );
}

function PoiList() {
  return (
    <div className="mt-4 space-y-2">
      <p className="text-sm font-semibold">Key places ({VENUE_DATA.nearby.length})</p>
      {VENUE_DATA.nearby.map((poi) => (
        <PoiRow key={poi.id} poi={poi} />
      ))}
      <p className="pt-2 text-sm font-semibold">Geocoded hotels</p>
      {HOTELS.filter((h) => h.latitude != null).map((h) => (
        <PoiRow
          key={h.id}
          poi={{
            id: h.id,
            name: h.name,
            category: "Hotel",
            note: h.location,
            latitude: h.latitude ?? undefined,
            longitude: h.longitude ?? undefined,
            distanceKm: hotelDistanceKm(h) ?? undefined,
          }}
        />
      ))}
    </div>
  );
}

function PoiRow({ poi }: { poi: NearbyPoi & { category: string } }) {
  const mapsUrl =
    poi.latitude != null && poi.longitude != null
      ? `https://www.google.com/maps/dir/?api=1&destination=${poi.latitude},${poi.longitude}`
      : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(poi.name + ", Maiduguri")}`;
  return (
    <Card className="flex items-center gap-3 border-0 p-3 shadow-card">
      <span
        className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-white ${poiPinTint(poi.category)}`}
      >
        <MapPin className="h-3.5 w-3.5" />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{poi.name}</p>
        <p className="truncate text-xs text-muted-foreground">
          {poi.category}
          {poi.distanceKm != null ? ` · ${poi.distanceKm} km` : ""}
        </p>
      </div>
      <a
        href={mapsUrl}
        target="_blank"
        rel="noreferrer"
        className="shrink-0 rounded-full border border-border px-3 py-1.5 text-xs font-medium text-foreground"
      >
        Go
      </a>
    </Card>
  );
}
