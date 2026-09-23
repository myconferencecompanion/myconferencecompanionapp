// Bundled reference data — synced from the Flutter app's assets by
// tool/sync_web_data.mjs (runs as prebuild). When we move to Supabase,
// these become the fallback layer.
import hotelsJson from "@/data/hotels.json";
import venueJson from "@/data/venue.json";

export interface HotelRoom {
  label: string;
  rate: string;
}

export interface Hotel {
  id: string;
  rank: number;
  qualityTier: "premier" | "standard" | "value" | "pending";
  name: string;
  shortName: string;
  tone: string;
  location: string;
  distanceToVenue: string | null;
  contactPhone: string | null;
  description: string;
  roomSummary: string | null;
  rateStatus: string;
  highlights: string[];
  rooms: HotelRoom[];
  images: { preview: string; thumb: string }[];
  photoCount: number;
  latitude?: number | null;
  longitude?: number | null;
}

export interface NearbyPoi {
  id: string;
  name: string;
  category: string;
  distance?: string;
  distanceKm?: number;
  latitude?: number;
  longitude?: number;
  note?: string;
  phone?: string;
  query?: string;
}

export interface VenueData {
  venue: { name: string; shortName: string; latitude: number; longitude: number; image: string };
  shuttle: string;
  parking: string;
  directions: string[];
  nearby: NearbyPoi[];
}

export const HOTELS = hotelsJson as Hotel[];
export const VENUE_DATA = venueJson as VenueData;

/** Minimum numeric nightly rate across a hotel's room list, in naira. */
export function hotelMinRate(hotel: Hotel): number | null {
  const nums = hotel.rooms
    .map((r) => Number(String(r.rate).replace(/[^0-9.]/g, "")))
    .filter((n) => Number.isFinite(n) && n > 0);
  return nums.length ? Math.min(...nums) : null;
}

export function hotelDistanceKm(hotel: Hotel): number | null {
  const m = hotel.distanceToVenue?.match(/([\d.]+)\s*km/i);
  return m ? Number(m[1]) : null;
}

export function hasHotelPhotos(hotel: Hotel): boolean {
  return hotel.photoCount > 0;
}

/** Photo URL resolver: bundled photos live under /hotels/<id>/… on the web. */
export function hotelPhotoUrl(hotel: Hotel, index = 0, thumb = true): string {
  const img = hotel.images[index];
  if (!img) return "";
  const raw = thumb ? img.thumb : img.preview;
  return raw.startsWith("http") ? raw : raw;
}

export const POI_CATEGORY_ORDER = [
  "Airport",
  "Security",
  "Government",
  "Culture",
  "Hospital",
  "Restaurant",
  "Pharmacy",
  "ATM",
  "Shopping",
  "Spouses visit",
] as const;

export function poisByCategory(pois: NearbyPoi[]): Map<string, NearbyPoi[]> {
  const map = new Map<string, NearbyPoi[]>();
  for (const poi of pois) {
    const list = map.get(poi.category) ?? [];
    list.push(poi);
    map.set(poi.category, list);
  }
  return map;
}

/** Haversine distance in km between two lat/lng pairs. */
export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
