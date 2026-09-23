// Conference-wide configuration. Easy to swap when the real event details land.
export const EVENT_CONFIG = {
  name: "NSE Conference",
  year: "2026",
  // The app's display brand (header title, AI concierge subtitle).
  shortName: "Conference Companion",
  tagline: "Engineering Innovation for Enhanced Security and Sustainable National Development",
  dates: "30 November – 4 December 2026",
  venue: {
    name: "International Conference Centre",
    address: "Maiduguri, Borno State, Nigeria",
    latitude: 11.8333,
    longitude: 13.1500,
  },
  wifi: { ssid: "NSE-Conference-2026", password: "engineers2026" },
  primaryHotline: "+2348009876543",
} as const;
