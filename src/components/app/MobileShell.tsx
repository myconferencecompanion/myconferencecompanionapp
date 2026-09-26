import type { ReactNode } from "react";
import { BottomTabs } from "./BottomTabs";
import { FloatingChatbot } from "./FloatingChatbot";

/**
 * Mirrors the Flutter MainShell: each page owns its own header
 * (NseHeroHeader / NseTitleHeader equivalents), so the shell only provides
 * the column, floating chat and bottom nav.
 */
export function MobileShell({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto flex min-h-screen w-full max-w-[640px] flex-col bg-background">
      {/* Clearance for the fixed bottom nav (incl. iPhone safe area) plus
          breathing room, so page-bottom actions like "Sign out" are never
          covered by the tab bar. */}
      <main
        className="flex-1"
        style={{ paddingBottom: "calc(env(safe-area-inset-bottom, 0px) + 6.5rem)" }}
      >
        {children}
      </main>
      <FloatingChatbot />
      <BottomTabs />
    </div>
  );
}
