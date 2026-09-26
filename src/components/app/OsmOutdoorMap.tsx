import { useMemo } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import { VENUE_DATA, HOTELS } from "@/lib/reference";
import { EVENT_CONFIG } from "@/lib/event-config";

/**
 * Interactive outdoor map — OpenStreetMap tiles via Leaflet.
 * No API key, no billing, works forever. Shows the venue, all nearby
 * places and every geocoded hotel with category-colored pins and
 * tap-to-navigate popups.
 */

const CATEGORY_COLORS: Record<string, string> = {
  Airport: "#123E73",
  Security: "#c0392b",
  Government: "#123E73",
  Culture: "#c9a227",
  Hospital: "#1e8e3e",
  Restaurant: "#c9a227",
  Pharmacy: "#1e8e3e",
  ATM: "#123E73",
  Shopping: "#c9a227",
  "Spouses visit": "#c9a227",
  Hotel: "#c9a227",
};

function pinIcon(color: string, size = "md") {
  const s = size === "lg" ? 34 : 24;
  return L.divIcon({
    className: "",
    html: `<span style="display:flex;width:${s}px;height:${s}px;border-radius:9999px;background:${color};border:2.5px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.35);align-items:center;justify-content:center;color:#fff;font-size:${s / 2}px;line-height:1">📍</span>`,
    iconSize: [s, s],
    iconAnchor: [s / 2, s / 2],
    popupAnchor: [0, -s / 2],
  });
}

export function OsmOutdoorMap() {
  const center = useMemo(
    () => [EVENT_CONFIG.venue.latitude, EVENT_CONFIG.venue.longitude] as [number, number],
    [],
  );

  const pois = VENUE_DATA.nearby.filter(
    (p) => p.latitude != null && p.longitude != null,
  );
  const hotels = HOTELS.filter((h) => h.latitude != null && h.longitude != null);

  return (
    <div className="overflow-hidden rounded-2xl shadow-card">
      <MapContainer
        center={center}
        zoom={13}
        scrollWheelZoom={false}
        className="h-[380px] w-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {/* Venue */}
        <Marker position={center} icon={pinIcon("#123E73", "lg")}>
          <Popup>
            <strong>{EVENT_CONFIG.venue.name}</strong>
            <br />
            {EVENT_CONFIG.venue.address}
            <br />
            <a
              href={`https://www.google.com/maps/dir/?api=1&destination=${center[0]},${center[1]}`}
              target="_blank"
              rel="noreferrer"
            >
              Get directions
            </a>
          </Popup>
        </Marker>
        {/* Nearby POIs */}
        {pois.map((p) => (
          <Marker
            key={p.id}
            position={[p.latitude!, p.longitude!]}
            icon={pinIcon(CATEGORY_COLORS[p.category] ?? "#555")}
          >
            <Popup>
              <strong>{p.name}</strong>
              <br />
              {p.category}
              {p.phone ? (
                <>
                  <br />
                  <a href={`tel:${p.phone.replace(/\s+/g, "")}`}>{p.phone}</a>
                </>
              ) : null}
              <br />
              <a
                href={`https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}`}
                target="_blank"
                rel="noreferrer"
              >
                Directions
              </a>
            </Popup>
          </Marker>
        ))}
        {/* Geocoded hotels */}
        {hotels.map((h) => (
          <Marker
            key={h.id}
            position={[h.latitude!, h.longitude!]}
            icon={pinIcon(CATEGORY_COLORS.Hotel)}
          >
            <Popup>
              <strong>{h.name}</strong>
              <br />
              Delegate hotel
              <br />
              <a
                href={`https://www.google.com/maps/dir/?api=1&destination=${h.latitude},${h.longitude}`}
                target="_blank"
                rel="noreferrer"
              >
                Directions
              </a>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
