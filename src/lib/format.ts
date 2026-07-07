import { format, formatDistanceToNow, isToday, isTomorrow } from "date-fns";

export function formatTime(d: string | Date) {
  return format(new Date(d), "h:mm a");
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
