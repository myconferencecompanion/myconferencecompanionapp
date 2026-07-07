import type { ReactNode } from "react";
import { TopBar } from "./TopBar";
import { BottomTabs } from "./BottomTabs";
import { FloatingChatbot } from "./FloatingChatbot";

export function MobileShell({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto flex min-h-screen w-full max-w-[640px] flex-col bg-background">
      <TopBar />
      <main className="flex-1 pb-24">{children}</main>
      <FloatingChatbot />
      <BottomTabs />
    </div>
  );
}
