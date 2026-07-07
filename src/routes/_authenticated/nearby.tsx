import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Utensils, Banknote, Pill, Bus, Coffee, ShoppingBag, Navigation, MapPin, Loader2, Star } from "lucide-react";
import { searchNearby, type Place } from "@/lib/maps.functions";
import { useServerFn } from "@tanstack/react-start";
import { useMutation } from "@tanstack/react-query";
import { Link } from "@tanstack/react-router";

export const Route = createFileRoute("/_authenticated/nearby")({
  component: NearbyPage,
});

const CATEGORIES = [
  { key: "restaurant", label: "Food", icon: Utensils },
  { key: "cafe", label: "Cafés", icon: Coffee },
  { key: "atm", label: "ATM", icon: Banknote },
  { key: "pharmacy", label: "Pharmacy", icon: Pill },
  { key: "transit_station", label: "Transport", icon: Bus },
  { key: "shopping_mall", label: "Shops", icon: ShoppingBag },
] as const;

function NearbyPage() {
  const [active, setActive] = useState<string>("restaurant");
  const fn = useServerFn(searchNearby);
  const { data: results = [], isPending, error, mutate } = useMutation({
    mutationFn: async (cat: string) => fn({ data: { category: cat } }),
  });

  function pick(cat: string) {
    setActive(cat);
    mutate(cat);
  }

  useEffect(() => {
    mutate("restaurant");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="px-4 pt-5">
      <h2 className="text-xl font-bold">Nearby</h2>
      <p className="text-sm text-muted-foreground">Around the venue</p>

      <div className="-mx-4 mt-4 flex gap-2 overflow-x-auto px-4 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {CATEGORIES.map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => pick(key)}
            className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-2 text-xs font-medium transition ${
              active === key
                ? "border-primary bg-primary text-primary-foreground"
                : "border-border bg-surface text-muted-foreground"
            }`}
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </button>
        ))}
      </div>

      <div className="mt-4 space-y-3">
        {isPending && (
          <div className="flex justify-center py-12 text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin" />
          </div>
        )}
        {error && (
          <Card className="border-destructive/30 bg-destructive/5 p-4 text-sm text-destructive">
            Couldn't load places. Try again.
          </Card>
        )}
        {!isPending && results.length === 0 && !error && (
          <p className="py-8 text-center text-sm text-muted-foreground">No results.</p>
        )}
        {results.map((p) => (
          <PlaceCard key={p.id} place={p} />
        ))}
      </div>
    </div>
  );
}

function PlaceCard({ place }: { place: Place }) {
  return (
    <Card className="border-0 p-4 shadow-card">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <h3 className="text-sm font-semibold">{place.name}</h3>
          {place.address && <p className="mt-0.5 text-xs text-muted-foreground">{place.address}</p>}
          <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
            {place.rating != null && (
              <span className="inline-flex items-center gap-1">
                <Star className="h-3 w-3 fill-accent text-accent" /> {place.rating.toFixed(1)}
              </span>
            )}
            {place.distanceMeters != null && (
              <span className="inline-flex items-center gap-1">
                <MapPin className="h-3 w-3" /> {Math.round(place.distanceMeters)} m
              </span>
            )}
            {place.openNow != null && (
              <span className={place.openNow ? "text-success" : "text-destructive"}>
                {place.openNow ? "Open now" : "Closed"}
              </span>
            )}
          </div>
        </div>
        {place.latitude != null && place.longitude != null && (
          <Button size="sm" variant="outline" asChild>
            <Link to="/directions" search={{ lat: place.latitude, lng: place.longitude, name: place.name }}>
              <Navigation className="h-3.5 w-3.5" />
            </Link>
          </Button>
        )}
      </div>
    </Card>
  );
}
