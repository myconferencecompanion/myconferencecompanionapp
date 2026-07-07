import { createFileRoute, Outlet } from "@tanstack/react-router";

export const Route = createFileRoute("/_authenticated/concierge")({
  component: () => <Outlet />,
});
