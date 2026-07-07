import { createServerFn } from "@tanstack/react-start";
import { EVENT_CONFIG } from "@/lib/event-config";

const GATEWAY = "https://connector-gateway.lovable.dev/google_maps";

export type Place = {
  id: string;
  name: string;
  address?: string;
  rating?: number;
  latitude?: number;
  longitude?: number;
  distanceMeters?: number;
  openNow?: boolean;
};

const CATEGORY_TO_INCLUDED_TYPE: Record<string, string> = {
  restaurant: "restaurant",
  cafe: "cafe",
  atm: "atm",
  pharmacy: "pharmacy",
  transit_station: "transit_station",
  shopping_mall: "shopping_mall",
};

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

export const searchNearby = createServerFn({ method: "POST" })
  .inputValidator((input: { category: string }) => {
    if (!input.category || typeof input.category !== "string" || input.category.length > 50) {
      throw new Error("Invalid category");
    }
    return input;
  })
  .handler(async ({ data }): Promise<Place[]> => {
    const lovableKey = process.env.LOVABLE_API_KEY;
    const mapsKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!lovableKey || !mapsKey) throw new Error("Maps connector not configured");

    const includedType = CATEGORY_TO_INCLUDED_TYPE[data.category] ?? data.category;

    const res = await fetch(`${GATEWAY}/places/v1/places:searchNearby`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${lovableKey}`,
        "X-Connection-Api-Key": mapsKey,
        "Content-Type": "application/json",
        "X-Goog-FieldMask":
          "places.id,places.displayName,places.formattedAddress,places.rating,places.location,places.currentOpeningHours.openNow",
      },
      body: JSON.stringify({
        includedTypes: [includedType],
        maxResultCount: 15,
        locationRestriction: {
          circle: {
            center: {
              latitude: EVENT_CONFIG.venue.latitude,
              longitude: EVENT_CONFIG.venue.longitude,
            },
            radius: 2000,
          },
        },
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error("Places API error", res.status, text);
      throw new Error(`Places lookup failed: ${res.status}`);
    }

    const json = (await res.json()) as { places?: Array<any> };
    const places: Place[] = (json.places ?? []).map((p) => {
      const lat = p.location?.latitude;
      const lng = p.location?.longitude;
      return {
        id: p.id,
        name: p.displayName?.text ?? "Unknown",
        address: p.formattedAddress,
        rating: p.rating,
        latitude: lat,
        longitude: lng,
        distanceMeters:
          lat != null && lng != null
            ? haversineMeters(EVENT_CONFIG.venue.latitude, EVENT_CONFIG.venue.longitude, lat, lng)
            : undefined,
        openNow: p.currentOpeningHours?.openNow,
      };
    });

    places.sort((a, b) => (a.distanceMeters ?? Infinity) - (b.distanceMeters ?? Infinity));
    return places;
  });

export type DirectionsRoute = {
  distanceMeters: number;
  durationSeconds: number;
  encodedPolyline: string;
  steps: { instruction: string; distanceMeters: number }[];
};

export const getDirections = createServerFn({ method: "POST" })
  .inputValidator((input: {
    originLat: number;
    originLng: number;
    destLat: number;
    destLng: number;
    travelMode?: "WALK" | "DRIVE";
  }) => {
    if (
      typeof input.originLat !== "number" ||
      typeof input.originLng !== "number" ||
      typeof input.destLat !== "number" ||
      typeof input.destLng !== "number"
    ) {
      throw new Error("Invalid coordinates");
    }
    return input;
  })
  .handler(async ({ data }): Promise<DirectionsRoute> => {
    const lovableKey = process.env.LOVABLE_API_KEY;
    const mapsKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!lovableKey || !mapsKey) throw new Error("Maps connector not configured");

    const travelMode = data.travelMode ?? "WALK";
    const res = await fetch(`${GATEWAY}/routes/directions/v2:computeRoutes`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${lovableKey}`,
        "X-Connection-Api-Key": mapsKey,
        "Content-Type": "application/json",
        "X-Goog-FieldMask":
          "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.legs.steps.navigationInstruction,routes.legs.steps.distanceMeters",
      },
      body: JSON.stringify({
        origin: { location: { latLng: { latitude: data.originLat, longitude: data.originLng } } },
        destination: { location: { latLng: { latitude: data.destLat, longitude: data.destLng } } },
        travelMode,
        polylineQuality: "OVERVIEW",
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      console.error("Directions API error", res.status, text);
      throw new Error(`Directions failed: ${res.status}`);
    }

    const json = (await res.json()) as { routes?: Array<any> };
    const route = json.routes?.[0];
    if (!route) throw new Error("No route found");

    const durationSeconds = route.duration ? parseInt(String(route.duration).replace(/s$/, "")) : 0;
    const steps = (route.legs?.[0]?.steps ?? []).map((s: any) => ({
      instruction: s.navigationInstruction?.instructions ?? "Continue",
      distanceMeters: s.distanceMeters ?? 0,
    }));

    return {
      distanceMeters: route.distanceMeters ?? 0,
      durationSeconds,
      encodedPolyline: route.polyline?.encodedPolyline ?? "",
      steps,
    };
  });
