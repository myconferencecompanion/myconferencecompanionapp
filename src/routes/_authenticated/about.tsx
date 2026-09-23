import { createFileRoute } from "@tanstack/react-router";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CONFERENCE_INFO, TRANSPORT } from "@/lib/reference";
import { EVENT_CONFIG } from "@/lib/event-config";

export const Route = createFileRoute("/_authenticated/about")({
  component: AboutPage,
});

function AboutPage() {
  const info = CONFERENCE_INFO;

  return (
    <div className="space-y-4 px-4 pb-6 pt-5">
      <div>
        <h2 className="text-xl font-bold">About NSE</h2>
        <p className="text-sm text-muted-foreground">
          Conference identity and context.
        </p>
      </div>

      {/* Identity card — brand gradient like the APK's hero */}
      <Card className="overflow-hidden border-0 shadow-card">
        <div className="bg-brand-gradient px-4 py-6 text-center text-white">
          <p className="text-xs font-medium uppercase tracking-widest text-white/70">
            {info.organizationName}
          </p>
          <h3 className="mt-2 text-lg font-bold leading-tight">
            {info.conferenceTitle}
          </h3>
          <p className="mx-auto mt-3 max-w-xs text-xs leading-relaxed text-white/85">
            {info.theme}
          </p>
        </div>
      </Card>

      {/* Dates, venue, chairman */}
      <Card className="border-0 p-4 shadow-card">
        <p className="text-sm font-semibold">{info.dates}</p>
        <p className="mt-1 text-sm text-muted-foreground">{info.venue}</p>
        <div className="mt-3 border-t border-border pt-3">
          <p className="text-xs uppercase tracking-wider text-muted-foreground">
            Conference Chairman
          </p>
          <p className="text-sm font-semibold">{info.chairman}</p>
        </div>
        <a
          href={info.officialSite}
          target="_blank"
          rel="noreferrer"
          className="mt-3 inline-block text-xs font-medium text-primary"
        >
          {info.officialSite.replace(/^https?:\/\//, "")} ↗
        </a>
      </Card>

      {/* NSE stats chips */}
      <div className="flex flex-wrap gap-2">
        {info.stats.map((s) => (
          <Badge
            key={s.label}
            variant="outline"
            className="border-success/25 bg-success-soft px-3 py-1.5 text-xs text-success-foreground"
          >
            {s.value} {s.label}
          </Badge>
        ))}
      </div>

      {/* Entertainment sub-committee */}
      <section>
        <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-muted-foreground">
          Entertainment
        </h3>
        <Card className="border-0 p-4 shadow-card">
          <p className="text-sm font-semibold">{info.entertainment.title}</p>
          <p className="text-xs text-muted-foreground">Chair: {info.entertainment.chair}</p>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            {info.entertainment.focus}
          </p>
        </Card>
      </section>

      {/* Spouses programme */}
      <section>
        <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-muted-foreground">
          Spouses programme
        </h3>
        <Card className="border-0 p-4 shadow-card">
          <p className="text-sm font-semibold">{info.spouses.title}</p>
          <p className="text-xs text-muted-foreground">{info.spouses.venue}</p>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            {info.spouses.focus}
          </p>
        </Card>
      </section>

      {/* Shuttle policy summary (from transport data, same as APK) */}
      <section>
        <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-muted-foreground">
          Delegate transport
        </h3>
        <Card className="border-0 p-4 shadow-card">
          <p className="text-sm font-semibold capitalize">
            {TRANSPORT.defaultPolicy.replace(/_/g, " ")} shuttle policy
          </p>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            {TRANSPORT.policyDescriptions[TRANSPORT.defaultPolicy]}
          </p>
          <p className="mt-2 text-xs text-muted-foreground">
            {TRANSPORT.buses.length} buses · shuttles run from ICC main entrance.
            Full routes under <span className="font-medium text-foreground">Transport</span>.
          </p>
        </Card>
      </section>

      <p className="pt-2 text-center text-xs text-muted-foreground">
        {EVENT_CONFIG.shortName} · {EVENT_CONFIG.dates}
      </p>
    </div>
  );
}
