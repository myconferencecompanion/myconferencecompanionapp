import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useGoogleMaps } from "@/lib/google-maps";
import { EVENT_CONFIG } from "@/lib/event-config";
import { useMutation } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { getDirections } from "@/lib/maps.functions";
import { ArrowLeft, Loader2, MapPin, Footprints, Car, Navigation } from "lucide-react";

type Search = { lat?: number; lng?: number; name?: string };

export const Route = createFileRoute("/_authenticated/directions")({
  validateSearch: (s: Record<string, unknown>): Search => ({
    lat: typeof s.lat === "number" ? s.lat : s.lat ? Number(s.lat) : undefined,
    lng: typeof s.lng === "number" ? s.lng : s.lng ? Number(s.lng) : undefined,
    name: typeof s.name === "string" ? s.name : undefined,
  }),
  component: DirectionsPage,
});

function DirectionsPage() {
  const { lat, lng, name } = Route.useSearch();
  const navigate = useNavigate();
  const { ready } = useGoogleMaps();
  const mapRef = useRef<HTMLDivElement>(null);
  const [origin, setOrigin] = useState<{ lat: number; lng: number } | null>(null);
  const [mode, setMode] = useState<"WALK" | "DRIVE">("WALK");
  const [geoError, setGeoError] = useState<string | null>(null);

  const dest = lat != null && lng != null
    ? { lat, lng, name: name ?? "Destination" }
    : { lat: EVENT_CONFIG.venue.latitude, lng: EVENT_CONFIG.venue.longitude, name: EVENT_CONFIG.venue.name };

  const dirFn = useServerFn(getDirections);
  const { data: route, mutate, isPending } = useMutation({
    mutationFn: async (vars: { origin: { lat: number; lng: number }; mode: "WALK" | "DRIVE" }) =>
      dirFn({
        data: {
          originLat: vars.origin.lat,
          originLng: vars.origin.lng,
          destLat: dest.lat,
          destLng: dest.lng,
          travelMode: vars.mode,
        },
      }),
  });

  function locate() {
    if (!navigator.geolocation) {
      setGeoError("Geolocation not supported");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const loc = { lat: pos.coords.latitude, lng: pos.coords.longitude };
        setOrigin(loc);
        mutate({ origin: loc, mode });
      },
      (err) => setGeoError(err.message),
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  }

  // Draw map + route
  useEffect(() => {
    if (!ready || !mapRef.current) return;
    const map = new window.google.maps.Map(mapRef.current, {
      center: { lat: dest.lat, lng: dest.lng },
      zoom: 15,
      disableDefaultUI: true,
      zoomControl: true,
    });
    new window.google.maps.Marker({
      position: { lat: dest.lat, lng: dest.lng },
      map,
      title: dest.name,
    });
    if (origin) {
      new window.google.maps.Marker({
        position: origin,
        map,
        title: "You",
        icon: {
          path: window.google.maps.SymbolPath.CIRCLE,
          scale: 8,
          fillColor: "#3a2db3",
          fillOpacity: 1,
          strokeColor: "#fff",
          strokeWeight: 3,
        },
      });
    }
    if (route?.encodedPolyline) {
      const path = window.google.maps.geometry.encoding.decodePath(route.encodedPolyline);
      const line = new window.google.maps.Polyline({
        path,
        strokeColor: "#3a2db3",
        strokeWeight: 5,
        strokeOpacity: 0.85,
      });
      line.setMap(map);
      const bounds = new window.google.maps.LatLngBounds();
      path.forEach((p: any) => bounds.extend(p));
      map.fitBounds(bounds, 60);
    }
  }, [ready, route, origin, dest.lat, dest.lng, dest.name]);

  return (
    <div>
      <div className="bg-brand-gradient px-4 pb-5 pt-4 text-white">
        <button onClick={() => navigate({ to: "/home" })} className="mb-3 inline-flex items-center gap-1 text-sm text-white/80">
          <ArrowLeft className="h-4 w-4" /> Home
        </button>
        <h1 className="text-xl font-bold">Live directions</h1>
        <p className="mt-1 text-sm text-white/80 inline-flex items-center gap-1">
          <MapPin className="h-3.5 w-3.5" /> To: <span className="font-semibold">{dest.name}</span>
        </p>
      </div>

      <div className="px-4 pt-4 space-y-3">
        <div className="flex gap-2">
          <Button
            variant={mode === "WALK" ? "default" : "outline"}
            size="sm"
            className="flex-1"
            onClick={() => {
              setMode("WALK");
              if (origin) mutate({ origin, mode: "WALK" });
            }}
          >
            <Footprints className="h-4 w-4" /> Walk
          </Button>
          <Button
            variant={mode === "DRIVE" ? "default" : "outline"}
            size="sm"
            className="flex-1"
            onClick={() => {
              setMode("DRIVE");
              if (origin) mutate({ origin, mode: "DRIVE" });
            }}
          >
            <Car className="h-4 w-4" /> Drive
          </Button>
        </div>

        {!origin && (
          <Button onClick={locate} className="w-full">
            <Navigation className="h-4 w-4" /> Use my location
          </Button>
        )}
        {geoError && <p className="text-xs text-destructive">{geoError}</p>}

        <Card className="overflow-hidden border-0 shadow-card">
          <div ref={mapRef} className="aspect-[4/5] w-full bg-muted" />
        </Card>

        {isPending && (
          <div className="flex items-center justify-center gap-2 p-4 text-sm text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" /> Computing route…
          </div>
        )}

        {route && (
          <Card className="border-0 p-4 shadow-card">
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div>
                <p className="text-2xl font-bold">{Math.round(route.durationSeconds / 60)} min</p>
                <p className="text-xs text-muted-foreground">{(route.distanceMeters / 1000).toFixed(1)} km</p>
              </div>
              <Button size="sm" variant="outline" asChild>
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${dest.lat},${dest.lng}&travelmode=${mode.toLowerCase()}`}
                  target="_blank"
                  rel="noreferrer"
                >
                  Open in Maps
                </a>
              </Button>
            </div>
            <div className="mt-3 max-h-72 space-y-2 overflow-y-auto">
              {route.steps.map((step, i) => (
                <div key={i} className="flex gap-3 text-sm">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary-soft text-xs font-semibold text-primary">
                    {i + 1}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p dangerouslySetInnerHTML={{ __html: step.instruction }} />
                    {step.distanceMeters > 0 && (
                      <p className="text-xs text-muted-foreground">{step.distanceMeters} m</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </Card>
        )}
      </div>
    </div>
  );
}
