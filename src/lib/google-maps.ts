import { useEffect, useRef, useState } from "react";

declare global {
  interface Window {
    google: any;
    __googleMapsLoaded?: boolean;
    __googleMapsLoading?: Promise<void>;
    __initGoogleMap?: () => void;
  }
}

const API_KEY = import.meta.env.VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_BROWSER_KEY;
const CHANNEL = import.meta.env.VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_TRACKING_ID;

export function loadGoogleMaps(): Promise<void> {
  if (typeof window === "undefined") return Promise.resolve();
  if (window.__googleMapsLoaded) return Promise.resolve();
  if (window.__googleMapsLoading) return window.__googleMapsLoading;

  if (!API_KEY) {
    return Promise.reject(new Error("Google Maps browser key is not configured."));
  }

  window.__googleMapsLoading = new Promise<void>((resolve, reject) => {
    window.__initGoogleMap = () => {
      window.__googleMapsLoaded = true;
      resolve();
    };
    const script = document.createElement("script");
    const params = new URLSearchParams({
      key: API_KEY,
      loading: "async",
      callback: "__initGoogleMap",
      libraries: "marker,places,geometry",
    });
    if (CHANNEL) params.set("channel", CHANNEL);
    script.src = `https://maps.googleapis.com/maps/api/js?${params.toString()}`;
    script.async = true;
    script.onerror = () => reject(new Error("Failed to load Google Maps script"));
    document.head.appendChild(script);
  });

  return window.__googleMapsLoading;
}

export function useGoogleMaps() {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    let mounted = true;
    loadGoogleMaps()
      .then(() => mounted && setReady(true))
      .catch((e) => mounted && setError(e.message));
    return () => {
      mounted = false;
    };
  }, []);
  return { ready, error };
}
