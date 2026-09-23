// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - tanstackStart, viteReact, tailwindcss, tsConfigPaths, nitro (build-only using cloudflare as a default target),
//     componentTagger (dev-only), VITE_* env injection, @ path alias, React/TanStack dedupe,
//     error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { readFileSync } from "node:fs";
import { resolve as resolvePath } from "node:path";
import { defineConfig } from "@lovable.dev/vite-tanstack-config";

// Nitro bundles the Flutter `assets/` directory as server assets and imports
// those JSON files via `raw:<file>` specifiers. Its raw plugin emits the file
// text as `export default "<text>"` with moduleType "js" — but the virtual id
// still ends in .json, and standard Vite ignores moduleType: vite:json then
// JSON.parses the emitted *module code* and the build fails.
// This plugin intercepts `raw:*.json` specifiers BEFORE Nitro's raw plugin
// and serves the identical default-exported-string module under a virtual id
// WITHOUT the .json suffix, so vite:json's filter never matches.
function nitroRawJsonCompat() {
  const files = new Map<string, string>();

  return {
    name: "cc-nitro-raw-json-compat",
    enforce: "pre" as const,
    resolveId: {
      order: "pre" as const,
      handler(id: string) {
        if (!id.startsWith("raw:") || !id.endsWith(".json")) return null;
        const file = resolvePath(id.slice(4));
        const virtualId = `\0cc-raw:${file.replace(/\.json$/i, "")}.ccjson`;
        files.set(virtualId, file);
        return virtualId;
      },
    },
    load(id: string) {
      const file = files.get(id);
      if (!file) return null;
      const text = readFileSync(file, "utf8");
      return `export default ${JSON.stringify(text)};\n`;
    },
  };
}

export default defineConfig({
  tanstackStart: {
    // Redirect TanStack Start's bundled server entry to src/server.ts (our SSR error wrapper).
    // nitro/vite builds from this
    server: { entry: "server" },
  },
  // Deploy target: Vercel (serverless SSR). Without this, the wrapper skips
  // the nitro deploy plugin outside Lovable sandboxes and the built app has
  // no server — every SSR route 404s on Vercel.
  nitro: { preset: "vercel" },
  vite: {
    plugins: [nitroRawJsonCompat()],
  },
});
