import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { initials } from "@/lib/format";

export const Route = createFileRoute("/_authenticated/speakers")({
  component: SpeakersPage,
});

function SpeakersPage() {
  const { data: speakers = [] } = useQuery({
    queryKey: ["speakers"],
    queryFn: async () => {
      const { data } = await supabase
        .from("speakers")
        .select("*")
        .order("is_keynote", { ascending: false })
        .order("name");
      return data ?? [];
    },
  });

  return (
    <div className="px-4 pt-5">
      <h2 className="text-xl font-bold">Speakers</h2>
      <p className="text-sm text-muted-foreground">{speakers.length} amazing people</p>

      <div className="mt-5 grid grid-cols-2 gap-3">
        {speakers.map((sp) => (
          <Link key={sp.id} to="/speakers/$speakerId" params={{ speakerId: sp.id }}>
            <Card className="overflow-hidden border-0 p-4 shadow-card">
              <Avatar className="mx-auto h-20 w-20">
                <AvatarImage src={sp.avatar_url ?? undefined} />
                <AvatarFallback className="text-base">{initials(sp.name)}</AvatarFallback>
              </Avatar>
              <p className="mt-3 text-center text-sm font-semibold leading-tight">{sp.name}</p>
              {sp.title && (
                <p className="mt-0.5 line-clamp-2 text-center text-[11px] text-muted-foreground">
                  {sp.title}
                </p>
              )}
              {sp.company && (
                <p className="text-center text-[11px] font-medium text-primary">{sp.company}</p>
              )}
              {sp.is_keynote && (
                <Badge className="mt-2 w-full justify-center bg-accent text-accent-foreground hover:bg-accent">
                  Keynote
                </Badge>
              )}
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
