import { useEffect, useState } from "react";
import { useRouterState } from "@tanstack/react-router";

/** Slim indeterminate progress bar shown during route transitions. */
export function RouteProgress() {
  const status = useRouterState({ select: (s) => s.status });
  const matches = useRouterState({ select: (s) => s.matches });
  const [visible, setVisible] = useState(false);

  // Only show for transitions that actually take a moment — avoids flashing
  // on instant, cache-served navigations.
  useEffect(() => {
    if (status === "pending") {
      const t = setTimeout(() => setVisible(true), 120);
      return () => clearTimeout(t);
    }
    setVisible(false);
  }, [status, matches.length]);

  if (!visible) return null;

  return (
    <div className="fixed inset-x-0 top-0 z-50 h-0.5" style={{ paddingTop: "env(safe-area-inset-top)" }}>
      <div className="h-full w-full overflow-hidden bg-primary/15">
        <div className="h-full w-1/3 animate-route-progress bg-primary" />
      </div>
    </div>
  );
}
