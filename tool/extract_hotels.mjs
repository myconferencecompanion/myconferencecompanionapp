import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const hotelsRoot = "C:/Users/Sage Trill/Music/SAGE/ORIVON EDGE/PROJECTS/NSE/Hotels";
const src = path.join(hotelsRoot, "src/App.tsx");
const imagesSrc = path.join(hotelsRoot, "src/generated/hotelImages.ts");
const out = path.resolve(__dirname, "../assets/data/hotels.json");

function idToImagesKey(id) {
  return id
    .split("-")
    .map((part, i) => (i === 0 ? part : part[0].toUpperCase() + part.slice(1)))
    .join("");
}

function parseHotels(ts) {
  const start = ts.indexOf("const hotels: Hotel[] = [");
  const end = ts.indexOf("\n];\n", start + 30);
  const body = ts.slice(start, end);
  const blocks = body.split(/\n  \{\n/).slice(1);
  const hotels = [];

  for (let i = 0; i < blocks.length; i++) {
    const block = blocks[i];
    const pick = (key) => {
      const re = new RegExp(`${key}:\\s*"([^"]*)"`);
      const m = block.match(re);
      return m ? m[1] : null;
    };
    const id = pick("id");
    if (!id) continue;

    const highlightsBlock = block.match(/highlights:\s*\[([\s\S]*?)\],/);
    const highlights = highlightsBlock
      ? [...highlightsBlock[1].matchAll(/"([^"]+)"/g)]
          .map((m) => m[1])
          .filter((s) => s.length > 8 && !s.includes("http") && !s.startsWith("N"))
          .slice(0, 4)
      : [];

    const rooms = [...block.matchAll(/\{ label: "([^"]+)", rate: "([^"]+)" \}/g)].map((m) => ({
      label: m[1],
      rate: m[2],
    }));

    const rates = rooms
      .flatMap((r) => [...r.rate.matchAll(/N\s?([0-9]{1,3}(?:,[0-9]{3})*)/gi)])
      .map((m) => Number(m[1].replaceAll(",", "")))
      .filter((n) => Number.isFinite(n));

    const maxRate = rates.length ? Math.max(...rates) : 0;
    const rank = i + 1;
    let qualityTier = "standard";
    if (rank <= 8 || maxRate >= 70000) qualityTier = "premier";
    else if (rank >= 20 || maxRate < 30000) qualityTier = "value";
    if (rooms.length === 0 || pick("rateStatus")?.toLowerCase().includes("pending")) {
      qualityTier = "pending";
    }

    hotels.push({
      id,
      rank,
      qualityTier,
      name: pick("name"),
      shortName: pick("shortName"),
      tone: pick("tone"),
      location: pick("location"),
      distanceToVenue: pick("distanceToVenue"),
      contactPhone: pick("contactPhone"),
      description: pick("description"),
      roomSummary: pick("roomSummary"),
      rateStatus: pick("rateStatus"),
      highlights,
      rooms,
      imagesKey: idToImagesKey(id),
    });
  }
  return hotels;
}

function parseImageMap(ts) {
  const map = {};
  const entries = [...ts.matchAll(/^\s+([a-zA-Z][a-zA-Z0-9]*):\s*\[/gm)];
  for (const match of entries) {
    const key = match[1];
    const start = match.index;
    const slice = ts.slice(start);
    const end = slice.indexOf("\n  ],");
    const block = slice.slice(0, end + 5);
    const photos = [...block.matchAll(/"preview":\s*"([^"]+)"/g)].map((m) => m[1]);
    const thumbs = [...block.matchAll(/"thumb":\s*"([^"]+)"/g)].map((m) => m[1]);
    map[key] = photos.map((preview, idx) => ({
      preview,
      thumb: thumbs[idx] ?? preview,
    }));
  }
  return map;
}

const hotelTs = fs.readFileSync(src, "utf8").replace(/\r\n/g, "\n");
const imageTs = fs.readFileSync(imagesSrc, "utf8").replace(/\r\n/g, "\n");
const imageMap = parseImageMap(imageTs);
const hotels = parseHotels(hotelTs).map((h) => {
  const images = imageMap[h.imagesKey] ?? [];
  const { imagesKey, ...rest } = h;
  return { ...rest, images, photoCount: images.length };
});

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(hotels, null, 2));
console.log(`Wrote ${hotels.length} ranked hotels (${hotels.filter((h) => h.photoCount > 0).length} with photos) to ${out}`);
