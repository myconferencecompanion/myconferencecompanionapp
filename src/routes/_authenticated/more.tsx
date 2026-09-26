import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { useAuth } from "@/lib/auth";
import { LogIn } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import {
  ShieldAlert,
  Megaphone,
  User,
  LogOut,
  Wifi,
  Settings,
  MessageCircle,
  KeyRound,
  Bus,
  HelpCircle,
  Info,
} from "lucide-react";
import { EVENT_CONFIG } from "@/lib/event-config";
import { toast } from "sonner";

export const Route = createFileRoute("/_authenticated/more")({
  component: MorePage,
});

const items = [
  { to: "/network", label: "Networking", icon: MessageCircle },
  { to: "/announcements", label: "Announcements", icon: Megaphone },
  { to: "/emergency", label: "Emergency", icon: ShieldAlert },
  { to: "/transport", label: "Transport", icon: Bus },
  { to: "/faq", label: "Conference Guide (FAQ)", icon: HelpCircle },
  { to: "/about", label: "About NSE", icon: Info },
  { to: "/profile", label: "Edit profile", icon: User, memberOnly: true },
] as const;

function MorePage() {
  const { isAdmin, user, signOut, refreshRoles } = useAuth();
  const [codeOpen, setCodeOpen] = useState(false);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);

  async function redeem() {
    if (!code.trim()) return;
    setBusy(true);
    const { data, error } = await supabase.rpc("redeem_signup_code", { _code: code.trim() });
    setBusy(false);
    if (error) return toast.error(error.message);
    const label = Array.isArray(data) && data[0]?.label;
    toast.success(label ? `Role granted: ${label}` : "Role granted");
    setCode("");
    setCodeOpen(false);
    await refreshRoles();
  }


  return (
    <div className="space-y-5 px-4 pt-5">
      <div>
        <h2 className="text-xl font-bold">More</h2>
      </div>

      <Card className="border-0 p-4 shadow-card">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent-soft text-warning-foreground">
            <Wifi className="h-5 w-5" />
          </div>
          <div className="flex-1">
            <p className="text-xs uppercase tracking-wider text-muted-foreground">Conference Wi-Fi</p>
            <p className="font-mono text-sm font-semibold">{EVENT_CONFIG.wifi.ssid}</p>
            <p className="font-mono text-xs text-muted-foreground">Password: {EVENT_CONFIG.wifi.password}</p>
          </div>
        </div>
      </Card>

      <Card className="overflow-hidden border-0 shadow-card">
        <ul className="divide-y divide-border">
          {items
            .filter((it) => !("memberOnly" in it) || user)
            .map(({ to, label, icon: Icon }) => (
            <li key={to}>
              <Link to={to} className="flex items-center gap-3 px-4 py-3.5 transition active:bg-muted">
                <Icon className="h-5 w-5 text-muted-foreground" />
                <span className="flex-1 text-sm font-medium">{label}</span>
                <span className="text-muted-foreground">›</span>
              </Link>
            </li>
            ))}
          {!user && (
            <li>
              <Link to="/auth" className="flex items-center gap-3 px-4 py-3.5 transition active:bg-muted">
                <LogIn className="h-5 w-5 text-primary" />
                <span className="flex-1 text-sm font-medium text-primary">Sign in / Create account</span>
                <span className="text-muted-foreground">›</span>
              </Link>
            </li>
          )}
          {isAdmin && (
            <li>
              <Link to="/admin" className="flex items-center gap-3 px-4 py-3.5 transition active:bg-muted">
                <Settings className="h-5 w-5 text-primary" />
                <span className="flex-1 text-sm font-medium text-primary">Admin dashboard</span>
                <span className="text-muted-foreground">›</span>
              </Link>
            </li>
          )}
          {user && (
            <li>
              <button
                type="button"
                onClick={() => setCodeOpen(true)}
                className="flex w-full items-center gap-3 px-4 py-3.5 text-left transition active:bg-muted"
              >
                <KeyRound className="h-5 w-5 text-muted-foreground" />
                <span className="flex-1 text-sm font-medium">Redeem role code</span>
                <span className="text-muted-foreground">›</span>
              </button>
            </li>
          )}
        </ul>
      </Card>

      <Dialog open={codeOpen} onOpenChange={setCodeOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Redeem a role code</DialogTitle>
          </DialogHeader>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <Label htmlFor="code">Code</Label>
              <Input
                id="code"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="NSE-KITCHEN-3046"
                autoCapitalize="characters"
              />
            </div>
            <Button onClick={redeem} disabled={busy || !code.trim()} className="w-full">
              {busy ? "Redeeming…" : "Redeem code"}
            </Button>
            <p className="text-xs text-muted-foreground">
              Your role unlocks the matching admin tabs immediately — no need to sign out.
            </p>
          </div>
        </DialogContent>
      </Dialog>

      {user ? (
        <Button
          variant="outline"
          className="w-full text-destructive hover:bg-destructive/10 hover:text-destructive"
          onClick={async () => {
            await signOut();
            toast.success("Signed out");
          }}
        >
          <LogOut className="h-4 w-4" /> Sign out
        </Button>
      ) : (
        <Button asChild variant="outline" className="w-full">
          <Link to="/auth">
            <LogIn className="h-4 w-4" /> Sign in
          </Link>
        </Button>
      )}


      <p className="pt-4 text-center text-xs text-muted-foreground">
        {EVENT_CONFIG.name} {EVENT_CONFIG.year}
      </p>
    </div>
  );
}
