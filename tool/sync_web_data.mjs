// Keeps the web app's bundled data in sync with the Flutter app's source of truth.
// Run automatically before every build via the "prebuild" npm script:
//   node tool/sync_web_data.mjs
import fs from "node:fs";
import path from "node:path";

const readJson = (p) =>
  JSON.parse(fs.readFileSync(p, "utf8").replace(/^\uFEFF/, ""));

const outDir = path.join(process.cwd(), "src", "data");
fs.mkdirSync(outDir, { recursive: true });

const jobs = [
  ["assets/data/hotels.json", "hotels.json"],
  ["assets/data/maiduguri_pois.json", "venue.json"],
];

for (const [src, dest] of jobs) {
  const data = readJson(path.join(process.cwd(), src));
  const out = path.join(outDir, dest);
  fs.writeFileSync(out, JSON.stringify(data, null, 2) + "\n", "utf8");
  console.log(`synced ${src} -> ${out}`);
}
