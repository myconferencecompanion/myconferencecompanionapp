import { format, formatDistanceToNow, isToday, isTomorrow } from "date-fns";

// Conference runs on West Africa Time; render all event times in WAT so every
// attendee sees the same schedule regardless of where they travel from.
const EVENT_TZ = "Africa/Lagos";

const watTime = new Intl.DateTimeFormat("en-NG", {
  hour: "numeric",
  minute: "2-digit",
  hour12: true,
  timeZone: EVENT_TZ,
});

export function formatTime(d: string | Date) {
  return watTime.format(new Date(d));
}

export function formatDayLabel(d: string | Date) {
  const date = new Date(d);
  if (isToday(date)) return "Today";
  if (isTomorrow(date)) return "Tomorrow";
  return format(date, "EEE, MMM d");
}

export function formatRelative(d: string | Date) {
  return formatDistanceToNow(new Date(d), { addSuffix: true });
}

export function formatTimeRange(start: string | Date, end: string | Date) {
  return `${formatTime(start)} – ${formatTime(end)}`;
}

export function initials(name: string) {
  return name
    .split(" ")
    .map((p) => p[0])
    .filter(Boolean)
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

const ngnFormatter = new Intl.NumberFormat("en-NG", {
  style: "currency",
  currency: "NGN",
  maximumFractionDigits: 0,
});

export function formatNGN(value: number | string) {
  const n = typeof value === "string" ? Number(value) : value;
  if (!Number.isFinite(n)) return "₦0";
  return ngnFormatter.format(n);
}
