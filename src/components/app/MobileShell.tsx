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
      <main className="flex-1 pb-24">{children}</main>
      <FloatingChatbot />
      <BottomTabs />
    </div>
  );
}
