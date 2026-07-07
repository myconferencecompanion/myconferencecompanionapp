import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Star, MapPin, Navigation } from "lucide-react";

export const Route = createFileRoute("/_authenticated/accommodation")({
  component: AccommodationPage,
});

function AccommodationPage() {
  const { data: hotels = [] } = useQuery({
    queryKey: ["accommodations"],
    queryFn: async () => {
      const { data } = await supabase.from("accommodations").select("*").order("distance_km");
      return data ?? [];
    },
  });

  return (
    <div className="space-y-4 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">Accommodation</h2>
        <p className="text-sm text-muted-foreground">Recommended stays near the venue</p>
      </div>

      <div className="space-y-4">
        {hotels.map((h) => (
          <Card key={h.id} className="overflow-hidden border-0 p-0 shadow-card">
            {h.image_url && (
              <img src={h.image_url} alt={h.name} className="h-44 w-full object-cover" loading="lazy" />
            )}
            <div className="space-y-2 p-4">
              <div className="flex items-start justify-between gap-2">
                <h3 className="text-base font-semibold leading-tight">{h.name}</h3>
                <Badge variant="secondary" className="shrink-0">{"₦".repeat(h.price_tier)}</Badge>
              </div>
              {h.description && <p className="text-xs text-muted-foreground">{h.description}</p>}
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                {h.rating != null && (
                  <span className="inline-flex items-center gap-1">
                    <Star className="h-3 w-3 fill-accent text-accent" /> {h.rating}
                  </span>
                )}
                {h.distance_km != null && (
                  <span className="inline-flex items-center gap-1">
                    <MapPin className="h-3 w-3" /> {h.distance_km} km from venue
                  </span>
                )}
                {h.price_range && <span className="text-foreground">{h.price_range}</span>}
              </div>
              {h.amenities && h.amenities.length > 0 && (
                <div className="flex flex-wrap gap-1">
                  {h.amenities.slice(0, 5).map((a) => (
                    <Badge key={a} variant="outline" className="text-[10px]">{a}</Badge>
                  ))}
                </div>
              )}
              <div className="flex gap-2 pt-2">
                {h.latitude != null && h.longitude != null && (
                  <Button variant="outline" size="sm" asChild className="flex-1">
                    <Link to="/directions" search={{ lat: h.latitude, lng: h.longitude, name: h.name }}>
                      <Navigation className="h-4 w-4" /> Directions
                    </Link>
                  </Button>
                )}
                {h.booking_url && (
                  <Button size="sm" asChild className="flex-1">
                    <a href={h.booking_url} target="_blank" rel="noreferrer">Book</a>
                  </Button>
                )}
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
