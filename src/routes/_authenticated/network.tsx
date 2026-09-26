import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { initials } from "@/lib/format";
import { Hash, Search, MessageCircle } from "lucide-react";

export const Route = createFileRoute("/_authenticated/network")({
  component: NetworkPage,
});

function NetworkPage() {
  const { user } = useAuth();
  const [q, setQ] = useState("");

  const { data: directory = [] } = useQuery({
    queryKey: ["directory"],
    queryFn: async () => {
      const { data } = await supabase
        .from("profiles")
        .select("*")
        .eq("networking_opt_in", true)
        .order("display_name");
      return (data ?? []).filter((p) => p.id !== user?.id);
    },
  });

  const { data: rooms = [] } = useQuery({
    queryKey: ["rooms"],
    queryFn: async () => {
      const { data } = await supabase.from("chat_rooms").select("*").order("sort_order");
      return data ?? [];
    },
  });

  const filtered = directory.filter((p) => {
    const s = q.toLowerCase();
    return (
      !s ||
      p.display_name?.toLowerCase().includes(s) ||
      p.company?.toLowerCase().includes(s) ||
      p.title?.toLowerCase().includes(s)
    );
  });

  return (
    <div className="px-4 pt-5">
      <h2 className="text-xl font-bold">Network</h2>
      <p className="text-sm text-muted-foreground">Connect with fellow attendees</p>

      <Tabs defaultValue="rooms" className="mt-4">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="rooms">Chat rooms</TabsTrigger>
          <TabsTrigger value="people">People</TabsTrigger>
        </TabsList>

        <TabsContent value="rooms" className="mt-4 space-y-3">
          {rooms.map((r) => (
            <Link key={r.id} to="/network/room/$roomId" params={{ roomId: r.id }}>
              <Card className="flex items-center gap-3 border-0 p-4 shadow-card">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary-soft text-primary">
                  <Hash className="h-5 w-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold">{r.name}</p>
                  {r.description && (
                    <p className="line-clamp-1 text-xs text-muted-foreground">{r.description}</p>
                  )}
                </div>
                <MessageCircle className="h-4 w-4 text-muted-foreground" />
              </Card>
            </Link>
          ))}
        </TabsContent>

        <TabsContent value="people" className="mt-4 space-y-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search by name, company, role…"
              className="pl-9"
            />
          </div>

          {filtered.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              {directory.length === 0
                ? "Be the first to join the directory! Enable it in your profile."
                : "No matches."}
            </p>
          ) : (
            filtered.map((p) => (
              <Link key={p.id} to="/network/$userId" params={{ userId: p.id }}>
                <Card className="flex items-center gap-3 border-0 p-4 shadow-card">
                  <Avatar className="h-12 w-12">
                    <AvatarImage src={p.avatar_url ?? undefined} />
                    <AvatarFallback>{initials(p.display_name)}</AvatarFallback>
                  </Avatar>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold">{p.display_name}</p>
                    <p className="truncate text-xs text-muted-foreground">
                      {[p.title, p.company].filter(Boolean).join(" · ") || "Attendee"}
                    </p>
                  </div>
                  <MessageCircle className="h-4 w-4 text-muted-foreground" />
                </Card>
              </Link>
            ))
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
